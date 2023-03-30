
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	b9010113          	addi	sp,sp,-1136 # 80008b90 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	a0070713          	addi	a4,a4,-1536 # 80008a50 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	1ae78793          	addi	a5,a5,430 # 80006210 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fb9c93f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f7278793          	addi	a5,a5,-142 # 8000101e <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	79a080e7          	jalr	1946(ra) # 800028c4 <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	792080e7          	jalr	1938(ra) # 800008cc <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	711d                	addi	sp,sp,-96
    80000166:	ec86                	sd	ra,88(sp)
    80000168:	e8a2                	sd	s0,80(sp)
    8000016a:	e4a6                	sd	s1,72(sp)
    8000016c:	e0ca                	sd	s2,64(sp)
    8000016e:	fc4e                	sd	s3,56(sp)
    80000170:	f852                	sd	s4,48(sp)
    80000172:	f456                	sd	s5,40(sp)
    80000174:	f05a                	sd	s6,32(sp)
    80000176:	ec5e                	sd	s7,24(sp)
    80000178:	1080                	addi	s0,sp,96
    8000017a:	8aaa                	mv	s5,a0
    8000017c:	8a2e                	mv	s4,a1
    8000017e:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000180:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    80000184:	00011517          	auipc	a0,0x11
    80000188:	a0c50513          	addi	a0,a0,-1524 # 80010b90 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	bf2080e7          	jalr	-1038(ra) # 80000d7e <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	9fc48493          	addi	s1,s1,-1540 # 80010b90 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	a8c90913          	addi	s2,s2,-1396 # 80010c28 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	b4a080e7          	jalr	-1206(ra) # 80001cfe <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	552080e7          	jalr	1362(ra) # 8000270e <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	29c080e7          	jalr	668(ra) # 80002466 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	9b270713          	addi	a4,a4,-1614 # 80010b90 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

        if (c == C('D'))
    800001fc:	4691                	li	a3,4
    800001fe:	06db8463          	beq	s7,a3,80000266 <consoleread+0x102>
            }
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00002097          	auipc	ra,0x2
    80000214:	65e080e7          	jalr	1630(ra) # 8000286e <either_copyout>
    80000218:	57fd                	li	a5,-1
    8000021a:	00f50763          	beq	a0,a5,80000228 <consoleread+0xc4>
            break;

        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1

        if (c == '\n')
    80000222:	47a9                	li	a5,10
    80000224:	f8fb90e3          	bne	s7,a5,800001a4 <consoleread+0x40>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000228:	00011517          	auipc	a0,0x11
    8000022c:	96850513          	addi	a0,a0,-1688 # 80010b90 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	c02080e7          	jalr	-1022(ra) # 80000e32 <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	95250513          	addi	a0,a0,-1710 # 80010b90 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	bec080e7          	jalr	-1044(ra) # 80000e32 <release>
                return -1;
    8000024e:	557d                	li	a0,-1
}
    80000250:	60e6                	ld	ra,88(sp)
    80000252:	6446                	ld	s0,80(sp)
    80000254:	64a6                	ld	s1,72(sp)
    80000256:	6906                	ld	s2,64(sp)
    80000258:	79e2                	ld	s3,56(sp)
    8000025a:	7a42                	ld	s4,48(sp)
    8000025c:	7aa2                	ld	s5,40(sp)
    8000025e:	7b02                	ld	s6,32(sp)
    80000260:	6be2                	ld	s7,24(sp)
    80000262:	6125                	addi	sp,sp,96
    80000264:	8082                	ret
            if (n < target)
    80000266:	0009871b          	sext.w	a4,s3
    8000026a:	fb677fe3          	bgeu	a4,s6,80000228 <consoleread+0xc4>
                cons.r--;
    8000026e:	00011717          	auipc	a4,0x11
    80000272:	9af72d23          	sw	a5,-1606(a4) # 80010c28 <cons+0x98>
    80000276:	bf4d                	j	80000228 <consoleread+0xc4>

0000000080000278 <consputc>:
{
    80000278:	1141                	addi	sp,sp,-16
    8000027a:	e406                	sd	ra,8(sp)
    8000027c:	e022                	sd	s0,0(sp)
    8000027e:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000280:	10000793          	li	a5,256
    80000284:	00f50a63          	beq	a0,a5,80000298 <consputc+0x20>
        uartputc_sync(c);
    80000288:	00000097          	auipc	ra,0x0
    8000028c:	572080e7          	jalr	1394(ra) # 800007fa <uartputc_sync>
}
    80000290:	60a2                	ld	ra,8(sp)
    80000292:	6402                	ld	s0,0(sp)
    80000294:	0141                	addi	sp,sp,16
    80000296:	8082                	ret
        uartputc_sync('\b');
    80000298:	4521                	li	a0,8
    8000029a:	00000097          	auipc	ra,0x0
    8000029e:	560080e7          	jalr	1376(ra) # 800007fa <uartputc_sync>
        uartputc_sync(' ');
    800002a2:	02000513          	li	a0,32
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	554080e7          	jalr	1364(ra) # 800007fa <uartputc_sync>
        uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	54a080e7          	jalr	1354(ra) # 800007fa <uartputc_sync>
    800002b8:	bfe1                	j	80000290 <consputc+0x18>

00000000800002ba <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002ba:	1101                	addi	sp,sp,-32
    800002bc:	ec06                	sd	ra,24(sp)
    800002be:	e822                	sd	s0,16(sp)
    800002c0:	e426                	sd	s1,8(sp)
    800002c2:	e04a                	sd	s2,0(sp)
    800002c4:	1000                	addi	s0,sp,32
    800002c6:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002c8:	00011517          	auipc	a0,0x11
    800002cc:	8c850513          	addi	a0,a0,-1848 # 80010b90 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	aae080e7          	jalr	-1362(ra) # 80000d7e <acquire>

    switch (c)
    800002d8:	47d5                	li	a5,21
    800002da:	0af48663          	beq	s1,a5,80000386 <consoleintr+0xcc>
    800002de:	0297ca63          	blt	a5,s1,80000312 <consoleintr+0x58>
    800002e2:	47a1                	li	a5,8
    800002e4:	0ef48763          	beq	s1,a5,800003d2 <consoleintr+0x118>
    800002e8:	47c1                	li	a5,16
    800002ea:	10f49a63          	bne	s1,a5,800003fe <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002ee:	00002097          	auipc	ra,0x2
    800002f2:	62c080e7          	jalr	1580(ra) # 8000291a <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	89a50513          	addi	a0,a0,-1894 # 80010b90 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	b34080e7          	jalr	-1228(ra) # 80000e32 <release>
}
    80000306:	60e2                	ld	ra,24(sp)
    80000308:	6442                	ld	s0,16(sp)
    8000030a:	64a2                	ld	s1,8(sp)
    8000030c:	6902                	ld	s2,0(sp)
    8000030e:	6105                	addi	sp,sp,32
    80000310:	8082                	ret
    switch (c)
    80000312:	07f00793          	li	a5,127
    80000316:	0af48e63          	beq	s1,a5,800003d2 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031a:	00011717          	auipc	a4,0x11
    8000031e:	87670713          	addi	a4,a4,-1930 # 80010b90 <cons>
    80000322:	0a072783          	lw	a5,160(a4)
    80000326:	09872703          	lw	a4,152(a4)
    8000032a:	9f99                	subw	a5,a5,a4
    8000032c:	07f00713          	li	a4,127
    80000330:	fcf763e3          	bltu	a4,a5,800002f6 <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000334:	47b5                	li	a5,13
    80000336:	0cf48763          	beq	s1,a5,80000404 <consoleintr+0x14a>
            consputc(c);
    8000033a:	8526                	mv	a0,s1
    8000033c:	00000097          	auipc	ra,0x0
    80000340:	f3c080e7          	jalr	-196(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000344:	00011797          	auipc	a5,0x11
    80000348:	84c78793          	addi	a5,a5,-1972 # 80010b90 <cons>
    8000034c:	0a07a683          	lw	a3,160(a5)
    80000350:	0016871b          	addiw	a4,a3,1
    80000354:	0007061b          	sext.w	a2,a4
    80000358:	0ae7a023          	sw	a4,160(a5)
    8000035c:	07f6f693          	andi	a3,a3,127
    80000360:	97b6                	add	a5,a5,a3
    80000362:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    80000366:	47a9                	li	a5,10
    80000368:	0cf48563          	beq	s1,a5,80000432 <consoleintr+0x178>
    8000036c:	4791                	li	a5,4
    8000036e:	0cf48263          	beq	s1,a5,80000432 <consoleintr+0x178>
    80000372:	00011797          	auipc	a5,0x11
    80000376:	8b67a783          	lw	a5,-1866(a5) # 80010c28 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	80a70713          	addi	a4,a4,-2038 # 80010b90 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00010497          	auipc	s1,0x10
    8000039a:	7fa48493          	addi	s1,s1,2042 # 80010b90 <cons>
        while (cons.e != cons.w &&
    8000039e:	4929                	li	s2,10
    800003a0:	f4f70be3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a4:	37fd                	addiw	a5,a5,-1
    800003a6:	07f7f713          	andi	a4,a5,127
    800003aa:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003ac:	01874703          	lbu	a4,24(a4)
    800003b0:	f52703e3          	beq	a4,s2,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003b4:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003b8:	10000513          	li	a0,256
    800003bc:	00000097          	auipc	ra,0x0
    800003c0:	ebc080e7          	jalr	-324(ra) # 80000278 <consputc>
        while (cons.e != cons.w &&
    800003c4:	0a04a783          	lw	a5,160(s1)
    800003c8:	09c4a703          	lw	a4,156(s1)
    800003cc:	fcf71ce3          	bne	a4,a5,800003a4 <consoleintr+0xea>
    800003d0:	b71d                	j	800002f6 <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d2:	00010717          	auipc	a4,0x10
    800003d6:	7be70713          	addi	a4,a4,1982 # 80010b90 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	84f72423          	sw	a5,-1976(a4) # 80010c30 <cons+0xa0>
            consputc(BACKSPACE);
    800003f0:	10000513          	li	a0,256
    800003f4:	00000097          	auipc	ra,0x0
    800003f8:	e84080e7          	jalr	-380(ra) # 80000278 <consputc>
    800003fc:	bded                	j	800002f6 <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    800003fe:	ee048ce3          	beqz	s1,800002f6 <consoleintr+0x3c>
    80000402:	bf21                	j	8000031a <consoleintr+0x60>
            consputc(c);
    80000404:	4529                	li	a0,10
    80000406:	00000097          	auipc	ra,0x0
    8000040a:	e72080e7          	jalr	-398(ra) # 80000278 <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000040e:	00010797          	auipc	a5,0x10
    80000412:	78278793          	addi	a5,a5,1922 # 80010b90 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00010797          	auipc	a5,0x10
    80000436:	7ec7ad23          	sw	a2,2042(a5) # 80010c2c <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00010517          	auipc	a0,0x10
    8000043e:	7ee50513          	addi	a0,a0,2030 # 80010c28 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	088080e7          	jalr	136(ra) # 800024ca <wakeup>
    8000044a:	b575                	j	800002f6 <consoleintr+0x3c>

000000008000044c <consoleinit>:

void consoleinit(void)
{
    8000044c:	1141                	addi	sp,sp,-16
    8000044e:	e406                	sd	ra,8(sp)
    80000450:	e022                	sd	s0,0(sp)
    80000452:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000454:	00008597          	auipc	a1,0x8
    80000458:	bcc58593          	addi	a1,a1,-1076 # 80008020 <__func__.1+0x18>
    8000045c:	00010517          	auipc	a0,0x10
    80000460:	73450513          	addi	a0,a0,1844 # 80010b90 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	88a080e7          	jalr	-1910(ra) # 80000cee <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00461797          	auipc	a5,0x461
    80000478:	8b478793          	addi	a5,a5,-1868 # 80460d28 <devsw>
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	ce870713          	addi	a4,a4,-792 # 80000164 <consoleread>
    80000484:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	c7a70713          	addi	a4,a4,-902 # 80000100 <consolewrite>
    8000048e:	ef98                	sd	a4,24(a5)
}
    80000490:	60a2                	ld	ra,8(sp)
    80000492:	6402                	ld	s0,0(sp)
    80000494:	0141                	addi	sp,sp,16
    80000496:	8082                	ret

0000000080000498 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    80000498:	7179                	addi	sp,sp,-48
    8000049a:	f406                	sd	ra,40(sp)
    8000049c:	f022                	sd	s0,32(sp)
    8000049e:	ec26                	sd	s1,24(sp)
    800004a0:	e84a                	sd	s2,16(sp)
    800004a2:	1800                	addi	s0,sp,48
    char buf[16];
    int i;
    uint x;

    if (sign && (sign = xx < 0))
    800004a4:	c219                	beqz	a2,800004aa <printint+0x12>
    800004a6:	08054763          	bltz	a0,80000534 <printint+0x9c>
        x = -xx;
    else
        x = xx;
    800004aa:	2501                	sext.w	a0,a0
    800004ac:	4881                	li	a7,0
    800004ae:	fd040693          	addi	a3,s0,-48

    i = 0;
    800004b2:	4701                	li	a4,0
    do
    {
        buf[i++] = digits[x % base];
    800004b4:	2581                	sext.w	a1,a1
    800004b6:	00008617          	auipc	a2,0x8
    800004ba:	b9a60613          	addi	a2,a2,-1126 # 80008050 <digits>
    800004be:	883a                	mv	a6,a4
    800004c0:	2705                	addiw	a4,a4,1
    800004c2:	02b577bb          	remuw	a5,a0,a1
    800004c6:	1782                	slli	a5,a5,0x20
    800004c8:	9381                	srli	a5,a5,0x20
    800004ca:	97b2                	add	a5,a5,a2
    800004cc:	0007c783          	lbu	a5,0(a5)
    800004d0:	00f68023          	sb	a5,0(a3)
    } while ((x /= base) != 0);
    800004d4:	0005079b          	sext.w	a5,a0
    800004d8:	02b5553b          	divuw	a0,a0,a1
    800004dc:	0685                	addi	a3,a3,1
    800004de:	feb7f0e3          	bgeu	a5,a1,800004be <printint+0x26>

    if (sign)
    800004e2:	00088c63          	beqz	a7,800004fa <printint+0x62>
        buf[i++] = '-';
    800004e6:	fe070793          	addi	a5,a4,-32
    800004ea:	00878733          	add	a4,a5,s0
    800004ee:	02d00793          	li	a5,45
    800004f2:	fef70823          	sb	a5,-16(a4)
    800004f6:	0028071b          	addiw	a4,a6,2

    while (--i >= 0)
    800004fa:	02e05763          	blez	a4,80000528 <printint+0x90>
    800004fe:	fd040793          	addi	a5,s0,-48
    80000502:	00e784b3          	add	s1,a5,a4
    80000506:	fff78913          	addi	s2,a5,-1
    8000050a:	993a                	add	s2,s2,a4
    8000050c:	377d                	addiw	a4,a4,-1
    8000050e:	1702                	slli	a4,a4,0x20
    80000510:	9301                	srli	a4,a4,0x20
    80000512:	40e90933          	sub	s2,s2,a4
        consputc(buf[i]);
    80000516:	fff4c503          	lbu	a0,-1(s1)
    8000051a:	00000097          	auipc	ra,0x0
    8000051e:	d5e080e7          	jalr	-674(ra) # 80000278 <consputc>
    while (--i >= 0)
    80000522:	14fd                	addi	s1,s1,-1
    80000524:	ff2499e3          	bne	s1,s2,80000516 <printint+0x7e>
}
    80000528:	70a2                	ld	ra,40(sp)
    8000052a:	7402                	ld	s0,32(sp)
    8000052c:	64e2                	ld	s1,24(sp)
    8000052e:	6942                	ld	s2,16(sp)
    80000530:	6145                	addi	sp,sp,48
    80000532:	8082                	ret
        x = -xx;
    80000534:	40a0053b          	negw	a0,a0
    if (sign && (sign = xx < 0))
    80000538:	4885                	li	a7,1
        x = -xx;
    8000053a:	bf95                	j	800004ae <printint+0x16>

000000008000053c <panic>:
    if (locking)
        release(&pr.lock);
}

void panic(char *s, ...)
{
    8000053c:	711d                	addi	sp,sp,-96
    8000053e:	ec06                	sd	ra,24(sp)
    80000540:	e822                	sd	s0,16(sp)
    80000542:	e426                	sd	s1,8(sp)
    80000544:	1000                	addi	s0,sp,32
    80000546:	84aa                	mv	s1,a0
    80000548:	e40c                	sd	a1,8(s0)
    8000054a:	e810                	sd	a2,16(s0)
    8000054c:	ec14                	sd	a3,24(s0)
    8000054e:	f018                	sd	a4,32(s0)
    80000550:	f41c                	sd	a5,40(s0)
    80000552:	03043823          	sd	a6,48(s0)
    80000556:	03143c23          	sd	a7,56(s0)
    pr.locking = 0;
    8000055a:	00010797          	auipc	a5,0x10
    8000055e:	6e07ab23          	sw	zero,1782(a5) # 80010c50 <pr+0x18>
    printf("panic: ");
    80000562:	00008517          	auipc	a0,0x8
    80000566:	ac650513          	addi	a0,a0,-1338 # 80008028 <__func__.1+0x20>
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	02e080e7          	jalr	46(ra) # 80000598 <printf>
    printf(s);
    80000572:	8526                	mv	a0,s1
    80000574:	00000097          	auipc	ra,0x0
    80000578:	024080e7          	jalr	36(ra) # 80000598 <printf>
    printf("\n");
    8000057c:	00008517          	auipc	a0,0x8
    80000580:	b0c50513          	addi	a0,a0,-1268 # 80008088 <digits+0x38>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	46f72923          	sw	a5,1138(a4) # 80008a00 <panicked>
    for (;;)
    80000596:	a001                	j	80000596 <panic+0x5a>

0000000080000598 <printf>:
{
    80000598:	7131                	addi	sp,sp,-192
    8000059a:	fc86                	sd	ra,120(sp)
    8000059c:	f8a2                	sd	s0,112(sp)
    8000059e:	f4a6                	sd	s1,104(sp)
    800005a0:	f0ca                	sd	s2,96(sp)
    800005a2:	ecce                	sd	s3,88(sp)
    800005a4:	e8d2                	sd	s4,80(sp)
    800005a6:	e4d6                	sd	s5,72(sp)
    800005a8:	e0da                	sd	s6,64(sp)
    800005aa:	fc5e                	sd	s7,56(sp)
    800005ac:	f862                	sd	s8,48(sp)
    800005ae:	f466                	sd	s9,40(sp)
    800005b0:	f06a                	sd	s10,32(sp)
    800005b2:	ec6e                	sd	s11,24(sp)
    800005b4:	0100                	addi	s0,sp,128
    800005b6:	8a2a                	mv	s4,a0
    800005b8:	e40c                	sd	a1,8(s0)
    800005ba:	e810                	sd	a2,16(s0)
    800005bc:	ec14                	sd	a3,24(s0)
    800005be:	f018                	sd	a4,32(s0)
    800005c0:	f41c                	sd	a5,40(s0)
    800005c2:	03043823          	sd	a6,48(s0)
    800005c6:	03143c23          	sd	a7,56(s0)
    locking = pr.locking;
    800005ca:	00010d97          	auipc	s11,0x10
    800005ce:	686dad83          	lw	s11,1670(s11) # 80010c50 <pr+0x18>
    if (locking)
    800005d2:	020d9b63          	bnez	s11,80000608 <printf+0x70>
    if (fmt == 0)
    800005d6:	040a0263          	beqz	s4,8000061a <printf+0x82>
    va_start(ap, fmt);
    800005da:	00840793          	addi	a5,s0,8
    800005de:	f8f43423          	sd	a5,-120(s0)
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    800005e2:	000a4503          	lbu	a0,0(s4)
    800005e6:	14050f63          	beqz	a0,80000744 <printf+0x1ac>
    800005ea:	4981                	li	s3,0
        if (c != '%')
    800005ec:	02500a93          	li	s5,37
        switch (c)
    800005f0:	07000b93          	li	s7,112
    consputc('x');
    800005f4:	4d41                	li	s10,16
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f6:	00008b17          	auipc	s6,0x8
    800005fa:	a5ab0b13          	addi	s6,s6,-1446 # 80008050 <digits>
        switch (c)
    800005fe:	07300c93          	li	s9,115
    80000602:	06400c13          	li	s8,100
    80000606:	a82d                	j	80000640 <printf+0xa8>
        acquire(&pr.lock);
    80000608:	00010517          	auipc	a0,0x10
    8000060c:	63050513          	addi	a0,a0,1584 # 80010c38 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	76e080e7          	jalr	1902(ra) # 80000d7e <acquire>
    80000618:	bf7d                	j	800005d6 <printf+0x3e>
        panic("null fmt");
    8000061a:	00008517          	auipc	a0,0x8
    8000061e:	a1e50513          	addi	a0,a0,-1506 # 80008038 <__func__.1+0x30>
    80000622:	00000097          	auipc	ra,0x0
    80000626:	f1a080e7          	jalr	-230(ra) # 8000053c <panic>
            consputc(c);
    8000062a:	00000097          	auipc	ra,0x0
    8000062e:	c4e080e7          	jalr	-946(ra) # 80000278 <consputc>
    for (i = 0; (c = fmt[i] & 0xff) != 0; i++)
    80000632:	2985                	addiw	s3,s3,1
    80000634:	013a07b3          	add	a5,s4,s3
    80000638:	0007c503          	lbu	a0,0(a5)
    8000063c:	10050463          	beqz	a0,80000744 <printf+0x1ac>
        if (c != '%')
    80000640:	ff5515e3          	bne	a0,s5,8000062a <printf+0x92>
        c = fmt[++i] & 0xff;
    80000644:	2985                	addiw	s3,s3,1
    80000646:	013a07b3          	add	a5,s4,s3
    8000064a:	0007c783          	lbu	a5,0(a5)
    8000064e:	0007849b          	sext.w	s1,a5
        if (c == 0)
    80000652:	cbed                	beqz	a5,80000744 <printf+0x1ac>
        switch (c)
    80000654:	05778a63          	beq	a5,s7,800006a8 <printf+0x110>
    80000658:	02fbf663          	bgeu	s7,a5,80000684 <printf+0xec>
    8000065c:	09978863          	beq	a5,s9,800006ec <printf+0x154>
    80000660:	07800713          	li	a4,120
    80000664:	0ce79563          	bne	a5,a4,8000072e <printf+0x196>
            printint(va_arg(ap, int), 16, 1);
    80000668:	f8843783          	ld	a5,-120(s0)
    8000066c:	00878713          	addi	a4,a5,8
    80000670:	f8e43423          	sd	a4,-120(s0)
    80000674:	4605                	li	a2,1
    80000676:	85ea                	mv	a1,s10
    80000678:	4388                	lw	a0,0(a5)
    8000067a:	00000097          	auipc	ra,0x0
    8000067e:	e1e080e7          	jalr	-482(ra) # 80000498 <printint>
            break;
    80000682:	bf45                	j	80000632 <printf+0x9a>
        switch (c)
    80000684:	09578f63          	beq	a5,s5,80000722 <printf+0x18a>
    80000688:	0b879363          	bne	a5,s8,8000072e <printf+0x196>
            printint(va_arg(ap, int), 10, 1);
    8000068c:	f8843783          	ld	a5,-120(s0)
    80000690:	00878713          	addi	a4,a5,8
    80000694:	f8e43423          	sd	a4,-120(s0)
    80000698:	4605                	li	a2,1
    8000069a:	45a9                	li	a1,10
    8000069c:	4388                	lw	a0,0(a5)
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	dfa080e7          	jalr	-518(ra) # 80000498 <printint>
            break;
    800006a6:	b771                	j	80000632 <printf+0x9a>
            printptr(va_arg(ap, uint64));
    800006a8:	f8843783          	ld	a5,-120(s0)
    800006ac:	00878713          	addi	a4,a5,8
    800006b0:	f8e43423          	sd	a4,-120(s0)
    800006b4:	0007b903          	ld	s2,0(a5)
    consputc('0');
    800006b8:	03000513          	li	a0,48
    800006bc:	00000097          	auipc	ra,0x0
    800006c0:	bbc080e7          	jalr	-1092(ra) # 80000278 <consputc>
    consputc('x');
    800006c4:	07800513          	li	a0,120
    800006c8:	00000097          	auipc	ra,0x0
    800006cc:	bb0080e7          	jalr	-1104(ra) # 80000278 <consputc>
    800006d0:	84ea                	mv	s1,s10
        consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d2:	03c95793          	srli	a5,s2,0x3c
    800006d6:	97da                	add	a5,a5,s6
    800006d8:	0007c503          	lbu	a0,0(a5)
    800006dc:	00000097          	auipc	ra,0x0
    800006e0:	b9c080e7          	jalr	-1124(ra) # 80000278 <consputc>
    for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e4:	0912                	slli	s2,s2,0x4
    800006e6:	34fd                	addiw	s1,s1,-1
    800006e8:	f4ed                	bnez	s1,800006d2 <printf+0x13a>
    800006ea:	b7a1                	j	80000632 <printf+0x9a>
            if ((s = va_arg(ap, char *)) == 0)
    800006ec:	f8843783          	ld	a5,-120(s0)
    800006f0:	00878713          	addi	a4,a5,8
    800006f4:	f8e43423          	sd	a4,-120(s0)
    800006f8:	6384                	ld	s1,0(a5)
    800006fa:	cc89                	beqz	s1,80000714 <printf+0x17c>
            for (; *s; s++)
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	d90d                	beqz	a0,80000632 <printf+0x9a>
                consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b76080e7          	jalr	-1162(ra) # 80000278 <consputc>
            for (; *s; s++)
    8000070a:	0485                	addi	s1,s1,1
    8000070c:	0004c503          	lbu	a0,0(s1)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x16a>
    80000712:	b705                	j	80000632 <printf+0x9a>
                s = "(null)";
    80000714:	00008497          	auipc	s1,0x8
    80000718:	91c48493          	addi	s1,s1,-1764 # 80008030 <__func__.1+0x28>
            for (; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x16a>
            consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b54080e7          	jalr	-1196(ra) # 80000278 <consputc>
            break;
    8000072c:	b719                	j	80000632 <printf+0x9a>
            consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b48080e7          	jalr	-1208(ra) # 80000278 <consputc>
            consputc(c);
    80000738:	8526                	mv	a0,s1
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b3e080e7          	jalr	-1218(ra) # 80000278 <consputc>
            break;
    80000742:	bdc5                	j	80000632 <printf+0x9a>
    if (locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1ce>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
        release(&pr.lock);
    80000766:	00010517          	auipc	a0,0x10
    8000076a:	4d250513          	addi	a0,a0,1234 # 80010c38 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	6c4080e7          	jalr	1732(ra) # 80000e32 <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b0>

0000000080000778 <printfinit>:
        ;
}

void printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
    initlock(&pr.lock, "pr");
    80000782:	00010497          	auipc	s1,0x10
    80000786:	4b648493          	addi	s1,s1,1206 # 80010c38 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8be58593          	addi	a1,a1,-1858 # 80008048 <__func__.1+0x40>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	55a080e7          	jalr	1370(ra) # 80000cee <initlock>
    pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	88e58593          	addi	a1,a1,-1906 # 80008068 <digits+0x18>
    800007e2:	00010517          	auipc	a0,0x10
    800007e6:	47650513          	addi	a0,a0,1142 # 80010c58 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	504080e7          	jalr	1284(ra) # 80000cee <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	52c080e7          	jalr	1324(ra) # 80000d32 <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	1f27a783          	lw	a5,498(a5) # 80008a00 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dfe5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f513          	zext.b	a0,s1
    8000082c:	100007b7          	lui	a5,0x10000
    80000830:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	59e080e7          	jalr	1438(ra) # 80000dd2 <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008797          	auipc	a5,0x8
    8000084a:	1c27b783          	ld	a5,450(a5) # 80008a08 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	1c273703          	ld	a4,450(a4) # 80008a10 <uart_tx_w>
    80000856:	06f70a63          	beq	a4,a5,800008ca <uartstart+0x84>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	3e8a0a13          	addi	s4,s4,1000 # 80010c58 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	19048493          	addi	s1,s1,400 # 80008a08 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	19098993          	addi	s3,s3,400 # 80008a10 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	02077713          	andi	a4,a4,32
    80000890:	c705                	beqz	a4,800008b8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000892:	01f7f713          	andi	a4,a5,31
    80000896:	9752                	add	a4,a4,s4
    80000898:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000089c:	0785                	addi	a5,a5,1
    8000089e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a0:	8526                	mv	a0,s1
    800008a2:	00002097          	auipc	ra,0x2
    800008a6:	c28080e7          	jalr	-984(ra) # 800024ca <wakeup>
    
    WriteReg(THR, c);
    800008aa:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ae:	609c                	ld	a5,0(s1)
    800008b0:	0009b703          	ld	a4,0(s3)
    800008b4:	fcf71ae3          	bne	a4,a5,80000888 <uartstart+0x42>
  }
}
    800008b8:	70e2                	ld	ra,56(sp)
    800008ba:	7442                	ld	s0,48(sp)
    800008bc:	74a2                	ld	s1,40(sp)
    800008be:	7902                	ld	s2,32(sp)
    800008c0:	69e2                	ld	s3,24(sp)
    800008c2:	6a42                	ld	s4,16(sp)
    800008c4:	6aa2                	ld	s5,8(sp)
    800008c6:	6121                	addi	sp,sp,64
    800008c8:	8082                	ret
    800008ca:	8082                	ret

00000000800008cc <uartputc>:
{
    800008cc:	7179                	addi	sp,sp,-48
    800008ce:	f406                	sd	ra,40(sp)
    800008d0:	f022                	sd	s0,32(sp)
    800008d2:	ec26                	sd	s1,24(sp)
    800008d4:	e84a                	sd	s2,16(sp)
    800008d6:	e44e                	sd	s3,8(sp)
    800008d8:	e052                	sd	s4,0(sp)
    800008da:	1800                	addi	s0,sp,48
    800008dc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008de:	00010517          	auipc	a0,0x10
    800008e2:	37a50513          	addi	a0,a0,890 # 80010c58 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	498080e7          	jalr	1176(ra) # 80000d7e <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1127a783          	lw	a5,274(a5) # 80008a00 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	11873703          	ld	a4,280(a4) # 80008a10 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1087b783          	ld	a5,264(a5) # 80008a08 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	34c98993          	addi	s3,s3,844 # 80010c58 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	0f448493          	addi	s1,s1,244 # 80008a08 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	0f490913          	addi	s2,s2,244 # 80008a10 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	b3a080e7          	jalr	-1222(ra) # 80002466 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	31648493          	addi	s1,s1,790 # 80010c58 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	0ae7bd23          	sd	a4,186(a5) # 80008a10 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	4ca080e7          	jalr	1226(ra) # 80000e32 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret
    for(;;)
    80000980:	a001                	j	80000980 <uartputc+0xb4>

0000000080000982 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000982:	1141                	addi	sp,sp,-16
    80000984:	e422                	sd	s0,8(sp)
    80000986:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000988:	100007b7          	lui	a5,0x10000
    8000098c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000990:	8b85                	andi	a5,a5,1
    80000992:	cb81                	beqz	a5,800009a2 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000994:	100007b7          	lui	a5,0x10000
    80000998:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000099c:	6422                	ld	s0,8(sp)
    8000099e:	0141                	addi	sp,sp,16
    800009a0:	8082                	ret
    return -1;
    800009a2:	557d                	li	a0,-1
    800009a4:	bfe5                	j	8000099c <uartgetc+0x1a>

00000000800009a6 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009a6:	1101                	addi	sp,sp,-32
    800009a8:	ec06                	sd	ra,24(sp)
    800009aa:	e822                	sd	s0,16(sp)
    800009ac:	e426                	sd	s1,8(sp)
    800009ae:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b0:	54fd                	li	s1,-1
    800009b2:	a029                	j	800009bc <uartintr+0x16>
      break;
    consoleintr(c);
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	906080e7          	jalr	-1786(ra) # 800002ba <consoleintr>
    int c = uartgetc();
    800009bc:	00000097          	auipc	ra,0x0
    800009c0:	fc6080e7          	jalr	-58(ra) # 80000982 <uartgetc>
    if(c == -1)
    800009c4:	fe9518e3          	bne	a0,s1,800009b4 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009c8:	00010497          	auipc	s1,0x10
    800009cc:	29048493          	addi	s1,s1,656 # 80010c58 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	3ac080e7          	jalr	940(ra) # 80000d7e <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	44e080e7          	jalr	1102(ra) # 80000e32 <release>
}
    800009ec:	60e2                	ld	ra,24(sp)
    800009ee:	6442                	ld	s0,16(sp)
    800009f0:	64a2                	ld	s1,8(sp)
    800009f2:	6105                	addi	sp,sp,32
    800009f4:	8082                	ret

00000000800009f6 <increment_refcount>:
        kfree(p);
    }
}

// Keep track of refcount
void increment_refcount(uint64 pa) {
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	e04a                	sd	s2,0(sp)
    80000a00:	1000                	addi	s0,sp,32
    int page_num = pa / PGSIZE;
    80000a02:	00c55493          	srli	s1,a0,0xc
    80000a06:	2481                	sext.w	s1,s1
    acquire(&kmem.lock);
    80000a08:	00010917          	auipc	s2,0x10
    80000a0c:	28890913          	addi	s2,s2,648 # 80010c90 <kmem>
    80000a10:	854a                	mv	a0,s2
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	36c080e7          	jalr	876(ra) # 80000d7e <acquire>
    ref_count[page_num]++;
    80000a1a:	048a                	slli	s1,s1,0x2
    80000a1c:	00010797          	auipc	a5,0x10
    80000a20:	29478793          	addi	a5,a5,660 # 80010cb0 <ref_count>
    80000a24:	97a6                	add	a5,a5,s1
    80000a26:	4398                	lw	a4,0(a5)
    80000a28:	2705                	addiw	a4,a4,1
    80000a2a:	c398                	sw	a4,0(a5)
    release(&kmem.lock);
    80000a2c:	854a                	mv	a0,s2
    80000a2e:	00000097          	auipc	ra,0x0
    80000a32:	404080e7          	jalr	1028(ra) # 80000e32 <release>
}
    80000a36:	60e2                	ld	ra,24(sp)
    80000a38:	6442                	ld	s0,16(sp)
    80000a3a:	64a2                	ld	s1,8(sp)
    80000a3c:	6902                	ld	s2,0(sp)
    80000a3e:	6105                	addi	sp,sp,32
    80000a40:	8082                	ret

0000000080000a42 <decrement_refcount>:

int decrement_refcount(uint64 pa) {
    80000a42:	1101                	addi	sp,sp,-32
    80000a44:	ec06                	sd	ra,24(sp)
    80000a46:	e822                	sd	s0,16(sp)
    80000a48:	e426                	sd	s1,8(sp)
    80000a4a:	e04a                	sd	s2,0(sp)
    80000a4c:	1000                	addi	s0,sp,32
    int page_num = pa / PGSIZE;
    80000a4e:	00c55493          	srli	s1,a0,0xc
    80000a52:	2481                	sext.w	s1,s1
    acquire(&kmem.lock);
    80000a54:	00010917          	auipc	s2,0x10
    80000a58:	23c90913          	addi	s2,s2,572 # 80010c90 <kmem>
    80000a5c:	854a                	mv	a0,s2
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	320080e7          	jalr	800(ra) # 80000d7e <acquire>
    ref_count[page_num]--;
    80000a66:	048a                	slli	s1,s1,0x2
    80000a68:	00010797          	auipc	a5,0x10
    80000a6c:	24878793          	addi	a5,a5,584 # 80010cb0 <ref_count>
    80000a70:	94be                	add	s1,s1,a5
    80000a72:	409c                	lw	a5,0(s1)
    80000a74:	37fd                	addiw	a5,a5,-1
    80000a76:	c09c                	sw	a5,0(s1)
    release(&kmem.lock);
    80000a78:	854a                	mv	a0,s2
    80000a7a:	00000097          	auipc	ra,0x0
    80000a7e:	3b8080e7          	jalr	952(ra) # 80000e32 <release>

    // Check if we have refs still
    if (ref_count[page_num] > 0) {
    80000a82:	4088                	lw	a0,0(s1)
        return 1;
    }
    return 0;
}
    80000a84:	00a03533          	snez	a0,a0
    80000a88:	60e2                	ld	ra,24(sp)
    80000a8a:	6442                	ld	s0,16(sp)
    80000a8c:	64a2                	ld	s1,8(sp)
    80000a8e:	6902                	ld	s2,0(sp)
    80000a90:	6105                	addi	sp,sp,32
    80000a92:	8082                	ret

0000000080000a94 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a94:	1101                	addi	sp,sp,-32
    80000a96:	ec06                	sd	ra,24(sp)
    80000a98:	e822                	sd	s0,16(sp)
    80000a9a:	e426                	sd	s1,8(sp)
    80000a9c:	e04a                	sd	s2,0(sp)
    80000a9e:	1000                	addi	s0,sp,32
    80000aa0:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000aa2:	00008797          	auipc	a5,0x8
    80000aa6:	f7e7b783          	ld	a5,-130(a5) # 80008a20 <MAX_PAGES>
    80000aaa:	c799                	beqz	a5,80000ab8 <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000aac:	00008717          	auipc	a4,0x8
    80000ab0:	f6c73703          	ld	a4,-148(a4) # 80008a18 <FREE_PAGES>
    80000ab4:	02f77c63          	bgeu	a4,a5,80000aec <kfree+0x58>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) {
    80000ab8:	03449793          	slli	a5,s1,0x34
    80000abc:	e3b5                	bnez	a5,80000b20 <kfree+0x8c>
    80000abe:	00461797          	auipc	a5,0x461
    80000ac2:	40278793          	addi	a5,a5,1026 # 80461ec0 <end>
    80000ac6:	04f4ed63          	bltu	s1,a5,80000b20 <kfree+0x8c>
    80000aca:	47c5                	li	a5,17
    80000acc:	07ee                	slli	a5,a5,0x1b
    80000ace:	04f4f963          	bgeu	s1,a5,80000b20 <kfree+0x8c>
        panic("kfree");
    }

    // We check if we still have some references to the page before continuing
    // If page has refs, we return, otherwise we continue to free it
    if (decrement_refcount((uint64) pa) > 0) {
    80000ad2:	8526                	mv	a0,s1
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	f6e080e7          	jalr	-146(ra) # 80000a42 <decrement_refcount>
    80000adc:	04a05a63          	blez	a0,80000b30 <kfree+0x9c>
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    FREE_PAGES++;
    release(&kmem.lock);
}
    80000ae0:	60e2                	ld	ra,24(sp)
    80000ae2:	6442                	ld	s0,16(sp)
    80000ae4:	64a2                	ld	s1,8(sp)
    80000ae6:	6902                	ld	s2,0(sp)
    80000ae8:	6105                	addi	sp,sp,32
    80000aea:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000aec:	05400693          	li	a3,84
    80000af0:	00007617          	auipc	a2,0x7
    80000af4:	51860613          	addi	a2,a2,1304 # 80008008 <__func__.1>
    80000af8:	00007597          	auipc	a1,0x7
    80000afc:	57858593          	addi	a1,a1,1400 # 80008070 <digits+0x20>
    80000b00:	00007517          	auipc	a0,0x7
    80000b04:	58050513          	addi	a0,a0,1408 # 80008080 <digits+0x30>
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	a90080e7          	jalr	-1392(ra) # 80000598 <printf>
    80000b10:	00007517          	auipc	a0,0x7
    80000b14:	58050513          	addi	a0,a0,1408 # 80008090 <digits+0x40>
    80000b18:	00000097          	auipc	ra,0x0
    80000b1c:	a24080e7          	jalr	-1500(ra) # 8000053c <panic>
        panic("kfree");
    80000b20:	00007517          	auipc	a0,0x7
    80000b24:	58050513          	addi	a0,a0,1408 # 800080a0 <digits+0x50>
    80000b28:	00000097          	auipc	ra,0x0
    80000b2c:	a14080e7          	jalr	-1516(ra) # 8000053c <panic>
    memset(pa, 1, PGSIZE);
    80000b30:	6605                	lui	a2,0x1
    80000b32:	4585                	li	a1,1
    80000b34:	8526                	mv	a0,s1
    80000b36:	00000097          	auipc	ra,0x0
    80000b3a:	344080e7          	jalr	836(ra) # 80000e7a <memset>
    acquire(&kmem.lock);
    80000b3e:	00010917          	auipc	s2,0x10
    80000b42:	15290913          	addi	s2,s2,338 # 80010c90 <kmem>
    80000b46:	854a                	mv	a0,s2
    80000b48:	00000097          	auipc	ra,0x0
    80000b4c:	236080e7          	jalr	566(ra) # 80000d7e <acquire>
    r->next = kmem.freelist;
    80000b50:	01893783          	ld	a5,24(s2)
    80000b54:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000b56:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000b5a:	00008717          	auipc	a4,0x8
    80000b5e:	ebe70713          	addi	a4,a4,-322 # 80008a18 <FREE_PAGES>
    80000b62:	631c                	ld	a5,0(a4)
    80000b64:	0785                	addi	a5,a5,1
    80000b66:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000b68:	854a                	mv	a0,s2
    80000b6a:	00000097          	auipc	ra,0x0
    80000b6e:	2c8080e7          	jalr	712(ra) # 80000e32 <release>
    80000b72:	b7bd                	j	80000ae0 <kfree+0x4c>

0000000080000b74 <freerange>:
{
    80000b74:	7139                	addi	sp,sp,-64
    80000b76:	fc06                	sd	ra,56(sp)
    80000b78:	f822                	sd	s0,48(sp)
    80000b7a:	f426                	sd	s1,40(sp)
    80000b7c:	f04a                	sd	s2,32(sp)
    80000b7e:	ec4e                	sd	s3,24(sp)
    80000b80:	e852                	sd	s4,16(sp)
    80000b82:	e456                	sd	s5,8(sp)
    80000b84:	e05a                	sd	s6,0(sp)
    80000b86:	0080                	addi	s0,sp,64
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000b88:	6785                	lui	a5,0x1
    80000b8a:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b8e:	953a                	add	a0,a0,a4
    80000b90:	777d                	lui	a4,0xfffff
    80000b92:	00e574b3          	and	s1,a0,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b96:	97a6                	add	a5,a5,s1
    80000b98:	02f5ea63          	bltu	a1,a5,80000bcc <freerange+0x58>
    80000b9c:	892e                	mv	s2,a1
        ref_count[(uint64) p / PGSIZE] = 1;
    80000b9e:	00010b17          	auipc	s6,0x10
    80000ba2:	112b0b13          	addi	s6,s6,274 # 80010cb0 <ref_count>
    80000ba6:	4a85                	li	s5,1
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ba8:	6a05                	lui	s4,0x1
    80000baa:	6989                	lui	s3,0x2
        ref_count[(uint64) p / PGSIZE] = 1;
    80000bac:	00c4d793          	srli	a5,s1,0xc
    80000bb0:	078a                	slli	a5,a5,0x2
    80000bb2:	97da                	add	a5,a5,s6
    80000bb4:	0157a023          	sw	s5,0(a5)
        kfree(p);
    80000bb8:	8526                	mv	a0,s1
    80000bba:	00000097          	auipc	ra,0x0
    80000bbe:	eda080e7          	jalr	-294(ra) # 80000a94 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bc2:	87a6                	mv	a5,s1
    80000bc4:	94d2                	add	s1,s1,s4
    80000bc6:	97ce                	add	a5,a5,s3
    80000bc8:	fef972e3          	bgeu	s2,a5,80000bac <freerange+0x38>
}
    80000bcc:	70e2                	ld	ra,56(sp)
    80000bce:	7442                	ld	s0,48(sp)
    80000bd0:	74a2                	ld	s1,40(sp)
    80000bd2:	7902                	ld	s2,32(sp)
    80000bd4:	69e2                	ld	s3,24(sp)
    80000bd6:	6a42                	ld	s4,16(sp)
    80000bd8:	6aa2                	ld	s5,8(sp)
    80000bda:	6b02                	ld	s6,0(sp)
    80000bdc:	6121                	addi	sp,sp,64
    80000bde:	8082                	ret

0000000080000be0 <kinit>:
{
    80000be0:	1141                	addi	sp,sp,-16
    80000be2:	e406                	sd	ra,8(sp)
    80000be4:	e022                	sd	s0,0(sp)
    80000be6:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000be8:	00007597          	auipc	a1,0x7
    80000bec:	4c058593          	addi	a1,a1,1216 # 800080a8 <digits+0x58>
    80000bf0:	00010517          	auipc	a0,0x10
    80000bf4:	0a050513          	addi	a0,a0,160 # 80010c90 <kmem>
    80000bf8:	00000097          	auipc	ra,0x0
    80000bfc:	0f6080e7          	jalr	246(ra) # 80000cee <initlock>
    freerange(end, (void *)PHYSTOP);
    80000c00:	45c5                	li	a1,17
    80000c02:	05ee                	slli	a1,a1,0x1b
    80000c04:	00461517          	auipc	a0,0x461
    80000c08:	2bc50513          	addi	a0,a0,700 # 80461ec0 <end>
    80000c0c:	00000097          	auipc	ra,0x0
    80000c10:	f68080e7          	jalr	-152(ra) # 80000b74 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000c14:	00008797          	auipc	a5,0x8
    80000c18:	e047b783          	ld	a5,-508(a5) # 80008a18 <FREE_PAGES>
    80000c1c:	00008717          	auipc	a4,0x8
    80000c20:	e0f73223          	sd	a5,-508(a4) # 80008a20 <MAX_PAGES>
}
    80000c24:	60a2                	ld	ra,8(sp)
    80000c26:	6402                	ld	s0,0(sp)
    80000c28:	0141                	addi	sp,sp,16
    80000c2a:	8082                	ret

0000000080000c2c <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c2c:	1101                	addi	sp,sp,-32
    80000c2e:	ec06                	sd	ra,24(sp)
    80000c30:	e822                	sd	s0,16(sp)
    80000c32:	e426                	sd	s1,8(sp)
    80000c34:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000c36:	00008797          	auipc	a5,0x8
    80000c3a:	de27b783          	ld	a5,-542(a5) # 80008a18 <FREE_PAGES>
    80000c3e:	c7ad                	beqz	a5,80000ca8 <kalloc+0x7c>
    struct run *r;

    acquire(&kmem.lock);
    80000c40:	00010497          	auipc	s1,0x10
    80000c44:	05048493          	addi	s1,s1,80 # 80010c90 <kmem>
    80000c48:	8526                	mv	a0,s1
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	134080e7          	jalr	308(ra) # 80000d7e <acquire>
    r = kmem.freelist;
    80000c52:	6c84                	ld	s1,24(s1)
    if (r) {
    80000c54:	c4c1                	beqz	s1,80000cdc <kalloc+0xb0>
        kmem.freelist = r->next;
    80000c56:	609c                	ld	a5,0(s1)
    80000c58:	00010517          	auipc	a0,0x10
    80000c5c:	03850513          	addi	a0,a0,56 # 80010c90 <kmem>
    80000c60:	ed1c                	sd	a5,24(a0)

        // We set the refcount for the page to one when allocating
        int page_num = (uint64) r / PGSIZE;
    80000c62:	00c4d793          	srli	a5,s1,0xc
        ref_count[page_num] = 1;
    80000c66:	2781                	sext.w	a5,a5
    80000c68:	078a                	slli	a5,a5,0x2
    80000c6a:	00010717          	auipc	a4,0x10
    80000c6e:	04670713          	addi	a4,a4,70 # 80010cb0 <ref_count>
    80000c72:	97ba                	add	a5,a5,a4
    80000c74:	4705                	li	a4,1
    80000c76:	c398                	sw	a4,0(a5)
    } 
    release(&kmem.lock);
    80000c78:	00000097          	auipc	ra,0x0
    80000c7c:	1ba080e7          	jalr	442(ra) # 80000e32 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000c80:	6605                	lui	a2,0x1
    80000c82:	4595                	li	a1,5
    80000c84:	8526                	mv	a0,s1
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	1f4080e7          	jalr	500(ra) # 80000e7a <memset>
    FREE_PAGES--;
    80000c8e:	00008717          	auipc	a4,0x8
    80000c92:	d8a70713          	addi	a4,a4,-630 # 80008a18 <FREE_PAGES>
    80000c96:	631c                	ld	a5,0(a4)
    80000c98:	17fd                	addi	a5,a5,-1
    80000c9a:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000c9c:	8526                	mv	a0,s1
    80000c9e:	60e2                	ld	ra,24(sp)
    80000ca0:	6442                	ld	s0,16(sp)
    80000ca2:	64a2                	ld	s1,8(sp)
    80000ca4:	6105                	addi	sp,sp,32
    80000ca6:	8082                	ret
    assert(FREE_PAGES > 0);
    80000ca8:	07300693          	li	a3,115
    80000cac:	00007617          	auipc	a2,0x7
    80000cb0:	35460613          	addi	a2,a2,852 # 80008000 <etext>
    80000cb4:	00007597          	auipc	a1,0x7
    80000cb8:	3bc58593          	addi	a1,a1,956 # 80008070 <digits+0x20>
    80000cbc:	00007517          	auipc	a0,0x7
    80000cc0:	3c450513          	addi	a0,a0,964 # 80008080 <digits+0x30>
    80000cc4:	00000097          	auipc	ra,0x0
    80000cc8:	8d4080e7          	jalr	-1836(ra) # 80000598 <printf>
    80000ccc:	00007517          	auipc	a0,0x7
    80000cd0:	3c450513          	addi	a0,a0,964 # 80008090 <digits+0x40>
    80000cd4:	00000097          	auipc	ra,0x0
    80000cd8:	868080e7          	jalr	-1944(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000cdc:	00010517          	auipc	a0,0x10
    80000ce0:	fb450513          	addi	a0,a0,-76 # 80010c90 <kmem>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	14e080e7          	jalr	334(ra) # 80000e32 <release>
    if (r)
    80000cec:	b74d                	j	80000c8e <kalloc+0x62>

0000000080000cee <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cee:	1141                	addi	sp,sp,-16
    80000cf0:	e422                	sd	s0,8(sp)
    80000cf2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cf4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cf6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cfa:	00053823          	sd	zero,16(a0)
}
    80000cfe:	6422                	ld	s0,8(sp)
    80000d00:	0141                	addi	sp,sp,16
    80000d02:	8082                	ret

0000000080000d04 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d04:	411c                	lw	a5,0(a0)
    80000d06:	e399                	bnez	a5,80000d0c <holding+0x8>
    80000d08:	4501                	li	a0,0
  return r;
}
    80000d0a:	8082                	ret
{
    80000d0c:	1101                	addi	sp,sp,-32
    80000d0e:	ec06                	sd	ra,24(sp)
    80000d10:	e822                	sd	s0,16(sp)
    80000d12:	e426                	sd	s1,8(sp)
    80000d14:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d16:	6904                	ld	s1,16(a0)
    80000d18:	00001097          	auipc	ra,0x1
    80000d1c:	fca080e7          	jalr	-54(ra) # 80001ce2 <mycpu>
    80000d20:	40a48533          	sub	a0,s1,a0
    80000d24:	00153513          	seqz	a0,a0
}
    80000d28:	60e2                	ld	ra,24(sp)
    80000d2a:	6442                	ld	s0,16(sp)
    80000d2c:	64a2                	ld	s1,8(sp)
    80000d2e:	6105                	addi	sp,sp,32
    80000d30:	8082                	ret

0000000080000d32 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d32:	1101                	addi	sp,sp,-32
    80000d34:	ec06                	sd	ra,24(sp)
    80000d36:	e822                	sd	s0,16(sp)
    80000d38:	e426                	sd	s1,8(sp)
    80000d3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3c:	100024f3          	csrr	s1,sstatus
    80000d40:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d44:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d46:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d4a:	00001097          	auipc	ra,0x1
    80000d4e:	f98080e7          	jalr	-104(ra) # 80001ce2 <mycpu>
    80000d52:	5d3c                	lw	a5,120(a0)
    80000d54:	cf89                	beqz	a5,80000d6e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d56:	00001097          	auipc	ra,0x1
    80000d5a:	f8c080e7          	jalr	-116(ra) # 80001ce2 <mycpu>
    80000d5e:	5d3c                	lw	a5,120(a0)
    80000d60:	2785                	addiw	a5,a5,1
    80000d62:	dd3c                	sw	a5,120(a0)
}
    80000d64:	60e2                	ld	ra,24(sp)
    80000d66:	6442                	ld	s0,16(sp)
    80000d68:	64a2                	ld	s1,8(sp)
    80000d6a:	6105                	addi	sp,sp,32
    80000d6c:	8082                	ret
    mycpu()->intena = old;
    80000d6e:	00001097          	auipc	ra,0x1
    80000d72:	f74080e7          	jalr	-140(ra) # 80001ce2 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d76:	8085                	srli	s1,s1,0x1
    80000d78:	8885                	andi	s1,s1,1
    80000d7a:	dd64                	sw	s1,124(a0)
    80000d7c:	bfe9                	j	80000d56 <push_off+0x24>

0000000080000d7e <acquire>:
{
    80000d7e:	1101                	addi	sp,sp,-32
    80000d80:	ec06                	sd	ra,24(sp)
    80000d82:	e822                	sd	s0,16(sp)
    80000d84:	e426                	sd	s1,8(sp)
    80000d86:	1000                	addi	s0,sp,32
    80000d88:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d8a:	00000097          	auipc	ra,0x0
    80000d8e:	fa8080e7          	jalr	-88(ra) # 80000d32 <push_off>
  if(holding(lk))
    80000d92:	8526                	mv	a0,s1
    80000d94:	00000097          	auipc	ra,0x0
    80000d98:	f70080e7          	jalr	-144(ra) # 80000d04 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d9c:	4705                	li	a4,1
  if(holding(lk))
    80000d9e:	e115                	bnez	a0,80000dc2 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000da0:	87ba                	mv	a5,a4
    80000da2:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000da6:	2781                	sext.w	a5,a5
    80000da8:	ffe5                	bnez	a5,80000da0 <acquire+0x22>
  __sync_synchronize();
    80000daa:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dae:	00001097          	auipc	ra,0x1
    80000db2:	f34080e7          	jalr	-204(ra) # 80001ce2 <mycpu>
    80000db6:	e888                	sd	a0,16(s1)
}
    80000db8:	60e2                	ld	ra,24(sp)
    80000dba:	6442                	ld	s0,16(sp)
    80000dbc:	64a2                	ld	s1,8(sp)
    80000dbe:	6105                	addi	sp,sp,32
    80000dc0:	8082                	ret
    panic("acquire");
    80000dc2:	00007517          	auipc	a0,0x7
    80000dc6:	2ee50513          	addi	a0,a0,750 # 800080b0 <digits+0x60>
    80000dca:	fffff097          	auipc	ra,0xfffff
    80000dce:	772080e7          	jalr	1906(ra) # 8000053c <panic>

0000000080000dd2 <pop_off>:

void
pop_off(void)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e406                	sd	ra,8(sp)
    80000dd6:	e022                	sd	s0,0(sp)
    80000dd8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dda:	00001097          	auipc	ra,0x1
    80000dde:	f08080e7          	jalr	-248(ra) # 80001ce2 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000de2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000de6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000de8:	e78d                	bnez	a5,80000e12 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000dea:	5d3c                	lw	a5,120(a0)
    80000dec:	02f05b63          	blez	a5,80000e22 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000df0:	37fd                	addiw	a5,a5,-1
    80000df2:	0007871b          	sext.w	a4,a5
    80000df6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000df8:	eb09                	bnez	a4,80000e0a <pop_off+0x38>
    80000dfa:	5d7c                	lw	a5,124(a0)
    80000dfc:	c799                	beqz	a5,80000e0a <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dfe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e02:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e06:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e0a:	60a2                	ld	ra,8(sp)
    80000e0c:	6402                	ld	s0,0(sp)
    80000e0e:	0141                	addi	sp,sp,16
    80000e10:	8082                	ret
    panic("pop_off - interruptible");
    80000e12:	00007517          	auipc	a0,0x7
    80000e16:	2a650513          	addi	a0,a0,678 # 800080b8 <digits+0x68>
    80000e1a:	fffff097          	auipc	ra,0xfffff
    80000e1e:	722080e7          	jalr	1826(ra) # 8000053c <panic>
    panic("pop_off");
    80000e22:	00007517          	auipc	a0,0x7
    80000e26:	2ae50513          	addi	a0,a0,686 # 800080d0 <digits+0x80>
    80000e2a:	fffff097          	auipc	ra,0xfffff
    80000e2e:	712080e7          	jalr	1810(ra) # 8000053c <panic>

0000000080000e32 <release>:
{
    80000e32:	1101                	addi	sp,sp,-32
    80000e34:	ec06                	sd	ra,24(sp)
    80000e36:	e822                	sd	s0,16(sp)
    80000e38:	e426                	sd	s1,8(sp)
    80000e3a:	1000                	addi	s0,sp,32
    80000e3c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e3e:	00000097          	auipc	ra,0x0
    80000e42:	ec6080e7          	jalr	-314(ra) # 80000d04 <holding>
    80000e46:	c115                	beqz	a0,80000e6a <release+0x38>
  lk->cpu = 0;
    80000e48:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e4c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e50:	0f50000f          	fence	iorw,ow
    80000e54:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e58:	00000097          	auipc	ra,0x0
    80000e5c:	f7a080e7          	jalr	-134(ra) # 80000dd2 <pop_off>
}
    80000e60:	60e2                	ld	ra,24(sp)
    80000e62:	6442                	ld	s0,16(sp)
    80000e64:	64a2                	ld	s1,8(sp)
    80000e66:	6105                	addi	sp,sp,32
    80000e68:	8082                	ret
    panic("release");
    80000e6a:	00007517          	auipc	a0,0x7
    80000e6e:	26e50513          	addi	a0,a0,622 # 800080d8 <digits+0x88>
    80000e72:	fffff097          	auipc	ra,0xfffff
    80000e76:	6ca080e7          	jalr	1738(ra) # 8000053c <panic>

0000000080000e7a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e7a:	1141                	addi	sp,sp,-16
    80000e7c:	e422                	sd	s0,8(sp)
    80000e7e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e80:	ca19                	beqz	a2,80000e96 <memset+0x1c>
    80000e82:	87aa                	mv	a5,a0
    80000e84:	1602                	slli	a2,a2,0x20
    80000e86:	9201                	srli	a2,a2,0x20
    80000e88:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e8c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e90:	0785                	addi	a5,a5,1
    80000e92:	fee79de3          	bne	a5,a4,80000e8c <memset+0x12>
  }
  return dst;
}
    80000e96:	6422                	ld	s0,8(sp)
    80000e98:	0141                	addi	sp,sp,16
    80000e9a:	8082                	ret

0000000080000e9c <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e422                	sd	s0,8(sp)
    80000ea0:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000ea2:	ca05                	beqz	a2,80000ed2 <memcmp+0x36>
    80000ea4:	fff6069b          	addiw	a3,a2,-1
    80000ea8:	1682                	slli	a3,a3,0x20
    80000eaa:	9281                	srli	a3,a3,0x20
    80000eac:	0685                	addi	a3,a3,1
    80000eae:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000eb0:	00054783          	lbu	a5,0(a0)
    80000eb4:	0005c703          	lbu	a4,0(a1)
    80000eb8:	00e79863          	bne	a5,a4,80000ec8 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000ebc:	0505                	addi	a0,a0,1
    80000ebe:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ec0:	fed518e3          	bne	a0,a3,80000eb0 <memcmp+0x14>
  }

  return 0;
    80000ec4:	4501                	li	a0,0
    80000ec6:	a019                	j	80000ecc <memcmp+0x30>
      return *s1 - *s2;
    80000ec8:	40e7853b          	subw	a0,a5,a4
}
    80000ecc:	6422                	ld	s0,8(sp)
    80000ece:	0141                	addi	sp,sp,16
    80000ed0:	8082                	ret
  return 0;
    80000ed2:	4501                	li	a0,0
    80000ed4:	bfe5                	j	80000ecc <memcmp+0x30>

0000000080000ed6 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000ed6:	1141                	addi	sp,sp,-16
    80000ed8:	e422                	sd	s0,8(sp)
    80000eda:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000edc:	c205                	beqz	a2,80000efc <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ede:	02a5e263          	bltu	a1,a0,80000f02 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ee2:	1602                	slli	a2,a2,0x20
    80000ee4:	9201                	srli	a2,a2,0x20
    80000ee6:	00c587b3          	add	a5,a1,a2
{
    80000eea:	872a                	mv	a4,a0
      *d++ = *s++;
    80000eec:	0585                	addi	a1,a1,1
    80000eee:	0705                	addi	a4,a4,1
    80000ef0:	fff5c683          	lbu	a3,-1(a1)
    80000ef4:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ef8:	fef59ae3          	bne	a1,a5,80000eec <memmove+0x16>

  return dst;
}
    80000efc:	6422                	ld	s0,8(sp)
    80000efe:	0141                	addi	sp,sp,16
    80000f00:	8082                	ret
  if(s < d && s + n > d){
    80000f02:	02061693          	slli	a3,a2,0x20
    80000f06:	9281                	srli	a3,a3,0x20
    80000f08:	00d58733          	add	a4,a1,a3
    80000f0c:	fce57be3          	bgeu	a0,a4,80000ee2 <memmove+0xc>
    d += n;
    80000f10:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f12:	fff6079b          	addiw	a5,a2,-1
    80000f16:	1782                	slli	a5,a5,0x20
    80000f18:	9381                	srli	a5,a5,0x20
    80000f1a:	fff7c793          	not	a5,a5
    80000f1e:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f20:	177d                	addi	a4,a4,-1
    80000f22:	16fd                	addi	a3,a3,-1
    80000f24:	00074603          	lbu	a2,0(a4)
    80000f28:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f2c:	fee79ae3          	bne	a5,a4,80000f20 <memmove+0x4a>
    80000f30:	b7f1                	j	80000efc <memmove+0x26>

0000000080000f32 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f32:	1141                	addi	sp,sp,-16
    80000f34:	e406                	sd	ra,8(sp)
    80000f36:	e022                	sd	s0,0(sp)
    80000f38:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f3a:	00000097          	auipc	ra,0x0
    80000f3e:	f9c080e7          	jalr	-100(ra) # 80000ed6 <memmove>
}
    80000f42:	60a2                	ld	ra,8(sp)
    80000f44:	6402                	ld	s0,0(sp)
    80000f46:	0141                	addi	sp,sp,16
    80000f48:	8082                	ret

0000000080000f4a <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f4a:	1141                	addi	sp,sp,-16
    80000f4c:	e422                	sd	s0,8(sp)
    80000f4e:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f50:	ce11                	beqz	a2,80000f6c <strncmp+0x22>
    80000f52:	00054783          	lbu	a5,0(a0)
    80000f56:	cf89                	beqz	a5,80000f70 <strncmp+0x26>
    80000f58:	0005c703          	lbu	a4,0(a1)
    80000f5c:	00f71a63          	bne	a4,a5,80000f70 <strncmp+0x26>
    n--, p++, q++;
    80000f60:	367d                	addiw	a2,a2,-1
    80000f62:	0505                	addi	a0,a0,1
    80000f64:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f66:	f675                	bnez	a2,80000f52 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f68:	4501                	li	a0,0
    80000f6a:	a809                	j	80000f7c <strncmp+0x32>
    80000f6c:	4501                	li	a0,0
    80000f6e:	a039                	j	80000f7c <strncmp+0x32>
  if(n == 0)
    80000f70:	ca09                	beqz	a2,80000f82 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f72:	00054503          	lbu	a0,0(a0)
    80000f76:	0005c783          	lbu	a5,0(a1)
    80000f7a:	9d1d                	subw	a0,a0,a5
}
    80000f7c:	6422                	ld	s0,8(sp)
    80000f7e:	0141                	addi	sp,sp,16
    80000f80:	8082                	ret
    return 0;
    80000f82:	4501                	li	a0,0
    80000f84:	bfe5                	j	80000f7c <strncmp+0x32>

0000000080000f86 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f86:	1141                	addi	sp,sp,-16
    80000f88:	e422                	sd	s0,8(sp)
    80000f8a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f8c:	87aa                	mv	a5,a0
    80000f8e:	86b2                	mv	a3,a2
    80000f90:	367d                	addiw	a2,a2,-1
    80000f92:	00d05963          	blez	a3,80000fa4 <strncpy+0x1e>
    80000f96:	0785                	addi	a5,a5,1
    80000f98:	0005c703          	lbu	a4,0(a1)
    80000f9c:	fee78fa3          	sb	a4,-1(a5)
    80000fa0:	0585                	addi	a1,a1,1
    80000fa2:	f775                	bnez	a4,80000f8e <strncpy+0x8>
    ;
  while(n-- > 0)
    80000fa4:	873e                	mv	a4,a5
    80000fa6:	9fb5                	addw	a5,a5,a3
    80000fa8:	37fd                	addiw	a5,a5,-1
    80000faa:	00c05963          	blez	a2,80000fbc <strncpy+0x36>
    *s++ = 0;
    80000fae:	0705                	addi	a4,a4,1
    80000fb0:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000fb4:	40e786bb          	subw	a3,a5,a4
    80000fb8:	fed04be3          	bgtz	a3,80000fae <strncpy+0x28>
  return os;
}
    80000fbc:	6422                	ld	s0,8(sp)
    80000fbe:	0141                	addi	sp,sp,16
    80000fc0:	8082                	ret

0000000080000fc2 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000fc2:	1141                	addi	sp,sp,-16
    80000fc4:	e422                	sd	s0,8(sp)
    80000fc6:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000fc8:	02c05363          	blez	a2,80000fee <safestrcpy+0x2c>
    80000fcc:	fff6069b          	addiw	a3,a2,-1
    80000fd0:	1682                	slli	a3,a3,0x20
    80000fd2:	9281                	srli	a3,a3,0x20
    80000fd4:	96ae                	add	a3,a3,a1
    80000fd6:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000fd8:	00d58963          	beq	a1,a3,80000fea <safestrcpy+0x28>
    80000fdc:	0585                	addi	a1,a1,1
    80000fde:	0785                	addi	a5,a5,1
    80000fe0:	fff5c703          	lbu	a4,-1(a1)
    80000fe4:	fee78fa3          	sb	a4,-1(a5)
    80000fe8:	fb65                	bnez	a4,80000fd8 <safestrcpy+0x16>
    ;
  *s = 0;
    80000fea:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fee:	6422                	ld	s0,8(sp)
    80000ff0:	0141                	addi	sp,sp,16
    80000ff2:	8082                	ret

0000000080000ff4 <strlen>:

int
strlen(const char *s)
{
    80000ff4:	1141                	addi	sp,sp,-16
    80000ff6:	e422                	sd	s0,8(sp)
    80000ff8:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ffa:	00054783          	lbu	a5,0(a0)
    80000ffe:	cf91                	beqz	a5,8000101a <strlen+0x26>
    80001000:	0505                	addi	a0,a0,1
    80001002:	87aa                	mv	a5,a0
    80001004:	86be                	mv	a3,a5
    80001006:	0785                	addi	a5,a5,1
    80001008:	fff7c703          	lbu	a4,-1(a5)
    8000100c:	ff65                	bnez	a4,80001004 <strlen+0x10>
    8000100e:	40a6853b          	subw	a0,a3,a0
    80001012:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80001014:	6422                	ld	s0,8(sp)
    80001016:	0141                	addi	sp,sp,16
    80001018:	8082                	ret
  for(n = 0; s[n]; n++)
    8000101a:	4501                	li	a0,0
    8000101c:	bfe5                	j	80001014 <strlen+0x20>

000000008000101e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    8000101e:	1141                	addi	sp,sp,-16
    80001020:	e406                	sd	ra,8(sp)
    80001022:	e022                	sd	s0,0(sp)
    80001024:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001026:	00001097          	auipc	ra,0x1
    8000102a:	cac080e7          	jalr	-852(ra) # 80001cd2 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    8000102e:	00008717          	auipc	a4,0x8
    80001032:	9fa70713          	addi	a4,a4,-1542 # 80008a28 <started>
  if(cpuid() == 0){
    80001036:	c139                	beqz	a0,8000107c <main+0x5e>
    while(started == 0)
    80001038:	431c                	lw	a5,0(a4)
    8000103a:	2781                	sext.w	a5,a5
    8000103c:	dff5                	beqz	a5,80001038 <main+0x1a>
      ;
    __sync_synchronize();
    8000103e:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001042:	00001097          	auipc	ra,0x1
    80001046:	c90080e7          	jalr	-880(ra) # 80001cd2 <cpuid>
    8000104a:	85aa                	mv	a1,a0
    8000104c:	00007517          	auipc	a0,0x7
    80001050:	0ac50513          	addi	a0,a0,172 # 800080f8 <digits+0xa8>
    80001054:	fffff097          	auipc	ra,0xfffff
    80001058:	544080e7          	jalr	1348(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    8000105c:	00000097          	auipc	ra,0x0
    80001060:	0d8080e7          	jalr	216(ra) # 80001134 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001064:	00002097          	auipc	ra,0x2
    80001068:	ada080e7          	jalr	-1318(ra) # 80002b3e <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    8000106c:	00005097          	auipc	ra,0x5
    80001070:	1e4080e7          	jalr	484(ra) # 80006250 <plicinithart>
  }

  scheduler();        
    80001074:	00001097          	auipc	ra,0x1
    80001078:	2d0080e7          	jalr	720(ra) # 80002344 <scheduler>
    consoleinit();
    8000107c:	fffff097          	auipc	ra,0xfffff
    80001080:	3d0080e7          	jalr	976(ra) # 8000044c <consoleinit>
    printfinit();
    80001084:	fffff097          	auipc	ra,0xfffff
    80001088:	6f4080e7          	jalr	1780(ra) # 80000778 <printfinit>
    printf("\n");
    8000108c:	00007517          	auipc	a0,0x7
    80001090:	ffc50513          	addi	a0,a0,-4 # 80008088 <digits+0x38>
    80001094:	fffff097          	auipc	ra,0xfffff
    80001098:	504080e7          	jalr	1284(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    8000109c:	00007517          	auipc	a0,0x7
    800010a0:	04450513          	addi	a0,a0,68 # 800080e0 <digits+0x90>
    800010a4:	fffff097          	auipc	ra,0xfffff
    800010a8:	4f4080e7          	jalr	1268(ra) # 80000598 <printf>
    printf("\n");
    800010ac:	00007517          	auipc	a0,0x7
    800010b0:	fdc50513          	addi	a0,a0,-36 # 80008088 <digits+0x38>
    800010b4:	fffff097          	auipc	ra,0xfffff
    800010b8:	4e4080e7          	jalr	1252(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	b24080e7          	jalr	-1244(ra) # 80000be0 <kinit>
    kvminit();       // create kernel page table
    800010c4:	00000097          	auipc	ra,0x0
    800010c8:	326080e7          	jalr	806(ra) # 800013ea <kvminit>
    kvminithart();   // turn on paging
    800010cc:	00000097          	auipc	ra,0x0
    800010d0:	068080e7          	jalr	104(ra) # 80001134 <kvminithart>
    procinit();      // process table
    800010d4:	00001097          	auipc	ra,0x1
    800010d8:	b26080e7          	jalr	-1242(ra) # 80001bfa <procinit>
    trapinit();      // trap vectors
    800010dc:	00002097          	auipc	ra,0x2
    800010e0:	a3a080e7          	jalr	-1478(ra) # 80002b16 <trapinit>
    trapinithart();  // install kernel trap vector
    800010e4:	00002097          	auipc	ra,0x2
    800010e8:	a5a080e7          	jalr	-1446(ra) # 80002b3e <trapinithart>
    plicinit();      // set up interrupt controller
    800010ec:	00005097          	auipc	ra,0x5
    800010f0:	14e080e7          	jalr	334(ra) # 8000623a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010f4:	00005097          	auipc	ra,0x5
    800010f8:	15c080e7          	jalr	348(ra) # 80006250 <plicinithart>
    binit();         // buffer cache
    800010fc:	00002097          	auipc	ra,0x2
    80001100:	354080e7          	jalr	852(ra) # 80003450 <binit>
    iinit();         // inode table
    80001104:	00003097          	auipc	ra,0x3
    80001108:	9f2080e7          	jalr	-1550(ra) # 80003af6 <iinit>
    fileinit();      // file table
    8000110c:	00004097          	auipc	ra,0x4
    80001110:	968080e7          	jalr	-1688(ra) # 80004a74 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001114:	00005097          	auipc	ra,0x5
    80001118:	244080e7          	jalr	580(ra) # 80006358 <virtio_disk_init>
    userinit();      // first user process
    8000111c:	00001097          	auipc	ra,0x1
    80001120:	eba080e7          	jalr	-326(ra) # 80001fd6 <userinit>
    __sync_synchronize();
    80001124:	0ff0000f          	fence
    started = 1;
    80001128:	4785                	li	a5,1
    8000112a:	00008717          	auipc	a4,0x8
    8000112e:	8ef72f23          	sw	a5,-1794(a4) # 80008a28 <started>
    80001132:	b789                	j	80001074 <main+0x56>

0000000080001134 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001134:	1141                	addi	sp,sp,-16
    80001136:	e422                	sd	s0,8(sp)
    80001138:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    8000113a:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    8000113e:	00008797          	auipc	a5,0x8
    80001142:	8f27b783          	ld	a5,-1806(a5) # 80008a30 <kernel_pagetable>
    80001146:	83b1                	srli	a5,a5,0xc
    80001148:	577d                	li	a4,-1
    8000114a:	177e                	slli	a4,a4,0x3f
    8000114c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000114e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001152:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80001156:	6422                	ld	s0,8(sp)
    80001158:	0141                	addi	sp,sp,16
    8000115a:	8082                	ret

000000008000115c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000115c:	7139                	addi	sp,sp,-64
    8000115e:	fc06                	sd	ra,56(sp)
    80001160:	f822                	sd	s0,48(sp)
    80001162:	f426                	sd	s1,40(sp)
    80001164:	f04a                	sd	s2,32(sp)
    80001166:	ec4e                	sd	s3,24(sp)
    80001168:	e852                	sd	s4,16(sp)
    8000116a:	e456                	sd	s5,8(sp)
    8000116c:	e05a                	sd	s6,0(sp)
    8000116e:	0080                	addi	s0,sp,64
    80001170:	84aa                	mv	s1,a0
    80001172:	89ae                	mv	s3,a1
    80001174:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001176:	57fd                	li	a5,-1
    80001178:	83e9                	srli	a5,a5,0x1a
    8000117a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000117c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000117e:	04b7f263          	bgeu	a5,a1,800011c2 <walk+0x66>
    panic("walk");
    80001182:	00007517          	auipc	a0,0x7
    80001186:	f8e50513          	addi	a0,a0,-114 # 80008110 <digits+0xc0>
    8000118a:	fffff097          	auipc	ra,0xfffff
    8000118e:	3b2080e7          	jalr	946(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001192:	060a8663          	beqz	s5,800011fe <walk+0xa2>
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	a96080e7          	jalr	-1386(ra) # 80000c2c <kalloc>
    8000119e:	84aa                	mv	s1,a0
    800011a0:	c529                	beqz	a0,800011ea <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011a2:	6605                	lui	a2,0x1
    800011a4:	4581                	li	a1,0
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	cd4080e7          	jalr	-812(ra) # 80000e7a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800011ae:	00c4d793          	srli	a5,s1,0xc
    800011b2:	07aa                	slli	a5,a5,0xa
    800011b4:	0017e793          	ori	a5,a5,1
    800011b8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800011bc:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    800011be:	036a0063          	beq	s4,s6,800011de <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800011c2:	0149d933          	srl	s2,s3,s4
    800011c6:	1ff97913          	andi	s2,s2,511
    800011ca:	090e                	slli	s2,s2,0x3
    800011cc:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800011ce:	00093483          	ld	s1,0(s2)
    800011d2:	0014f793          	andi	a5,s1,1
    800011d6:	dfd5                	beqz	a5,80001192 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800011d8:	80a9                	srli	s1,s1,0xa
    800011da:	04b2                	slli	s1,s1,0xc
    800011dc:	b7c5                	j	800011bc <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011de:	00c9d513          	srli	a0,s3,0xc
    800011e2:	1ff57513          	andi	a0,a0,511
    800011e6:	050e                	slli	a0,a0,0x3
    800011e8:	9526                	add	a0,a0,s1
}
    800011ea:	70e2                	ld	ra,56(sp)
    800011ec:	7442                	ld	s0,48(sp)
    800011ee:	74a2                	ld	s1,40(sp)
    800011f0:	7902                	ld	s2,32(sp)
    800011f2:	69e2                	ld	s3,24(sp)
    800011f4:	6a42                	ld	s4,16(sp)
    800011f6:	6aa2                	ld	s5,8(sp)
    800011f8:	6b02                	ld	s6,0(sp)
    800011fa:	6121                	addi	sp,sp,64
    800011fc:	8082                	ret
        return 0;
    800011fe:	4501                	li	a0,0
    80001200:	b7ed                	j	800011ea <walk+0x8e>

0000000080001202 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001202:	57fd                	li	a5,-1
    80001204:	83e9                	srli	a5,a5,0x1a
    80001206:	00b7f463          	bgeu	a5,a1,8000120e <walkaddr+0xc>
    return 0;
    8000120a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000120c:	8082                	ret
{
    8000120e:	1141                	addi	sp,sp,-16
    80001210:	e406                	sd	ra,8(sp)
    80001212:	e022                	sd	s0,0(sp)
    80001214:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001216:	4601                	li	a2,0
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f44080e7          	jalr	-188(ra) # 8000115c <walk>
  if(pte == 0)
    80001220:	c105                	beqz	a0,80001240 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001222:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001224:	0117f693          	andi	a3,a5,17
    80001228:	4745                	li	a4,17
    return 0;
    8000122a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000122c:	00e68663          	beq	a3,a4,80001238 <walkaddr+0x36>
}
    80001230:	60a2                	ld	ra,8(sp)
    80001232:	6402                	ld	s0,0(sp)
    80001234:	0141                	addi	sp,sp,16
    80001236:	8082                	ret
  pa = PTE2PA(*pte);
    80001238:	83a9                	srli	a5,a5,0xa
    8000123a:	00c79513          	slli	a0,a5,0xc
  return pa;
    8000123e:	bfcd                	j	80001230 <walkaddr+0x2e>
    return 0;
    80001240:	4501                	li	a0,0
    80001242:	b7fd                	j	80001230 <walkaddr+0x2e>

0000000080001244 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001244:	715d                	addi	sp,sp,-80
    80001246:	e486                	sd	ra,72(sp)
    80001248:	e0a2                	sd	s0,64(sp)
    8000124a:	fc26                	sd	s1,56(sp)
    8000124c:	f84a                	sd	s2,48(sp)
    8000124e:	f44e                	sd	s3,40(sp)
    80001250:	f052                	sd	s4,32(sp)
    80001252:	ec56                	sd	s5,24(sp)
    80001254:	e85a                	sd	s6,16(sp)
    80001256:	e45e                	sd	s7,8(sp)
    80001258:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    8000125a:	c639                	beqz	a2,800012a8 <mappages+0x64>
    8000125c:	8aaa                	mv	s5,a0
    8000125e:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001260:	777d                	lui	a4,0xfffff
    80001262:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001266:	fff58993          	addi	s3,a1,-1
    8000126a:	99b2                	add	s3,s3,a2
    8000126c:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001270:	893e                	mv	s2,a5
    80001272:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001276:	6b85                	lui	s7,0x1
    80001278:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000127c:	4605                	li	a2,1
    8000127e:	85ca                	mv	a1,s2
    80001280:	8556                	mv	a0,s5
    80001282:	00000097          	auipc	ra,0x0
    80001286:	eda080e7          	jalr	-294(ra) # 8000115c <walk>
    8000128a:	cd1d                	beqz	a0,800012c8 <mappages+0x84>
    if(*pte & PTE_V)
    8000128c:	611c                	ld	a5,0(a0)
    8000128e:	8b85                	andi	a5,a5,1
    80001290:	e785                	bnez	a5,800012b8 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001292:	80b1                	srli	s1,s1,0xc
    80001294:	04aa                	slli	s1,s1,0xa
    80001296:	0164e4b3          	or	s1,s1,s6
    8000129a:	0014e493          	ori	s1,s1,1
    8000129e:	e104                	sd	s1,0(a0)
    if(a == last)
    800012a0:	05390063          	beq	s2,s3,800012e0 <mappages+0x9c>
    a += PGSIZE;
    800012a4:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800012a6:	bfc9                	j	80001278 <mappages+0x34>
    panic("mappages: size");
    800012a8:	00007517          	auipc	a0,0x7
    800012ac:	e7050513          	addi	a0,a0,-400 # 80008118 <digits+0xc8>
    800012b0:	fffff097          	auipc	ra,0xfffff
    800012b4:	28c080e7          	jalr	652(ra) # 8000053c <panic>
      panic("mappages: remap");
    800012b8:	00007517          	auipc	a0,0x7
    800012bc:	e7050513          	addi	a0,a0,-400 # 80008128 <digits+0xd8>
    800012c0:	fffff097          	auipc	ra,0xfffff
    800012c4:	27c080e7          	jalr	636(ra) # 8000053c <panic>
      return -1;
    800012c8:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800012ca:	60a6                	ld	ra,72(sp)
    800012cc:	6406                	ld	s0,64(sp)
    800012ce:	74e2                	ld	s1,56(sp)
    800012d0:	7942                	ld	s2,48(sp)
    800012d2:	79a2                	ld	s3,40(sp)
    800012d4:	7a02                	ld	s4,32(sp)
    800012d6:	6ae2                	ld	s5,24(sp)
    800012d8:	6b42                	ld	s6,16(sp)
    800012da:	6ba2                	ld	s7,8(sp)
    800012dc:	6161                	addi	sp,sp,80
    800012de:	8082                	ret
  return 0;
    800012e0:	4501                	li	a0,0
    800012e2:	b7e5                	j	800012ca <mappages+0x86>

00000000800012e4 <kvmmap>:
{
    800012e4:	1141                	addi	sp,sp,-16
    800012e6:	e406                	sd	ra,8(sp)
    800012e8:	e022                	sd	s0,0(sp)
    800012ea:	0800                	addi	s0,sp,16
    800012ec:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012ee:	86b2                	mv	a3,a2
    800012f0:	863e                	mv	a2,a5
    800012f2:	00000097          	auipc	ra,0x0
    800012f6:	f52080e7          	jalr	-174(ra) # 80001244 <mappages>
    800012fa:	e509                	bnez	a0,80001304 <kvmmap+0x20>
}
    800012fc:	60a2                	ld	ra,8(sp)
    800012fe:	6402                	ld	s0,0(sp)
    80001300:	0141                	addi	sp,sp,16
    80001302:	8082                	ret
    panic("kvmmap");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e3450513          	addi	a0,a0,-460 # 80008138 <digits+0xe8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	230080e7          	jalr	560(ra) # 8000053c <panic>

0000000080001314 <kvmmake>:
{
    80001314:	1101                	addi	sp,sp,-32
    80001316:	ec06                	sd	ra,24(sp)
    80001318:	e822                	sd	s0,16(sp)
    8000131a:	e426                	sd	s1,8(sp)
    8000131c:	e04a                	sd	s2,0(sp)
    8000131e:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    80001320:	00000097          	auipc	ra,0x0
    80001324:	90c080e7          	jalr	-1780(ra) # 80000c2c <kalloc>
    80001328:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    8000132a:	6605                	lui	a2,0x1
    8000132c:	4581                	li	a1,0
    8000132e:	00000097          	auipc	ra,0x0
    80001332:	b4c080e7          	jalr	-1204(ra) # 80000e7a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001336:	4719                	li	a4,6
    80001338:	6685                	lui	a3,0x1
    8000133a:	10000637          	lui	a2,0x10000
    8000133e:	100005b7          	lui	a1,0x10000
    80001342:	8526                	mv	a0,s1
    80001344:	00000097          	auipc	ra,0x0
    80001348:	fa0080e7          	jalr	-96(ra) # 800012e4 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000134c:	4719                	li	a4,6
    8000134e:	6685                	lui	a3,0x1
    80001350:	10001637          	lui	a2,0x10001
    80001354:	100015b7          	lui	a1,0x10001
    80001358:	8526                	mv	a0,s1
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f8a080e7          	jalr	-118(ra) # 800012e4 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001362:	4719                	li	a4,6
    80001364:	004006b7          	lui	a3,0x400
    80001368:	0c000637          	lui	a2,0xc000
    8000136c:	0c0005b7          	lui	a1,0xc000
    80001370:	8526                	mv	a0,s1
    80001372:	00000097          	auipc	ra,0x0
    80001376:	f72080e7          	jalr	-142(ra) # 800012e4 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000137a:	00007917          	auipc	s2,0x7
    8000137e:	c8690913          	addi	s2,s2,-890 # 80008000 <etext>
    80001382:	4729                	li	a4,10
    80001384:	80007697          	auipc	a3,0x80007
    80001388:	c7c68693          	addi	a3,a3,-900 # 8000 <_entry-0x7fff8000>
    8000138c:	4605                	li	a2,1
    8000138e:	067e                	slli	a2,a2,0x1f
    80001390:	85b2                	mv	a1,a2
    80001392:	8526                	mv	a0,s1
    80001394:	00000097          	auipc	ra,0x0
    80001398:	f50080e7          	jalr	-176(ra) # 800012e4 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000139c:	4719                	li	a4,6
    8000139e:	46c5                	li	a3,17
    800013a0:	06ee                	slli	a3,a3,0x1b
    800013a2:	412686b3          	sub	a3,a3,s2
    800013a6:	864a                	mv	a2,s2
    800013a8:	85ca                	mv	a1,s2
    800013aa:	8526                	mv	a0,s1
    800013ac:	00000097          	auipc	ra,0x0
    800013b0:	f38080e7          	jalr	-200(ra) # 800012e4 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800013b4:	4729                	li	a4,10
    800013b6:	6685                	lui	a3,0x1
    800013b8:	00006617          	auipc	a2,0x6
    800013bc:	c4860613          	addi	a2,a2,-952 # 80007000 <_trampoline>
    800013c0:	040005b7          	lui	a1,0x4000
    800013c4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800013c6:	05b2                	slli	a1,a1,0xc
    800013c8:	8526                	mv	a0,s1
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	f1a080e7          	jalr	-230(ra) # 800012e4 <kvmmap>
  proc_mapstacks(kpgtbl);
    800013d2:	8526                	mv	a0,s1
    800013d4:	00000097          	auipc	ra,0x0
    800013d8:	790080e7          	jalr	1936(ra) # 80001b64 <proc_mapstacks>
}
    800013dc:	8526                	mv	a0,s1
    800013de:	60e2                	ld	ra,24(sp)
    800013e0:	6442                	ld	s0,16(sp)
    800013e2:	64a2                	ld	s1,8(sp)
    800013e4:	6902                	ld	s2,0(sp)
    800013e6:	6105                	addi	sp,sp,32
    800013e8:	8082                	ret

00000000800013ea <kvminit>:
{
    800013ea:	1141                	addi	sp,sp,-16
    800013ec:	e406                	sd	ra,8(sp)
    800013ee:	e022                	sd	s0,0(sp)
    800013f0:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	f22080e7          	jalr	-222(ra) # 80001314 <kvmmake>
    800013fa:	00007797          	auipc	a5,0x7
    800013fe:	62a7bb23          	sd	a0,1590(a5) # 80008a30 <kernel_pagetable>
}
    80001402:	60a2                	ld	ra,8(sp)
    80001404:	6402                	ld	s0,0(sp)
    80001406:	0141                	addi	sp,sp,16
    80001408:	8082                	ret

000000008000140a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000140a:	715d                	addi	sp,sp,-80
    8000140c:	e486                	sd	ra,72(sp)
    8000140e:	e0a2                	sd	s0,64(sp)
    80001410:	fc26                	sd	s1,56(sp)
    80001412:	f84a                	sd	s2,48(sp)
    80001414:	f44e                	sd	s3,40(sp)
    80001416:	f052                	sd	s4,32(sp)
    80001418:	ec56                	sd	s5,24(sp)
    8000141a:	e85a                	sd	s6,16(sp)
    8000141c:	e45e                	sd	s7,8(sp)
    8000141e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001420:	03459793          	slli	a5,a1,0x34
    80001424:	e795                	bnez	a5,80001450 <uvmunmap+0x46>
    80001426:	8a2a                	mv	s4,a0
    80001428:	892e                	mv	s2,a1
    8000142a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000142c:	0632                	slli	a2,a2,0xc
    8000142e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001432:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001434:	6b05                	lui	s6,0x1
    80001436:	0735e263          	bltu	a1,s3,8000149a <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000143a:	60a6                	ld	ra,72(sp)
    8000143c:	6406                	ld	s0,64(sp)
    8000143e:	74e2                	ld	s1,56(sp)
    80001440:	7942                	ld	s2,48(sp)
    80001442:	79a2                	ld	s3,40(sp)
    80001444:	7a02                	ld	s4,32(sp)
    80001446:	6ae2                	ld	s5,24(sp)
    80001448:	6b42                	ld	s6,16(sp)
    8000144a:	6ba2                	ld	s7,8(sp)
    8000144c:	6161                	addi	sp,sp,80
    8000144e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001450:	00007517          	auipc	a0,0x7
    80001454:	cf050513          	addi	a0,a0,-784 # 80008140 <digits+0xf0>
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	0e4080e7          	jalr	228(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    80001460:	00007517          	auipc	a0,0x7
    80001464:	cf850513          	addi	a0,a0,-776 # 80008158 <digits+0x108>
    80001468:	fffff097          	auipc	ra,0xfffff
    8000146c:	0d4080e7          	jalr	212(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    80001470:	00007517          	auipc	a0,0x7
    80001474:	cf850513          	addi	a0,a0,-776 # 80008168 <digits+0x118>
    80001478:	fffff097          	auipc	ra,0xfffff
    8000147c:	0c4080e7          	jalr	196(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    80001480:	00007517          	auipc	a0,0x7
    80001484:	d0050513          	addi	a0,a0,-768 # 80008180 <digits+0x130>
    80001488:	fffff097          	auipc	ra,0xfffff
    8000148c:	0b4080e7          	jalr	180(ra) # 8000053c <panic>
    *pte = 0;
    80001490:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001494:	995a                	add	s2,s2,s6
    80001496:	fb3972e3          	bgeu	s2,s3,8000143a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000149a:	4601                	li	a2,0
    8000149c:	85ca                	mv	a1,s2
    8000149e:	8552                	mv	a0,s4
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	cbc080e7          	jalr	-836(ra) # 8000115c <walk>
    800014a8:	84aa                	mv	s1,a0
    800014aa:	d95d                	beqz	a0,80001460 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800014ac:	6108                	ld	a0,0(a0)
    800014ae:	00157793          	andi	a5,a0,1
    800014b2:	dfdd                	beqz	a5,80001470 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800014b4:	3ff57793          	andi	a5,a0,1023
    800014b8:	fd7784e3          	beq	a5,s7,80001480 <uvmunmap+0x76>
    if(do_free){
    800014bc:	fc0a8ae3          	beqz	s5,80001490 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    800014c0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800014c2:	0532                	slli	a0,a0,0xc
    800014c4:	fffff097          	auipc	ra,0xfffff
    800014c8:	5d0080e7          	jalr	1488(ra) # 80000a94 <kfree>
    800014cc:	b7d1                	j	80001490 <uvmunmap+0x86>

00000000800014ce <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800014ce:	1101                	addi	sp,sp,-32
    800014d0:	ec06                	sd	ra,24(sp)
    800014d2:	e822                	sd	s0,16(sp)
    800014d4:	e426                	sd	s1,8(sp)
    800014d6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	754080e7          	jalr	1876(ra) # 80000c2c <kalloc>
    800014e0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014e2:	c519                	beqz	a0,800014f0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014e4:	6605                	lui	a2,0x1
    800014e6:	4581                	li	a1,0
    800014e8:	00000097          	auipc	ra,0x0
    800014ec:	992080e7          	jalr	-1646(ra) # 80000e7a <memset>
  return pagetable;
}
    800014f0:	8526                	mv	a0,s1
    800014f2:	60e2                	ld	ra,24(sp)
    800014f4:	6442                	ld	s0,16(sp)
    800014f6:	64a2                	ld	s1,8(sp)
    800014f8:	6105                	addi	sp,sp,32
    800014fa:	8082                	ret

00000000800014fc <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014fc:	7179                	addi	sp,sp,-48
    800014fe:	f406                	sd	ra,40(sp)
    80001500:	f022                	sd	s0,32(sp)
    80001502:	ec26                	sd	s1,24(sp)
    80001504:	e84a                	sd	s2,16(sp)
    80001506:	e44e                	sd	s3,8(sp)
    80001508:	e052                	sd	s4,0(sp)
    8000150a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000150c:	6785                	lui	a5,0x1
    8000150e:	04f67863          	bgeu	a2,a5,8000155e <uvmfirst+0x62>
    80001512:	8a2a                	mv	s4,a0
    80001514:	89ae                	mv	s3,a1
    80001516:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001518:	fffff097          	auipc	ra,0xfffff
    8000151c:	714080e7          	jalr	1812(ra) # 80000c2c <kalloc>
    80001520:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001522:	6605                	lui	a2,0x1
    80001524:	4581                	li	a1,0
    80001526:	00000097          	auipc	ra,0x0
    8000152a:	954080e7          	jalr	-1708(ra) # 80000e7a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000152e:	4779                	li	a4,30
    80001530:	86ca                	mv	a3,s2
    80001532:	6605                	lui	a2,0x1
    80001534:	4581                	li	a1,0
    80001536:	8552                	mv	a0,s4
    80001538:	00000097          	auipc	ra,0x0
    8000153c:	d0c080e7          	jalr	-756(ra) # 80001244 <mappages>
  memmove(mem, src, sz);
    80001540:	8626                	mv	a2,s1
    80001542:	85ce                	mv	a1,s3
    80001544:	854a                	mv	a0,s2
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	990080e7          	jalr	-1648(ra) # 80000ed6 <memmove>
}
    8000154e:	70a2                	ld	ra,40(sp)
    80001550:	7402                	ld	s0,32(sp)
    80001552:	64e2                	ld	s1,24(sp)
    80001554:	6942                	ld	s2,16(sp)
    80001556:	69a2                	ld	s3,8(sp)
    80001558:	6a02                	ld	s4,0(sp)
    8000155a:	6145                	addi	sp,sp,48
    8000155c:	8082                	ret
    panic("uvmfirst: more than a page");
    8000155e:	00007517          	auipc	a0,0x7
    80001562:	c3a50513          	addi	a0,a0,-966 # 80008198 <digits+0x148>
    80001566:	fffff097          	auipc	ra,0xfffff
    8000156a:	fd6080e7          	jalr	-42(ra) # 8000053c <panic>

000000008000156e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000156e:	1101                	addi	sp,sp,-32
    80001570:	ec06                	sd	ra,24(sp)
    80001572:	e822                	sd	s0,16(sp)
    80001574:	e426                	sd	s1,8(sp)
    80001576:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001578:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000157a:	00b67d63          	bgeu	a2,a1,80001594 <uvmdealloc+0x26>
    8000157e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001580:	6785                	lui	a5,0x1
    80001582:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001584:	00f60733          	add	a4,a2,a5
    80001588:	76fd                	lui	a3,0xfffff
    8000158a:	8f75                	and	a4,a4,a3
    8000158c:	97ae                	add	a5,a5,a1
    8000158e:	8ff5                	and	a5,a5,a3
    80001590:	00f76863          	bltu	a4,a5,800015a0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001594:	8526                	mv	a0,s1
    80001596:	60e2                	ld	ra,24(sp)
    80001598:	6442                	ld	s0,16(sp)
    8000159a:	64a2                	ld	s1,8(sp)
    8000159c:	6105                	addi	sp,sp,32
    8000159e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015a0:	8f99                	sub	a5,a5,a4
    800015a2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015a4:	4685                	li	a3,1
    800015a6:	0007861b          	sext.w	a2,a5
    800015aa:	85ba                	mv	a1,a4
    800015ac:	00000097          	auipc	ra,0x0
    800015b0:	e5e080e7          	jalr	-418(ra) # 8000140a <uvmunmap>
    800015b4:	b7c5                	j	80001594 <uvmdealloc+0x26>

00000000800015b6 <uvmalloc>:
  if(newsz < oldsz)
    800015b6:	0ab66563          	bltu	a2,a1,80001660 <uvmalloc+0xaa>
{
    800015ba:	7139                	addi	sp,sp,-64
    800015bc:	fc06                	sd	ra,56(sp)
    800015be:	f822                	sd	s0,48(sp)
    800015c0:	f426                	sd	s1,40(sp)
    800015c2:	f04a                	sd	s2,32(sp)
    800015c4:	ec4e                	sd	s3,24(sp)
    800015c6:	e852                	sd	s4,16(sp)
    800015c8:	e456                	sd	s5,8(sp)
    800015ca:	e05a                	sd	s6,0(sp)
    800015cc:	0080                	addi	s0,sp,64
    800015ce:	8aaa                	mv	s5,a0
    800015d0:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800015d2:	6785                	lui	a5,0x1
    800015d4:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015d6:	95be                	add	a1,a1,a5
    800015d8:	77fd                	lui	a5,0xfffff
    800015da:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015de:	08c9f363          	bgeu	s3,a2,80001664 <uvmalloc+0xae>
    800015e2:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015e4:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	644080e7          	jalr	1604(ra) # 80000c2c <kalloc>
    800015f0:	84aa                	mv	s1,a0
    if(mem == 0){
    800015f2:	c51d                	beqz	a0,80001620 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015f4:	6605                	lui	a2,0x1
    800015f6:	4581                	li	a1,0
    800015f8:	00000097          	auipc	ra,0x0
    800015fc:	882080e7          	jalr	-1918(ra) # 80000e7a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001600:	875a                	mv	a4,s6
    80001602:	86a6                	mv	a3,s1
    80001604:	6605                	lui	a2,0x1
    80001606:	85ca                	mv	a1,s2
    80001608:	8556                	mv	a0,s5
    8000160a:	00000097          	auipc	ra,0x0
    8000160e:	c3a080e7          	jalr	-966(ra) # 80001244 <mappages>
    80001612:	e90d                	bnez	a0,80001644 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001614:	6785                	lui	a5,0x1
    80001616:	993e                	add	s2,s2,a5
    80001618:	fd4968e3          	bltu	s2,s4,800015e8 <uvmalloc+0x32>
  return newsz;
    8000161c:	8552                	mv	a0,s4
    8000161e:	a809                	j	80001630 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001620:	864e                	mv	a2,s3
    80001622:	85ca                	mv	a1,s2
    80001624:	8556                	mv	a0,s5
    80001626:	00000097          	auipc	ra,0x0
    8000162a:	f48080e7          	jalr	-184(ra) # 8000156e <uvmdealloc>
      return 0;
    8000162e:	4501                	li	a0,0
}
    80001630:	70e2                	ld	ra,56(sp)
    80001632:	7442                	ld	s0,48(sp)
    80001634:	74a2                	ld	s1,40(sp)
    80001636:	7902                	ld	s2,32(sp)
    80001638:	69e2                	ld	s3,24(sp)
    8000163a:	6a42                	ld	s4,16(sp)
    8000163c:	6aa2                	ld	s5,8(sp)
    8000163e:	6b02                	ld	s6,0(sp)
    80001640:	6121                	addi	sp,sp,64
    80001642:	8082                	ret
      kfree(mem);
    80001644:	8526                	mv	a0,s1
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	44e080e7          	jalr	1102(ra) # 80000a94 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000164e:	864e                	mv	a2,s3
    80001650:	85ca                	mv	a1,s2
    80001652:	8556                	mv	a0,s5
    80001654:	00000097          	auipc	ra,0x0
    80001658:	f1a080e7          	jalr	-230(ra) # 8000156e <uvmdealloc>
      return 0;
    8000165c:	4501                	li	a0,0
    8000165e:	bfc9                	j	80001630 <uvmalloc+0x7a>
    return oldsz;
    80001660:	852e                	mv	a0,a1
}
    80001662:	8082                	ret
  return newsz;
    80001664:	8532                	mv	a0,a2
    80001666:	b7e9                	j	80001630 <uvmalloc+0x7a>

0000000080001668 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001668:	7179                	addi	sp,sp,-48
    8000166a:	f406                	sd	ra,40(sp)
    8000166c:	f022                	sd	s0,32(sp)
    8000166e:	ec26                	sd	s1,24(sp)
    80001670:	e84a                	sd	s2,16(sp)
    80001672:	e44e                	sd	s3,8(sp)
    80001674:	e052                	sd	s4,0(sp)
    80001676:	1800                	addi	s0,sp,48
    80001678:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000167a:	84aa                	mv	s1,a0
    8000167c:	6905                	lui	s2,0x1
    8000167e:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001680:	4985                	li	s3,1
    80001682:	a829                	j	8000169c <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001684:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    80001686:	00c79513          	slli	a0,a5,0xc
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	fde080e7          	jalr	-34(ra) # 80001668 <freewalk>
      pagetable[i] = 0;
    80001692:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001696:	04a1                	addi	s1,s1,8
    80001698:	03248163          	beq	s1,s2,800016ba <freewalk+0x52>
    pte_t pte = pagetable[i];
    8000169c:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000169e:	00f7f713          	andi	a4,a5,15
    800016a2:	ff3701e3          	beq	a4,s3,80001684 <freewalk+0x1c>
    } else if(pte & PTE_V){
    800016a6:	8b85                	andi	a5,a5,1
    800016a8:	d7fd                	beqz	a5,80001696 <freewalk+0x2e>
      panic("freewalk: leaf");
    800016aa:	00007517          	auipc	a0,0x7
    800016ae:	b0e50513          	addi	a0,a0,-1266 # 800081b8 <digits+0x168>
    800016b2:	fffff097          	auipc	ra,0xfffff
    800016b6:	e8a080e7          	jalr	-374(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    800016ba:	8552                	mv	a0,s4
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	3d8080e7          	jalr	984(ra) # 80000a94 <kfree>
}
    800016c4:	70a2                	ld	ra,40(sp)
    800016c6:	7402                	ld	s0,32(sp)
    800016c8:	64e2                	ld	s1,24(sp)
    800016ca:	6942                	ld	s2,16(sp)
    800016cc:	69a2                	ld	s3,8(sp)
    800016ce:	6a02                	ld	s4,0(sp)
    800016d0:	6145                	addi	sp,sp,48
    800016d2:	8082                	ret

00000000800016d4 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800016d4:	1101                	addi	sp,sp,-32
    800016d6:	ec06                	sd	ra,24(sp)
    800016d8:	e822                	sd	s0,16(sp)
    800016da:	e426                	sd	s1,8(sp)
    800016dc:	1000                	addi	s0,sp,32
    800016de:	84aa                	mv	s1,a0
  if(sz > 0)
    800016e0:	e999                	bnez	a1,800016f6 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016e2:	8526                	mv	a0,s1
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	f84080e7          	jalr	-124(ra) # 80001668 <freewalk>
}
    800016ec:	60e2                	ld	ra,24(sp)
    800016ee:	6442                	ld	s0,16(sp)
    800016f0:	64a2                	ld	s1,8(sp)
    800016f2:	6105                	addi	sp,sp,32
    800016f4:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016f6:	6785                	lui	a5,0x1
    800016f8:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016fa:	95be                	add	a1,a1,a5
    800016fc:	4685                	li	a3,1
    800016fe:	00c5d613          	srli	a2,a1,0xc
    80001702:	4581                	li	a1,0
    80001704:	00000097          	auipc	ra,0x0
    80001708:	d06080e7          	jalr	-762(ra) # 8000140a <uvmunmap>
    8000170c:	bfd9                	j	800016e2 <uvmfree+0xe>

000000008000170e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000170e:	c679                	beqz	a2,800017dc <uvmcopy+0xce>
{
    80001710:	715d                	addi	sp,sp,-80
    80001712:	e486                	sd	ra,72(sp)
    80001714:	e0a2                	sd	s0,64(sp)
    80001716:	fc26                	sd	s1,56(sp)
    80001718:	f84a                	sd	s2,48(sp)
    8000171a:	f44e                	sd	s3,40(sp)
    8000171c:	f052                	sd	s4,32(sp)
    8000171e:	ec56                	sd	s5,24(sp)
    80001720:	e85a                	sd	s6,16(sp)
    80001722:	e45e                	sd	s7,8(sp)
    80001724:	0880                	addi	s0,sp,80
    80001726:	8b2a                	mv	s6,a0
    80001728:	8aae                	mv	s5,a1
    8000172a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000172c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000172e:	4601                	li	a2,0
    80001730:	85ce                	mv	a1,s3
    80001732:	855a                	mv	a0,s6
    80001734:	00000097          	auipc	ra,0x0
    80001738:	a28080e7          	jalr	-1496(ra) # 8000115c <walk>
    8000173c:	c531                	beqz	a0,80001788 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000173e:	6118                	ld	a4,0(a0)
    80001740:	00177793          	andi	a5,a4,1
    80001744:	cbb1                	beqz	a5,80001798 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001746:	00a75593          	srli	a1,a4,0xa
    8000174a:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000174e:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001752:	fffff097          	auipc	ra,0xfffff
    80001756:	4da080e7          	jalr	1242(ra) # 80000c2c <kalloc>
    8000175a:	892a                	mv	s2,a0
    8000175c:	c939                	beqz	a0,800017b2 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    8000175e:	6605                	lui	a2,0x1
    80001760:	85de                	mv	a1,s7
    80001762:	fffff097          	auipc	ra,0xfffff
    80001766:	774080e7          	jalr	1908(ra) # 80000ed6 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000176a:	8726                	mv	a4,s1
    8000176c:	86ca                	mv	a3,s2
    8000176e:	6605                	lui	a2,0x1
    80001770:	85ce                	mv	a1,s3
    80001772:	8556                	mv	a0,s5
    80001774:	00000097          	auipc	ra,0x0
    80001778:	ad0080e7          	jalr	-1328(ra) # 80001244 <mappages>
    8000177c:	e515                	bnez	a0,800017a8 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    8000177e:	6785                	lui	a5,0x1
    80001780:	99be                	add	s3,s3,a5
    80001782:	fb49e6e3          	bltu	s3,s4,8000172e <uvmcopy+0x20>
    80001786:	a081                	j	800017c6 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001788:	00007517          	auipc	a0,0x7
    8000178c:	a4050513          	addi	a0,a0,-1472 # 800081c8 <digits+0x178>
    80001790:	fffff097          	auipc	ra,0xfffff
    80001794:	dac080e7          	jalr	-596(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001798:	00007517          	auipc	a0,0x7
    8000179c:	a5050513          	addi	a0,a0,-1456 # 800081e8 <digits+0x198>
    800017a0:	fffff097          	auipc	ra,0xfffff
    800017a4:	d9c080e7          	jalr	-612(ra) # 8000053c <panic>
      kfree(mem);
    800017a8:	854a                	mv	a0,s2
    800017aa:	fffff097          	auipc	ra,0xfffff
    800017ae:	2ea080e7          	jalr	746(ra) # 80000a94 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800017b2:	4685                	li	a3,1
    800017b4:	00c9d613          	srli	a2,s3,0xc
    800017b8:	4581                	li	a1,0
    800017ba:	8556                	mv	a0,s5
    800017bc:	00000097          	auipc	ra,0x0
    800017c0:	c4e080e7          	jalr	-946(ra) # 8000140a <uvmunmap>
  return -1;
    800017c4:	557d                	li	a0,-1
}
    800017c6:	60a6                	ld	ra,72(sp)
    800017c8:	6406                	ld	s0,64(sp)
    800017ca:	74e2                	ld	s1,56(sp)
    800017cc:	7942                	ld	s2,48(sp)
    800017ce:	79a2                	ld	s3,40(sp)
    800017d0:	7a02                	ld	s4,32(sp)
    800017d2:	6ae2                	ld	s5,24(sp)
    800017d4:	6b42                	ld	s6,16(sp)
    800017d6:	6ba2                	ld	s7,8(sp)
    800017d8:	6161                	addi	sp,sp,80
    800017da:	8082                	ret
  return 0;
    800017dc:	4501                	li	a0,0
}
    800017de:	8082                	ret

00000000800017e0 <uvmshare>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //struct spinlock lock;

  for(i = 0; i < sz; i += PGSIZE){
    800017e0:	ca55                	beqz	a2,80001894 <uvmshare+0xb4>
int uvmshare(pagetable_t old, pagetable_t new, uint64 sz) {
    800017e2:	7139                	addi	sp,sp,-64
    800017e4:	fc06                	sd	ra,56(sp)
    800017e6:	f822                	sd	s0,48(sp)
    800017e8:	f426                	sd	s1,40(sp)
    800017ea:	f04a                	sd	s2,32(sp)
    800017ec:	ec4e                	sd	s3,24(sp)
    800017ee:	e852                	sd	s4,16(sp)
    800017f0:	e456                	sd	s5,8(sp)
    800017f2:	e05a                	sd	s6,0(sp)
    800017f4:	0080                	addi	s0,sp,64
    800017f6:	8b2a                	mv	s6,a0
    800017f8:	8aae                	mv	s5,a1
    800017fa:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800017fc:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    800017fe:	4601                	li	a2,0
    80001800:	85ca                	mv	a1,s2
    80001802:	855a                	mv	a0,s6
    80001804:	00000097          	auipc	ra,0x0
    80001808:	958080e7          	jalr	-1704(ra) # 8000115c <walk>
    8000180c:	c121                	beqz	a0,8000184c <uvmshare+0x6c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000180e:	6118                	ld	a4,0(a0)
    80001810:	00177793          	andi	a5,a4,1
    80001814:	c7a1                	beqz	a5,8000185c <uvmshare+0x7c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001816:	00a75993          	srli	s3,a4,0xa
    8000181a:	09b2                	slli	s3,s3,0xc
    // Remove write permission flag
    *pte = (*pte & (~PTE_W));
    8000181c:	ffb77493          	andi	s1,a4,-5
    80001820:	e104                	sd	s1,0(a0)

    flags = PTE_FLAGS(*pte);

    // Increment the refcount
    increment_refcount(pa); 
    80001822:	854e                	mv	a0,s3
    80001824:	fffff097          	auipc	ra,0xfffff
    80001828:	1d2080e7          	jalr	466(ra) # 800009f6 <increment_refcount>

    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    8000182c:	3fb4f713          	andi	a4,s1,1019
    80001830:	86ce                	mv	a3,s3
    80001832:	6605                	lui	a2,0x1
    80001834:	85ca                	mv	a1,s2
    80001836:	8556                	mv	a0,s5
    80001838:	00000097          	auipc	ra,0x0
    8000183c:	a0c080e7          	jalr	-1524(ra) # 80001244 <mappages>
    80001840:	e515                	bnez	a0,8000186c <uvmshare+0x8c>
  for(i = 0; i < sz; i += PGSIZE){
    80001842:	6785                	lui	a5,0x1
    80001844:	993e                	add	s2,s2,a5
    80001846:	fb496ce3          	bltu	s2,s4,800017fe <uvmshare+0x1e>
    8000184a:	a81d                	j	80001880 <uvmshare+0xa0>
      panic("uvmcopy: pte should exist");
    8000184c:	00007517          	auipc	a0,0x7
    80001850:	97c50513          	addi	a0,a0,-1668 # 800081c8 <digits+0x178>
    80001854:	fffff097          	auipc	ra,0xfffff
    80001858:	ce8080e7          	jalr	-792(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    8000185c:	00007517          	auipc	a0,0x7
    80001860:	98c50513          	addi	a0,a0,-1652 # 800081e8 <digits+0x198>
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	cd8080e7          	jalr	-808(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000186c:	4685                	li	a3,1
    8000186e:	00c95613          	srli	a2,s2,0xc
    80001872:	4581                	li	a1,0
    80001874:	8556                	mv	a0,s5
    80001876:	00000097          	auipc	ra,0x0
    8000187a:	b94080e7          	jalr	-1132(ra) # 8000140a <uvmunmap>
  return -1;
    8000187e:	557d                	li	a0,-1
}
    80001880:	70e2                	ld	ra,56(sp)
    80001882:	7442                	ld	s0,48(sp)
    80001884:	74a2                	ld	s1,40(sp)
    80001886:	7902                	ld	s2,32(sp)
    80001888:	69e2                	ld	s3,24(sp)
    8000188a:	6a42                	ld	s4,16(sp)
    8000188c:	6aa2                	ld	s5,8(sp)
    8000188e:	6b02                	ld	s6,0(sp)
    80001890:	6121                	addi	sp,sp,64
    80001892:	8082                	ret
  return 0;
    80001894:	4501                	li	a0,0
}
    80001896:	8082                	ret

0000000080001898 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001898:	1141                	addi	sp,sp,-16
    8000189a:	e406                	sd	ra,8(sp)
    8000189c:	e022                	sd	s0,0(sp)
    8000189e:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800018a0:	4601                	li	a2,0
    800018a2:	00000097          	auipc	ra,0x0
    800018a6:	8ba080e7          	jalr	-1862(ra) # 8000115c <walk>
  if(pte == 0)
    800018aa:	c901                	beqz	a0,800018ba <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800018ac:	611c                	ld	a5,0(a0)
    800018ae:	9bbd                	andi	a5,a5,-17
    800018b0:	e11c                	sd	a5,0(a0)
}
    800018b2:	60a2                	ld	ra,8(sp)
    800018b4:	6402                	ld	s0,0(sp)
    800018b6:	0141                	addi	sp,sp,16
    800018b8:	8082                	ret
    panic("uvmclear");
    800018ba:	00007517          	auipc	a0,0x7
    800018be:	94e50513          	addi	a0,a0,-1714 # 80008208 <digits+0x1b8>
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	c7a080e7          	jalr	-902(ra) # 8000053c <panic>

00000000800018ca <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018ca:	c6bd                	beqz	a3,80001938 <copyout+0x6e>
{
    800018cc:	715d                	addi	sp,sp,-80
    800018ce:	e486                	sd	ra,72(sp)
    800018d0:	e0a2                	sd	s0,64(sp)
    800018d2:	fc26                	sd	s1,56(sp)
    800018d4:	f84a                	sd	s2,48(sp)
    800018d6:	f44e                	sd	s3,40(sp)
    800018d8:	f052                	sd	s4,32(sp)
    800018da:	ec56                	sd	s5,24(sp)
    800018dc:	e85a                	sd	s6,16(sp)
    800018de:	e45e                	sd	s7,8(sp)
    800018e0:	e062                	sd	s8,0(sp)
    800018e2:	0880                	addi	s0,sp,80
    800018e4:	8b2a                	mv	s6,a0
    800018e6:	8c2e                	mv	s8,a1
    800018e8:	8a32                	mv	s4,a2
    800018ea:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018ec:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018ee:	6a85                	lui	s5,0x1
    800018f0:	a015                	j	80001914 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018f2:	9562                	add	a0,a0,s8
    800018f4:	0004861b          	sext.w	a2,s1
    800018f8:	85d2                	mv	a1,s4
    800018fa:	41250533          	sub	a0,a0,s2
    800018fe:	fffff097          	auipc	ra,0xfffff
    80001902:	5d8080e7          	jalr	1496(ra) # 80000ed6 <memmove>

    len -= n;
    80001906:	409989b3          	sub	s3,s3,s1
    src += n;
    8000190a:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000190c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001910:	02098263          	beqz	s3,80001934 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001914:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001918:	85ca                	mv	a1,s2
    8000191a:	855a                	mv	a0,s6
    8000191c:	00000097          	auipc	ra,0x0
    80001920:	8e6080e7          	jalr	-1818(ra) # 80001202 <walkaddr>
    if(pa0 == 0)
    80001924:	cd01                	beqz	a0,8000193c <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001926:	418904b3          	sub	s1,s2,s8
    8000192a:	94d6                	add	s1,s1,s5
    8000192c:	fc99f3e3          	bgeu	s3,s1,800018f2 <copyout+0x28>
    80001930:	84ce                	mv	s1,s3
    80001932:	b7c1                	j	800018f2 <copyout+0x28>
  }
  return 0;
    80001934:	4501                	li	a0,0
    80001936:	a021                	j	8000193e <copyout+0x74>
    80001938:	4501                	li	a0,0
}
    8000193a:	8082                	ret
      return -1;
    8000193c:	557d                	li	a0,-1
}
    8000193e:	60a6                	ld	ra,72(sp)
    80001940:	6406                	ld	s0,64(sp)
    80001942:	74e2                	ld	s1,56(sp)
    80001944:	7942                	ld	s2,48(sp)
    80001946:	79a2                	ld	s3,40(sp)
    80001948:	7a02                	ld	s4,32(sp)
    8000194a:	6ae2                	ld	s5,24(sp)
    8000194c:	6b42                	ld	s6,16(sp)
    8000194e:	6ba2                	ld	s7,8(sp)
    80001950:	6c02                	ld	s8,0(sp)
    80001952:	6161                	addi	sp,sp,80
    80001954:	8082                	ret

0000000080001956 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001956:	caa5                	beqz	a3,800019c6 <copyin+0x70>
{
    80001958:	715d                	addi	sp,sp,-80
    8000195a:	e486                	sd	ra,72(sp)
    8000195c:	e0a2                	sd	s0,64(sp)
    8000195e:	fc26                	sd	s1,56(sp)
    80001960:	f84a                	sd	s2,48(sp)
    80001962:	f44e                	sd	s3,40(sp)
    80001964:	f052                	sd	s4,32(sp)
    80001966:	ec56                	sd	s5,24(sp)
    80001968:	e85a                	sd	s6,16(sp)
    8000196a:	e45e                	sd	s7,8(sp)
    8000196c:	e062                	sd	s8,0(sp)
    8000196e:	0880                	addi	s0,sp,80
    80001970:	8b2a                	mv	s6,a0
    80001972:	8a2e                	mv	s4,a1
    80001974:	8c32                	mv	s8,a2
    80001976:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001978:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000197a:	6a85                	lui	s5,0x1
    8000197c:	a01d                	j	800019a2 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000197e:	018505b3          	add	a1,a0,s8
    80001982:	0004861b          	sext.w	a2,s1
    80001986:	412585b3          	sub	a1,a1,s2
    8000198a:	8552                	mv	a0,s4
    8000198c:	fffff097          	auipc	ra,0xfffff
    80001990:	54a080e7          	jalr	1354(ra) # 80000ed6 <memmove>

    len -= n;
    80001994:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001998:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000199a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000199e:	02098263          	beqz	s3,800019c2 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    800019a2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019a6:	85ca                	mv	a1,s2
    800019a8:	855a                	mv	a0,s6
    800019aa:	00000097          	auipc	ra,0x0
    800019ae:	858080e7          	jalr	-1960(ra) # 80001202 <walkaddr>
    if(pa0 == 0)
    800019b2:	cd01                	beqz	a0,800019ca <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800019b4:	418904b3          	sub	s1,s2,s8
    800019b8:	94d6                	add	s1,s1,s5
    800019ba:	fc99f2e3          	bgeu	s3,s1,8000197e <copyin+0x28>
    800019be:	84ce                	mv	s1,s3
    800019c0:	bf7d                	j	8000197e <copyin+0x28>
  }
  return 0;
    800019c2:	4501                	li	a0,0
    800019c4:	a021                	j	800019cc <copyin+0x76>
    800019c6:	4501                	li	a0,0
}
    800019c8:	8082                	ret
      return -1;
    800019ca:	557d                	li	a0,-1
}
    800019cc:	60a6                	ld	ra,72(sp)
    800019ce:	6406                	ld	s0,64(sp)
    800019d0:	74e2                	ld	s1,56(sp)
    800019d2:	7942                	ld	s2,48(sp)
    800019d4:	79a2                	ld	s3,40(sp)
    800019d6:	7a02                	ld	s4,32(sp)
    800019d8:	6ae2                	ld	s5,24(sp)
    800019da:	6b42                	ld	s6,16(sp)
    800019dc:	6ba2                	ld	s7,8(sp)
    800019de:	6c02                	ld	s8,0(sp)
    800019e0:	6161                	addi	sp,sp,80
    800019e2:	8082                	ret

00000000800019e4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019e4:	c2dd                	beqz	a3,80001a8a <copyinstr+0xa6>
{
    800019e6:	715d                	addi	sp,sp,-80
    800019e8:	e486                	sd	ra,72(sp)
    800019ea:	e0a2                	sd	s0,64(sp)
    800019ec:	fc26                	sd	s1,56(sp)
    800019ee:	f84a                	sd	s2,48(sp)
    800019f0:	f44e                	sd	s3,40(sp)
    800019f2:	f052                	sd	s4,32(sp)
    800019f4:	ec56                	sd	s5,24(sp)
    800019f6:	e85a                	sd	s6,16(sp)
    800019f8:	e45e                	sd	s7,8(sp)
    800019fa:	0880                	addi	s0,sp,80
    800019fc:	8a2a                	mv	s4,a0
    800019fe:	8b2e                	mv	s6,a1
    80001a00:	8bb2                	mv	s7,a2
    80001a02:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001a04:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a06:	6985                	lui	s3,0x1
    80001a08:	a02d                	j	80001a32 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a0a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a0e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a10:	37fd                	addiw	a5,a5,-1
    80001a12:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001a16:	60a6                	ld	ra,72(sp)
    80001a18:	6406                	ld	s0,64(sp)
    80001a1a:	74e2                	ld	s1,56(sp)
    80001a1c:	7942                	ld	s2,48(sp)
    80001a1e:	79a2                	ld	s3,40(sp)
    80001a20:	7a02                	ld	s4,32(sp)
    80001a22:	6ae2                	ld	s5,24(sp)
    80001a24:	6b42                	ld	s6,16(sp)
    80001a26:	6ba2                	ld	s7,8(sp)
    80001a28:	6161                	addi	sp,sp,80
    80001a2a:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a2c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a30:	c8a9                	beqz	s1,80001a82 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001a32:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a36:	85ca                	mv	a1,s2
    80001a38:	8552                	mv	a0,s4
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	7c8080e7          	jalr	1992(ra) # 80001202 <walkaddr>
    if(pa0 == 0)
    80001a42:	c131                	beqz	a0,80001a86 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001a44:	417906b3          	sub	a3,s2,s7
    80001a48:	96ce                	add	a3,a3,s3
    80001a4a:	00d4f363          	bgeu	s1,a3,80001a50 <copyinstr+0x6c>
    80001a4e:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a50:	955e                	add	a0,a0,s7
    80001a52:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a56:	daf9                	beqz	a3,80001a2c <copyinstr+0x48>
    80001a58:	87da                	mv	a5,s6
    80001a5a:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001a5c:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001a60:	96da                	add	a3,a3,s6
    80001a62:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001a64:	00f60733          	add	a4,a2,a5
    80001a68:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fb9d140>
    80001a6c:	df59                	beqz	a4,80001a0a <copyinstr+0x26>
        *dst = *p;
    80001a6e:	00e78023          	sb	a4,0(a5)
      dst++;
    80001a72:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a74:	fed797e3          	bne	a5,a3,80001a62 <copyinstr+0x7e>
    80001a78:	14fd                	addi	s1,s1,-1
    80001a7a:	94c2                	add	s1,s1,a6
      --max;
    80001a7c:	8c8d                	sub	s1,s1,a1
      dst++;
    80001a7e:	8b3e                	mv	s6,a5
    80001a80:	b775                	j	80001a2c <copyinstr+0x48>
    80001a82:	4781                	li	a5,0
    80001a84:	b771                	j	80001a10 <copyinstr+0x2c>
      return -1;
    80001a86:	557d                	li	a0,-1
    80001a88:	b779                	j	80001a16 <copyinstr+0x32>
  int got_null = 0;
    80001a8a:	4781                	li	a5,0
  if(got_null){
    80001a8c:	37fd                	addiw	a5,a5,-1
    80001a8e:	0007851b          	sext.w	a0,a5
}
    80001a92:	8082                	ret

0000000080001a94 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001a94:	715d                	addi	sp,sp,-80
    80001a96:	e486                	sd	ra,72(sp)
    80001a98:	e0a2                	sd	s0,64(sp)
    80001a9a:	fc26                	sd	s1,56(sp)
    80001a9c:	f84a                	sd	s2,48(sp)
    80001a9e:	f44e                	sd	s3,40(sp)
    80001aa0:	f052                	sd	s4,32(sp)
    80001aa2:	ec56                	sd	s5,24(sp)
    80001aa4:	e85a                	sd	s6,16(sp)
    80001aa6:	e45e                	sd	s7,8(sp)
    80001aa8:	e062                	sd	s8,0(sp)
    80001aaa:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aac:	8792                	mv	a5,tp
    int id = r_tp();
    80001aae:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001ab0:	0044fa97          	auipc	s5,0x44f
    80001ab4:	200a8a93          	addi	s5,s5,512 # 80450cb0 <cpus>
    80001ab8:	00779713          	slli	a4,a5,0x7
    80001abc:	00ea86b3          	add	a3,s5,a4
    80001ac0:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fb9d140>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001ac4:	0721                	addi	a4,a4,8
    80001ac6:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001ac8:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001aca:	00007c17          	auipc	s8,0x7
    80001ace:	ebec0c13          	addi	s8,s8,-322 # 80008988 <sched_pointer>
    80001ad2:	00000b97          	auipc	s7,0x0
    80001ad6:	fc2b8b93          	addi	s7,s7,-62 # 80001a94 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001ada:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001ade:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ae2:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001ae6:	0044f497          	auipc	s1,0x44f
    80001aea:	5fa48493          	addi	s1,s1,1530 # 804510e0 <proc>
            if (p->state == RUNNABLE)
    80001aee:	498d                	li	s3,3
                p->state = RUNNING;
    80001af0:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001af2:	00455a17          	auipc	s4,0x455
    80001af6:	feea0a13          	addi	s4,s4,-18 # 80456ae0 <tickslock>
    80001afa:	a81d                	j	80001b30 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001afc:	8526                	mv	a0,s1
    80001afe:	fffff097          	auipc	ra,0xfffff
    80001b02:	334080e7          	jalr	820(ra) # 80000e32 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001b06:	60a6                	ld	ra,72(sp)
    80001b08:	6406                	ld	s0,64(sp)
    80001b0a:	74e2                	ld	s1,56(sp)
    80001b0c:	7942                	ld	s2,48(sp)
    80001b0e:	79a2                	ld	s3,40(sp)
    80001b10:	7a02                	ld	s4,32(sp)
    80001b12:	6ae2                	ld	s5,24(sp)
    80001b14:	6b42                	ld	s6,16(sp)
    80001b16:	6ba2                	ld	s7,8(sp)
    80001b18:	6c02                	ld	s8,0(sp)
    80001b1a:	6161                	addi	sp,sp,80
    80001b1c:	8082                	ret
            release(&p->lock);
    80001b1e:	8526                	mv	a0,s1
    80001b20:	fffff097          	auipc	ra,0xfffff
    80001b24:	312080e7          	jalr	786(ra) # 80000e32 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001b28:	16848493          	addi	s1,s1,360
    80001b2c:	fb4487e3          	beq	s1,s4,80001ada <rr_scheduler+0x46>
            acquire(&p->lock);
    80001b30:	8526                	mv	a0,s1
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	24c080e7          	jalr	588(ra) # 80000d7e <acquire>
            if (p->state == RUNNABLE)
    80001b3a:	4c9c                	lw	a5,24(s1)
    80001b3c:	ff3791e3          	bne	a5,s3,80001b1e <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001b40:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001b44:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001b48:	06048593          	addi	a1,s1,96
    80001b4c:	8556                	mv	a0,s5
    80001b4e:	00001097          	auipc	ra,0x1
    80001b52:	f5e080e7          	jalr	-162(ra) # 80002aac <swtch>
                if (sched_pointer != &rr_scheduler)
    80001b56:	000c3783          	ld	a5,0(s8)
    80001b5a:	fb7791e3          	bne	a5,s7,80001afc <rr_scheduler+0x68>
                c->proc = 0;
    80001b5e:	00093023          	sd	zero,0(s2)
    80001b62:	bf75                	j	80001b1e <rr_scheduler+0x8a>

0000000080001b64 <proc_mapstacks>:
{
    80001b64:	7139                	addi	sp,sp,-64
    80001b66:	fc06                	sd	ra,56(sp)
    80001b68:	f822                	sd	s0,48(sp)
    80001b6a:	f426                	sd	s1,40(sp)
    80001b6c:	f04a                	sd	s2,32(sp)
    80001b6e:	ec4e                	sd	s3,24(sp)
    80001b70:	e852                	sd	s4,16(sp)
    80001b72:	e456                	sd	s5,8(sp)
    80001b74:	e05a                	sd	s6,0(sp)
    80001b76:	0080                	addi	s0,sp,64
    80001b78:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001b7a:	0044f497          	auipc	s1,0x44f
    80001b7e:	56648493          	addi	s1,s1,1382 # 804510e0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001b82:	8b26                	mv	s6,s1
    80001b84:	00006a97          	auipc	s5,0x6
    80001b88:	48ca8a93          	addi	s5,s5,1164 # 80008010 <__func__.1+0x8>
    80001b8c:	04000937          	lui	s2,0x4000
    80001b90:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b92:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b94:	00455a17          	auipc	s4,0x455
    80001b98:	f4ca0a13          	addi	s4,s4,-180 # 80456ae0 <tickslock>
        char *pa = kalloc();
    80001b9c:	fffff097          	auipc	ra,0xfffff
    80001ba0:	090080e7          	jalr	144(ra) # 80000c2c <kalloc>
    80001ba4:	862a                	mv	a2,a0
        if (pa == 0)
    80001ba6:	c131                	beqz	a0,80001bea <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001ba8:	416485b3          	sub	a1,s1,s6
    80001bac:	858d                	srai	a1,a1,0x3
    80001bae:	000ab783          	ld	a5,0(s5)
    80001bb2:	02f585b3          	mul	a1,a1,a5
    80001bb6:	2585                	addiw	a1,a1,1
    80001bb8:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bbc:	4719                	li	a4,6
    80001bbe:	6685                	lui	a3,0x1
    80001bc0:	40b905b3          	sub	a1,s2,a1
    80001bc4:	854e                	mv	a0,s3
    80001bc6:	fffff097          	auipc	ra,0xfffff
    80001bca:	71e080e7          	jalr	1822(ra) # 800012e4 <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001bce:	16848493          	addi	s1,s1,360
    80001bd2:	fd4495e3          	bne	s1,s4,80001b9c <proc_mapstacks+0x38>
}
    80001bd6:	70e2                	ld	ra,56(sp)
    80001bd8:	7442                	ld	s0,48(sp)
    80001bda:	74a2                	ld	s1,40(sp)
    80001bdc:	7902                	ld	s2,32(sp)
    80001bde:	69e2                	ld	s3,24(sp)
    80001be0:	6a42                	ld	s4,16(sp)
    80001be2:	6aa2                	ld	s5,8(sp)
    80001be4:	6b02                	ld	s6,0(sp)
    80001be6:	6121                	addi	sp,sp,64
    80001be8:	8082                	ret
            panic("kalloc");
    80001bea:	00006517          	auipc	a0,0x6
    80001bee:	62e50513          	addi	a0,a0,1582 # 80008218 <digits+0x1c8>
    80001bf2:	fffff097          	auipc	ra,0xfffff
    80001bf6:	94a080e7          	jalr	-1718(ra) # 8000053c <panic>

0000000080001bfa <procinit>:
{
    80001bfa:	7139                	addi	sp,sp,-64
    80001bfc:	fc06                	sd	ra,56(sp)
    80001bfe:	f822                	sd	s0,48(sp)
    80001c00:	f426                	sd	s1,40(sp)
    80001c02:	f04a                	sd	s2,32(sp)
    80001c04:	ec4e                	sd	s3,24(sp)
    80001c06:	e852                	sd	s4,16(sp)
    80001c08:	e456                	sd	s5,8(sp)
    80001c0a:	e05a                	sd	s6,0(sp)
    80001c0c:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001c0e:	00006597          	auipc	a1,0x6
    80001c12:	61258593          	addi	a1,a1,1554 # 80008220 <digits+0x1d0>
    80001c16:	0044f517          	auipc	a0,0x44f
    80001c1a:	49a50513          	addi	a0,a0,1178 # 804510b0 <pid_lock>
    80001c1e:	fffff097          	auipc	ra,0xfffff
    80001c22:	0d0080e7          	jalr	208(ra) # 80000cee <initlock>
    initlock(&wait_lock, "wait_lock");
    80001c26:	00006597          	auipc	a1,0x6
    80001c2a:	60258593          	addi	a1,a1,1538 # 80008228 <digits+0x1d8>
    80001c2e:	0044f517          	auipc	a0,0x44f
    80001c32:	49a50513          	addi	a0,a0,1178 # 804510c8 <wait_lock>
    80001c36:	fffff097          	auipc	ra,0xfffff
    80001c3a:	0b8080e7          	jalr	184(ra) # 80000cee <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001c3e:	0044f497          	auipc	s1,0x44f
    80001c42:	4a248493          	addi	s1,s1,1186 # 804510e0 <proc>
        initlock(&p->lock, "proc");
    80001c46:	00006b17          	auipc	s6,0x6
    80001c4a:	5f2b0b13          	addi	s6,s6,1522 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001c4e:	8aa6                	mv	s5,s1
    80001c50:	00006a17          	auipc	s4,0x6
    80001c54:	3c0a0a13          	addi	s4,s4,960 # 80008010 <__func__.1+0x8>
    80001c58:	04000937          	lui	s2,0x4000
    80001c5c:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c5e:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c60:	00455997          	auipc	s3,0x455
    80001c64:	e8098993          	addi	s3,s3,-384 # 80456ae0 <tickslock>
        initlock(&p->lock, "proc");
    80001c68:	85da                	mv	a1,s6
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	fffff097          	auipc	ra,0xfffff
    80001c70:	082080e7          	jalr	130(ra) # 80000cee <initlock>
        p->state = UNUSED;
    80001c74:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001c78:	415487b3          	sub	a5,s1,s5
    80001c7c:	878d                	srai	a5,a5,0x3
    80001c7e:	000a3703          	ld	a4,0(s4)
    80001c82:	02e787b3          	mul	a5,a5,a4
    80001c86:	2785                	addiw	a5,a5,1
    80001c88:	00d7979b          	slliw	a5,a5,0xd
    80001c8c:	40f907b3          	sub	a5,s2,a5
    80001c90:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001c92:	16848493          	addi	s1,s1,360
    80001c96:	fd3499e3          	bne	s1,s3,80001c68 <procinit+0x6e>
}
    80001c9a:	70e2                	ld	ra,56(sp)
    80001c9c:	7442                	ld	s0,48(sp)
    80001c9e:	74a2                	ld	s1,40(sp)
    80001ca0:	7902                	ld	s2,32(sp)
    80001ca2:	69e2                	ld	s3,24(sp)
    80001ca4:	6a42                	ld	s4,16(sp)
    80001ca6:	6aa2                	ld	s5,8(sp)
    80001ca8:	6b02                	ld	s6,0(sp)
    80001caa:	6121                	addi	sp,sp,64
    80001cac:	8082                	ret

0000000080001cae <copy_array>:
{
    80001cae:	1141                	addi	sp,sp,-16
    80001cb0:	e422                	sd	s0,8(sp)
    80001cb2:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001cb4:	00c05c63          	blez	a2,80001ccc <copy_array+0x1e>
    80001cb8:	87aa                	mv	a5,a0
    80001cba:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001cbc:	0007c703          	lbu	a4,0(a5)
    80001cc0:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001cc4:	0785                	addi	a5,a5,1
    80001cc6:	0585                	addi	a1,a1,1
    80001cc8:	fea79ae3          	bne	a5,a0,80001cbc <copy_array+0xe>
}
    80001ccc:	6422                	ld	s0,8(sp)
    80001cce:	0141                	addi	sp,sp,16
    80001cd0:	8082                	ret

0000000080001cd2 <cpuid>:
{
    80001cd2:	1141                	addi	sp,sp,-16
    80001cd4:	e422                	sd	s0,8(sp)
    80001cd6:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cd8:	8512                	mv	a0,tp
}
    80001cda:	2501                	sext.w	a0,a0
    80001cdc:	6422                	ld	s0,8(sp)
    80001cde:	0141                	addi	sp,sp,16
    80001ce0:	8082                	ret

0000000080001ce2 <mycpu>:
{
    80001ce2:	1141                	addi	sp,sp,-16
    80001ce4:	e422                	sd	s0,8(sp)
    80001ce6:	0800                	addi	s0,sp,16
    80001ce8:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001cea:	2781                	sext.w	a5,a5
    80001cec:	079e                	slli	a5,a5,0x7
}
    80001cee:	0044f517          	auipc	a0,0x44f
    80001cf2:	fc250513          	addi	a0,a0,-62 # 80450cb0 <cpus>
    80001cf6:	953e                	add	a0,a0,a5
    80001cf8:	6422                	ld	s0,8(sp)
    80001cfa:	0141                	addi	sp,sp,16
    80001cfc:	8082                	ret

0000000080001cfe <myproc>:
{
    80001cfe:	1101                	addi	sp,sp,-32
    80001d00:	ec06                	sd	ra,24(sp)
    80001d02:	e822                	sd	s0,16(sp)
    80001d04:	e426                	sd	s1,8(sp)
    80001d06:	1000                	addi	s0,sp,32
    push_off();
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	02a080e7          	jalr	42(ra) # 80000d32 <push_off>
    80001d10:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001d12:	2781                	sext.w	a5,a5
    80001d14:	079e                	slli	a5,a5,0x7
    80001d16:	0044f717          	auipc	a4,0x44f
    80001d1a:	f9a70713          	addi	a4,a4,-102 # 80450cb0 <cpus>
    80001d1e:	97ba                	add	a5,a5,a4
    80001d20:	6384                	ld	s1,0(a5)
    pop_off();
    80001d22:	fffff097          	auipc	ra,0xfffff
    80001d26:	0b0080e7          	jalr	176(ra) # 80000dd2 <pop_off>
}
    80001d2a:	8526                	mv	a0,s1
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret

0000000080001d36 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d36:	1141                	addi	sp,sp,-16
    80001d38:	e406                	sd	ra,8(sp)
    80001d3a:	e022                	sd	s0,0(sp)
    80001d3c:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	fc0080e7          	jalr	-64(ra) # 80001cfe <myproc>
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	0ec080e7          	jalr	236(ra) # 80000e32 <release>

    if (first)
    80001d4e:	00007797          	auipc	a5,0x7
    80001d52:	c327a783          	lw	a5,-974(a5) # 80008980 <first.1>
    80001d56:	eb89                	bnez	a5,80001d68 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001d58:	00001097          	auipc	ra,0x1
    80001d5c:	dfe080e7          	jalr	-514(ra) # 80002b56 <usertrapret>
}
    80001d60:	60a2                	ld	ra,8(sp)
    80001d62:	6402                	ld	s0,0(sp)
    80001d64:	0141                	addi	sp,sp,16
    80001d66:	8082                	ret
        first = 0;
    80001d68:	00007797          	auipc	a5,0x7
    80001d6c:	c007ac23          	sw	zero,-1000(a5) # 80008980 <first.1>
        fsinit(ROOTDEV);
    80001d70:	4505                	li	a0,1
    80001d72:	00002097          	auipc	ra,0x2
    80001d76:	d04080e7          	jalr	-764(ra) # 80003a76 <fsinit>
    80001d7a:	bff9                	j	80001d58 <forkret+0x22>

0000000080001d7c <allocpid>:
{
    80001d7c:	1101                	addi	sp,sp,-32
    80001d7e:	ec06                	sd	ra,24(sp)
    80001d80:	e822                	sd	s0,16(sp)
    80001d82:	e426                	sd	s1,8(sp)
    80001d84:	e04a                	sd	s2,0(sp)
    80001d86:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001d88:	0044f917          	auipc	s2,0x44f
    80001d8c:	32890913          	addi	s2,s2,808 # 804510b0 <pid_lock>
    80001d90:	854a                	mv	a0,s2
    80001d92:	fffff097          	auipc	ra,0xfffff
    80001d96:	fec080e7          	jalr	-20(ra) # 80000d7e <acquire>
    pid = nextpid;
    80001d9a:	00007797          	auipc	a5,0x7
    80001d9e:	bf678793          	addi	a5,a5,-1034 # 80008990 <nextpid>
    80001da2:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001da4:	0014871b          	addiw	a4,s1,1
    80001da8:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001daa:	854a                	mv	a0,s2
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	086080e7          	jalr	134(ra) # 80000e32 <release>
}
    80001db4:	8526                	mv	a0,s1
    80001db6:	60e2                	ld	ra,24(sp)
    80001db8:	6442                	ld	s0,16(sp)
    80001dba:	64a2                	ld	s1,8(sp)
    80001dbc:	6902                	ld	s2,0(sp)
    80001dbe:	6105                	addi	sp,sp,32
    80001dc0:	8082                	ret

0000000080001dc2 <proc_pagetable>:
{
    80001dc2:	1101                	addi	sp,sp,-32
    80001dc4:	ec06                	sd	ra,24(sp)
    80001dc6:	e822                	sd	s0,16(sp)
    80001dc8:	e426                	sd	s1,8(sp)
    80001dca:	e04a                	sd	s2,0(sp)
    80001dcc:	1000                	addi	s0,sp,32
    80001dce:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	6fe080e7          	jalr	1790(ra) # 800014ce <uvmcreate>
    80001dd8:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001dda:	c121                	beqz	a0,80001e1a <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ddc:	4729                	li	a4,10
    80001dde:	00005697          	auipc	a3,0x5
    80001de2:	22268693          	addi	a3,a3,546 # 80007000 <_trampoline>
    80001de6:	6605                	lui	a2,0x1
    80001de8:	040005b7          	lui	a1,0x4000
    80001dec:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001dee:	05b2                	slli	a1,a1,0xc
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	454080e7          	jalr	1108(ra) # 80001244 <mappages>
    80001df8:	02054863          	bltz	a0,80001e28 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dfc:	4719                	li	a4,6
    80001dfe:	05893683          	ld	a3,88(s2)
    80001e02:	6605                	lui	a2,0x1
    80001e04:	020005b7          	lui	a1,0x2000
    80001e08:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e0a:	05b6                	slli	a1,a1,0xd
    80001e0c:	8526                	mv	a0,s1
    80001e0e:	fffff097          	auipc	ra,0xfffff
    80001e12:	436080e7          	jalr	1078(ra) # 80001244 <mappages>
    80001e16:	02054163          	bltz	a0,80001e38 <proc_pagetable+0x76>
}
    80001e1a:	8526                	mv	a0,s1
    80001e1c:	60e2                	ld	ra,24(sp)
    80001e1e:	6442                	ld	s0,16(sp)
    80001e20:	64a2                	ld	s1,8(sp)
    80001e22:	6902                	ld	s2,0(sp)
    80001e24:	6105                	addi	sp,sp,32
    80001e26:	8082                	ret
        uvmfree(pagetable, 0);
    80001e28:	4581                	li	a1,0
    80001e2a:	8526                	mv	a0,s1
    80001e2c:	00000097          	auipc	ra,0x0
    80001e30:	8a8080e7          	jalr	-1880(ra) # 800016d4 <uvmfree>
        return 0;
    80001e34:	4481                	li	s1,0
    80001e36:	b7d5                	j	80001e1a <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e38:	4681                	li	a3,0
    80001e3a:	4605                	li	a2,1
    80001e3c:	040005b7          	lui	a1,0x4000
    80001e40:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e42:	05b2                	slli	a1,a1,0xc
    80001e44:	8526                	mv	a0,s1
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	5c4080e7          	jalr	1476(ra) # 8000140a <uvmunmap>
        uvmfree(pagetable, 0);
    80001e4e:	4581                	li	a1,0
    80001e50:	8526                	mv	a0,s1
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	882080e7          	jalr	-1918(ra) # 800016d4 <uvmfree>
        return 0;
    80001e5a:	4481                	li	s1,0
    80001e5c:	bf7d                	j	80001e1a <proc_pagetable+0x58>

0000000080001e5e <proc_freepagetable>:
{
    80001e5e:	1101                	addi	sp,sp,-32
    80001e60:	ec06                	sd	ra,24(sp)
    80001e62:	e822                	sd	s0,16(sp)
    80001e64:	e426                	sd	s1,8(sp)
    80001e66:	e04a                	sd	s2,0(sp)
    80001e68:	1000                	addi	s0,sp,32
    80001e6a:	84aa                	mv	s1,a0
    80001e6c:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e6e:	4681                	li	a3,0
    80001e70:	4605                	li	a2,1
    80001e72:	040005b7          	lui	a1,0x4000
    80001e76:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e78:	05b2                	slli	a1,a1,0xc
    80001e7a:	fffff097          	auipc	ra,0xfffff
    80001e7e:	590080e7          	jalr	1424(ra) # 8000140a <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e82:	4681                	li	a3,0
    80001e84:	4605                	li	a2,1
    80001e86:	020005b7          	lui	a1,0x2000
    80001e8a:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e8c:	05b6                	slli	a1,a1,0xd
    80001e8e:	8526                	mv	a0,s1
    80001e90:	fffff097          	auipc	ra,0xfffff
    80001e94:	57a080e7          	jalr	1402(ra) # 8000140a <uvmunmap>
    uvmfree(pagetable, sz);
    80001e98:	85ca                	mv	a1,s2
    80001e9a:	8526                	mv	a0,s1
    80001e9c:	00000097          	auipc	ra,0x0
    80001ea0:	838080e7          	jalr	-1992(ra) # 800016d4 <uvmfree>
}
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6902                	ld	s2,0(sp)
    80001eac:	6105                	addi	sp,sp,32
    80001eae:	8082                	ret

0000000080001eb0 <freeproc>:
{
    80001eb0:	1101                	addi	sp,sp,-32
    80001eb2:	ec06                	sd	ra,24(sp)
    80001eb4:	e822                	sd	s0,16(sp)
    80001eb6:	e426                	sd	s1,8(sp)
    80001eb8:	1000                	addi	s0,sp,32
    80001eba:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001ebc:	6d28                	ld	a0,88(a0)
    80001ebe:	c509                	beqz	a0,80001ec8 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	bd4080e7          	jalr	-1068(ra) # 80000a94 <kfree>
    p->trapframe = 0;
    80001ec8:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001ecc:	68a8                	ld	a0,80(s1)
    80001ece:	c511                	beqz	a0,80001eda <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001ed0:	64ac                	ld	a1,72(s1)
    80001ed2:	00000097          	auipc	ra,0x0
    80001ed6:	f8c080e7          	jalr	-116(ra) # 80001e5e <proc_freepagetable>
    p->pagetable = 0;
    80001eda:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001ede:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001ee2:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001ee6:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001eea:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001eee:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001ef2:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001ef6:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001efa:	0004ac23          	sw	zero,24(s1)
}
    80001efe:	60e2                	ld	ra,24(sp)
    80001f00:	6442                	ld	s0,16(sp)
    80001f02:	64a2                	ld	s1,8(sp)
    80001f04:	6105                	addi	sp,sp,32
    80001f06:	8082                	ret

0000000080001f08 <allocproc>:
{
    80001f08:	1101                	addi	sp,sp,-32
    80001f0a:	ec06                	sd	ra,24(sp)
    80001f0c:	e822                	sd	s0,16(sp)
    80001f0e:	e426                	sd	s1,8(sp)
    80001f10:	e04a                	sd	s2,0(sp)
    80001f12:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001f14:	0044f497          	auipc	s1,0x44f
    80001f18:	1cc48493          	addi	s1,s1,460 # 804510e0 <proc>
    80001f1c:	00455917          	auipc	s2,0x455
    80001f20:	bc490913          	addi	s2,s2,-1084 # 80456ae0 <tickslock>
        acquire(&p->lock);
    80001f24:	8526                	mv	a0,s1
    80001f26:	fffff097          	auipc	ra,0xfffff
    80001f2a:	e58080e7          	jalr	-424(ra) # 80000d7e <acquire>
        if (p->state == UNUSED)
    80001f2e:	4c9c                	lw	a5,24(s1)
    80001f30:	cf81                	beqz	a5,80001f48 <allocproc+0x40>
            release(&p->lock);
    80001f32:	8526                	mv	a0,s1
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	efe080e7          	jalr	-258(ra) # 80000e32 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f3c:	16848493          	addi	s1,s1,360
    80001f40:	ff2492e3          	bne	s1,s2,80001f24 <allocproc+0x1c>
    return 0;
    80001f44:	4481                	li	s1,0
    80001f46:	a889                	j	80001f98 <allocproc+0x90>
    p->pid = allocpid();
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	e34080e7          	jalr	-460(ra) # 80001d7c <allocpid>
    80001f50:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001f52:	4785                	li	a5,1
    80001f54:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001f56:	fffff097          	auipc	ra,0xfffff
    80001f5a:	cd6080e7          	jalr	-810(ra) # 80000c2c <kalloc>
    80001f5e:	892a                	mv	s2,a0
    80001f60:	eca8                	sd	a0,88(s1)
    80001f62:	c131                	beqz	a0,80001fa6 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001f64:	8526                	mv	a0,s1
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	e5c080e7          	jalr	-420(ra) # 80001dc2 <proc_pagetable>
    80001f6e:	892a                	mv	s2,a0
    80001f70:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001f72:	c531                	beqz	a0,80001fbe <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001f74:	07000613          	li	a2,112
    80001f78:	4581                	li	a1,0
    80001f7a:	06048513          	addi	a0,s1,96
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	efc080e7          	jalr	-260(ra) # 80000e7a <memset>
    p->context.ra = (uint64)forkret;
    80001f86:	00000797          	auipc	a5,0x0
    80001f8a:	db078793          	addi	a5,a5,-592 # 80001d36 <forkret>
    80001f8e:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001f90:	60bc                	ld	a5,64(s1)
    80001f92:	6705                	lui	a4,0x1
    80001f94:	97ba                	add	a5,a5,a4
    80001f96:	f4bc                	sd	a5,104(s1)
}
    80001f98:	8526                	mv	a0,s1
    80001f9a:	60e2                	ld	ra,24(sp)
    80001f9c:	6442                	ld	s0,16(sp)
    80001f9e:	64a2                	ld	s1,8(sp)
    80001fa0:	6902                	ld	s2,0(sp)
    80001fa2:	6105                	addi	sp,sp,32
    80001fa4:	8082                	ret
        freeproc(p);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	00000097          	auipc	ra,0x0
    80001fac:	f08080e7          	jalr	-248(ra) # 80001eb0 <freeproc>
        release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	e80080e7          	jalr	-384(ra) # 80000e32 <release>
        return 0;
    80001fba:	84ca                	mv	s1,s2
    80001fbc:	bff1                	j	80001f98 <allocproc+0x90>
        freeproc(p);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	00000097          	auipc	ra,0x0
    80001fc4:	ef0080e7          	jalr	-272(ra) # 80001eb0 <freeproc>
        release(&p->lock);
    80001fc8:	8526                	mv	a0,s1
    80001fca:	fffff097          	auipc	ra,0xfffff
    80001fce:	e68080e7          	jalr	-408(ra) # 80000e32 <release>
        return 0;
    80001fd2:	84ca                	mv	s1,s2
    80001fd4:	b7d1                	j	80001f98 <allocproc+0x90>

0000000080001fd6 <userinit>:
{
    80001fd6:	1101                	addi	sp,sp,-32
    80001fd8:	ec06                	sd	ra,24(sp)
    80001fda:	e822                	sd	s0,16(sp)
    80001fdc:	e426                	sd	s1,8(sp)
    80001fde:	1000                	addi	s0,sp,32
    p = allocproc();
    80001fe0:	00000097          	auipc	ra,0x0
    80001fe4:	f28080e7          	jalr	-216(ra) # 80001f08 <allocproc>
    80001fe8:	84aa                	mv	s1,a0
    initproc = p;
    80001fea:	00007797          	auipc	a5,0x7
    80001fee:	a4a7b723          	sd	a0,-1458(a5) # 80008a38 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ff2:	03400613          	li	a2,52
    80001ff6:	00007597          	auipc	a1,0x7
    80001ffa:	9aa58593          	addi	a1,a1,-1622 # 800089a0 <initcode>
    80001ffe:	6928                	ld	a0,80(a0)
    80002000:	fffff097          	auipc	ra,0xfffff
    80002004:	4fc080e7          	jalr	1276(ra) # 800014fc <uvmfirst>
    p->sz = PGSIZE;
    80002008:	6785                	lui	a5,0x1
    8000200a:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    8000200c:	6cb8                	ld	a4,88(s1)
    8000200e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80002012:	6cb8                	ld	a4,88(s1)
    80002014:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80002016:	4641                	li	a2,16
    80002018:	00006597          	auipc	a1,0x6
    8000201c:	22858593          	addi	a1,a1,552 # 80008240 <digits+0x1f0>
    80002020:	15848513          	addi	a0,s1,344
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	f9e080e7          	jalr	-98(ra) # 80000fc2 <safestrcpy>
    p->cwd = namei("/");
    8000202c:	00006517          	auipc	a0,0x6
    80002030:	22450513          	addi	a0,a0,548 # 80008250 <digits+0x200>
    80002034:	00002097          	auipc	ra,0x2
    80002038:	460080e7          	jalr	1120(ra) # 80004494 <namei>
    8000203c:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80002040:	478d                	li	a5,3
    80002042:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80002044:	8526                	mv	a0,s1
    80002046:	fffff097          	auipc	ra,0xfffff
    8000204a:	dec080e7          	jalr	-532(ra) # 80000e32 <release>
}
    8000204e:	60e2                	ld	ra,24(sp)
    80002050:	6442                	ld	s0,16(sp)
    80002052:	64a2                	ld	s1,8(sp)
    80002054:	6105                	addi	sp,sp,32
    80002056:	8082                	ret

0000000080002058 <growproc>:
{
    80002058:	1101                	addi	sp,sp,-32
    8000205a:	ec06                	sd	ra,24(sp)
    8000205c:	e822                	sd	s0,16(sp)
    8000205e:	e426                	sd	s1,8(sp)
    80002060:	e04a                	sd	s2,0(sp)
    80002062:	1000                	addi	s0,sp,32
    80002064:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80002066:	00000097          	auipc	ra,0x0
    8000206a:	c98080e7          	jalr	-872(ra) # 80001cfe <myproc>
    8000206e:	84aa                	mv	s1,a0
    sz = p->sz;
    80002070:	652c                	ld	a1,72(a0)
    if (n > 0)
    80002072:	01204c63          	bgtz	s2,8000208a <growproc+0x32>
    else if (n < 0)
    80002076:	02094663          	bltz	s2,800020a2 <growproc+0x4a>
    p->sz = sz;
    8000207a:	e4ac                	sd	a1,72(s1)
    return 0;
    8000207c:	4501                	li	a0,0
}
    8000207e:	60e2                	ld	ra,24(sp)
    80002080:	6442                	ld	s0,16(sp)
    80002082:	64a2                	ld	s1,8(sp)
    80002084:	6902                	ld	s2,0(sp)
    80002086:	6105                	addi	sp,sp,32
    80002088:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    8000208a:	4691                	li	a3,4
    8000208c:	00b90633          	add	a2,s2,a1
    80002090:	6928                	ld	a0,80(a0)
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	524080e7          	jalr	1316(ra) # 800015b6 <uvmalloc>
    8000209a:	85aa                	mv	a1,a0
    8000209c:	fd79                	bnez	a0,8000207a <growproc+0x22>
            return -1;
    8000209e:	557d                	li	a0,-1
    800020a0:	bff9                	j	8000207e <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020a2:	00b90633          	add	a2,s2,a1
    800020a6:	6928                	ld	a0,80(a0)
    800020a8:	fffff097          	auipc	ra,0xfffff
    800020ac:	4c6080e7          	jalr	1222(ra) # 8000156e <uvmdealloc>
    800020b0:	85aa                	mv	a1,a0
    800020b2:	b7e1                	j	8000207a <growproc+0x22>

00000000800020b4 <ps>:
{
    800020b4:	715d                	addi	sp,sp,-80
    800020b6:	e486                	sd	ra,72(sp)
    800020b8:	e0a2                	sd	s0,64(sp)
    800020ba:	fc26                	sd	s1,56(sp)
    800020bc:	f84a                	sd	s2,48(sp)
    800020be:	f44e                	sd	s3,40(sp)
    800020c0:	f052                	sd	s4,32(sp)
    800020c2:	ec56                	sd	s5,24(sp)
    800020c4:	e85a                	sd	s6,16(sp)
    800020c6:	e45e                	sd	s7,8(sp)
    800020c8:	e062                	sd	s8,0(sp)
    800020ca:	0880                	addi	s0,sp,80
    800020cc:	84aa                	mv	s1,a0
    800020ce:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    800020d0:	00000097          	auipc	ra,0x0
    800020d4:	c2e080e7          	jalr	-978(ra) # 80001cfe <myproc>
    if (count == 0)
    800020d8:	120b8063          	beqz	s7,800021f8 <ps+0x144>
    void *result = (void *)myproc()->sz;
    800020dc:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    800020e0:	003b951b          	slliw	a0,s7,0x3
    800020e4:	0175053b          	addw	a0,a0,s7
    800020e8:	0025151b          	slliw	a0,a0,0x2
    800020ec:	00000097          	auipc	ra,0x0
    800020f0:	f6c080e7          	jalr	-148(ra) # 80002058 <growproc>
    800020f4:	10054463          	bltz	a0,800021fc <ps+0x148>
    struct user_proc loc_result[count];
    800020f8:	003b9a13          	slli	s4,s7,0x3
    800020fc:	9a5e                	add	s4,s4,s7
    800020fe:	0a0a                	slli	s4,s4,0x2
    80002100:	00fa0793          	addi	a5,s4,15
    80002104:	8391                	srli	a5,a5,0x4
    80002106:	0792                	slli	a5,a5,0x4
    80002108:	40f10133          	sub	sp,sp,a5
    8000210c:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    8000210e:	007e97b7          	lui	a5,0x7e9
    80002112:	02f484b3          	mul	s1,s1,a5
    80002116:	0044f797          	auipc	a5,0x44f
    8000211a:	fca78793          	addi	a5,a5,-54 # 804510e0 <proc>
    8000211e:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80002120:	00455797          	auipc	a5,0x455
    80002124:	9c078793          	addi	a5,a5,-1600 # 80456ae0 <tickslock>
    80002128:	0cf4fc63          	bgeu	s1,a5,80002200 <ps+0x14c>
        if (localCount == count)
    8000212c:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80002130:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80002132:	8c3e                	mv	s8,a5
    80002134:	a069                	j	800021be <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80002136:	00399793          	slli	a5,s3,0x3
    8000213a:	97ce                	add	a5,a5,s3
    8000213c:	078a                	slli	a5,a5,0x2
    8000213e:	97d6                	add	a5,a5,s5
    80002140:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80002144:	8526                	mv	a0,s1
    80002146:	fffff097          	auipc	ra,0xfffff
    8000214a:	cec080e7          	jalr	-788(ra) # 80000e32 <release>
    if (localCount < count)
    8000214e:	0179f963          	bgeu	s3,s7,80002160 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002152:	00399793          	slli	a5,s3,0x3
    80002156:	97ce                	add	a5,a5,s3
    80002158:	078a                	slli	a5,a5,0x2
    8000215a:	97d6                	add	a5,a5,s5
    8000215c:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80002160:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002162:	00000097          	auipc	ra,0x0
    80002166:	b9c080e7          	jalr	-1124(ra) # 80001cfe <myproc>
    8000216a:	86d2                	mv	a3,s4
    8000216c:	8656                	mv	a2,s5
    8000216e:	85da                	mv	a1,s6
    80002170:	6928                	ld	a0,80(a0)
    80002172:	fffff097          	auipc	ra,0xfffff
    80002176:	758080e7          	jalr	1880(ra) # 800018ca <copyout>
}
    8000217a:	8526                	mv	a0,s1
    8000217c:	fb040113          	addi	sp,s0,-80
    80002180:	60a6                	ld	ra,72(sp)
    80002182:	6406                	ld	s0,64(sp)
    80002184:	74e2                	ld	s1,56(sp)
    80002186:	7942                	ld	s2,48(sp)
    80002188:	79a2                	ld	s3,40(sp)
    8000218a:	7a02                	ld	s4,32(sp)
    8000218c:	6ae2                	ld	s5,24(sp)
    8000218e:	6b42                	ld	s6,16(sp)
    80002190:	6ba2                	ld	s7,8(sp)
    80002192:	6c02                	ld	s8,0(sp)
    80002194:	6161                	addi	sp,sp,80
    80002196:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002198:	5b9c                	lw	a5,48(a5)
    8000219a:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000219e:	8526                	mv	a0,s1
    800021a0:	fffff097          	auipc	ra,0xfffff
    800021a4:	c92080e7          	jalr	-878(ra) # 80000e32 <release>
        localCount++;
    800021a8:	2985                	addiw	s3,s3,1
    800021aa:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    800021ae:	16848493          	addi	s1,s1,360
    800021b2:	f984fee3          	bgeu	s1,s8,8000214e <ps+0x9a>
        if (localCount == count)
    800021b6:	02490913          	addi	s2,s2,36
    800021ba:	fb3b83e3          	beq	s7,s3,80002160 <ps+0xac>
        acquire(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	bbe080e7          	jalr	-1090(ra) # 80000d7e <acquire>
        if (p->state == UNUSED)
    800021c8:	4c9c                	lw	a5,24(s1)
    800021ca:	d7b5                	beqz	a5,80002136 <ps+0x82>
        loc_result[localCount].state = p->state;
    800021cc:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    800021d0:	549c                	lw	a5,40(s1)
    800021d2:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    800021d6:	54dc                	lw	a5,44(s1)
    800021d8:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800021dc:	589c                	lw	a5,48(s1)
    800021de:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    800021e2:	4641                	li	a2,16
    800021e4:	85ca                	mv	a1,s2
    800021e6:	15848513          	addi	a0,s1,344
    800021ea:	00000097          	auipc	ra,0x0
    800021ee:	ac4080e7          	jalr	-1340(ra) # 80001cae <copy_array>
        if (p->parent != 0) // init
    800021f2:	7c9c                	ld	a5,56(s1)
    800021f4:	f3d5                	bnez	a5,80002198 <ps+0xe4>
    800021f6:	b765                	j	8000219e <ps+0xea>
        return result;
    800021f8:	4481                	li	s1,0
    800021fa:	b741                	j	8000217a <ps+0xc6>
        return result;
    800021fc:	4481                	li	s1,0
    800021fe:	bfb5                	j	8000217a <ps+0xc6>
        return result;
    80002200:	4481                	li	s1,0
    80002202:	bfa5                	j	8000217a <ps+0xc6>

0000000080002204 <fork>:
{
    80002204:	7139                	addi	sp,sp,-64
    80002206:	fc06                	sd	ra,56(sp)
    80002208:	f822                	sd	s0,48(sp)
    8000220a:	f426                	sd	s1,40(sp)
    8000220c:	f04a                	sd	s2,32(sp)
    8000220e:	ec4e                	sd	s3,24(sp)
    80002210:	e852                	sd	s4,16(sp)
    80002212:	e456                	sd	s5,8(sp)
    80002214:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	ae8080e7          	jalr	-1304(ra) # 80001cfe <myproc>
    8000221e:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80002220:	00000097          	auipc	ra,0x0
    80002224:	ce8080e7          	jalr	-792(ra) # 80001f08 <allocproc>
    80002228:	10050c63          	beqz	a0,80002340 <fork+0x13c>
    8000222c:	8a2a                	mv	s4,a0
    if (uvmshare(p->pagetable, np->pagetable, p->sz) < 0)
    8000222e:	048ab603          	ld	a2,72(s5)
    80002232:	692c                	ld	a1,80(a0)
    80002234:	050ab503          	ld	a0,80(s5)
    80002238:	fffff097          	auipc	ra,0xfffff
    8000223c:	5a8080e7          	jalr	1448(ra) # 800017e0 <uvmshare>
    80002240:	04054863          	bltz	a0,80002290 <fork+0x8c>
    np->sz = p->sz;
    80002244:	048ab783          	ld	a5,72(s5)
    80002248:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    8000224c:	058ab683          	ld	a3,88(s5)
    80002250:	87b6                	mv	a5,a3
    80002252:	058a3703          	ld	a4,88(s4)
    80002256:	12068693          	addi	a3,a3,288
    8000225a:	0007b803          	ld	a6,0(a5)
    8000225e:	6788                	ld	a0,8(a5)
    80002260:	6b8c                	ld	a1,16(a5)
    80002262:	6f90                	ld	a2,24(a5)
    80002264:	01073023          	sd	a6,0(a4)
    80002268:	e708                	sd	a0,8(a4)
    8000226a:	eb0c                	sd	a1,16(a4)
    8000226c:	ef10                	sd	a2,24(a4)
    8000226e:	02078793          	addi	a5,a5,32
    80002272:	02070713          	addi	a4,a4,32
    80002276:	fed792e3          	bne	a5,a3,8000225a <fork+0x56>
    np->trapframe->a0 = 0;
    8000227a:	058a3783          	ld	a5,88(s4)
    8000227e:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002282:	0d0a8493          	addi	s1,s5,208
    80002286:	0d0a0913          	addi	s2,s4,208
    8000228a:	150a8993          	addi	s3,s5,336
    8000228e:	a00d                	j	800022b0 <fork+0xac>
        freeproc(np);
    80002290:	8552                	mv	a0,s4
    80002292:	00000097          	auipc	ra,0x0
    80002296:	c1e080e7          	jalr	-994(ra) # 80001eb0 <freeproc>
        release(&np->lock);
    8000229a:	8552                	mv	a0,s4
    8000229c:	fffff097          	auipc	ra,0xfffff
    800022a0:	b96080e7          	jalr	-1130(ra) # 80000e32 <release>
        return -1;
    800022a4:	597d                	li	s2,-1
    800022a6:	a059                	j	8000232c <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    800022a8:	04a1                	addi	s1,s1,8
    800022aa:	0921                	addi	s2,s2,8
    800022ac:	01348b63          	beq	s1,s3,800022c2 <fork+0xbe>
        if (p->ofile[i])
    800022b0:	6088                	ld	a0,0(s1)
    800022b2:	d97d                	beqz	a0,800022a8 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    800022b4:	00003097          	auipc	ra,0x3
    800022b8:	852080e7          	jalr	-1966(ra) # 80004b06 <filedup>
    800022bc:	00a93023          	sd	a0,0(s2)
    800022c0:	b7e5                	j	800022a8 <fork+0xa4>
    np->cwd = idup(p->cwd);
    800022c2:	150ab503          	ld	a0,336(s5)
    800022c6:	00002097          	auipc	ra,0x2
    800022ca:	9ea080e7          	jalr	-1558(ra) # 80003cb0 <idup>
    800022ce:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    800022d2:	4641                	li	a2,16
    800022d4:	158a8593          	addi	a1,s5,344
    800022d8:	158a0513          	addi	a0,s4,344
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	ce6080e7          	jalr	-794(ra) # 80000fc2 <safestrcpy>
    pid = np->pid;
    800022e4:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800022e8:	8552                	mv	a0,s4
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	b48080e7          	jalr	-1208(ra) # 80000e32 <release>
    acquire(&wait_lock);
    800022f2:	0044f497          	auipc	s1,0x44f
    800022f6:	dd648493          	addi	s1,s1,-554 # 804510c8 <wait_lock>
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	a82080e7          	jalr	-1406(ra) # 80000d7e <acquire>
    np->parent = p;
    80002304:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002308:	8526                	mv	a0,s1
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	b28080e7          	jalr	-1240(ra) # 80000e32 <release>
    acquire(&np->lock);
    80002312:	8552                	mv	a0,s4
    80002314:	fffff097          	auipc	ra,0xfffff
    80002318:	a6a080e7          	jalr	-1430(ra) # 80000d7e <acquire>
    np->state = RUNNABLE;
    8000231c:	478d                	li	a5,3
    8000231e:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002322:	8552                	mv	a0,s4
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	b0e080e7          	jalr	-1266(ra) # 80000e32 <release>
}
    8000232c:	854a                	mv	a0,s2
    8000232e:	70e2                	ld	ra,56(sp)
    80002330:	7442                	ld	s0,48(sp)
    80002332:	74a2                	ld	s1,40(sp)
    80002334:	7902                	ld	s2,32(sp)
    80002336:	69e2                	ld	s3,24(sp)
    80002338:	6a42                	ld	s4,16(sp)
    8000233a:	6aa2                	ld	s5,8(sp)
    8000233c:	6121                	addi	sp,sp,64
    8000233e:	8082                	ret
        return -1;
    80002340:	597d                	li	s2,-1
    80002342:	b7ed                	j	8000232c <fork+0x128>

0000000080002344 <scheduler>:
{
    80002344:	1101                	addi	sp,sp,-32
    80002346:	ec06                	sd	ra,24(sp)
    80002348:	e822                	sd	s0,16(sp)
    8000234a:	e426                	sd	s1,8(sp)
    8000234c:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    8000234e:	00006497          	auipc	s1,0x6
    80002352:	63a48493          	addi	s1,s1,1594 # 80008988 <sched_pointer>
    80002356:	609c                	ld	a5,0(s1)
    80002358:	9782                	jalr	a5
    while (1)
    8000235a:	bff5                	j	80002356 <scheduler+0x12>

000000008000235c <sched>:
{
    8000235c:	7179                	addi	sp,sp,-48
    8000235e:	f406                	sd	ra,40(sp)
    80002360:	f022                	sd	s0,32(sp)
    80002362:	ec26                	sd	s1,24(sp)
    80002364:	e84a                	sd	s2,16(sp)
    80002366:	e44e                	sd	s3,8(sp)
    80002368:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	994080e7          	jalr	-1644(ra) # 80001cfe <myproc>
    80002372:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	990080e7          	jalr	-1648(ra) # 80000d04 <holding>
    8000237c:	c53d                	beqz	a0,800023ea <sched+0x8e>
    8000237e:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002380:	2781                	sext.w	a5,a5
    80002382:	079e                	slli	a5,a5,0x7
    80002384:	0044f717          	auipc	a4,0x44f
    80002388:	92c70713          	addi	a4,a4,-1748 # 80450cb0 <cpus>
    8000238c:	97ba                	add	a5,a5,a4
    8000238e:	5fb8                	lw	a4,120(a5)
    80002390:	4785                	li	a5,1
    80002392:	06f71463          	bne	a4,a5,800023fa <sched+0x9e>
    if (p->state == RUNNING)
    80002396:	4c98                	lw	a4,24(s1)
    80002398:	4791                	li	a5,4
    8000239a:	06f70863          	beq	a4,a5,8000240a <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000239e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023a2:	8b89                	andi	a5,a5,2
    if (intr_get())
    800023a4:	ebbd                	bnez	a5,8000241a <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023a6:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800023a8:	0044f917          	auipc	s2,0x44f
    800023ac:	90890913          	addi	s2,s2,-1784 # 80450cb0 <cpus>
    800023b0:	2781                	sext.w	a5,a5
    800023b2:	079e                	slli	a5,a5,0x7
    800023b4:	97ca                	add	a5,a5,s2
    800023b6:	07c7a983          	lw	s3,124(a5)
    800023ba:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    800023bc:	2581                	sext.w	a1,a1
    800023be:	059e                	slli	a1,a1,0x7
    800023c0:	05a1                	addi	a1,a1,8
    800023c2:	95ca                	add	a1,a1,s2
    800023c4:	06048513          	addi	a0,s1,96
    800023c8:	00000097          	auipc	ra,0x0
    800023cc:	6e4080e7          	jalr	1764(ra) # 80002aac <swtch>
    800023d0:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800023d2:	2781                	sext.w	a5,a5
    800023d4:	079e                	slli	a5,a5,0x7
    800023d6:	993e                	add	s2,s2,a5
    800023d8:	07392e23          	sw	s3,124(s2)
}
    800023dc:	70a2                	ld	ra,40(sp)
    800023de:	7402                	ld	s0,32(sp)
    800023e0:	64e2                	ld	s1,24(sp)
    800023e2:	6942                	ld	s2,16(sp)
    800023e4:	69a2                	ld	s3,8(sp)
    800023e6:	6145                	addi	sp,sp,48
    800023e8:	8082                	ret
        panic("sched p->lock");
    800023ea:	00006517          	auipc	a0,0x6
    800023ee:	e6e50513          	addi	a0,a0,-402 # 80008258 <digits+0x208>
    800023f2:	ffffe097          	auipc	ra,0xffffe
    800023f6:	14a080e7          	jalr	330(ra) # 8000053c <panic>
        panic("sched locks");
    800023fa:	00006517          	auipc	a0,0x6
    800023fe:	e6e50513          	addi	a0,a0,-402 # 80008268 <digits+0x218>
    80002402:	ffffe097          	auipc	ra,0xffffe
    80002406:	13a080e7          	jalr	314(ra) # 8000053c <panic>
        panic("sched running");
    8000240a:	00006517          	auipc	a0,0x6
    8000240e:	e6e50513          	addi	a0,a0,-402 # 80008278 <digits+0x228>
    80002412:	ffffe097          	auipc	ra,0xffffe
    80002416:	12a080e7          	jalr	298(ra) # 8000053c <panic>
        panic("sched interruptible");
    8000241a:	00006517          	auipc	a0,0x6
    8000241e:	e6e50513          	addi	a0,a0,-402 # 80008288 <digits+0x238>
    80002422:	ffffe097          	auipc	ra,0xffffe
    80002426:	11a080e7          	jalr	282(ra) # 8000053c <panic>

000000008000242a <yield>:
{
    8000242a:	1101                	addi	sp,sp,-32
    8000242c:	ec06                	sd	ra,24(sp)
    8000242e:	e822                	sd	s0,16(sp)
    80002430:	e426                	sd	s1,8(sp)
    80002432:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    80002434:	00000097          	auipc	ra,0x0
    80002438:	8ca080e7          	jalr	-1846(ra) # 80001cfe <myproc>
    8000243c:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000243e:	fffff097          	auipc	ra,0xfffff
    80002442:	940080e7          	jalr	-1728(ra) # 80000d7e <acquire>
    p->state = RUNNABLE;
    80002446:	478d                	li	a5,3
    80002448:	cc9c                	sw	a5,24(s1)
    sched();
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	f12080e7          	jalr	-238(ra) # 8000235c <sched>
    release(&p->lock);
    80002452:	8526                	mv	a0,s1
    80002454:	fffff097          	auipc	ra,0xfffff
    80002458:	9de080e7          	jalr	-1570(ra) # 80000e32 <release>
}
    8000245c:	60e2                	ld	ra,24(sp)
    8000245e:	6442                	ld	s0,16(sp)
    80002460:	64a2                	ld	s1,8(sp)
    80002462:	6105                	addi	sp,sp,32
    80002464:	8082                	ret

0000000080002466 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	1800                	addi	s0,sp,48
    80002474:	89aa                	mv	s3,a0
    80002476:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002478:	00000097          	auipc	ra,0x0
    8000247c:	886080e7          	jalr	-1914(ra) # 80001cfe <myproc>
    80002480:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002482:	fffff097          	auipc	ra,0xfffff
    80002486:	8fc080e7          	jalr	-1796(ra) # 80000d7e <acquire>
    release(lk);
    8000248a:	854a                	mv	a0,s2
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	9a6080e7          	jalr	-1626(ra) # 80000e32 <release>

    // Go to sleep.
    p->chan = chan;
    80002494:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002498:	4789                	li	a5,2
    8000249a:	cc9c                	sw	a5,24(s1)

    sched();
    8000249c:	00000097          	auipc	ra,0x0
    800024a0:	ec0080e7          	jalr	-320(ra) # 8000235c <sched>

    // Tidy up.
    p->chan = 0;
    800024a4:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800024a8:	8526                	mv	a0,s1
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	988080e7          	jalr	-1656(ra) # 80000e32 <release>
    acquire(lk);
    800024b2:	854a                	mv	a0,s2
    800024b4:	fffff097          	auipc	ra,0xfffff
    800024b8:	8ca080e7          	jalr	-1846(ra) # 80000d7e <acquire>
}
    800024bc:	70a2                	ld	ra,40(sp)
    800024be:	7402                	ld	s0,32(sp)
    800024c0:	64e2                	ld	s1,24(sp)
    800024c2:	6942                	ld	s2,16(sp)
    800024c4:	69a2                	ld	s3,8(sp)
    800024c6:	6145                	addi	sp,sp,48
    800024c8:	8082                	ret

00000000800024ca <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800024ca:	7139                	addi	sp,sp,-64
    800024cc:	fc06                	sd	ra,56(sp)
    800024ce:	f822                	sd	s0,48(sp)
    800024d0:	f426                	sd	s1,40(sp)
    800024d2:	f04a                	sd	s2,32(sp)
    800024d4:	ec4e                	sd	s3,24(sp)
    800024d6:	e852                	sd	s4,16(sp)
    800024d8:	e456                	sd	s5,8(sp)
    800024da:	0080                	addi	s0,sp,64
    800024dc:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024de:	0044f497          	auipc	s1,0x44f
    800024e2:	c0248493          	addi	s1,s1,-1022 # 804510e0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800024e6:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800024e8:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800024ea:	00454917          	auipc	s2,0x454
    800024ee:	5f690913          	addi	s2,s2,1526 # 80456ae0 <tickslock>
    800024f2:	a811                	j	80002506 <wakeup+0x3c>
            }
            release(&p->lock);
    800024f4:	8526                	mv	a0,s1
    800024f6:	fffff097          	auipc	ra,0xfffff
    800024fa:	93c080e7          	jalr	-1732(ra) # 80000e32 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024fe:	16848493          	addi	s1,s1,360
    80002502:	03248663          	beq	s1,s2,8000252e <wakeup+0x64>
        if (p != myproc())
    80002506:	fffff097          	auipc	ra,0xfffff
    8000250a:	7f8080e7          	jalr	2040(ra) # 80001cfe <myproc>
    8000250e:	fea488e3          	beq	s1,a0,800024fe <wakeup+0x34>
            acquire(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	86a080e7          	jalr	-1942(ra) # 80000d7e <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000251c:	4c9c                	lw	a5,24(s1)
    8000251e:	fd379be3          	bne	a5,s3,800024f4 <wakeup+0x2a>
    80002522:	709c                	ld	a5,32(s1)
    80002524:	fd4798e3          	bne	a5,s4,800024f4 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002528:	0154ac23          	sw	s5,24(s1)
    8000252c:	b7e1                	j	800024f4 <wakeup+0x2a>
        }
    }
}
    8000252e:	70e2                	ld	ra,56(sp)
    80002530:	7442                	ld	s0,48(sp)
    80002532:	74a2                	ld	s1,40(sp)
    80002534:	7902                	ld	s2,32(sp)
    80002536:	69e2                	ld	s3,24(sp)
    80002538:	6a42                	ld	s4,16(sp)
    8000253a:	6aa2                	ld	s5,8(sp)
    8000253c:	6121                	addi	sp,sp,64
    8000253e:	8082                	ret

0000000080002540 <reparent>:
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	e052                	sd	s4,0(sp)
    8000254e:	1800                	addi	s0,sp,48
    80002550:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002552:	0044f497          	auipc	s1,0x44f
    80002556:	b8e48493          	addi	s1,s1,-1138 # 804510e0 <proc>
            pp->parent = initproc;
    8000255a:	00006a17          	auipc	s4,0x6
    8000255e:	4dea0a13          	addi	s4,s4,1246 # 80008a38 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002562:	00454997          	auipc	s3,0x454
    80002566:	57e98993          	addi	s3,s3,1406 # 80456ae0 <tickslock>
    8000256a:	a029                	j	80002574 <reparent+0x34>
    8000256c:	16848493          	addi	s1,s1,360
    80002570:	01348d63          	beq	s1,s3,8000258a <reparent+0x4a>
        if (pp->parent == p)
    80002574:	7c9c                	ld	a5,56(s1)
    80002576:	ff279be3          	bne	a5,s2,8000256c <reparent+0x2c>
            pp->parent = initproc;
    8000257a:	000a3503          	ld	a0,0(s4)
    8000257e:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002580:	00000097          	auipc	ra,0x0
    80002584:	f4a080e7          	jalr	-182(ra) # 800024ca <wakeup>
    80002588:	b7d5                	j	8000256c <reparent+0x2c>
}
    8000258a:	70a2                	ld	ra,40(sp)
    8000258c:	7402                	ld	s0,32(sp)
    8000258e:	64e2                	ld	s1,24(sp)
    80002590:	6942                	ld	s2,16(sp)
    80002592:	69a2                	ld	s3,8(sp)
    80002594:	6a02                	ld	s4,0(sp)
    80002596:	6145                	addi	sp,sp,48
    80002598:	8082                	ret

000000008000259a <exit>:
{
    8000259a:	7179                	addi	sp,sp,-48
    8000259c:	f406                	sd	ra,40(sp)
    8000259e:	f022                	sd	s0,32(sp)
    800025a0:	ec26                	sd	s1,24(sp)
    800025a2:	e84a                	sd	s2,16(sp)
    800025a4:	e44e                	sd	s3,8(sp)
    800025a6:	e052                	sd	s4,0(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800025ac:	fffff097          	auipc	ra,0xfffff
    800025b0:	752080e7          	jalr	1874(ra) # 80001cfe <myproc>
    800025b4:	89aa                	mv	s3,a0
    if (p == initproc)
    800025b6:	00006797          	auipc	a5,0x6
    800025ba:	4827b783          	ld	a5,1154(a5) # 80008a38 <initproc>
    800025be:	0d050493          	addi	s1,a0,208
    800025c2:	15050913          	addi	s2,a0,336
    800025c6:	02a79363          	bne	a5,a0,800025ec <exit+0x52>
        panic("init exiting");
    800025ca:	00006517          	auipc	a0,0x6
    800025ce:	cd650513          	addi	a0,a0,-810 # 800082a0 <digits+0x250>
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	f6a080e7          	jalr	-150(ra) # 8000053c <panic>
            fileclose(f);
    800025da:	00002097          	auipc	ra,0x2
    800025de:	57e080e7          	jalr	1406(ra) # 80004b58 <fileclose>
            p->ofile[fd] = 0;
    800025e2:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800025e6:	04a1                	addi	s1,s1,8
    800025e8:	01248563          	beq	s1,s2,800025f2 <exit+0x58>
        if (p->ofile[fd])
    800025ec:	6088                	ld	a0,0(s1)
    800025ee:	f575                	bnez	a0,800025da <exit+0x40>
    800025f0:	bfdd                	j	800025e6 <exit+0x4c>
    begin_op();
    800025f2:	00002097          	auipc	ra,0x2
    800025f6:	0a2080e7          	jalr	162(ra) # 80004694 <begin_op>
    iput(p->cwd);
    800025fa:	1509b503          	ld	a0,336(s3)
    800025fe:	00002097          	auipc	ra,0x2
    80002602:	8aa080e7          	jalr	-1878(ra) # 80003ea8 <iput>
    end_op();
    80002606:	00002097          	auipc	ra,0x2
    8000260a:	108080e7          	jalr	264(ra) # 8000470e <end_op>
    p->cwd = 0;
    8000260e:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002612:	0044f497          	auipc	s1,0x44f
    80002616:	ab648493          	addi	s1,s1,-1354 # 804510c8 <wait_lock>
    8000261a:	8526                	mv	a0,s1
    8000261c:	ffffe097          	auipc	ra,0xffffe
    80002620:	762080e7          	jalr	1890(ra) # 80000d7e <acquire>
    reparent(p);
    80002624:	854e                	mv	a0,s3
    80002626:	00000097          	auipc	ra,0x0
    8000262a:	f1a080e7          	jalr	-230(ra) # 80002540 <reparent>
    wakeup(p->parent);
    8000262e:	0389b503          	ld	a0,56(s3)
    80002632:	00000097          	auipc	ra,0x0
    80002636:	e98080e7          	jalr	-360(ra) # 800024ca <wakeup>
    acquire(&p->lock);
    8000263a:	854e                	mv	a0,s3
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	742080e7          	jalr	1858(ra) # 80000d7e <acquire>
    p->xstate = status;
    80002644:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    80002648:	4795                	li	a5,5
    8000264a:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    8000264e:	8526                	mv	a0,s1
    80002650:	ffffe097          	auipc	ra,0xffffe
    80002654:	7e2080e7          	jalr	2018(ra) # 80000e32 <release>
    sched();
    80002658:	00000097          	auipc	ra,0x0
    8000265c:	d04080e7          	jalr	-764(ra) # 8000235c <sched>
    panic("zombie exit");
    80002660:	00006517          	auipc	a0,0x6
    80002664:	c5050513          	addi	a0,a0,-944 # 800082b0 <digits+0x260>
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	ed4080e7          	jalr	-300(ra) # 8000053c <panic>

0000000080002670 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002670:	7179                	addi	sp,sp,-48
    80002672:	f406                	sd	ra,40(sp)
    80002674:	f022                	sd	s0,32(sp)
    80002676:	ec26                	sd	s1,24(sp)
    80002678:	e84a                	sd	s2,16(sp)
    8000267a:	e44e                	sd	s3,8(sp)
    8000267c:	1800                	addi	s0,sp,48
    8000267e:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002680:	0044f497          	auipc	s1,0x44f
    80002684:	a6048493          	addi	s1,s1,-1440 # 804510e0 <proc>
    80002688:	00454997          	auipc	s3,0x454
    8000268c:	45898993          	addi	s3,s3,1112 # 80456ae0 <tickslock>
    {
        acquire(&p->lock);
    80002690:	8526                	mv	a0,s1
    80002692:	ffffe097          	auipc	ra,0xffffe
    80002696:	6ec080e7          	jalr	1772(ra) # 80000d7e <acquire>
        if (p->pid == pid)
    8000269a:	589c                	lw	a5,48(s1)
    8000269c:	01278d63          	beq	a5,s2,800026b6 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800026a0:	8526                	mv	a0,s1
    800026a2:	ffffe097          	auipc	ra,0xffffe
    800026a6:	790080e7          	jalr	1936(ra) # 80000e32 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800026aa:	16848493          	addi	s1,s1,360
    800026ae:	ff3491e3          	bne	s1,s3,80002690 <kill+0x20>
    }
    return -1;
    800026b2:	557d                	li	a0,-1
    800026b4:	a829                	j	800026ce <kill+0x5e>
            p->killed = 1;
    800026b6:	4785                	li	a5,1
    800026b8:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800026ba:	4c98                	lw	a4,24(s1)
    800026bc:	4789                	li	a5,2
    800026be:	00f70f63          	beq	a4,a5,800026dc <kill+0x6c>
            release(&p->lock);
    800026c2:	8526                	mv	a0,s1
    800026c4:	ffffe097          	auipc	ra,0xffffe
    800026c8:	76e080e7          	jalr	1902(ra) # 80000e32 <release>
            return 0;
    800026cc:	4501                	li	a0,0
}
    800026ce:	70a2                	ld	ra,40(sp)
    800026d0:	7402                	ld	s0,32(sp)
    800026d2:	64e2                	ld	s1,24(sp)
    800026d4:	6942                	ld	s2,16(sp)
    800026d6:	69a2                	ld	s3,8(sp)
    800026d8:	6145                	addi	sp,sp,48
    800026da:	8082                	ret
                p->state = RUNNABLE;
    800026dc:	478d                	li	a5,3
    800026de:	cc9c                	sw	a5,24(s1)
    800026e0:	b7cd                	j	800026c2 <kill+0x52>

00000000800026e2 <setkilled>:

void setkilled(struct proc *p)
{
    800026e2:	1101                	addi	sp,sp,-32
    800026e4:	ec06                	sd	ra,24(sp)
    800026e6:	e822                	sd	s0,16(sp)
    800026e8:	e426                	sd	s1,8(sp)
    800026ea:	1000                	addi	s0,sp,32
    800026ec:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800026ee:	ffffe097          	auipc	ra,0xffffe
    800026f2:	690080e7          	jalr	1680(ra) # 80000d7e <acquire>
    p->killed = 1;
    800026f6:	4785                	li	a5,1
    800026f8:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800026fa:	8526                	mv	a0,s1
    800026fc:	ffffe097          	auipc	ra,0xffffe
    80002700:	736080e7          	jalr	1846(ra) # 80000e32 <release>
}
    80002704:	60e2                	ld	ra,24(sp)
    80002706:	6442                	ld	s0,16(sp)
    80002708:	64a2                	ld	s1,8(sp)
    8000270a:	6105                	addi	sp,sp,32
    8000270c:	8082                	ret

000000008000270e <killed>:

int killed(struct proc *p)
{
    8000270e:	1101                	addi	sp,sp,-32
    80002710:	ec06                	sd	ra,24(sp)
    80002712:	e822                	sd	s0,16(sp)
    80002714:	e426                	sd	s1,8(sp)
    80002716:	e04a                	sd	s2,0(sp)
    80002718:	1000                	addi	s0,sp,32
    8000271a:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000271c:	ffffe097          	auipc	ra,0xffffe
    80002720:	662080e7          	jalr	1634(ra) # 80000d7e <acquire>
    k = p->killed;
    80002724:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002728:	8526                	mv	a0,s1
    8000272a:	ffffe097          	auipc	ra,0xffffe
    8000272e:	708080e7          	jalr	1800(ra) # 80000e32 <release>
    return k;
}
    80002732:	854a                	mv	a0,s2
    80002734:	60e2                	ld	ra,24(sp)
    80002736:	6442                	ld	s0,16(sp)
    80002738:	64a2                	ld	s1,8(sp)
    8000273a:	6902                	ld	s2,0(sp)
    8000273c:	6105                	addi	sp,sp,32
    8000273e:	8082                	ret

0000000080002740 <wait>:
{
    80002740:	715d                	addi	sp,sp,-80
    80002742:	e486                	sd	ra,72(sp)
    80002744:	e0a2                	sd	s0,64(sp)
    80002746:	fc26                	sd	s1,56(sp)
    80002748:	f84a                	sd	s2,48(sp)
    8000274a:	f44e                	sd	s3,40(sp)
    8000274c:	f052                	sd	s4,32(sp)
    8000274e:	ec56                	sd	s5,24(sp)
    80002750:	e85a                	sd	s6,16(sp)
    80002752:	e45e                	sd	s7,8(sp)
    80002754:	e062                	sd	s8,0(sp)
    80002756:	0880                	addi	s0,sp,80
    80002758:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    8000275a:	fffff097          	auipc	ra,0xfffff
    8000275e:	5a4080e7          	jalr	1444(ra) # 80001cfe <myproc>
    80002762:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002764:	0044f517          	auipc	a0,0x44f
    80002768:	96450513          	addi	a0,a0,-1692 # 804510c8 <wait_lock>
    8000276c:	ffffe097          	auipc	ra,0xffffe
    80002770:	612080e7          	jalr	1554(ra) # 80000d7e <acquire>
        havekids = 0;
    80002774:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002776:	4a15                	li	s4,5
                havekids = 1;
    80002778:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    8000277a:	00454997          	auipc	s3,0x454
    8000277e:	36698993          	addi	s3,s3,870 # 80456ae0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002782:	0044fc17          	auipc	s8,0x44f
    80002786:	946c0c13          	addi	s8,s8,-1722 # 804510c8 <wait_lock>
    8000278a:	a0d1                	j	8000284e <wait+0x10e>
                    pid = pp->pid;
    8000278c:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002790:	000b0e63          	beqz	s6,800027ac <wait+0x6c>
    80002794:	4691                	li	a3,4
    80002796:	02c48613          	addi	a2,s1,44
    8000279a:	85da                	mv	a1,s6
    8000279c:	05093503          	ld	a0,80(s2)
    800027a0:	fffff097          	auipc	ra,0xfffff
    800027a4:	12a080e7          	jalr	298(ra) # 800018ca <copyout>
    800027a8:	04054163          	bltz	a0,800027ea <wait+0xaa>
                    freeproc(pp);
    800027ac:	8526                	mv	a0,s1
    800027ae:	fffff097          	auipc	ra,0xfffff
    800027b2:	702080e7          	jalr	1794(ra) # 80001eb0 <freeproc>
                    release(&pp->lock);
    800027b6:	8526                	mv	a0,s1
    800027b8:	ffffe097          	auipc	ra,0xffffe
    800027bc:	67a080e7          	jalr	1658(ra) # 80000e32 <release>
                    release(&wait_lock);
    800027c0:	0044f517          	auipc	a0,0x44f
    800027c4:	90850513          	addi	a0,a0,-1784 # 804510c8 <wait_lock>
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	66a080e7          	jalr	1642(ra) # 80000e32 <release>
}
    800027d0:	854e                	mv	a0,s3
    800027d2:	60a6                	ld	ra,72(sp)
    800027d4:	6406                	ld	s0,64(sp)
    800027d6:	74e2                	ld	s1,56(sp)
    800027d8:	7942                	ld	s2,48(sp)
    800027da:	79a2                	ld	s3,40(sp)
    800027dc:	7a02                	ld	s4,32(sp)
    800027de:	6ae2                	ld	s5,24(sp)
    800027e0:	6b42                	ld	s6,16(sp)
    800027e2:	6ba2                	ld	s7,8(sp)
    800027e4:	6c02                	ld	s8,0(sp)
    800027e6:	6161                	addi	sp,sp,80
    800027e8:	8082                	ret
                        release(&pp->lock);
    800027ea:	8526                	mv	a0,s1
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	646080e7          	jalr	1606(ra) # 80000e32 <release>
                        release(&wait_lock);
    800027f4:	0044f517          	auipc	a0,0x44f
    800027f8:	8d450513          	addi	a0,a0,-1836 # 804510c8 <wait_lock>
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	636080e7          	jalr	1590(ra) # 80000e32 <release>
                        return -1;
    80002804:	59fd                	li	s3,-1
    80002806:	b7e9                	j	800027d0 <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002808:	16848493          	addi	s1,s1,360
    8000280c:	03348463          	beq	s1,s3,80002834 <wait+0xf4>
            if (pp->parent == p)
    80002810:	7c9c                	ld	a5,56(s1)
    80002812:	ff279be3          	bne	a5,s2,80002808 <wait+0xc8>
                acquire(&pp->lock);
    80002816:	8526                	mv	a0,s1
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	566080e7          	jalr	1382(ra) # 80000d7e <acquire>
                if (pp->state == ZOMBIE)
    80002820:	4c9c                	lw	a5,24(s1)
    80002822:	f74785e3          	beq	a5,s4,8000278c <wait+0x4c>
                release(&pp->lock);
    80002826:	8526                	mv	a0,s1
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	60a080e7          	jalr	1546(ra) # 80000e32 <release>
                havekids = 1;
    80002830:	8756                	mv	a4,s5
    80002832:	bfd9                	j	80002808 <wait+0xc8>
        if (!havekids || killed(p))
    80002834:	c31d                	beqz	a4,8000285a <wait+0x11a>
    80002836:	854a                	mv	a0,s2
    80002838:	00000097          	auipc	ra,0x0
    8000283c:	ed6080e7          	jalr	-298(ra) # 8000270e <killed>
    80002840:	ed09                	bnez	a0,8000285a <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002842:	85e2                	mv	a1,s8
    80002844:	854a                	mv	a0,s2
    80002846:	00000097          	auipc	ra,0x0
    8000284a:	c20080e7          	jalr	-992(ra) # 80002466 <sleep>
        havekids = 0;
    8000284e:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002850:	0044f497          	auipc	s1,0x44f
    80002854:	89048493          	addi	s1,s1,-1904 # 804510e0 <proc>
    80002858:	bf65                	j	80002810 <wait+0xd0>
            release(&wait_lock);
    8000285a:	0044f517          	auipc	a0,0x44f
    8000285e:	86e50513          	addi	a0,a0,-1938 # 804510c8 <wait_lock>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	5d0080e7          	jalr	1488(ra) # 80000e32 <release>
            return -1;
    8000286a:	59fd                	li	s3,-1
    8000286c:	b795                	j	800027d0 <wait+0x90>

000000008000286e <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000286e:	7179                	addi	sp,sp,-48
    80002870:	f406                	sd	ra,40(sp)
    80002872:	f022                	sd	s0,32(sp)
    80002874:	ec26                	sd	s1,24(sp)
    80002876:	e84a                	sd	s2,16(sp)
    80002878:	e44e                	sd	s3,8(sp)
    8000287a:	e052                	sd	s4,0(sp)
    8000287c:	1800                	addi	s0,sp,48
    8000287e:	84aa                	mv	s1,a0
    80002880:	892e                	mv	s2,a1
    80002882:	89b2                	mv	s3,a2
    80002884:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002886:	fffff097          	auipc	ra,0xfffff
    8000288a:	478080e7          	jalr	1144(ra) # 80001cfe <myproc>
    if (user_dst)
    8000288e:	c08d                	beqz	s1,800028b0 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002890:	86d2                	mv	a3,s4
    80002892:	864e                	mv	a2,s3
    80002894:	85ca                	mv	a1,s2
    80002896:	6928                	ld	a0,80(a0)
    80002898:	fffff097          	auipc	ra,0xfffff
    8000289c:	032080e7          	jalr	50(ra) # 800018ca <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800028a0:	70a2                	ld	ra,40(sp)
    800028a2:	7402                	ld	s0,32(sp)
    800028a4:	64e2                	ld	s1,24(sp)
    800028a6:	6942                	ld	s2,16(sp)
    800028a8:	69a2                	ld	s3,8(sp)
    800028aa:	6a02                	ld	s4,0(sp)
    800028ac:	6145                	addi	sp,sp,48
    800028ae:	8082                	ret
        memmove((char *)dst, src, len);
    800028b0:	000a061b          	sext.w	a2,s4
    800028b4:	85ce                	mv	a1,s3
    800028b6:	854a                	mv	a0,s2
    800028b8:	ffffe097          	auipc	ra,0xffffe
    800028bc:	61e080e7          	jalr	1566(ra) # 80000ed6 <memmove>
        return 0;
    800028c0:	8526                	mv	a0,s1
    800028c2:	bff9                	j	800028a0 <either_copyout+0x32>

00000000800028c4 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028c4:	7179                	addi	sp,sp,-48
    800028c6:	f406                	sd	ra,40(sp)
    800028c8:	f022                	sd	s0,32(sp)
    800028ca:	ec26                	sd	s1,24(sp)
    800028cc:	e84a                	sd	s2,16(sp)
    800028ce:	e44e                	sd	s3,8(sp)
    800028d0:	e052                	sd	s4,0(sp)
    800028d2:	1800                	addi	s0,sp,48
    800028d4:	892a                	mv	s2,a0
    800028d6:	84ae                	mv	s1,a1
    800028d8:	89b2                	mv	s3,a2
    800028da:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028dc:	fffff097          	auipc	ra,0xfffff
    800028e0:	422080e7          	jalr	1058(ra) # 80001cfe <myproc>
    if (user_src)
    800028e4:	c08d                	beqz	s1,80002906 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800028e6:	86d2                	mv	a3,s4
    800028e8:	864e                	mv	a2,s3
    800028ea:	85ca                	mv	a1,s2
    800028ec:	6928                	ld	a0,80(a0)
    800028ee:	fffff097          	auipc	ra,0xfffff
    800028f2:	068080e7          	jalr	104(ra) # 80001956 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800028f6:	70a2                	ld	ra,40(sp)
    800028f8:	7402                	ld	s0,32(sp)
    800028fa:	64e2                	ld	s1,24(sp)
    800028fc:	6942                	ld	s2,16(sp)
    800028fe:	69a2                	ld	s3,8(sp)
    80002900:	6a02                	ld	s4,0(sp)
    80002902:	6145                	addi	sp,sp,48
    80002904:	8082                	ret
        memmove(dst, (char *)src, len);
    80002906:	000a061b          	sext.w	a2,s4
    8000290a:	85ce                	mv	a1,s3
    8000290c:	854a                	mv	a0,s2
    8000290e:	ffffe097          	auipc	ra,0xffffe
    80002912:	5c8080e7          	jalr	1480(ra) # 80000ed6 <memmove>
        return 0;
    80002916:	8526                	mv	a0,s1
    80002918:	bff9                	j	800028f6 <either_copyin+0x32>

000000008000291a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000291a:	715d                	addi	sp,sp,-80
    8000291c:	e486                	sd	ra,72(sp)
    8000291e:	e0a2                	sd	s0,64(sp)
    80002920:	fc26                	sd	s1,56(sp)
    80002922:	f84a                	sd	s2,48(sp)
    80002924:	f44e                	sd	s3,40(sp)
    80002926:	f052                	sd	s4,32(sp)
    80002928:	ec56                	sd	s5,24(sp)
    8000292a:	e85a                	sd	s6,16(sp)
    8000292c:	e45e                	sd	s7,8(sp)
    8000292e:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002930:	00005517          	auipc	a0,0x5
    80002934:	75850513          	addi	a0,a0,1880 # 80008088 <digits+0x38>
    80002938:	ffffe097          	auipc	ra,0xffffe
    8000293c:	c60080e7          	jalr	-928(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002940:	0044f497          	auipc	s1,0x44f
    80002944:	8f848493          	addi	s1,s1,-1800 # 80451238 <proc+0x158>
    80002948:	00454917          	auipc	s2,0x454
    8000294c:	2f090913          	addi	s2,s2,752 # 80456c38 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002950:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002952:	00006997          	auipc	s3,0x6
    80002956:	96e98993          	addi	s3,s3,-1682 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    8000295a:	00006a97          	auipc	s5,0x6
    8000295e:	96ea8a93          	addi	s5,s5,-1682 # 800082c8 <digits+0x278>
        printf("\n");
    80002962:	00005a17          	auipc	s4,0x5
    80002966:	726a0a13          	addi	s4,s4,1830 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000296a:	00006b97          	auipc	s7,0x6
    8000296e:	a6eb8b93          	addi	s7,s7,-1426 # 800083d8 <states.0>
    80002972:	a00d                	j	80002994 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002974:	ed86a583          	lw	a1,-296(a3)
    80002978:	8556                	mv	a0,s5
    8000297a:	ffffe097          	auipc	ra,0xffffe
    8000297e:	c1e080e7          	jalr	-994(ra) # 80000598 <printf>
        printf("\n");
    80002982:	8552                	mv	a0,s4
    80002984:	ffffe097          	auipc	ra,0xffffe
    80002988:	c14080e7          	jalr	-1004(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    8000298c:	16848493          	addi	s1,s1,360
    80002990:	03248263          	beq	s1,s2,800029b4 <procdump+0x9a>
        if (p->state == UNUSED)
    80002994:	86a6                	mv	a3,s1
    80002996:	ec04a783          	lw	a5,-320(s1)
    8000299a:	dbed                	beqz	a5,8000298c <procdump+0x72>
            state = "???";
    8000299c:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000299e:	fcfb6be3          	bltu	s6,a5,80002974 <procdump+0x5a>
    800029a2:	02079713          	slli	a4,a5,0x20
    800029a6:	01d75793          	srli	a5,a4,0x1d
    800029aa:	97de                	add	a5,a5,s7
    800029ac:	6390                	ld	a2,0(a5)
    800029ae:	f279                	bnez	a2,80002974 <procdump+0x5a>
            state = "???";
    800029b0:	864e                	mv	a2,s3
    800029b2:	b7c9                	j	80002974 <procdump+0x5a>
    }
}
    800029b4:	60a6                	ld	ra,72(sp)
    800029b6:	6406                	ld	s0,64(sp)
    800029b8:	74e2                	ld	s1,56(sp)
    800029ba:	7942                	ld	s2,48(sp)
    800029bc:	79a2                	ld	s3,40(sp)
    800029be:	7a02                	ld	s4,32(sp)
    800029c0:	6ae2                	ld	s5,24(sp)
    800029c2:	6b42                	ld	s6,16(sp)
    800029c4:	6ba2                	ld	s7,8(sp)
    800029c6:	6161                	addi	sp,sp,80
    800029c8:	8082                	ret

00000000800029ca <schedls>:

void schedls()
{
    800029ca:	1141                	addi	sp,sp,-16
    800029cc:	e406                	sd	ra,8(sp)
    800029ce:	e022                	sd	s0,0(sp)
    800029d0:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800029d2:	00006517          	auipc	a0,0x6
    800029d6:	90650513          	addi	a0,a0,-1786 # 800082d8 <digits+0x288>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	bbe080e7          	jalr	-1090(ra) # 80000598 <printf>
    printf("====================================\n");
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	91e50513          	addi	a0,a0,-1762 # 80008300 <digits+0x2b0>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	bae080e7          	jalr	-1106(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800029f2:	00006717          	auipc	a4,0x6
    800029f6:	ff673703          	ld	a4,-10(a4) # 800089e8 <available_schedulers+0x10>
    800029fa:	00006797          	auipc	a5,0x6
    800029fe:	f8e7b783          	ld	a5,-114(a5) # 80008988 <sched_pointer>
    80002a02:	04f70663          	beq	a4,a5,80002a4e <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002a06:	00006517          	auipc	a0,0x6
    80002a0a:	92a50513          	addi	a0,a0,-1750 # 80008330 <digits+0x2e0>
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	b8a080e7          	jalr	-1142(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a16:	00006617          	auipc	a2,0x6
    80002a1a:	fda62603          	lw	a2,-38(a2) # 800089f0 <available_schedulers+0x18>
    80002a1e:	00006597          	auipc	a1,0x6
    80002a22:	fba58593          	addi	a1,a1,-70 # 800089d8 <available_schedulers>
    80002a26:	00006517          	auipc	a0,0x6
    80002a2a:	91250513          	addi	a0,a0,-1774 # 80008338 <digits+0x2e8>
    80002a2e:	ffffe097          	auipc	ra,0xffffe
    80002a32:	b6a080e7          	jalr	-1174(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002a36:	00006517          	auipc	a0,0x6
    80002a3a:	90a50513          	addi	a0,a0,-1782 # 80008340 <digits+0x2f0>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	b5a080e7          	jalr	-1190(ra) # 80000598 <printf>
}
    80002a46:	60a2                	ld	ra,8(sp)
    80002a48:	6402                	ld	s0,0(sp)
    80002a4a:	0141                	addi	sp,sp,16
    80002a4c:	8082                	ret
            printf("[*]\t");
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	8da50513          	addi	a0,a0,-1830 # 80008328 <digits+0x2d8>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	b42080e7          	jalr	-1214(ra) # 80000598 <printf>
    80002a5e:	bf65                	j	80002a16 <schedls+0x4c>

0000000080002a60 <schedset>:

void schedset(int id)
{
    80002a60:	1141                	addi	sp,sp,-16
    80002a62:	e406                	sd	ra,8(sp)
    80002a64:	e022                	sd	s0,0(sp)
    80002a66:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002a68:	e90d                	bnez	a0,80002a9a <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002a6a:	00006797          	auipc	a5,0x6
    80002a6e:	f7e7b783          	ld	a5,-130(a5) # 800089e8 <available_schedulers+0x10>
    80002a72:	00006717          	auipc	a4,0x6
    80002a76:	f0f73b23          	sd	a5,-234(a4) # 80008988 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002a7a:	00006597          	auipc	a1,0x6
    80002a7e:	f5e58593          	addi	a1,a1,-162 # 800089d8 <available_schedulers>
    80002a82:	00006517          	auipc	a0,0x6
    80002a86:	8fe50513          	addi	a0,a0,-1794 # 80008380 <digits+0x330>
    80002a8a:	ffffe097          	auipc	ra,0xffffe
    80002a8e:	b0e080e7          	jalr	-1266(ra) # 80000598 <printf>
    80002a92:	60a2                	ld	ra,8(sp)
    80002a94:	6402                	ld	s0,0(sp)
    80002a96:	0141                	addi	sp,sp,16
    80002a98:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a9a:	00006517          	auipc	a0,0x6
    80002a9e:	8be50513          	addi	a0,a0,-1858 # 80008358 <digits+0x308>
    80002aa2:	ffffe097          	auipc	ra,0xffffe
    80002aa6:	af6080e7          	jalr	-1290(ra) # 80000598 <printf>
        return;
    80002aaa:	b7e5                	j	80002a92 <schedset+0x32>

0000000080002aac <swtch>:
    80002aac:	00153023          	sd	ra,0(a0)
    80002ab0:	00253423          	sd	sp,8(a0)
    80002ab4:	e900                	sd	s0,16(a0)
    80002ab6:	ed04                	sd	s1,24(a0)
    80002ab8:	03253023          	sd	s2,32(a0)
    80002abc:	03353423          	sd	s3,40(a0)
    80002ac0:	03453823          	sd	s4,48(a0)
    80002ac4:	03553c23          	sd	s5,56(a0)
    80002ac8:	05653023          	sd	s6,64(a0)
    80002acc:	05753423          	sd	s7,72(a0)
    80002ad0:	05853823          	sd	s8,80(a0)
    80002ad4:	05953c23          	sd	s9,88(a0)
    80002ad8:	07a53023          	sd	s10,96(a0)
    80002adc:	07b53423          	sd	s11,104(a0)
    80002ae0:	0005b083          	ld	ra,0(a1)
    80002ae4:	0085b103          	ld	sp,8(a1)
    80002ae8:	6980                	ld	s0,16(a1)
    80002aea:	6d84                	ld	s1,24(a1)
    80002aec:	0205b903          	ld	s2,32(a1)
    80002af0:	0285b983          	ld	s3,40(a1)
    80002af4:	0305ba03          	ld	s4,48(a1)
    80002af8:	0385ba83          	ld	s5,56(a1)
    80002afc:	0405bb03          	ld	s6,64(a1)
    80002b00:	0485bb83          	ld	s7,72(a1)
    80002b04:	0505bc03          	ld	s8,80(a1)
    80002b08:	0585bc83          	ld	s9,88(a1)
    80002b0c:	0605bd03          	ld	s10,96(a1)
    80002b10:	0685bd83          	ld	s11,104(a1)
    80002b14:	8082                	ret

0000000080002b16 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b16:	1141                	addi	sp,sp,-16
    80002b18:	e406                	sd	ra,8(sp)
    80002b1a:	e022                	sd	s0,0(sp)
    80002b1c:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b1e:	00006597          	auipc	a1,0x6
    80002b22:	8ea58593          	addi	a1,a1,-1814 # 80008408 <states.0+0x30>
    80002b26:	00454517          	auipc	a0,0x454
    80002b2a:	fba50513          	addi	a0,a0,-70 # 80456ae0 <tickslock>
    80002b2e:	ffffe097          	auipc	ra,0xffffe
    80002b32:	1c0080e7          	jalr	448(ra) # 80000cee <initlock>
}
    80002b36:	60a2                	ld	ra,8(sp)
    80002b38:	6402                	ld	s0,0(sp)
    80002b3a:	0141                	addi	sp,sp,16
    80002b3c:	8082                	ret

0000000080002b3e <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b3e:	1141                	addi	sp,sp,-16
    80002b40:	e422                	sd	s0,8(sp)
    80002b42:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b44:	00003797          	auipc	a5,0x3
    80002b48:	63c78793          	addi	a5,a5,1596 # 80006180 <kernelvec>
    80002b4c:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b50:	6422                	ld	s0,8(sp)
    80002b52:	0141                	addi	sp,sp,16
    80002b54:	8082                	ret

0000000080002b56 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b56:	1141                	addi	sp,sp,-16
    80002b58:	e406                	sd	ra,8(sp)
    80002b5a:	e022                	sd	s0,0(sp)
    80002b5c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b5e:	fffff097          	auipc	ra,0xfffff
    80002b62:	1a0080e7          	jalr	416(ra) # 80001cfe <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b66:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b6a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b6c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b70:	00004697          	auipc	a3,0x4
    80002b74:	49068693          	addi	a3,a3,1168 # 80007000 <_trampoline>
    80002b78:	00004717          	auipc	a4,0x4
    80002b7c:	48870713          	addi	a4,a4,1160 # 80007000 <_trampoline>
    80002b80:	8f15                	sub	a4,a4,a3
    80002b82:	040007b7          	lui	a5,0x4000
    80002b86:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b88:	07b2                	slli	a5,a5,0xc
    80002b8a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b8c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b90:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b92:	18002673          	csrr	a2,satp
    80002b96:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b98:	6d30                	ld	a2,88(a0)
    80002b9a:	6138                	ld	a4,64(a0)
    80002b9c:	6585                	lui	a1,0x1
    80002b9e:	972e                	add	a4,a4,a1
    80002ba0:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002ba2:	6d38                	ld	a4,88(a0)
    80002ba4:	00000617          	auipc	a2,0x0
    80002ba8:	25e60613          	addi	a2,a2,606 # 80002e02 <usertrap>
    80002bac:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002bae:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bb0:	8612                	mv	a2,tp
    80002bb2:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb4:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bb8:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002bbc:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc0:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bc4:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bc6:	6f18                	ld	a4,24(a4)
    80002bc8:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bcc:	6928                	ld	a0,80(a0)
    80002bce:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002bd0:	00004717          	auipc	a4,0x4
    80002bd4:	4cc70713          	addi	a4,a4,1228 # 8000709c <userret>
    80002bd8:	8f15                	sub	a4,a4,a3
    80002bda:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002bdc:	577d                	li	a4,-1
    80002bde:	177e                	slli	a4,a4,0x3f
    80002be0:	8d59                	or	a0,a0,a4
    80002be2:	9782                	jalr	a5
}
    80002be4:	60a2                	ld	ra,8(sp)
    80002be6:	6402                	ld	s0,0(sp)
    80002be8:	0141                	addi	sp,sp,16
    80002bea:	8082                	ret

0000000080002bec <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bec:	1101                	addi	sp,sp,-32
    80002bee:	ec06                	sd	ra,24(sp)
    80002bf0:	e822                	sd	s0,16(sp)
    80002bf2:	e426                	sd	s1,8(sp)
    80002bf4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bf6:	00454497          	auipc	s1,0x454
    80002bfa:	eea48493          	addi	s1,s1,-278 # 80456ae0 <tickslock>
    80002bfe:	8526                	mv	a0,s1
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	17e080e7          	jalr	382(ra) # 80000d7e <acquire>
  ticks++;
    80002c08:	00006517          	auipc	a0,0x6
    80002c0c:	e3850513          	addi	a0,a0,-456 # 80008a40 <ticks>
    80002c10:	411c                	lw	a5,0(a0)
    80002c12:	2785                	addiw	a5,a5,1
    80002c14:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	8b4080e7          	jalr	-1868(ra) # 800024ca <wakeup>
  release(&tickslock);
    80002c1e:	8526                	mv	a0,s1
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	212080e7          	jalr	530(ra) # 80000e32 <release>
}
    80002c28:	60e2                	ld	ra,24(sp)
    80002c2a:	6442                	ld	s0,16(sp)
    80002c2c:	64a2                	ld	s1,8(sp)
    80002c2e:	6105                	addi	sp,sp,32
    80002c30:	8082                	ret

0000000080002c32 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c32:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002c36:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002c38:	0807df63          	bgez	a5,80002cd6 <devintr+0xa4>
{
    80002c3c:	1101                	addi	sp,sp,-32
    80002c3e:	ec06                	sd	ra,24(sp)
    80002c40:	e822                	sd	s0,16(sp)
    80002c42:	e426                	sd	s1,8(sp)
    80002c44:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002c46:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002c4a:	46a5                	li	a3,9
    80002c4c:	00d70d63          	beq	a4,a3,80002c66 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002c50:	577d                	li	a4,-1
    80002c52:	177e                	slli	a4,a4,0x3f
    80002c54:	0705                	addi	a4,a4,1
    return 0;
    80002c56:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c58:	04e78e63          	beq	a5,a4,80002cb4 <devintr+0x82>
  }
}
    80002c5c:	60e2                	ld	ra,24(sp)
    80002c5e:	6442                	ld	s0,16(sp)
    80002c60:	64a2                	ld	s1,8(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret
    int irq = plic_claim();
    80002c66:	00003097          	auipc	ra,0x3
    80002c6a:	622080e7          	jalr	1570(ra) # 80006288 <plic_claim>
    80002c6e:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c70:	47a9                	li	a5,10
    80002c72:	02f50763          	beq	a0,a5,80002ca0 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002c76:	4785                	li	a5,1
    80002c78:	02f50963          	beq	a0,a5,80002caa <devintr+0x78>
    return 1;
    80002c7c:	4505                	li	a0,1
    } else if(irq){
    80002c7e:	dcf9                	beqz	s1,80002c5c <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c80:	85a6                	mv	a1,s1
    80002c82:	00005517          	auipc	a0,0x5
    80002c86:	78e50513          	addi	a0,a0,1934 # 80008410 <states.0+0x38>
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	90e080e7          	jalr	-1778(ra) # 80000598 <printf>
      plic_complete(irq);
    80002c92:	8526                	mv	a0,s1
    80002c94:	00003097          	auipc	ra,0x3
    80002c98:	618080e7          	jalr	1560(ra) # 800062ac <plic_complete>
    return 1;
    80002c9c:	4505                	li	a0,1
    80002c9e:	bf7d                	j	80002c5c <devintr+0x2a>
      uartintr();
    80002ca0:	ffffe097          	auipc	ra,0xffffe
    80002ca4:	d06080e7          	jalr	-762(ra) # 800009a6 <uartintr>
    if(irq)
    80002ca8:	b7ed                	j	80002c92 <devintr+0x60>
      virtio_disk_intr();
    80002caa:	00004097          	auipc	ra,0x4
    80002cae:	ac8080e7          	jalr	-1336(ra) # 80006772 <virtio_disk_intr>
    if(irq)
    80002cb2:	b7c5                	j	80002c92 <devintr+0x60>
    if(cpuid() == 0){
    80002cb4:	fffff097          	auipc	ra,0xfffff
    80002cb8:	01e080e7          	jalr	30(ra) # 80001cd2 <cpuid>
    80002cbc:	c901                	beqz	a0,80002ccc <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cbe:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cc2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cc4:	14479073          	csrw	sip,a5
    return 2;
    80002cc8:	4509                	li	a0,2
    80002cca:	bf49                	j	80002c5c <devintr+0x2a>
      clockintr();
    80002ccc:	00000097          	auipc	ra,0x0
    80002cd0:	f20080e7          	jalr	-224(ra) # 80002bec <clockintr>
    80002cd4:	b7ed                	j	80002cbe <devintr+0x8c>
}
    80002cd6:	8082                	ret

0000000080002cd8 <kerneltrap>:
{
    80002cd8:	7179                	addi	sp,sp,-48
    80002cda:	f406                	sd	ra,40(sp)
    80002cdc:	f022                	sd	s0,32(sp)
    80002cde:	ec26                	sd	s1,24(sp)
    80002ce0:	e84a                	sd	s2,16(sp)
    80002ce2:	e44e                	sd	s3,8(sp)
    80002ce4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cea:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cee:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cf2:	1004f793          	andi	a5,s1,256
    80002cf6:	cb85                	beqz	a5,80002d26 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cf8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cfc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cfe:	ef85                	bnez	a5,80002d36 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d00:	00000097          	auipc	ra,0x0
    80002d04:	f32080e7          	jalr	-206(ra) # 80002c32 <devintr>
    80002d08:	cd1d                	beqz	a0,80002d46 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d0a:	4789                	li	a5,2
    80002d0c:	06f50a63          	beq	a0,a5,80002d80 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d10:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d14:	10049073          	csrw	sstatus,s1
}
    80002d18:	70a2                	ld	ra,40(sp)
    80002d1a:	7402                	ld	s0,32(sp)
    80002d1c:	64e2                	ld	s1,24(sp)
    80002d1e:	6942                	ld	s2,16(sp)
    80002d20:	69a2                	ld	s3,8(sp)
    80002d22:	6145                	addi	sp,sp,48
    80002d24:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d26:	00005517          	auipc	a0,0x5
    80002d2a:	70a50513          	addi	a0,a0,1802 # 80008430 <states.0+0x58>
    80002d2e:	ffffe097          	auipc	ra,0xffffe
    80002d32:	80e080e7          	jalr	-2034(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002d36:	00005517          	auipc	a0,0x5
    80002d3a:	72250513          	addi	a0,a0,1826 # 80008458 <states.0+0x80>
    80002d3e:	ffffd097          	auipc	ra,0xffffd
    80002d42:	7fe080e7          	jalr	2046(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002d46:	85ce                	mv	a1,s3
    80002d48:	00005517          	auipc	a0,0x5
    80002d4c:	73050513          	addi	a0,a0,1840 # 80008478 <states.0+0xa0>
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	848080e7          	jalr	-1976(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d58:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d5c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d60:	00005517          	auipc	a0,0x5
    80002d64:	72850513          	addi	a0,a0,1832 # 80008488 <states.0+0xb0>
    80002d68:	ffffe097          	auipc	ra,0xffffe
    80002d6c:	830080e7          	jalr	-2000(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002d70:	00005517          	auipc	a0,0x5
    80002d74:	73050513          	addi	a0,a0,1840 # 800084a0 <states.0+0xc8>
    80002d78:	ffffd097          	auipc	ra,0xffffd
    80002d7c:	7c4080e7          	jalr	1988(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d80:	fffff097          	auipc	ra,0xfffff
    80002d84:	f7e080e7          	jalr	-130(ra) # 80001cfe <myproc>
    80002d88:	d541                	beqz	a0,80002d10 <kerneltrap+0x38>
    80002d8a:	fffff097          	auipc	ra,0xfffff
    80002d8e:	f74080e7          	jalr	-140(ra) # 80001cfe <myproc>
    80002d92:	4d18                	lw	a4,24(a0)
    80002d94:	4791                	li	a5,4
    80002d96:	f6f71de3          	bne	a4,a5,80002d10 <kerneltrap+0x38>
    yield();
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	690080e7          	jalr	1680(ra) # 8000242a <yield>
    80002da2:	b7bd                	j	80002d10 <kerneltrap+0x38>

0000000080002da4 <handle_page_fault>:

void
 handle_page_fault(pagetable_t pagetable, uint64 va)
 {
    80002da4:	7179                	addi	sp,sp,-48
    80002da6:	f406                	sd	ra,40(sp)
    80002da8:	f022                	sd	s0,32(sp)
    80002daa:	ec26                	sd	s1,24(sp)
    80002dac:	e84a                	sd	s2,16(sp)
    80002dae:	e44e                	sd	s3,8(sp)
    80002db0:	1800                	addi	s0,sp,48
   pte_t* pte = walk(pagetable, va, 0);
    80002db2:	4601                	li	a2,0
    80002db4:	ffffe097          	auipc	ra,0xffffe
    80002db8:	3a8080e7          	jalr	936(ra) # 8000115c <walk>
    80002dbc:	89aa                	mv	s3,a0
   uint64 old = PTE2PA(*pte);
    80002dbe:	00053903          	ld	s2,0(a0)
    80002dc2:	00a95913          	srli	s2,s2,0xa
    80002dc6:	0932                	slli	s2,s2,0xc
   uint64 new = (uint64) kalloc();
    80002dc8:	ffffe097          	auipc	ra,0xffffe
    80002dcc:	e64080e7          	jalr	-412(ra) # 80000c2c <kalloc>
    80002dd0:	84aa                	mv	s1,a0
   memmove((void*) new, (void*) old, PGSIZE);
    80002dd2:	6605                	lui	a2,0x1
    80002dd4:	85ca                	mv	a1,s2
    80002dd6:	ffffe097          	auipc	ra,0xffffe
    80002dda:	100080e7          	jalr	256(ra) # 80000ed6 <memmove>
   kfree((void*) old);
    80002dde:	854a                	mv	a0,s2
    80002de0:	ffffe097          	auipc	ra,0xffffe
    80002de4:	cb4080e7          	jalr	-844(ra) # 80000a94 <kfree>

  // Flags
  uint64 flags = PTE_V | PTE_U | PTE_R | PTE_W | PTE_X;
  *pte = PA2PTE(new) | flags;
    80002de8:	80b1                	srli	s1,s1,0xc
    80002dea:	04aa                	slli	s1,s1,0xa
    80002dec:	01f4e493          	ori	s1,s1,31
    80002df0:	0099b023          	sd	s1,0(s3)
 }
    80002df4:	70a2                	ld	ra,40(sp)
    80002df6:	7402                	ld	s0,32(sp)
    80002df8:	64e2                	ld	s1,24(sp)
    80002dfa:	6942                	ld	s2,16(sp)
    80002dfc:	69a2                	ld	s3,8(sp)
    80002dfe:	6145                	addi	sp,sp,48
    80002e00:	8082                	ret

0000000080002e02 <usertrap>:
{
    80002e02:	1101                	addi	sp,sp,-32
    80002e04:	ec06                	sd	ra,24(sp)
    80002e06:	e822                	sd	s0,16(sp)
    80002e08:	e426                	sd	s1,8(sp)
    80002e0a:	e04a                	sd	s2,0(sp)
    80002e0c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e0e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002e12:	1007f793          	andi	a5,a5,256
    80002e16:	e7b9                	bnez	a5,80002e64 <usertrap+0x62>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e18:	00003797          	auipc	a5,0x3
    80002e1c:	36878793          	addi	a5,a5,872 # 80006180 <kernelvec>
    80002e20:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002e24:	fffff097          	auipc	ra,0xfffff
    80002e28:	eda080e7          	jalr	-294(ra) # 80001cfe <myproc>
    80002e2c:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002e2e:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e30:	14102773          	csrr	a4,sepc
    80002e34:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e36:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002e3a:	47a1                	li	a5,8
    80002e3c:	02f70c63          	beq	a4,a5,80002e74 <usertrap+0x72>
    80002e40:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15) {
    80002e44:	47bd                	li	a5,15
    80002e46:	06f70163          	beq	a4,a5,80002ea8 <usertrap+0xa6>
  } else if((which_dev = devintr()) != 0){
    80002e4a:	00000097          	auipc	ra,0x0
    80002e4e:	de8080e7          	jalr	-536(ra) # 80002c32 <devintr>
    80002e52:	892a                	mv	s2,a0
    80002e54:	c149                	beqz	a0,80002ed6 <usertrap+0xd4>
  if(killed(p))
    80002e56:	8526                	mv	a0,s1
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	8b6080e7          	jalr	-1866(ra) # 8000270e <killed>
    80002e60:	cd55                	beqz	a0,80002f1c <usertrap+0x11a>
    80002e62:	a845                	j	80002f12 <usertrap+0x110>
    panic("usertrap: not from user mode");
    80002e64:	00005517          	auipc	a0,0x5
    80002e68:	64c50513          	addi	a0,a0,1612 # 800084b0 <states.0+0xd8>
    80002e6c:	ffffd097          	auipc	ra,0xffffd
    80002e70:	6d0080e7          	jalr	1744(ra) # 8000053c <panic>
    if(killed(p))
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	89a080e7          	jalr	-1894(ra) # 8000270e <killed>
    80002e7c:	e105                	bnez	a0,80002e9c <usertrap+0x9a>
    p->trapframe->epc += 4;
    80002e7e:	6cb8                	ld	a4,88(s1)
    80002e80:	6f1c                	ld	a5,24(a4)
    80002e82:	0791                	addi	a5,a5,4
    80002e84:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e86:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002e8a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e8e:	10079073          	csrw	sstatus,a5
    syscall();
    80002e92:	00000097          	auipc	ra,0x0
    80002e96:	218080e7          	jalr	536(ra) # 800030aa <syscall>
    80002e9a:	a831                	j	80002eb6 <usertrap+0xb4>
      exit(-1);
    80002e9c:	557d                	li	a0,-1
    80002e9e:	fffff097          	auipc	ra,0xfffff
    80002ea2:	6fc080e7          	jalr	1788(ra) # 8000259a <exit>
    80002ea6:	bfe1                	j	80002e7e <usertrap+0x7c>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ea8:	143025f3          	csrr	a1,stval
    handle_page_fault(p->pagetable, r_stval());
    80002eac:	6928                	ld	a0,80(a0)
    80002eae:	00000097          	auipc	ra,0x0
    80002eb2:	ef6080e7          	jalr	-266(ra) # 80002da4 <handle_page_fault>
  if(killed(p))
    80002eb6:	8526                	mv	a0,s1
    80002eb8:	00000097          	auipc	ra,0x0
    80002ebc:	856080e7          	jalr	-1962(ra) # 8000270e <killed>
    80002ec0:	e921                	bnez	a0,80002f10 <usertrap+0x10e>
  usertrapret();
    80002ec2:	00000097          	auipc	ra,0x0
    80002ec6:	c94080e7          	jalr	-876(ra) # 80002b56 <usertrapret>
}
    80002eca:	60e2                	ld	ra,24(sp)
    80002ecc:	6442                	ld	s0,16(sp)
    80002ece:	64a2                	ld	s1,8(sp)
    80002ed0:	6902                	ld	s2,0(sp)
    80002ed2:	6105                	addi	sp,sp,32
    80002ed4:	8082                	ret
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ed6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002eda:	5890                	lw	a2,48(s1)
    80002edc:	00005517          	auipc	a0,0x5
    80002ee0:	5f450513          	addi	a0,a0,1524 # 800084d0 <states.0+0xf8>
    80002ee4:	ffffd097          	auipc	ra,0xffffd
    80002ee8:	6b4080e7          	jalr	1716(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002eec:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ef0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ef4:	00005517          	auipc	a0,0x5
    80002ef8:	60c50513          	addi	a0,a0,1548 # 80008500 <states.0+0x128>
    80002efc:	ffffd097          	auipc	ra,0xffffd
    80002f00:	69c080e7          	jalr	1692(ra) # 80000598 <printf>
    setkilled(p);
    80002f04:	8526                	mv	a0,s1
    80002f06:	fffff097          	auipc	ra,0xfffff
    80002f0a:	7dc080e7          	jalr	2012(ra) # 800026e2 <setkilled>
    80002f0e:	b765                	j	80002eb6 <usertrap+0xb4>
  if(killed(p))
    80002f10:	4901                	li	s2,0
    exit(-1);
    80002f12:	557d                	li	a0,-1
    80002f14:	fffff097          	auipc	ra,0xfffff
    80002f18:	686080e7          	jalr	1670(ra) # 8000259a <exit>
  if(which_dev == 2)
    80002f1c:	4789                	li	a5,2
    80002f1e:	faf912e3          	bne	s2,a5,80002ec2 <usertrap+0xc0>
    yield();
    80002f22:	fffff097          	auipc	ra,0xfffff
    80002f26:	508080e7          	jalr	1288(ra) # 8000242a <yield>
    80002f2a:	bf61                	j	80002ec2 <usertrap+0xc0>

0000000080002f2c <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f2c:	1101                	addi	sp,sp,-32
    80002f2e:	ec06                	sd	ra,24(sp)
    80002f30:	e822                	sd	s0,16(sp)
    80002f32:	e426                	sd	s1,8(sp)
    80002f34:	1000                	addi	s0,sp,32
    80002f36:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f38:	fffff097          	auipc	ra,0xfffff
    80002f3c:	dc6080e7          	jalr	-570(ra) # 80001cfe <myproc>
    switch (n)
    80002f40:	4795                	li	a5,5
    80002f42:	0497e163          	bltu	a5,s1,80002f84 <argraw+0x58>
    80002f46:	048a                	slli	s1,s1,0x2
    80002f48:	00005717          	auipc	a4,0x5
    80002f4c:	60070713          	addi	a4,a4,1536 # 80008548 <states.0+0x170>
    80002f50:	94ba                	add	s1,s1,a4
    80002f52:	409c                	lw	a5,0(s1)
    80002f54:	97ba                	add	a5,a5,a4
    80002f56:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f58:	6d3c                	ld	a5,88(a0)
    80002f5a:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f5c:	60e2                	ld	ra,24(sp)
    80002f5e:	6442                	ld	s0,16(sp)
    80002f60:	64a2                	ld	s1,8(sp)
    80002f62:	6105                	addi	sp,sp,32
    80002f64:	8082                	ret
        return p->trapframe->a1;
    80002f66:	6d3c                	ld	a5,88(a0)
    80002f68:	7fa8                	ld	a0,120(a5)
    80002f6a:	bfcd                	j	80002f5c <argraw+0x30>
        return p->trapframe->a2;
    80002f6c:	6d3c                	ld	a5,88(a0)
    80002f6e:	63c8                	ld	a0,128(a5)
    80002f70:	b7f5                	j	80002f5c <argraw+0x30>
        return p->trapframe->a3;
    80002f72:	6d3c                	ld	a5,88(a0)
    80002f74:	67c8                	ld	a0,136(a5)
    80002f76:	b7dd                	j	80002f5c <argraw+0x30>
        return p->trapframe->a4;
    80002f78:	6d3c                	ld	a5,88(a0)
    80002f7a:	6bc8                	ld	a0,144(a5)
    80002f7c:	b7c5                	j	80002f5c <argraw+0x30>
        return p->trapframe->a5;
    80002f7e:	6d3c                	ld	a5,88(a0)
    80002f80:	6fc8                	ld	a0,152(a5)
    80002f82:	bfe9                	j	80002f5c <argraw+0x30>
    panic("argraw");
    80002f84:	00005517          	auipc	a0,0x5
    80002f88:	59c50513          	addi	a0,a0,1436 # 80008520 <states.0+0x148>
    80002f8c:	ffffd097          	auipc	ra,0xffffd
    80002f90:	5b0080e7          	jalr	1456(ra) # 8000053c <panic>

0000000080002f94 <fetchaddr>:
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	e426                	sd	s1,8(sp)
    80002f9c:	e04a                	sd	s2,0(sp)
    80002f9e:	1000                	addi	s0,sp,32
    80002fa0:	84aa                	mv	s1,a0
    80002fa2:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002fa4:	fffff097          	auipc	ra,0xfffff
    80002fa8:	d5a080e7          	jalr	-678(ra) # 80001cfe <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fac:	653c                	ld	a5,72(a0)
    80002fae:	02f4f863          	bgeu	s1,a5,80002fde <fetchaddr+0x4a>
    80002fb2:	00848713          	addi	a4,s1,8
    80002fb6:	02e7e663          	bltu	a5,a4,80002fe2 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fba:	46a1                	li	a3,8
    80002fbc:	8626                	mv	a2,s1
    80002fbe:	85ca                	mv	a1,s2
    80002fc0:	6928                	ld	a0,80(a0)
    80002fc2:	fffff097          	auipc	ra,0xfffff
    80002fc6:	994080e7          	jalr	-1644(ra) # 80001956 <copyin>
    80002fca:	00a03533          	snez	a0,a0
    80002fce:	40a00533          	neg	a0,a0
}
    80002fd2:	60e2                	ld	ra,24(sp)
    80002fd4:	6442                	ld	s0,16(sp)
    80002fd6:	64a2                	ld	s1,8(sp)
    80002fd8:	6902                	ld	s2,0(sp)
    80002fda:	6105                	addi	sp,sp,32
    80002fdc:	8082                	ret
        return -1;
    80002fde:	557d                	li	a0,-1
    80002fe0:	bfcd                	j	80002fd2 <fetchaddr+0x3e>
    80002fe2:	557d                	li	a0,-1
    80002fe4:	b7fd                	j	80002fd2 <fetchaddr+0x3e>

0000000080002fe6 <fetchstr>:
{
    80002fe6:	7179                	addi	sp,sp,-48
    80002fe8:	f406                	sd	ra,40(sp)
    80002fea:	f022                	sd	s0,32(sp)
    80002fec:	ec26                	sd	s1,24(sp)
    80002fee:	e84a                	sd	s2,16(sp)
    80002ff0:	e44e                	sd	s3,8(sp)
    80002ff2:	1800                	addi	s0,sp,48
    80002ff4:	892a                	mv	s2,a0
    80002ff6:	84ae                	mv	s1,a1
    80002ff8:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	d04080e7          	jalr	-764(ra) # 80001cfe <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80003002:	86ce                	mv	a3,s3
    80003004:	864a                	mv	a2,s2
    80003006:	85a6                	mv	a1,s1
    80003008:	6928                	ld	a0,80(a0)
    8000300a:	fffff097          	auipc	ra,0xfffff
    8000300e:	9da080e7          	jalr	-1574(ra) # 800019e4 <copyinstr>
    80003012:	00054e63          	bltz	a0,8000302e <fetchstr+0x48>
    return strlen(buf);
    80003016:	8526                	mv	a0,s1
    80003018:	ffffe097          	auipc	ra,0xffffe
    8000301c:	fdc080e7          	jalr	-36(ra) # 80000ff4 <strlen>
}
    80003020:	70a2                	ld	ra,40(sp)
    80003022:	7402                	ld	s0,32(sp)
    80003024:	64e2                	ld	s1,24(sp)
    80003026:	6942                	ld	s2,16(sp)
    80003028:	69a2                	ld	s3,8(sp)
    8000302a:	6145                	addi	sp,sp,48
    8000302c:	8082                	ret
        return -1;
    8000302e:	557d                	li	a0,-1
    80003030:	bfc5                	j	80003020 <fetchstr+0x3a>

0000000080003032 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003032:	1101                	addi	sp,sp,-32
    80003034:	ec06                	sd	ra,24(sp)
    80003036:	e822                	sd	s0,16(sp)
    80003038:	e426                	sd	s1,8(sp)
    8000303a:	1000                	addi	s0,sp,32
    8000303c:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000303e:	00000097          	auipc	ra,0x0
    80003042:	eee080e7          	jalr	-274(ra) # 80002f2c <argraw>
    80003046:	c088                	sw	a0,0(s1)
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret

0000000080003052 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003052:	1101                	addi	sp,sp,-32
    80003054:	ec06                	sd	ra,24(sp)
    80003056:	e822                	sd	s0,16(sp)
    80003058:	e426                	sd	s1,8(sp)
    8000305a:	1000                	addi	s0,sp,32
    8000305c:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000305e:	00000097          	auipc	ra,0x0
    80003062:	ece080e7          	jalr	-306(ra) # 80002f2c <argraw>
    80003066:	e088                	sd	a0,0(s1)
}
    80003068:	60e2                	ld	ra,24(sp)
    8000306a:	6442                	ld	s0,16(sp)
    8000306c:	64a2                	ld	s1,8(sp)
    8000306e:	6105                	addi	sp,sp,32
    80003070:	8082                	ret

0000000080003072 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003072:	7179                	addi	sp,sp,-48
    80003074:	f406                	sd	ra,40(sp)
    80003076:	f022                	sd	s0,32(sp)
    80003078:	ec26                	sd	s1,24(sp)
    8000307a:	e84a                	sd	s2,16(sp)
    8000307c:	1800                	addi	s0,sp,48
    8000307e:	84ae                	mv	s1,a1
    80003080:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003082:	fd840593          	addi	a1,s0,-40
    80003086:	00000097          	auipc	ra,0x0
    8000308a:	fcc080e7          	jalr	-52(ra) # 80003052 <argaddr>
    return fetchstr(addr, buf, max);
    8000308e:	864a                	mv	a2,s2
    80003090:	85a6                	mv	a1,s1
    80003092:	fd843503          	ld	a0,-40(s0)
    80003096:	00000097          	auipc	ra,0x0
    8000309a:	f50080e7          	jalr	-176(ra) # 80002fe6 <fetchstr>
}
    8000309e:	70a2                	ld	ra,40(sp)
    800030a0:	7402                	ld	s0,32(sp)
    800030a2:	64e2                	ld	s1,24(sp)
    800030a4:	6942                	ld	s2,16(sp)
    800030a6:	6145                	addi	sp,sp,48
    800030a8:	8082                	ret

00000000800030aa <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    800030aa:	1101                	addi	sp,sp,-32
    800030ac:	ec06                	sd	ra,24(sp)
    800030ae:	e822                	sd	s0,16(sp)
    800030b0:	e426                	sd	s1,8(sp)
    800030b2:	e04a                	sd	s2,0(sp)
    800030b4:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800030b6:	fffff097          	auipc	ra,0xfffff
    800030ba:	c48080e7          	jalr	-952(ra) # 80001cfe <myproc>
    800030be:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800030c0:	05853903          	ld	s2,88(a0)
    800030c4:	0a893783          	ld	a5,168(s2)
    800030c8:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800030cc:	37fd                	addiw	a5,a5,-1
    800030ce:	4765                	li	a4,25
    800030d0:	00f76f63          	bltu	a4,a5,800030ee <syscall+0x44>
    800030d4:	00369713          	slli	a4,a3,0x3
    800030d8:	00005797          	auipc	a5,0x5
    800030dc:	48878793          	addi	a5,a5,1160 # 80008560 <syscalls>
    800030e0:	97ba                	add	a5,a5,a4
    800030e2:	639c                	ld	a5,0(a5)
    800030e4:	c789                	beqz	a5,800030ee <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800030e6:	9782                	jalr	a5
    800030e8:	06a93823          	sd	a0,112(s2)
    800030ec:	a839                	j	8000310a <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030ee:	15848613          	addi	a2,s1,344
    800030f2:	588c                	lw	a1,48(s1)
    800030f4:	00005517          	auipc	a0,0x5
    800030f8:	43450513          	addi	a0,a0,1076 # 80008528 <states.0+0x150>
    800030fc:	ffffd097          	auipc	ra,0xffffd
    80003100:	49c080e7          	jalr	1180(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    80003104:	6cbc                	ld	a5,88(s1)
    80003106:	577d                	li	a4,-1
    80003108:	fbb8                	sd	a4,112(a5)
    }
}
    8000310a:	60e2                	ld	ra,24(sp)
    8000310c:	6442                	ld	s0,16(sp)
    8000310e:	64a2                	ld	s1,8(sp)
    80003110:	6902                	ld	s2,0(sp)
    80003112:	6105                	addi	sp,sp,32
    80003114:	8082                	ret

0000000080003116 <sys_exit>:
extern uint64 FREE_PAGES; // kalloc.c keeps track of those
extern struct proc proc[];

uint64
sys_exit(void)
{
    80003116:	1101                	addi	sp,sp,-32
    80003118:	ec06                	sd	ra,24(sp)
    8000311a:	e822                	sd	s0,16(sp)
    8000311c:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000311e:	fec40593          	addi	a1,s0,-20
    80003122:	4501                	li	a0,0
    80003124:	00000097          	auipc	ra,0x0
    80003128:	f0e080e7          	jalr	-242(ra) # 80003032 <argint>
    exit(n);
    8000312c:	fec42503          	lw	a0,-20(s0)
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	46a080e7          	jalr	1130(ra) # 8000259a <exit>
    return 0; // not reached
}
    80003138:	4501                	li	a0,0
    8000313a:	60e2                	ld	ra,24(sp)
    8000313c:	6442                	ld	s0,16(sp)
    8000313e:	6105                	addi	sp,sp,32
    80003140:	8082                	ret

0000000080003142 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003142:	1141                	addi	sp,sp,-16
    80003144:	e406                	sd	ra,8(sp)
    80003146:	e022                	sd	s0,0(sp)
    80003148:	0800                	addi	s0,sp,16
    return myproc()->pid;
    8000314a:	fffff097          	auipc	ra,0xfffff
    8000314e:	bb4080e7          	jalr	-1100(ra) # 80001cfe <myproc>
}
    80003152:	5908                	lw	a0,48(a0)
    80003154:	60a2                	ld	ra,8(sp)
    80003156:	6402                	ld	s0,0(sp)
    80003158:	0141                	addi	sp,sp,16
    8000315a:	8082                	ret

000000008000315c <sys_fork>:

uint64
sys_fork(void)
{
    8000315c:	1141                	addi	sp,sp,-16
    8000315e:	e406                	sd	ra,8(sp)
    80003160:	e022                	sd	s0,0(sp)
    80003162:	0800                	addi	s0,sp,16
    return fork();
    80003164:	fffff097          	auipc	ra,0xfffff
    80003168:	0a0080e7          	jalr	160(ra) # 80002204 <fork>
}
    8000316c:	60a2                	ld	ra,8(sp)
    8000316e:	6402                	ld	s0,0(sp)
    80003170:	0141                	addi	sp,sp,16
    80003172:	8082                	ret

0000000080003174 <sys_wait>:

uint64
sys_wait(void)
{
    80003174:	1101                	addi	sp,sp,-32
    80003176:	ec06                	sd	ra,24(sp)
    80003178:	e822                	sd	s0,16(sp)
    8000317a:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000317c:	fe840593          	addi	a1,s0,-24
    80003180:	4501                	li	a0,0
    80003182:	00000097          	auipc	ra,0x0
    80003186:	ed0080e7          	jalr	-304(ra) # 80003052 <argaddr>
    return wait(p);
    8000318a:	fe843503          	ld	a0,-24(s0)
    8000318e:	fffff097          	auipc	ra,0xfffff
    80003192:	5b2080e7          	jalr	1458(ra) # 80002740 <wait>
}
    80003196:	60e2                	ld	ra,24(sp)
    80003198:	6442                	ld	s0,16(sp)
    8000319a:	6105                	addi	sp,sp,32
    8000319c:	8082                	ret

000000008000319e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000319e:	7179                	addi	sp,sp,-48
    800031a0:	f406                	sd	ra,40(sp)
    800031a2:	f022                	sd	s0,32(sp)
    800031a4:	ec26                	sd	s1,24(sp)
    800031a6:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    800031a8:	fdc40593          	addi	a1,s0,-36
    800031ac:	4501                	li	a0,0
    800031ae:	00000097          	auipc	ra,0x0
    800031b2:	e84080e7          	jalr	-380(ra) # 80003032 <argint>
    addr = myproc()->sz;
    800031b6:	fffff097          	auipc	ra,0xfffff
    800031ba:	b48080e7          	jalr	-1208(ra) # 80001cfe <myproc>
    800031be:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800031c0:	fdc42503          	lw	a0,-36(s0)
    800031c4:	fffff097          	auipc	ra,0xfffff
    800031c8:	e94080e7          	jalr	-364(ra) # 80002058 <growproc>
    800031cc:	00054863          	bltz	a0,800031dc <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800031d0:	8526                	mv	a0,s1
    800031d2:	70a2                	ld	ra,40(sp)
    800031d4:	7402                	ld	s0,32(sp)
    800031d6:	64e2                	ld	s1,24(sp)
    800031d8:	6145                	addi	sp,sp,48
    800031da:	8082                	ret
        return -1;
    800031dc:	54fd                	li	s1,-1
    800031de:	bfcd                	j	800031d0 <sys_sbrk+0x32>

00000000800031e0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800031e0:	7139                	addi	sp,sp,-64
    800031e2:	fc06                	sd	ra,56(sp)
    800031e4:	f822                	sd	s0,48(sp)
    800031e6:	f426                	sd	s1,40(sp)
    800031e8:	f04a                	sd	s2,32(sp)
    800031ea:	ec4e                	sd	s3,24(sp)
    800031ec:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031ee:	fcc40593          	addi	a1,s0,-52
    800031f2:	4501                	li	a0,0
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	e3e080e7          	jalr	-450(ra) # 80003032 <argint>
    acquire(&tickslock);
    800031fc:	00454517          	auipc	a0,0x454
    80003200:	8e450513          	addi	a0,a0,-1820 # 80456ae0 <tickslock>
    80003204:	ffffe097          	auipc	ra,0xffffe
    80003208:	b7a080e7          	jalr	-1158(ra) # 80000d7e <acquire>
    ticks0 = ticks;
    8000320c:	00006917          	auipc	s2,0x6
    80003210:	83492903          	lw	s2,-1996(s2) # 80008a40 <ticks>
    while (ticks - ticks0 < n)
    80003214:	fcc42783          	lw	a5,-52(s0)
    80003218:	cf9d                	beqz	a5,80003256 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    8000321a:	00454997          	auipc	s3,0x454
    8000321e:	8c698993          	addi	s3,s3,-1850 # 80456ae0 <tickslock>
    80003222:	00006497          	auipc	s1,0x6
    80003226:	81e48493          	addi	s1,s1,-2018 # 80008a40 <ticks>
        if (killed(myproc()))
    8000322a:	fffff097          	auipc	ra,0xfffff
    8000322e:	ad4080e7          	jalr	-1324(ra) # 80001cfe <myproc>
    80003232:	fffff097          	auipc	ra,0xfffff
    80003236:	4dc080e7          	jalr	1244(ra) # 8000270e <killed>
    8000323a:	ed15                	bnez	a0,80003276 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    8000323c:	85ce                	mv	a1,s3
    8000323e:	8526                	mv	a0,s1
    80003240:	fffff097          	auipc	ra,0xfffff
    80003244:	226080e7          	jalr	550(ra) # 80002466 <sleep>
    while (ticks - ticks0 < n)
    80003248:	409c                	lw	a5,0(s1)
    8000324a:	412787bb          	subw	a5,a5,s2
    8000324e:	fcc42703          	lw	a4,-52(s0)
    80003252:	fce7ece3          	bltu	a5,a4,8000322a <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003256:	00454517          	auipc	a0,0x454
    8000325a:	88a50513          	addi	a0,a0,-1910 # 80456ae0 <tickslock>
    8000325e:	ffffe097          	auipc	ra,0xffffe
    80003262:	bd4080e7          	jalr	-1068(ra) # 80000e32 <release>
    return 0;
    80003266:	4501                	li	a0,0
}
    80003268:	70e2                	ld	ra,56(sp)
    8000326a:	7442                	ld	s0,48(sp)
    8000326c:	74a2                	ld	s1,40(sp)
    8000326e:	7902                	ld	s2,32(sp)
    80003270:	69e2                	ld	s3,24(sp)
    80003272:	6121                	addi	sp,sp,64
    80003274:	8082                	ret
            release(&tickslock);
    80003276:	00454517          	auipc	a0,0x454
    8000327a:	86a50513          	addi	a0,a0,-1942 # 80456ae0 <tickslock>
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	bb4080e7          	jalr	-1100(ra) # 80000e32 <release>
            return -1;
    80003286:	557d                	li	a0,-1
    80003288:	b7c5                	j	80003268 <sys_sleep+0x88>

000000008000328a <sys_kill>:

uint64
sys_kill(void)
{
    8000328a:	1101                	addi	sp,sp,-32
    8000328c:	ec06                	sd	ra,24(sp)
    8000328e:	e822                	sd	s0,16(sp)
    80003290:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003292:	fec40593          	addi	a1,s0,-20
    80003296:	4501                	li	a0,0
    80003298:	00000097          	auipc	ra,0x0
    8000329c:	d9a080e7          	jalr	-614(ra) # 80003032 <argint>
    return kill(pid);
    800032a0:	fec42503          	lw	a0,-20(s0)
    800032a4:	fffff097          	auipc	ra,0xfffff
    800032a8:	3cc080e7          	jalr	972(ra) # 80002670 <kill>
}
    800032ac:	60e2                	ld	ra,24(sp)
    800032ae:	6442                	ld	s0,16(sp)
    800032b0:	6105                	addi	sp,sp,32
    800032b2:	8082                	ret

00000000800032b4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032b4:	1101                	addi	sp,sp,-32
    800032b6:	ec06                	sd	ra,24(sp)
    800032b8:	e822                	sd	s0,16(sp)
    800032ba:	e426                	sd	s1,8(sp)
    800032bc:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800032be:	00454517          	auipc	a0,0x454
    800032c2:	82250513          	addi	a0,a0,-2014 # 80456ae0 <tickslock>
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	ab8080e7          	jalr	-1352(ra) # 80000d7e <acquire>
    xticks = ticks;
    800032ce:	00005497          	auipc	s1,0x5
    800032d2:	7724a483          	lw	s1,1906(s1) # 80008a40 <ticks>
    release(&tickslock);
    800032d6:	00454517          	auipc	a0,0x454
    800032da:	80a50513          	addi	a0,a0,-2038 # 80456ae0 <tickslock>
    800032de:	ffffe097          	auipc	ra,0xffffe
    800032e2:	b54080e7          	jalr	-1196(ra) # 80000e32 <release>
    return xticks;
}
    800032e6:	02049513          	slli	a0,s1,0x20
    800032ea:	9101                	srli	a0,a0,0x20
    800032ec:	60e2                	ld	ra,24(sp)
    800032ee:	6442                	ld	s0,16(sp)
    800032f0:	64a2                	ld	s1,8(sp)
    800032f2:	6105                	addi	sp,sp,32
    800032f4:	8082                	ret

00000000800032f6 <sys_ps>:

void *
sys_ps(void)
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032fe:	fe042623          	sw	zero,-20(s0)
    80003302:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    80003306:	fec40593          	addi	a1,s0,-20
    8000330a:	4501                	li	a0,0
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	d26080e7          	jalr	-730(ra) # 80003032 <argint>
    argint(1, &count);
    80003314:	fe840593          	addi	a1,s0,-24
    80003318:	4505                	li	a0,1
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	d18080e7          	jalr	-744(ra) # 80003032 <argint>
    return ps((uint8)start, (uint8)count);
    80003322:	fe844583          	lbu	a1,-24(s0)
    80003326:	fec44503          	lbu	a0,-20(s0)
    8000332a:	fffff097          	auipc	ra,0xfffff
    8000332e:	d8a080e7          	jalr	-630(ra) # 800020b4 <ps>
}
    80003332:	60e2                	ld	ra,24(sp)
    80003334:	6442                	ld	s0,16(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret

000000008000333a <sys_schedls>:

uint64 sys_schedls(void)
{
    8000333a:	1141                	addi	sp,sp,-16
    8000333c:	e406                	sd	ra,8(sp)
    8000333e:	e022                	sd	s0,0(sp)
    80003340:	0800                	addi	s0,sp,16
    schedls();
    80003342:	fffff097          	auipc	ra,0xfffff
    80003346:	688080e7          	jalr	1672(ra) # 800029ca <schedls>
    return 0;
}
    8000334a:	4501                	li	a0,0
    8000334c:	60a2                	ld	ra,8(sp)
    8000334e:	6402                	ld	s0,0(sp)
    80003350:	0141                	addi	sp,sp,16
    80003352:	8082                	ret

0000000080003354 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003354:	1101                	addi	sp,sp,-32
    80003356:	ec06                	sd	ra,24(sp)
    80003358:	e822                	sd	s0,16(sp)
    8000335a:	1000                	addi	s0,sp,32
    int id = 0;
    8000335c:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003360:	fec40593          	addi	a1,s0,-20
    80003364:	4501                	li	a0,0
    80003366:	00000097          	auipc	ra,0x0
    8000336a:	ccc080e7          	jalr	-820(ra) # 80003032 <argint>
    schedset(id - 1);
    8000336e:	fec42503          	lw	a0,-20(s0)
    80003372:	357d                	addiw	a0,a0,-1
    80003374:	fffff097          	auipc	ra,0xfffff
    80003378:	6ec080e7          	jalr	1772(ra) # 80002a60 <schedset>
    return 0;
}
    8000337c:	4501                	li	a0,0
    8000337e:	60e2                	ld	ra,24(sp)
    80003380:	6442                	ld	s0,16(sp)
    80003382:	6105                	addi	sp,sp,32
    80003384:	8082                	ret

0000000080003386 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003386:	7179                	addi	sp,sp,-48
    80003388:	f406                	sd	ra,40(sp)
    8000338a:	f022                	sd	s0,32(sp)
    8000338c:	ec26                	sd	s1,24(sp)
    8000338e:	e84a                	sd	s2,16(sp)
    80003390:	1800                	addi	s0,sp,48
    int pid = 0;
    80003392:	fc042e23          	sw	zero,-36(s0)
    uint64 va = 0;
    80003396:	fc043823          	sd	zero,-48(s0)
    
    argint(1, &pid);
    8000339a:	fdc40593          	addi	a1,s0,-36
    8000339e:	4505                	li	a0,1
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	c92080e7          	jalr	-878(ra) # 80003032 <argint>
    argaddr(0, &va);
    800033a8:	fd040593          	addi	a1,s0,-48
    800033ac:	4501                	li	a0,0
    800033ae:	00000097          	auipc	ra,0x0
    800033b2:	ca4080e7          	jalr	-860(ra) # 80003052 <argaddr>

    struct proc *p;
    int pidExists = 0;

    // Check if we supplied a PID
    if (pid != 0) {
    800033b6:	fdc42783          	lw	a5,-36(s0)
    800033ba:	c3a5                	beqz	a5,8000341a <sys_va2pa+0x94>
        for (p = proc; p < &proc[NPROC]; p++) {
    800033bc:	0044e497          	auipc	s1,0x44e
    800033c0:	d2448493          	addi	s1,s1,-732 # 804510e0 <proc>
    800033c4:	00453917          	auipc	s2,0x453
    800033c8:	71c90913          	addi	s2,s2,1820 # 80456ae0 <tickslock>
            acquire(&p->lock);
    800033cc:	8526                	mv	a0,s1
    800033ce:	ffffe097          	auipc	ra,0xffffe
    800033d2:	9b0080e7          	jalr	-1616(ra) # 80000d7e <acquire>
            if (p->pid == pid) {
    800033d6:	5898                	lw	a4,48(s1)
    800033d8:	fdc42783          	lw	a5,-36(s0)
    800033dc:	00f70d63          	beq	a4,a5,800033f6 <sys_va2pa+0x70>
                release(&p->lock);
                pidExists = 1;
                break;
            }
            release(&p->lock);
    800033e0:	8526                	mv	a0,s1
    800033e2:	ffffe097          	auipc	ra,0xffffe
    800033e6:	a50080e7          	jalr	-1456(ra) # 80000e32 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    800033ea:	16848493          	addi	s1,s1,360
    800033ee:	fd249fe3          	bne	s1,s2,800033cc <sys_va2pa+0x46>
        }
        if (pidExists == 0) {
            return 0;
    800033f2:	4501                	li	a0,0
    800033f4:	a829                	j	8000340e <sys_va2pa+0x88>
                release(&p->lock);
    800033f6:	8526                	mv	a0,s1
    800033f8:	ffffe097          	auipc	ra,0xffffe
    800033fc:	a3a080e7          	jalr	-1478(ra) # 80000e32 <release>
        p = myproc();
    }

    // Find the VA
    pagetable_t pagetable = p->pagetable;
    uint64 pa = walkaddr(pagetable, va);
    80003400:	fd043583          	ld	a1,-48(s0)
    80003404:	68a8                	ld	a0,80(s1)
    80003406:	ffffe097          	auipc	ra,0xffffe
    8000340a:	dfc080e7          	jalr	-516(ra) # 80001202 <walkaddr>
        return 0;
    } else {
        return pa;
    }
    return 0;
}
    8000340e:	70a2                	ld	ra,40(sp)
    80003410:	7402                	ld	s0,32(sp)
    80003412:	64e2                	ld	s1,24(sp)
    80003414:	6942                	ld	s2,16(sp)
    80003416:	6145                	addi	sp,sp,48
    80003418:	8082                	ret
        p = myproc();
    8000341a:	fffff097          	auipc	ra,0xfffff
    8000341e:	8e4080e7          	jalr	-1820(ra) # 80001cfe <myproc>
    80003422:	84aa                	mv	s1,a0
    80003424:	bff1                	j	80003400 <sys_va2pa+0x7a>

0000000080003426 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003426:	1141                	addi	sp,sp,-16
    80003428:	e406                	sd	ra,8(sp)
    8000342a:	e022                	sd	s0,0(sp)
    8000342c:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    8000342e:	00005597          	auipc	a1,0x5
    80003432:	5ea5b583          	ld	a1,1514(a1) # 80008a18 <FREE_PAGES>
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	10a50513          	addi	a0,a0,266 # 80008540 <states.0+0x168>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	15a080e7          	jalr	346(ra) # 80000598 <printf>
    return 0;
    80003446:	4501                	li	a0,0
    80003448:	60a2                	ld	ra,8(sp)
    8000344a:	6402                	ld	s0,0(sp)
    8000344c:	0141                	addi	sp,sp,16
    8000344e:	8082                	ret

0000000080003450 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003450:	7179                	addi	sp,sp,-48
    80003452:	f406                	sd	ra,40(sp)
    80003454:	f022                	sd	s0,32(sp)
    80003456:	ec26                	sd	s1,24(sp)
    80003458:	e84a                	sd	s2,16(sp)
    8000345a:	e44e                	sd	s3,8(sp)
    8000345c:	e052                	sd	s4,0(sp)
    8000345e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003460:	00005597          	auipc	a1,0x5
    80003464:	1d858593          	addi	a1,a1,472 # 80008638 <syscalls+0xd8>
    80003468:	00453517          	auipc	a0,0x453
    8000346c:	69050513          	addi	a0,a0,1680 # 80456af8 <bcache>
    80003470:	ffffe097          	auipc	ra,0xffffe
    80003474:	87e080e7          	jalr	-1922(ra) # 80000cee <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003478:	0045b797          	auipc	a5,0x45b
    8000347c:	68078793          	addi	a5,a5,1664 # 8045eaf8 <bcache+0x8000>
    80003480:	0045c717          	auipc	a4,0x45c
    80003484:	8e070713          	addi	a4,a4,-1824 # 8045ed60 <bcache+0x8268>
    80003488:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000348c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003490:	00453497          	auipc	s1,0x453
    80003494:	68048493          	addi	s1,s1,1664 # 80456b10 <bcache+0x18>
    b->next = bcache.head.next;
    80003498:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000349a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000349c:	00005a17          	auipc	s4,0x5
    800034a0:	1a4a0a13          	addi	s4,s4,420 # 80008640 <syscalls+0xe0>
    b->next = bcache.head.next;
    800034a4:	2b893783          	ld	a5,696(s2)
    800034a8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800034aa:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800034ae:	85d2                	mv	a1,s4
    800034b0:	01048513          	addi	a0,s1,16
    800034b4:	00001097          	auipc	ra,0x1
    800034b8:	496080e7          	jalr	1174(ra) # 8000494a <initsleeplock>
    bcache.head.next->prev = b;
    800034bc:	2b893783          	ld	a5,696(s2)
    800034c0:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800034c2:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800034c6:	45848493          	addi	s1,s1,1112
    800034ca:	fd349de3          	bne	s1,s3,800034a4 <binit+0x54>
  }
}
    800034ce:	70a2                	ld	ra,40(sp)
    800034d0:	7402                	ld	s0,32(sp)
    800034d2:	64e2                	ld	s1,24(sp)
    800034d4:	6942                	ld	s2,16(sp)
    800034d6:	69a2                	ld	s3,8(sp)
    800034d8:	6a02                	ld	s4,0(sp)
    800034da:	6145                	addi	sp,sp,48
    800034dc:	8082                	ret

00000000800034de <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800034de:	7179                	addi	sp,sp,-48
    800034e0:	f406                	sd	ra,40(sp)
    800034e2:	f022                	sd	s0,32(sp)
    800034e4:	ec26                	sd	s1,24(sp)
    800034e6:	e84a                	sd	s2,16(sp)
    800034e8:	e44e                	sd	s3,8(sp)
    800034ea:	1800                	addi	s0,sp,48
    800034ec:	892a                	mv	s2,a0
    800034ee:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800034f0:	00453517          	auipc	a0,0x453
    800034f4:	60850513          	addi	a0,a0,1544 # 80456af8 <bcache>
    800034f8:	ffffe097          	auipc	ra,0xffffe
    800034fc:	886080e7          	jalr	-1914(ra) # 80000d7e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003500:	0045c497          	auipc	s1,0x45c
    80003504:	8b04b483          	ld	s1,-1872(s1) # 8045edb0 <bcache+0x82b8>
    80003508:	0045c797          	auipc	a5,0x45c
    8000350c:	85878793          	addi	a5,a5,-1960 # 8045ed60 <bcache+0x8268>
    80003510:	02f48f63          	beq	s1,a5,8000354e <bread+0x70>
    80003514:	873e                	mv	a4,a5
    80003516:	a021                	j	8000351e <bread+0x40>
    80003518:	68a4                	ld	s1,80(s1)
    8000351a:	02e48a63          	beq	s1,a4,8000354e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000351e:	449c                	lw	a5,8(s1)
    80003520:	ff279ce3          	bne	a5,s2,80003518 <bread+0x3a>
    80003524:	44dc                	lw	a5,12(s1)
    80003526:	ff3799e3          	bne	a5,s3,80003518 <bread+0x3a>
      b->refcnt++;
    8000352a:	40bc                	lw	a5,64(s1)
    8000352c:	2785                	addiw	a5,a5,1
    8000352e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003530:	00453517          	auipc	a0,0x453
    80003534:	5c850513          	addi	a0,a0,1480 # 80456af8 <bcache>
    80003538:	ffffe097          	auipc	ra,0xffffe
    8000353c:	8fa080e7          	jalr	-1798(ra) # 80000e32 <release>
      acquiresleep(&b->lock);
    80003540:	01048513          	addi	a0,s1,16
    80003544:	00001097          	auipc	ra,0x1
    80003548:	440080e7          	jalr	1088(ra) # 80004984 <acquiresleep>
      return b;
    8000354c:	a8b9                	j	800035aa <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000354e:	0045c497          	auipc	s1,0x45c
    80003552:	85a4b483          	ld	s1,-1958(s1) # 8045eda8 <bcache+0x82b0>
    80003556:	0045c797          	auipc	a5,0x45c
    8000355a:	80a78793          	addi	a5,a5,-2038 # 8045ed60 <bcache+0x8268>
    8000355e:	00f48863          	beq	s1,a5,8000356e <bread+0x90>
    80003562:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003564:	40bc                	lw	a5,64(s1)
    80003566:	cf81                	beqz	a5,8000357e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003568:	64a4                	ld	s1,72(s1)
    8000356a:	fee49de3          	bne	s1,a4,80003564 <bread+0x86>
  panic("bget: no buffers");
    8000356e:	00005517          	auipc	a0,0x5
    80003572:	0da50513          	addi	a0,a0,218 # 80008648 <syscalls+0xe8>
    80003576:	ffffd097          	auipc	ra,0xffffd
    8000357a:	fc6080e7          	jalr	-58(ra) # 8000053c <panic>
      b->dev = dev;
    8000357e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003582:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003586:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000358a:	4785                	li	a5,1
    8000358c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000358e:	00453517          	auipc	a0,0x453
    80003592:	56a50513          	addi	a0,a0,1386 # 80456af8 <bcache>
    80003596:	ffffe097          	auipc	ra,0xffffe
    8000359a:	89c080e7          	jalr	-1892(ra) # 80000e32 <release>
      acquiresleep(&b->lock);
    8000359e:	01048513          	addi	a0,s1,16
    800035a2:	00001097          	auipc	ra,0x1
    800035a6:	3e2080e7          	jalr	994(ra) # 80004984 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800035aa:	409c                	lw	a5,0(s1)
    800035ac:	cb89                	beqz	a5,800035be <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800035ae:	8526                	mv	a0,s1
    800035b0:	70a2                	ld	ra,40(sp)
    800035b2:	7402                	ld	s0,32(sp)
    800035b4:	64e2                	ld	s1,24(sp)
    800035b6:	6942                	ld	s2,16(sp)
    800035b8:	69a2                	ld	s3,8(sp)
    800035ba:	6145                	addi	sp,sp,48
    800035bc:	8082                	ret
    virtio_disk_rw(b, 0);
    800035be:	4581                	li	a1,0
    800035c0:	8526                	mv	a0,s1
    800035c2:	00003097          	auipc	ra,0x3
    800035c6:	f80080e7          	jalr	-128(ra) # 80006542 <virtio_disk_rw>
    b->valid = 1;
    800035ca:	4785                	li	a5,1
    800035cc:	c09c                	sw	a5,0(s1)
  return b;
    800035ce:	b7c5                	j	800035ae <bread+0xd0>

00000000800035d0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800035d0:	1101                	addi	sp,sp,-32
    800035d2:	ec06                	sd	ra,24(sp)
    800035d4:	e822                	sd	s0,16(sp)
    800035d6:	e426                	sd	s1,8(sp)
    800035d8:	1000                	addi	s0,sp,32
    800035da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035dc:	0541                	addi	a0,a0,16
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	440080e7          	jalr	1088(ra) # 80004a1e <holdingsleep>
    800035e6:	cd01                	beqz	a0,800035fe <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800035e8:	4585                	li	a1,1
    800035ea:	8526                	mv	a0,s1
    800035ec:	00003097          	auipc	ra,0x3
    800035f0:	f56080e7          	jalr	-170(ra) # 80006542 <virtio_disk_rw>
}
    800035f4:	60e2                	ld	ra,24(sp)
    800035f6:	6442                	ld	s0,16(sp)
    800035f8:	64a2                	ld	s1,8(sp)
    800035fa:	6105                	addi	sp,sp,32
    800035fc:	8082                	ret
    panic("bwrite");
    800035fe:	00005517          	auipc	a0,0x5
    80003602:	06250513          	addi	a0,a0,98 # 80008660 <syscalls+0x100>
    80003606:	ffffd097          	auipc	ra,0xffffd
    8000360a:	f36080e7          	jalr	-202(ra) # 8000053c <panic>

000000008000360e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000360e:	1101                	addi	sp,sp,-32
    80003610:	ec06                	sd	ra,24(sp)
    80003612:	e822                	sd	s0,16(sp)
    80003614:	e426                	sd	s1,8(sp)
    80003616:	e04a                	sd	s2,0(sp)
    80003618:	1000                	addi	s0,sp,32
    8000361a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000361c:	01050913          	addi	s2,a0,16
    80003620:	854a                	mv	a0,s2
    80003622:	00001097          	auipc	ra,0x1
    80003626:	3fc080e7          	jalr	1020(ra) # 80004a1e <holdingsleep>
    8000362a:	c925                	beqz	a0,8000369a <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    8000362c:	854a                	mv	a0,s2
    8000362e:	00001097          	auipc	ra,0x1
    80003632:	3ac080e7          	jalr	940(ra) # 800049da <releasesleep>

  acquire(&bcache.lock);
    80003636:	00453517          	auipc	a0,0x453
    8000363a:	4c250513          	addi	a0,a0,1218 # 80456af8 <bcache>
    8000363e:	ffffd097          	auipc	ra,0xffffd
    80003642:	740080e7          	jalr	1856(ra) # 80000d7e <acquire>
  b->refcnt--;
    80003646:	40bc                	lw	a5,64(s1)
    80003648:	37fd                	addiw	a5,a5,-1
    8000364a:	0007871b          	sext.w	a4,a5
    8000364e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003650:	e71d                	bnez	a4,8000367e <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003652:	68b8                	ld	a4,80(s1)
    80003654:	64bc                	ld	a5,72(s1)
    80003656:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003658:	68b8                	ld	a4,80(s1)
    8000365a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000365c:	0045b797          	auipc	a5,0x45b
    80003660:	49c78793          	addi	a5,a5,1180 # 8045eaf8 <bcache+0x8000>
    80003664:	2b87b703          	ld	a4,696(a5)
    80003668:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000366a:	0045b717          	auipc	a4,0x45b
    8000366e:	6f670713          	addi	a4,a4,1782 # 8045ed60 <bcache+0x8268>
    80003672:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003674:	2b87b703          	ld	a4,696(a5)
    80003678:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000367a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000367e:	00453517          	auipc	a0,0x453
    80003682:	47a50513          	addi	a0,a0,1146 # 80456af8 <bcache>
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	7ac080e7          	jalr	1964(ra) # 80000e32 <release>
}
    8000368e:	60e2                	ld	ra,24(sp)
    80003690:	6442                	ld	s0,16(sp)
    80003692:	64a2                	ld	s1,8(sp)
    80003694:	6902                	ld	s2,0(sp)
    80003696:	6105                	addi	sp,sp,32
    80003698:	8082                	ret
    panic("brelse");
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	fce50513          	addi	a0,a0,-50 # 80008668 <syscalls+0x108>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	e9a080e7          	jalr	-358(ra) # 8000053c <panic>

00000000800036aa <bpin>:

void
bpin(struct buf *b) {
    800036aa:	1101                	addi	sp,sp,-32
    800036ac:	ec06                	sd	ra,24(sp)
    800036ae:	e822                	sd	s0,16(sp)
    800036b0:	e426                	sd	s1,8(sp)
    800036b2:	1000                	addi	s0,sp,32
    800036b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036b6:	00453517          	auipc	a0,0x453
    800036ba:	44250513          	addi	a0,a0,1090 # 80456af8 <bcache>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	6c0080e7          	jalr	1728(ra) # 80000d7e <acquire>
  b->refcnt++;
    800036c6:	40bc                	lw	a5,64(s1)
    800036c8:	2785                	addiw	a5,a5,1
    800036ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036cc:	00453517          	auipc	a0,0x453
    800036d0:	42c50513          	addi	a0,a0,1068 # 80456af8 <bcache>
    800036d4:	ffffd097          	auipc	ra,0xffffd
    800036d8:	75e080e7          	jalr	1886(ra) # 80000e32 <release>
}
    800036dc:	60e2                	ld	ra,24(sp)
    800036de:	6442                	ld	s0,16(sp)
    800036e0:	64a2                	ld	s1,8(sp)
    800036e2:	6105                	addi	sp,sp,32
    800036e4:	8082                	ret

00000000800036e6 <bunpin>:

void
bunpin(struct buf *b) {
    800036e6:	1101                	addi	sp,sp,-32
    800036e8:	ec06                	sd	ra,24(sp)
    800036ea:	e822                	sd	s0,16(sp)
    800036ec:	e426                	sd	s1,8(sp)
    800036ee:	1000                	addi	s0,sp,32
    800036f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800036f2:	00453517          	auipc	a0,0x453
    800036f6:	40650513          	addi	a0,a0,1030 # 80456af8 <bcache>
    800036fa:	ffffd097          	auipc	ra,0xffffd
    800036fe:	684080e7          	jalr	1668(ra) # 80000d7e <acquire>
  b->refcnt--;
    80003702:	40bc                	lw	a5,64(s1)
    80003704:	37fd                	addiw	a5,a5,-1
    80003706:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003708:	00453517          	auipc	a0,0x453
    8000370c:	3f050513          	addi	a0,a0,1008 # 80456af8 <bcache>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	722080e7          	jalr	1826(ra) # 80000e32 <release>
}
    80003718:	60e2                	ld	ra,24(sp)
    8000371a:	6442                	ld	s0,16(sp)
    8000371c:	64a2                	ld	s1,8(sp)
    8000371e:	6105                	addi	sp,sp,32
    80003720:	8082                	ret

0000000080003722 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003722:	1101                	addi	sp,sp,-32
    80003724:	ec06                	sd	ra,24(sp)
    80003726:	e822                	sd	s0,16(sp)
    80003728:	e426                	sd	s1,8(sp)
    8000372a:	e04a                	sd	s2,0(sp)
    8000372c:	1000                	addi	s0,sp,32
    8000372e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003730:	00d5d59b          	srliw	a1,a1,0xd
    80003734:	0045c797          	auipc	a5,0x45c
    80003738:	aa07a783          	lw	a5,-1376(a5) # 8045f1d4 <sb+0x1c>
    8000373c:	9dbd                	addw	a1,a1,a5
    8000373e:	00000097          	auipc	ra,0x0
    80003742:	da0080e7          	jalr	-608(ra) # 800034de <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003746:	0074f713          	andi	a4,s1,7
    8000374a:	4785                	li	a5,1
    8000374c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003750:	14ce                	slli	s1,s1,0x33
    80003752:	90d9                	srli	s1,s1,0x36
    80003754:	00950733          	add	a4,a0,s1
    80003758:	05874703          	lbu	a4,88(a4)
    8000375c:	00e7f6b3          	and	a3,a5,a4
    80003760:	c69d                	beqz	a3,8000378e <bfree+0x6c>
    80003762:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003764:	94aa                	add	s1,s1,a0
    80003766:	fff7c793          	not	a5,a5
    8000376a:	8f7d                	and	a4,a4,a5
    8000376c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003770:	00001097          	auipc	ra,0x1
    80003774:	0f6080e7          	jalr	246(ra) # 80004866 <log_write>
  brelse(bp);
    80003778:	854a                	mv	a0,s2
    8000377a:	00000097          	auipc	ra,0x0
    8000377e:	e94080e7          	jalr	-364(ra) # 8000360e <brelse>
}
    80003782:	60e2                	ld	ra,24(sp)
    80003784:	6442                	ld	s0,16(sp)
    80003786:	64a2                	ld	s1,8(sp)
    80003788:	6902                	ld	s2,0(sp)
    8000378a:	6105                	addi	sp,sp,32
    8000378c:	8082                	ret
    panic("freeing free block");
    8000378e:	00005517          	auipc	a0,0x5
    80003792:	ee250513          	addi	a0,a0,-286 # 80008670 <syscalls+0x110>
    80003796:	ffffd097          	auipc	ra,0xffffd
    8000379a:	da6080e7          	jalr	-602(ra) # 8000053c <panic>

000000008000379e <balloc>:
{
    8000379e:	711d                	addi	sp,sp,-96
    800037a0:	ec86                	sd	ra,88(sp)
    800037a2:	e8a2                	sd	s0,80(sp)
    800037a4:	e4a6                	sd	s1,72(sp)
    800037a6:	e0ca                	sd	s2,64(sp)
    800037a8:	fc4e                	sd	s3,56(sp)
    800037aa:	f852                	sd	s4,48(sp)
    800037ac:	f456                	sd	s5,40(sp)
    800037ae:	f05a                	sd	s6,32(sp)
    800037b0:	ec5e                	sd	s7,24(sp)
    800037b2:	e862                	sd	s8,16(sp)
    800037b4:	e466                	sd	s9,8(sp)
    800037b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800037b8:	0045c797          	auipc	a5,0x45c
    800037bc:	a047a783          	lw	a5,-1532(a5) # 8045f1bc <sb+0x4>
    800037c0:	cff5                	beqz	a5,800038bc <balloc+0x11e>
    800037c2:	8baa                	mv	s7,a0
    800037c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800037c6:	0045cb17          	auipc	s6,0x45c
    800037ca:	9f2b0b13          	addi	s6,s6,-1550 # 8045f1b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800037d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800037d4:	6c89                	lui	s9,0x2
    800037d6:	a061                	j	8000385e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800037d8:	97ca                	add	a5,a5,s2
    800037da:	8e55                	or	a2,a2,a3
    800037dc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800037e0:	854a                	mv	a0,s2
    800037e2:	00001097          	auipc	ra,0x1
    800037e6:	084080e7          	jalr	132(ra) # 80004866 <log_write>
        brelse(bp);
    800037ea:	854a                	mv	a0,s2
    800037ec:	00000097          	auipc	ra,0x0
    800037f0:	e22080e7          	jalr	-478(ra) # 8000360e <brelse>
  bp = bread(dev, bno);
    800037f4:	85a6                	mv	a1,s1
    800037f6:	855e                	mv	a0,s7
    800037f8:	00000097          	auipc	ra,0x0
    800037fc:	ce6080e7          	jalr	-794(ra) # 800034de <bread>
    80003800:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003802:	40000613          	li	a2,1024
    80003806:	4581                	li	a1,0
    80003808:	05850513          	addi	a0,a0,88
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	66e080e7          	jalr	1646(ra) # 80000e7a <memset>
  log_write(bp);
    80003814:	854a                	mv	a0,s2
    80003816:	00001097          	auipc	ra,0x1
    8000381a:	050080e7          	jalr	80(ra) # 80004866 <log_write>
  brelse(bp);
    8000381e:	854a                	mv	a0,s2
    80003820:	00000097          	auipc	ra,0x0
    80003824:	dee080e7          	jalr	-530(ra) # 8000360e <brelse>
}
    80003828:	8526                	mv	a0,s1
    8000382a:	60e6                	ld	ra,88(sp)
    8000382c:	6446                	ld	s0,80(sp)
    8000382e:	64a6                	ld	s1,72(sp)
    80003830:	6906                	ld	s2,64(sp)
    80003832:	79e2                	ld	s3,56(sp)
    80003834:	7a42                	ld	s4,48(sp)
    80003836:	7aa2                	ld	s5,40(sp)
    80003838:	7b02                	ld	s6,32(sp)
    8000383a:	6be2                	ld	s7,24(sp)
    8000383c:	6c42                	ld	s8,16(sp)
    8000383e:	6ca2                	ld	s9,8(sp)
    80003840:	6125                	addi	sp,sp,96
    80003842:	8082                	ret
    brelse(bp);
    80003844:	854a                	mv	a0,s2
    80003846:	00000097          	auipc	ra,0x0
    8000384a:	dc8080e7          	jalr	-568(ra) # 8000360e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000384e:	015c87bb          	addw	a5,s9,s5
    80003852:	00078a9b          	sext.w	s5,a5
    80003856:	004b2703          	lw	a4,4(s6)
    8000385a:	06eaf163          	bgeu	s5,a4,800038bc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000385e:	41fad79b          	sraiw	a5,s5,0x1f
    80003862:	0137d79b          	srliw	a5,a5,0x13
    80003866:	015787bb          	addw	a5,a5,s5
    8000386a:	40d7d79b          	sraiw	a5,a5,0xd
    8000386e:	01cb2583          	lw	a1,28(s6)
    80003872:	9dbd                	addw	a1,a1,a5
    80003874:	855e                	mv	a0,s7
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	c68080e7          	jalr	-920(ra) # 800034de <bread>
    8000387e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003880:	004b2503          	lw	a0,4(s6)
    80003884:	000a849b          	sext.w	s1,s5
    80003888:	8762                	mv	a4,s8
    8000388a:	faa4fde3          	bgeu	s1,a0,80003844 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000388e:	00777693          	andi	a3,a4,7
    80003892:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003896:	41f7579b          	sraiw	a5,a4,0x1f
    8000389a:	01d7d79b          	srliw	a5,a5,0x1d
    8000389e:	9fb9                	addw	a5,a5,a4
    800038a0:	4037d79b          	sraiw	a5,a5,0x3
    800038a4:	00f90633          	add	a2,s2,a5
    800038a8:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800038ac:	00c6f5b3          	and	a1,a3,a2
    800038b0:	d585                	beqz	a1,800037d8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038b2:	2705                	addiw	a4,a4,1
    800038b4:	2485                	addiw	s1,s1,1
    800038b6:	fd471ae3          	bne	a4,s4,8000388a <balloc+0xec>
    800038ba:	b769                	j	80003844 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800038bc:	00005517          	auipc	a0,0x5
    800038c0:	dcc50513          	addi	a0,a0,-564 # 80008688 <syscalls+0x128>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	cd4080e7          	jalr	-812(ra) # 80000598 <printf>
  return 0;
    800038cc:	4481                	li	s1,0
    800038ce:	bfa9                	j	80003828 <balloc+0x8a>

00000000800038d0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800038d0:	7179                	addi	sp,sp,-48
    800038d2:	f406                	sd	ra,40(sp)
    800038d4:	f022                	sd	s0,32(sp)
    800038d6:	ec26                	sd	s1,24(sp)
    800038d8:	e84a                	sd	s2,16(sp)
    800038da:	e44e                	sd	s3,8(sp)
    800038dc:	e052                	sd	s4,0(sp)
    800038de:	1800                	addi	s0,sp,48
    800038e0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800038e2:	47ad                	li	a5,11
    800038e4:	02b7e863          	bltu	a5,a1,80003914 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800038e8:	02059793          	slli	a5,a1,0x20
    800038ec:	01e7d593          	srli	a1,a5,0x1e
    800038f0:	00b504b3          	add	s1,a0,a1
    800038f4:	0504a903          	lw	s2,80(s1)
    800038f8:	06091e63          	bnez	s2,80003974 <bmap+0xa4>
      addr = balloc(ip->dev);
    800038fc:	4108                	lw	a0,0(a0)
    800038fe:	00000097          	auipc	ra,0x0
    80003902:	ea0080e7          	jalr	-352(ra) # 8000379e <balloc>
    80003906:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000390a:	06090563          	beqz	s2,80003974 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000390e:	0524a823          	sw	s2,80(s1)
    80003912:	a08d                	j	80003974 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003914:	ff45849b          	addiw	s1,a1,-12
    80003918:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000391c:	0ff00793          	li	a5,255
    80003920:	08e7e563          	bltu	a5,a4,800039aa <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003924:	08052903          	lw	s2,128(a0)
    80003928:	00091d63          	bnez	s2,80003942 <bmap+0x72>
      addr = balloc(ip->dev);
    8000392c:	4108                	lw	a0,0(a0)
    8000392e:	00000097          	auipc	ra,0x0
    80003932:	e70080e7          	jalr	-400(ra) # 8000379e <balloc>
    80003936:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000393a:	02090d63          	beqz	s2,80003974 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000393e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003942:	85ca                	mv	a1,s2
    80003944:	0009a503          	lw	a0,0(s3)
    80003948:	00000097          	auipc	ra,0x0
    8000394c:	b96080e7          	jalr	-1130(ra) # 800034de <bread>
    80003950:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003952:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003956:	02049713          	slli	a4,s1,0x20
    8000395a:	01e75593          	srli	a1,a4,0x1e
    8000395e:	00b784b3          	add	s1,a5,a1
    80003962:	0004a903          	lw	s2,0(s1)
    80003966:	02090063          	beqz	s2,80003986 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000396a:	8552                	mv	a0,s4
    8000396c:	00000097          	auipc	ra,0x0
    80003970:	ca2080e7          	jalr	-862(ra) # 8000360e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003974:	854a                	mv	a0,s2
    80003976:	70a2                	ld	ra,40(sp)
    80003978:	7402                	ld	s0,32(sp)
    8000397a:	64e2                	ld	s1,24(sp)
    8000397c:	6942                	ld	s2,16(sp)
    8000397e:	69a2                	ld	s3,8(sp)
    80003980:	6a02                	ld	s4,0(sp)
    80003982:	6145                	addi	sp,sp,48
    80003984:	8082                	ret
      addr = balloc(ip->dev);
    80003986:	0009a503          	lw	a0,0(s3)
    8000398a:	00000097          	auipc	ra,0x0
    8000398e:	e14080e7          	jalr	-492(ra) # 8000379e <balloc>
    80003992:	0005091b          	sext.w	s2,a0
      if(addr){
    80003996:	fc090ae3          	beqz	s2,8000396a <bmap+0x9a>
        a[bn] = addr;
    8000399a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000399e:	8552                	mv	a0,s4
    800039a0:	00001097          	auipc	ra,0x1
    800039a4:	ec6080e7          	jalr	-314(ra) # 80004866 <log_write>
    800039a8:	b7c9                	j	8000396a <bmap+0x9a>
  panic("bmap: out of range");
    800039aa:	00005517          	auipc	a0,0x5
    800039ae:	cf650513          	addi	a0,a0,-778 # 800086a0 <syscalls+0x140>
    800039b2:	ffffd097          	auipc	ra,0xffffd
    800039b6:	b8a080e7          	jalr	-1142(ra) # 8000053c <panic>

00000000800039ba <iget>:
{
    800039ba:	7179                	addi	sp,sp,-48
    800039bc:	f406                	sd	ra,40(sp)
    800039be:	f022                	sd	s0,32(sp)
    800039c0:	ec26                	sd	s1,24(sp)
    800039c2:	e84a                	sd	s2,16(sp)
    800039c4:	e44e                	sd	s3,8(sp)
    800039c6:	e052                	sd	s4,0(sp)
    800039c8:	1800                	addi	s0,sp,48
    800039ca:	89aa                	mv	s3,a0
    800039cc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800039ce:	0045c517          	auipc	a0,0x45c
    800039d2:	80a50513          	addi	a0,a0,-2038 # 8045f1d8 <itable>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	3a8080e7          	jalr	936(ra) # 80000d7e <acquire>
  empty = 0;
    800039de:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039e0:	0045c497          	auipc	s1,0x45c
    800039e4:	81048493          	addi	s1,s1,-2032 # 8045f1f0 <itable+0x18>
    800039e8:	0045d697          	auipc	a3,0x45d
    800039ec:	29868693          	addi	a3,a3,664 # 80460c80 <log>
    800039f0:	a039                	j	800039fe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039f2:	02090b63          	beqz	s2,80003a28 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039f6:	08848493          	addi	s1,s1,136
    800039fa:	02d48a63          	beq	s1,a3,80003a2e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039fe:	449c                	lw	a5,8(s1)
    80003a00:	fef059e3          	blez	a5,800039f2 <iget+0x38>
    80003a04:	4098                	lw	a4,0(s1)
    80003a06:	ff3716e3          	bne	a4,s3,800039f2 <iget+0x38>
    80003a0a:	40d8                	lw	a4,4(s1)
    80003a0c:	ff4713e3          	bne	a4,s4,800039f2 <iget+0x38>
      ip->ref++;
    80003a10:	2785                	addiw	a5,a5,1
    80003a12:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003a14:	0045b517          	auipc	a0,0x45b
    80003a18:	7c450513          	addi	a0,a0,1988 # 8045f1d8 <itable>
    80003a1c:	ffffd097          	auipc	ra,0xffffd
    80003a20:	416080e7          	jalr	1046(ra) # 80000e32 <release>
      return ip;
    80003a24:	8926                	mv	s2,s1
    80003a26:	a03d                	j	80003a54 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003a28:	f7f9                	bnez	a5,800039f6 <iget+0x3c>
    80003a2a:	8926                	mv	s2,s1
    80003a2c:	b7e9                	j	800039f6 <iget+0x3c>
  if(empty == 0)
    80003a2e:	02090c63          	beqz	s2,80003a66 <iget+0xac>
  ip->dev = dev;
    80003a32:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003a36:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003a3a:	4785                	li	a5,1
    80003a3c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003a40:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003a44:	0045b517          	auipc	a0,0x45b
    80003a48:	79450513          	addi	a0,a0,1940 # 8045f1d8 <itable>
    80003a4c:	ffffd097          	auipc	ra,0xffffd
    80003a50:	3e6080e7          	jalr	998(ra) # 80000e32 <release>
}
    80003a54:	854a                	mv	a0,s2
    80003a56:	70a2                	ld	ra,40(sp)
    80003a58:	7402                	ld	s0,32(sp)
    80003a5a:	64e2                	ld	s1,24(sp)
    80003a5c:	6942                	ld	s2,16(sp)
    80003a5e:	69a2                	ld	s3,8(sp)
    80003a60:	6a02                	ld	s4,0(sp)
    80003a62:	6145                	addi	sp,sp,48
    80003a64:	8082                	ret
    panic("iget: no inodes");
    80003a66:	00005517          	auipc	a0,0x5
    80003a6a:	c5250513          	addi	a0,a0,-942 # 800086b8 <syscalls+0x158>
    80003a6e:	ffffd097          	auipc	ra,0xffffd
    80003a72:	ace080e7          	jalr	-1330(ra) # 8000053c <panic>

0000000080003a76 <fsinit>:
fsinit(int dev) {
    80003a76:	7179                	addi	sp,sp,-48
    80003a78:	f406                	sd	ra,40(sp)
    80003a7a:	f022                	sd	s0,32(sp)
    80003a7c:	ec26                	sd	s1,24(sp)
    80003a7e:	e84a                	sd	s2,16(sp)
    80003a80:	e44e                	sd	s3,8(sp)
    80003a82:	1800                	addi	s0,sp,48
    80003a84:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a86:	4585                	li	a1,1
    80003a88:	00000097          	auipc	ra,0x0
    80003a8c:	a56080e7          	jalr	-1450(ra) # 800034de <bread>
    80003a90:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a92:	0045b997          	auipc	s3,0x45b
    80003a96:	72698993          	addi	s3,s3,1830 # 8045f1b8 <sb>
    80003a9a:	02000613          	li	a2,32
    80003a9e:	05850593          	addi	a1,a0,88
    80003aa2:	854e                	mv	a0,s3
    80003aa4:	ffffd097          	auipc	ra,0xffffd
    80003aa8:	432080e7          	jalr	1074(ra) # 80000ed6 <memmove>
  brelse(bp);
    80003aac:	8526                	mv	a0,s1
    80003aae:	00000097          	auipc	ra,0x0
    80003ab2:	b60080e7          	jalr	-1184(ra) # 8000360e <brelse>
  if(sb.magic != FSMAGIC)
    80003ab6:	0009a703          	lw	a4,0(s3)
    80003aba:	102037b7          	lui	a5,0x10203
    80003abe:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003ac2:	02f71263          	bne	a4,a5,80003ae6 <fsinit+0x70>
  initlog(dev, &sb);
    80003ac6:	0045b597          	auipc	a1,0x45b
    80003aca:	6f258593          	addi	a1,a1,1778 # 8045f1b8 <sb>
    80003ace:	854a                	mv	a0,s2
    80003ad0:	00001097          	auipc	ra,0x1
    80003ad4:	b2c080e7          	jalr	-1236(ra) # 800045fc <initlog>
}
    80003ad8:	70a2                	ld	ra,40(sp)
    80003ada:	7402                	ld	s0,32(sp)
    80003adc:	64e2                	ld	s1,24(sp)
    80003ade:	6942                	ld	s2,16(sp)
    80003ae0:	69a2                	ld	s3,8(sp)
    80003ae2:	6145                	addi	sp,sp,48
    80003ae4:	8082                	ret
    panic("invalid file system");
    80003ae6:	00005517          	auipc	a0,0x5
    80003aea:	be250513          	addi	a0,a0,-1054 # 800086c8 <syscalls+0x168>
    80003aee:	ffffd097          	auipc	ra,0xffffd
    80003af2:	a4e080e7          	jalr	-1458(ra) # 8000053c <panic>

0000000080003af6 <iinit>:
{
    80003af6:	7179                	addi	sp,sp,-48
    80003af8:	f406                	sd	ra,40(sp)
    80003afa:	f022                	sd	s0,32(sp)
    80003afc:	ec26                	sd	s1,24(sp)
    80003afe:	e84a                	sd	s2,16(sp)
    80003b00:	e44e                	sd	s3,8(sp)
    80003b02:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003b04:	00005597          	auipc	a1,0x5
    80003b08:	bdc58593          	addi	a1,a1,-1060 # 800086e0 <syscalls+0x180>
    80003b0c:	0045b517          	auipc	a0,0x45b
    80003b10:	6cc50513          	addi	a0,a0,1740 # 8045f1d8 <itable>
    80003b14:	ffffd097          	auipc	ra,0xffffd
    80003b18:	1da080e7          	jalr	474(ra) # 80000cee <initlock>
  for(i = 0; i < NINODE; i++) {
    80003b1c:	0045b497          	auipc	s1,0x45b
    80003b20:	6e448493          	addi	s1,s1,1764 # 8045f200 <itable+0x28>
    80003b24:	0045d997          	auipc	s3,0x45d
    80003b28:	16c98993          	addi	s3,s3,364 # 80460c90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003b2c:	00005917          	auipc	s2,0x5
    80003b30:	bbc90913          	addi	s2,s2,-1092 # 800086e8 <syscalls+0x188>
    80003b34:	85ca                	mv	a1,s2
    80003b36:	8526                	mv	a0,s1
    80003b38:	00001097          	auipc	ra,0x1
    80003b3c:	e12080e7          	jalr	-494(ra) # 8000494a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003b40:	08848493          	addi	s1,s1,136
    80003b44:	ff3498e3          	bne	s1,s3,80003b34 <iinit+0x3e>
}
    80003b48:	70a2                	ld	ra,40(sp)
    80003b4a:	7402                	ld	s0,32(sp)
    80003b4c:	64e2                	ld	s1,24(sp)
    80003b4e:	6942                	ld	s2,16(sp)
    80003b50:	69a2                	ld	s3,8(sp)
    80003b52:	6145                	addi	sp,sp,48
    80003b54:	8082                	ret

0000000080003b56 <ialloc>:
{
    80003b56:	7139                	addi	sp,sp,-64
    80003b58:	fc06                	sd	ra,56(sp)
    80003b5a:	f822                	sd	s0,48(sp)
    80003b5c:	f426                	sd	s1,40(sp)
    80003b5e:	f04a                	sd	s2,32(sp)
    80003b60:	ec4e                	sd	s3,24(sp)
    80003b62:	e852                	sd	s4,16(sp)
    80003b64:	e456                	sd	s5,8(sp)
    80003b66:	e05a                	sd	s6,0(sp)
    80003b68:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b6a:	0045b717          	auipc	a4,0x45b
    80003b6e:	65a72703          	lw	a4,1626(a4) # 8045f1c4 <sb+0xc>
    80003b72:	4785                	li	a5,1
    80003b74:	04e7f863          	bgeu	a5,a4,80003bc4 <ialloc+0x6e>
    80003b78:	8aaa                	mv	s5,a0
    80003b7a:	8b2e                	mv	s6,a1
    80003b7c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b7e:	0045ba17          	auipc	s4,0x45b
    80003b82:	63aa0a13          	addi	s4,s4,1594 # 8045f1b8 <sb>
    80003b86:	00495593          	srli	a1,s2,0x4
    80003b8a:	018a2783          	lw	a5,24(s4)
    80003b8e:	9dbd                	addw	a1,a1,a5
    80003b90:	8556                	mv	a0,s5
    80003b92:	00000097          	auipc	ra,0x0
    80003b96:	94c080e7          	jalr	-1716(ra) # 800034de <bread>
    80003b9a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b9c:	05850993          	addi	s3,a0,88
    80003ba0:	00f97793          	andi	a5,s2,15
    80003ba4:	079a                	slli	a5,a5,0x6
    80003ba6:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ba8:	00099783          	lh	a5,0(s3)
    80003bac:	cf9d                	beqz	a5,80003bea <ialloc+0x94>
    brelse(bp);
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	a60080e7          	jalr	-1440(ra) # 8000360e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003bb6:	0905                	addi	s2,s2,1
    80003bb8:	00ca2703          	lw	a4,12(s4)
    80003bbc:	0009079b          	sext.w	a5,s2
    80003bc0:	fce7e3e3          	bltu	a5,a4,80003b86 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003bc4:	00005517          	auipc	a0,0x5
    80003bc8:	b2c50513          	addi	a0,a0,-1236 # 800086f0 <syscalls+0x190>
    80003bcc:	ffffd097          	auipc	ra,0xffffd
    80003bd0:	9cc080e7          	jalr	-1588(ra) # 80000598 <printf>
  return 0;
    80003bd4:	4501                	li	a0,0
}
    80003bd6:	70e2                	ld	ra,56(sp)
    80003bd8:	7442                	ld	s0,48(sp)
    80003bda:	74a2                	ld	s1,40(sp)
    80003bdc:	7902                	ld	s2,32(sp)
    80003bde:	69e2                	ld	s3,24(sp)
    80003be0:	6a42                	ld	s4,16(sp)
    80003be2:	6aa2                	ld	s5,8(sp)
    80003be4:	6b02                	ld	s6,0(sp)
    80003be6:	6121                	addi	sp,sp,64
    80003be8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003bea:	04000613          	li	a2,64
    80003bee:	4581                	li	a1,0
    80003bf0:	854e                	mv	a0,s3
    80003bf2:	ffffd097          	auipc	ra,0xffffd
    80003bf6:	288080e7          	jalr	648(ra) # 80000e7a <memset>
      dip->type = type;
    80003bfa:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003bfe:	8526                	mv	a0,s1
    80003c00:	00001097          	auipc	ra,0x1
    80003c04:	c66080e7          	jalr	-922(ra) # 80004866 <log_write>
      brelse(bp);
    80003c08:	8526                	mv	a0,s1
    80003c0a:	00000097          	auipc	ra,0x0
    80003c0e:	a04080e7          	jalr	-1532(ra) # 8000360e <brelse>
      return iget(dev, inum);
    80003c12:	0009059b          	sext.w	a1,s2
    80003c16:	8556                	mv	a0,s5
    80003c18:	00000097          	auipc	ra,0x0
    80003c1c:	da2080e7          	jalr	-606(ra) # 800039ba <iget>
    80003c20:	bf5d                	j	80003bd6 <ialloc+0x80>

0000000080003c22 <iupdate>:
{
    80003c22:	1101                	addi	sp,sp,-32
    80003c24:	ec06                	sd	ra,24(sp)
    80003c26:	e822                	sd	s0,16(sp)
    80003c28:	e426                	sd	s1,8(sp)
    80003c2a:	e04a                	sd	s2,0(sp)
    80003c2c:	1000                	addi	s0,sp,32
    80003c2e:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c30:	415c                	lw	a5,4(a0)
    80003c32:	0047d79b          	srliw	a5,a5,0x4
    80003c36:	0045b597          	auipc	a1,0x45b
    80003c3a:	59a5a583          	lw	a1,1434(a1) # 8045f1d0 <sb+0x18>
    80003c3e:	9dbd                	addw	a1,a1,a5
    80003c40:	4108                	lw	a0,0(a0)
    80003c42:	00000097          	auipc	ra,0x0
    80003c46:	89c080e7          	jalr	-1892(ra) # 800034de <bread>
    80003c4a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c4c:	05850793          	addi	a5,a0,88
    80003c50:	40d8                	lw	a4,4(s1)
    80003c52:	8b3d                	andi	a4,a4,15
    80003c54:	071a                	slli	a4,a4,0x6
    80003c56:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c58:	04449703          	lh	a4,68(s1)
    80003c5c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c60:	04649703          	lh	a4,70(s1)
    80003c64:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c68:	04849703          	lh	a4,72(s1)
    80003c6c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c70:	04a49703          	lh	a4,74(s1)
    80003c74:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c78:	44f8                	lw	a4,76(s1)
    80003c7a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c7c:	03400613          	li	a2,52
    80003c80:	05048593          	addi	a1,s1,80
    80003c84:	00c78513          	addi	a0,a5,12
    80003c88:	ffffd097          	auipc	ra,0xffffd
    80003c8c:	24e080e7          	jalr	590(ra) # 80000ed6 <memmove>
  log_write(bp);
    80003c90:	854a                	mv	a0,s2
    80003c92:	00001097          	auipc	ra,0x1
    80003c96:	bd4080e7          	jalr	-1068(ra) # 80004866 <log_write>
  brelse(bp);
    80003c9a:	854a                	mv	a0,s2
    80003c9c:	00000097          	auipc	ra,0x0
    80003ca0:	972080e7          	jalr	-1678(ra) # 8000360e <brelse>
}
    80003ca4:	60e2                	ld	ra,24(sp)
    80003ca6:	6442                	ld	s0,16(sp)
    80003ca8:	64a2                	ld	s1,8(sp)
    80003caa:	6902                	ld	s2,0(sp)
    80003cac:	6105                	addi	sp,sp,32
    80003cae:	8082                	ret

0000000080003cb0 <idup>:
{
    80003cb0:	1101                	addi	sp,sp,-32
    80003cb2:	ec06                	sd	ra,24(sp)
    80003cb4:	e822                	sd	s0,16(sp)
    80003cb6:	e426                	sd	s1,8(sp)
    80003cb8:	1000                	addi	s0,sp,32
    80003cba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cbc:	0045b517          	auipc	a0,0x45b
    80003cc0:	51c50513          	addi	a0,a0,1308 # 8045f1d8 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	0ba080e7          	jalr	186(ra) # 80000d7e <acquire>
  ip->ref++;
    80003ccc:	449c                	lw	a5,8(s1)
    80003cce:	2785                	addiw	a5,a5,1
    80003cd0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cd2:	0045b517          	auipc	a0,0x45b
    80003cd6:	50650513          	addi	a0,a0,1286 # 8045f1d8 <itable>
    80003cda:	ffffd097          	auipc	ra,0xffffd
    80003cde:	158080e7          	jalr	344(ra) # 80000e32 <release>
}
    80003ce2:	8526                	mv	a0,s1
    80003ce4:	60e2                	ld	ra,24(sp)
    80003ce6:	6442                	ld	s0,16(sp)
    80003ce8:	64a2                	ld	s1,8(sp)
    80003cea:	6105                	addi	sp,sp,32
    80003cec:	8082                	ret

0000000080003cee <ilock>:
{
    80003cee:	1101                	addi	sp,sp,-32
    80003cf0:	ec06                	sd	ra,24(sp)
    80003cf2:	e822                	sd	s0,16(sp)
    80003cf4:	e426                	sd	s1,8(sp)
    80003cf6:	e04a                	sd	s2,0(sp)
    80003cf8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003cfa:	c115                	beqz	a0,80003d1e <ilock+0x30>
    80003cfc:	84aa                	mv	s1,a0
    80003cfe:	451c                	lw	a5,8(a0)
    80003d00:	00f05f63          	blez	a5,80003d1e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003d04:	0541                	addi	a0,a0,16
    80003d06:	00001097          	auipc	ra,0x1
    80003d0a:	c7e080e7          	jalr	-898(ra) # 80004984 <acquiresleep>
  if(ip->valid == 0){
    80003d0e:	40bc                	lw	a5,64(s1)
    80003d10:	cf99                	beqz	a5,80003d2e <ilock+0x40>
}
    80003d12:	60e2                	ld	ra,24(sp)
    80003d14:	6442                	ld	s0,16(sp)
    80003d16:	64a2                	ld	s1,8(sp)
    80003d18:	6902                	ld	s2,0(sp)
    80003d1a:	6105                	addi	sp,sp,32
    80003d1c:	8082                	ret
    panic("ilock");
    80003d1e:	00005517          	auipc	a0,0x5
    80003d22:	9ea50513          	addi	a0,a0,-1558 # 80008708 <syscalls+0x1a8>
    80003d26:	ffffd097          	auipc	ra,0xffffd
    80003d2a:	816080e7          	jalr	-2026(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2e:	40dc                	lw	a5,4(s1)
    80003d30:	0047d79b          	srliw	a5,a5,0x4
    80003d34:	0045b597          	auipc	a1,0x45b
    80003d38:	49c5a583          	lw	a1,1180(a1) # 8045f1d0 <sb+0x18>
    80003d3c:	9dbd                	addw	a1,a1,a5
    80003d3e:	4088                	lw	a0,0(s1)
    80003d40:	fffff097          	auipc	ra,0xfffff
    80003d44:	79e080e7          	jalr	1950(ra) # 800034de <bread>
    80003d48:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d4a:	05850593          	addi	a1,a0,88
    80003d4e:	40dc                	lw	a5,4(s1)
    80003d50:	8bbd                	andi	a5,a5,15
    80003d52:	079a                	slli	a5,a5,0x6
    80003d54:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d56:	00059783          	lh	a5,0(a1)
    80003d5a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d5e:	00259783          	lh	a5,2(a1)
    80003d62:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d66:	00459783          	lh	a5,4(a1)
    80003d6a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d6e:	00659783          	lh	a5,6(a1)
    80003d72:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d76:	459c                	lw	a5,8(a1)
    80003d78:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d7a:	03400613          	li	a2,52
    80003d7e:	05b1                	addi	a1,a1,12
    80003d80:	05048513          	addi	a0,s1,80
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	152080e7          	jalr	338(ra) # 80000ed6 <memmove>
    brelse(bp);
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00000097          	auipc	ra,0x0
    80003d92:	880080e7          	jalr	-1920(ra) # 8000360e <brelse>
    ip->valid = 1;
    80003d96:	4785                	li	a5,1
    80003d98:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d9a:	04449783          	lh	a5,68(s1)
    80003d9e:	fbb5                	bnez	a5,80003d12 <ilock+0x24>
      panic("ilock: no type");
    80003da0:	00005517          	auipc	a0,0x5
    80003da4:	97050513          	addi	a0,a0,-1680 # 80008710 <syscalls+0x1b0>
    80003da8:	ffffc097          	auipc	ra,0xffffc
    80003dac:	794080e7          	jalr	1940(ra) # 8000053c <panic>

0000000080003db0 <iunlock>:
{
    80003db0:	1101                	addi	sp,sp,-32
    80003db2:	ec06                	sd	ra,24(sp)
    80003db4:	e822                	sd	s0,16(sp)
    80003db6:	e426                	sd	s1,8(sp)
    80003db8:	e04a                	sd	s2,0(sp)
    80003dba:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003dbc:	c905                	beqz	a0,80003dec <iunlock+0x3c>
    80003dbe:	84aa                	mv	s1,a0
    80003dc0:	01050913          	addi	s2,a0,16
    80003dc4:	854a                	mv	a0,s2
    80003dc6:	00001097          	auipc	ra,0x1
    80003dca:	c58080e7          	jalr	-936(ra) # 80004a1e <holdingsleep>
    80003dce:	cd19                	beqz	a0,80003dec <iunlock+0x3c>
    80003dd0:	449c                	lw	a5,8(s1)
    80003dd2:	00f05d63          	blez	a5,80003dec <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003dd6:	854a                	mv	a0,s2
    80003dd8:	00001097          	auipc	ra,0x1
    80003ddc:	c02080e7          	jalr	-1022(ra) # 800049da <releasesleep>
}
    80003de0:	60e2                	ld	ra,24(sp)
    80003de2:	6442                	ld	s0,16(sp)
    80003de4:	64a2                	ld	s1,8(sp)
    80003de6:	6902                	ld	s2,0(sp)
    80003de8:	6105                	addi	sp,sp,32
    80003dea:	8082                	ret
    panic("iunlock");
    80003dec:	00005517          	auipc	a0,0x5
    80003df0:	93450513          	addi	a0,a0,-1740 # 80008720 <syscalls+0x1c0>
    80003df4:	ffffc097          	auipc	ra,0xffffc
    80003df8:	748080e7          	jalr	1864(ra) # 8000053c <panic>

0000000080003dfc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003dfc:	7179                	addi	sp,sp,-48
    80003dfe:	f406                	sd	ra,40(sp)
    80003e00:	f022                	sd	s0,32(sp)
    80003e02:	ec26                	sd	s1,24(sp)
    80003e04:	e84a                	sd	s2,16(sp)
    80003e06:	e44e                	sd	s3,8(sp)
    80003e08:	e052                	sd	s4,0(sp)
    80003e0a:	1800                	addi	s0,sp,48
    80003e0c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003e0e:	05050493          	addi	s1,a0,80
    80003e12:	08050913          	addi	s2,a0,128
    80003e16:	a021                	j	80003e1e <itrunc+0x22>
    80003e18:	0491                	addi	s1,s1,4
    80003e1a:	01248d63          	beq	s1,s2,80003e34 <itrunc+0x38>
    if(ip->addrs[i]){
    80003e1e:	408c                	lw	a1,0(s1)
    80003e20:	dde5                	beqz	a1,80003e18 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003e22:	0009a503          	lw	a0,0(s3)
    80003e26:	00000097          	auipc	ra,0x0
    80003e2a:	8fc080e7          	jalr	-1796(ra) # 80003722 <bfree>
      ip->addrs[i] = 0;
    80003e2e:	0004a023          	sw	zero,0(s1)
    80003e32:	b7dd                	j	80003e18 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003e34:	0809a583          	lw	a1,128(s3)
    80003e38:	e185                	bnez	a1,80003e58 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003e3a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003e3e:	854e                	mv	a0,s3
    80003e40:	00000097          	auipc	ra,0x0
    80003e44:	de2080e7          	jalr	-542(ra) # 80003c22 <iupdate>
}
    80003e48:	70a2                	ld	ra,40(sp)
    80003e4a:	7402                	ld	s0,32(sp)
    80003e4c:	64e2                	ld	s1,24(sp)
    80003e4e:	6942                	ld	s2,16(sp)
    80003e50:	69a2                	ld	s3,8(sp)
    80003e52:	6a02                	ld	s4,0(sp)
    80003e54:	6145                	addi	sp,sp,48
    80003e56:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e58:	0009a503          	lw	a0,0(s3)
    80003e5c:	fffff097          	auipc	ra,0xfffff
    80003e60:	682080e7          	jalr	1666(ra) # 800034de <bread>
    80003e64:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e66:	05850493          	addi	s1,a0,88
    80003e6a:	45850913          	addi	s2,a0,1112
    80003e6e:	a021                	j	80003e76 <itrunc+0x7a>
    80003e70:	0491                	addi	s1,s1,4
    80003e72:	01248b63          	beq	s1,s2,80003e88 <itrunc+0x8c>
      if(a[j])
    80003e76:	408c                	lw	a1,0(s1)
    80003e78:	dde5                	beqz	a1,80003e70 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e7a:	0009a503          	lw	a0,0(s3)
    80003e7e:	00000097          	auipc	ra,0x0
    80003e82:	8a4080e7          	jalr	-1884(ra) # 80003722 <bfree>
    80003e86:	b7ed                	j	80003e70 <itrunc+0x74>
    brelse(bp);
    80003e88:	8552                	mv	a0,s4
    80003e8a:	fffff097          	auipc	ra,0xfffff
    80003e8e:	784080e7          	jalr	1924(ra) # 8000360e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e92:	0809a583          	lw	a1,128(s3)
    80003e96:	0009a503          	lw	a0,0(s3)
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	888080e7          	jalr	-1912(ra) # 80003722 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ea2:	0809a023          	sw	zero,128(s3)
    80003ea6:	bf51                	j	80003e3a <itrunc+0x3e>

0000000080003ea8 <iput>:
{
    80003ea8:	1101                	addi	sp,sp,-32
    80003eaa:	ec06                	sd	ra,24(sp)
    80003eac:	e822                	sd	s0,16(sp)
    80003eae:	e426                	sd	s1,8(sp)
    80003eb0:	e04a                	sd	s2,0(sp)
    80003eb2:	1000                	addi	s0,sp,32
    80003eb4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003eb6:	0045b517          	auipc	a0,0x45b
    80003eba:	32250513          	addi	a0,a0,802 # 8045f1d8 <itable>
    80003ebe:	ffffd097          	auipc	ra,0xffffd
    80003ec2:	ec0080e7          	jalr	-320(ra) # 80000d7e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ec6:	4498                	lw	a4,8(s1)
    80003ec8:	4785                	li	a5,1
    80003eca:	02f70363          	beq	a4,a5,80003ef0 <iput+0x48>
  ip->ref--;
    80003ece:	449c                	lw	a5,8(s1)
    80003ed0:	37fd                	addiw	a5,a5,-1
    80003ed2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ed4:	0045b517          	auipc	a0,0x45b
    80003ed8:	30450513          	addi	a0,a0,772 # 8045f1d8 <itable>
    80003edc:	ffffd097          	auipc	ra,0xffffd
    80003ee0:	f56080e7          	jalr	-170(ra) # 80000e32 <release>
}
    80003ee4:	60e2                	ld	ra,24(sp)
    80003ee6:	6442                	ld	s0,16(sp)
    80003ee8:	64a2                	ld	s1,8(sp)
    80003eea:	6902                	ld	s2,0(sp)
    80003eec:	6105                	addi	sp,sp,32
    80003eee:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ef0:	40bc                	lw	a5,64(s1)
    80003ef2:	dff1                	beqz	a5,80003ece <iput+0x26>
    80003ef4:	04a49783          	lh	a5,74(s1)
    80003ef8:	fbf9                	bnez	a5,80003ece <iput+0x26>
    acquiresleep(&ip->lock);
    80003efa:	01048913          	addi	s2,s1,16
    80003efe:	854a                	mv	a0,s2
    80003f00:	00001097          	auipc	ra,0x1
    80003f04:	a84080e7          	jalr	-1404(ra) # 80004984 <acquiresleep>
    release(&itable.lock);
    80003f08:	0045b517          	auipc	a0,0x45b
    80003f0c:	2d050513          	addi	a0,a0,720 # 8045f1d8 <itable>
    80003f10:	ffffd097          	auipc	ra,0xffffd
    80003f14:	f22080e7          	jalr	-222(ra) # 80000e32 <release>
    itrunc(ip);
    80003f18:	8526                	mv	a0,s1
    80003f1a:	00000097          	auipc	ra,0x0
    80003f1e:	ee2080e7          	jalr	-286(ra) # 80003dfc <itrunc>
    ip->type = 0;
    80003f22:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003f26:	8526                	mv	a0,s1
    80003f28:	00000097          	auipc	ra,0x0
    80003f2c:	cfa080e7          	jalr	-774(ra) # 80003c22 <iupdate>
    ip->valid = 0;
    80003f30:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003f34:	854a                	mv	a0,s2
    80003f36:	00001097          	auipc	ra,0x1
    80003f3a:	aa4080e7          	jalr	-1372(ra) # 800049da <releasesleep>
    acquire(&itable.lock);
    80003f3e:	0045b517          	auipc	a0,0x45b
    80003f42:	29a50513          	addi	a0,a0,666 # 8045f1d8 <itable>
    80003f46:	ffffd097          	auipc	ra,0xffffd
    80003f4a:	e38080e7          	jalr	-456(ra) # 80000d7e <acquire>
    80003f4e:	b741                	j	80003ece <iput+0x26>

0000000080003f50 <iunlockput>:
{
    80003f50:	1101                	addi	sp,sp,-32
    80003f52:	ec06                	sd	ra,24(sp)
    80003f54:	e822                	sd	s0,16(sp)
    80003f56:	e426                	sd	s1,8(sp)
    80003f58:	1000                	addi	s0,sp,32
    80003f5a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f5c:	00000097          	auipc	ra,0x0
    80003f60:	e54080e7          	jalr	-428(ra) # 80003db0 <iunlock>
  iput(ip);
    80003f64:	8526                	mv	a0,s1
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	f42080e7          	jalr	-190(ra) # 80003ea8 <iput>
}
    80003f6e:	60e2                	ld	ra,24(sp)
    80003f70:	6442                	ld	s0,16(sp)
    80003f72:	64a2                	ld	s1,8(sp)
    80003f74:	6105                	addi	sp,sp,32
    80003f76:	8082                	ret

0000000080003f78 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f78:	1141                	addi	sp,sp,-16
    80003f7a:	e422                	sd	s0,8(sp)
    80003f7c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f7e:	411c                	lw	a5,0(a0)
    80003f80:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f82:	415c                	lw	a5,4(a0)
    80003f84:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f86:	04451783          	lh	a5,68(a0)
    80003f8a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f8e:	04a51783          	lh	a5,74(a0)
    80003f92:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f96:	04c56783          	lwu	a5,76(a0)
    80003f9a:	e99c                	sd	a5,16(a1)
}
    80003f9c:	6422                	ld	s0,8(sp)
    80003f9e:	0141                	addi	sp,sp,16
    80003fa0:	8082                	ret

0000000080003fa2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fa2:	457c                	lw	a5,76(a0)
    80003fa4:	0ed7e963          	bltu	a5,a3,80004096 <readi+0xf4>
{
    80003fa8:	7159                	addi	sp,sp,-112
    80003faa:	f486                	sd	ra,104(sp)
    80003fac:	f0a2                	sd	s0,96(sp)
    80003fae:	eca6                	sd	s1,88(sp)
    80003fb0:	e8ca                	sd	s2,80(sp)
    80003fb2:	e4ce                	sd	s3,72(sp)
    80003fb4:	e0d2                	sd	s4,64(sp)
    80003fb6:	fc56                	sd	s5,56(sp)
    80003fb8:	f85a                	sd	s6,48(sp)
    80003fba:	f45e                	sd	s7,40(sp)
    80003fbc:	f062                	sd	s8,32(sp)
    80003fbe:	ec66                	sd	s9,24(sp)
    80003fc0:	e86a                	sd	s10,16(sp)
    80003fc2:	e46e                	sd	s11,8(sp)
    80003fc4:	1880                	addi	s0,sp,112
    80003fc6:	8b2a                	mv	s6,a0
    80003fc8:	8bae                	mv	s7,a1
    80003fca:	8a32                	mv	s4,a2
    80003fcc:	84b6                	mv	s1,a3
    80003fce:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003fd0:	9f35                	addw	a4,a4,a3
    return 0;
    80003fd2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003fd4:	0ad76063          	bltu	a4,a3,80004074 <readi+0xd2>
  if(off + n > ip->size)
    80003fd8:	00e7f463          	bgeu	a5,a4,80003fe0 <readi+0x3e>
    n = ip->size - off;
    80003fdc:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fe0:	0a0a8963          	beqz	s5,80004092 <readi+0xf0>
    80003fe4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fe6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003fea:	5c7d                	li	s8,-1
    80003fec:	a82d                	j	80004026 <readi+0x84>
    80003fee:	020d1d93          	slli	s11,s10,0x20
    80003ff2:	020ddd93          	srli	s11,s11,0x20
    80003ff6:	05890613          	addi	a2,s2,88
    80003ffa:	86ee                	mv	a3,s11
    80003ffc:	963a                	add	a2,a2,a4
    80003ffe:	85d2                	mv	a1,s4
    80004000:	855e                	mv	a0,s7
    80004002:	fffff097          	auipc	ra,0xfffff
    80004006:	86c080e7          	jalr	-1940(ra) # 8000286e <either_copyout>
    8000400a:	05850d63          	beq	a0,s8,80004064 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000400e:	854a                	mv	a0,s2
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	5fe080e7          	jalr	1534(ra) # 8000360e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004018:	013d09bb          	addw	s3,s10,s3
    8000401c:	009d04bb          	addw	s1,s10,s1
    80004020:	9a6e                	add	s4,s4,s11
    80004022:	0559f763          	bgeu	s3,s5,80004070 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004026:	00a4d59b          	srliw	a1,s1,0xa
    8000402a:	855a                	mv	a0,s6
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	8a4080e7          	jalr	-1884(ra) # 800038d0 <bmap>
    80004034:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004038:	cd85                	beqz	a1,80004070 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000403a:	000b2503          	lw	a0,0(s6)
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	4a0080e7          	jalr	1184(ra) # 800034de <bread>
    80004046:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004048:	3ff4f713          	andi	a4,s1,1023
    8000404c:	40ec87bb          	subw	a5,s9,a4
    80004050:	413a86bb          	subw	a3,s5,s3
    80004054:	8d3e                	mv	s10,a5
    80004056:	2781                	sext.w	a5,a5
    80004058:	0006861b          	sext.w	a2,a3
    8000405c:	f8f679e3          	bgeu	a2,a5,80003fee <readi+0x4c>
    80004060:	8d36                	mv	s10,a3
    80004062:	b771                	j	80003fee <readi+0x4c>
      brelse(bp);
    80004064:	854a                	mv	a0,s2
    80004066:	fffff097          	auipc	ra,0xfffff
    8000406a:	5a8080e7          	jalr	1448(ra) # 8000360e <brelse>
      tot = -1;
    8000406e:	59fd                	li	s3,-1
  }
  return tot;
    80004070:	0009851b          	sext.w	a0,s3
}
    80004074:	70a6                	ld	ra,104(sp)
    80004076:	7406                	ld	s0,96(sp)
    80004078:	64e6                	ld	s1,88(sp)
    8000407a:	6946                	ld	s2,80(sp)
    8000407c:	69a6                	ld	s3,72(sp)
    8000407e:	6a06                	ld	s4,64(sp)
    80004080:	7ae2                	ld	s5,56(sp)
    80004082:	7b42                	ld	s6,48(sp)
    80004084:	7ba2                	ld	s7,40(sp)
    80004086:	7c02                	ld	s8,32(sp)
    80004088:	6ce2                	ld	s9,24(sp)
    8000408a:	6d42                	ld	s10,16(sp)
    8000408c:	6da2                	ld	s11,8(sp)
    8000408e:	6165                	addi	sp,sp,112
    80004090:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004092:	89d6                	mv	s3,s5
    80004094:	bff1                	j	80004070 <readi+0xce>
    return 0;
    80004096:	4501                	li	a0,0
}
    80004098:	8082                	ret

000000008000409a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409a:	457c                	lw	a5,76(a0)
    8000409c:	10d7e863          	bltu	a5,a3,800041ac <writei+0x112>
{
    800040a0:	7159                	addi	sp,sp,-112
    800040a2:	f486                	sd	ra,104(sp)
    800040a4:	f0a2                	sd	s0,96(sp)
    800040a6:	eca6                	sd	s1,88(sp)
    800040a8:	e8ca                	sd	s2,80(sp)
    800040aa:	e4ce                	sd	s3,72(sp)
    800040ac:	e0d2                	sd	s4,64(sp)
    800040ae:	fc56                	sd	s5,56(sp)
    800040b0:	f85a                	sd	s6,48(sp)
    800040b2:	f45e                	sd	s7,40(sp)
    800040b4:	f062                	sd	s8,32(sp)
    800040b6:	ec66                	sd	s9,24(sp)
    800040b8:	e86a                	sd	s10,16(sp)
    800040ba:	e46e                	sd	s11,8(sp)
    800040bc:	1880                	addi	s0,sp,112
    800040be:	8aaa                	mv	s5,a0
    800040c0:	8bae                	mv	s7,a1
    800040c2:	8a32                	mv	s4,a2
    800040c4:	8936                	mv	s2,a3
    800040c6:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800040c8:	00e687bb          	addw	a5,a3,a4
    800040cc:	0ed7e263          	bltu	a5,a3,800041b0 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800040d0:	00043737          	lui	a4,0x43
    800040d4:	0ef76063          	bltu	a4,a5,800041b4 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d8:	0c0b0863          	beqz	s6,800041a8 <writei+0x10e>
    800040dc:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040de:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800040e2:	5c7d                	li	s8,-1
    800040e4:	a091                	j	80004128 <writei+0x8e>
    800040e6:	020d1d93          	slli	s11,s10,0x20
    800040ea:	020ddd93          	srli	s11,s11,0x20
    800040ee:	05848513          	addi	a0,s1,88
    800040f2:	86ee                	mv	a3,s11
    800040f4:	8652                	mv	a2,s4
    800040f6:	85de                	mv	a1,s7
    800040f8:	953a                	add	a0,a0,a4
    800040fa:	ffffe097          	auipc	ra,0xffffe
    800040fe:	7ca080e7          	jalr	1994(ra) # 800028c4 <either_copyin>
    80004102:	07850263          	beq	a0,s8,80004166 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004106:	8526                	mv	a0,s1
    80004108:	00000097          	auipc	ra,0x0
    8000410c:	75e080e7          	jalr	1886(ra) # 80004866 <log_write>
    brelse(bp);
    80004110:	8526                	mv	a0,s1
    80004112:	fffff097          	auipc	ra,0xfffff
    80004116:	4fc080e7          	jalr	1276(ra) # 8000360e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000411a:	013d09bb          	addw	s3,s10,s3
    8000411e:	012d093b          	addw	s2,s10,s2
    80004122:	9a6e                	add	s4,s4,s11
    80004124:	0569f663          	bgeu	s3,s6,80004170 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004128:	00a9559b          	srliw	a1,s2,0xa
    8000412c:	8556                	mv	a0,s5
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	7a2080e7          	jalr	1954(ra) # 800038d0 <bmap>
    80004136:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000413a:	c99d                	beqz	a1,80004170 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000413c:	000aa503          	lw	a0,0(s5)
    80004140:	fffff097          	auipc	ra,0xfffff
    80004144:	39e080e7          	jalr	926(ra) # 800034de <bread>
    80004148:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000414a:	3ff97713          	andi	a4,s2,1023
    8000414e:	40ec87bb          	subw	a5,s9,a4
    80004152:	413b06bb          	subw	a3,s6,s3
    80004156:	8d3e                	mv	s10,a5
    80004158:	2781                	sext.w	a5,a5
    8000415a:	0006861b          	sext.w	a2,a3
    8000415e:	f8f674e3          	bgeu	a2,a5,800040e6 <writei+0x4c>
    80004162:	8d36                	mv	s10,a3
    80004164:	b749                	j	800040e6 <writei+0x4c>
      brelse(bp);
    80004166:	8526                	mv	a0,s1
    80004168:	fffff097          	auipc	ra,0xfffff
    8000416c:	4a6080e7          	jalr	1190(ra) # 8000360e <brelse>
  }

  if(off > ip->size)
    80004170:	04caa783          	lw	a5,76(s5)
    80004174:	0127f463          	bgeu	a5,s2,8000417c <writei+0xe2>
    ip->size = off;
    80004178:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000417c:	8556                	mv	a0,s5
    8000417e:	00000097          	auipc	ra,0x0
    80004182:	aa4080e7          	jalr	-1372(ra) # 80003c22 <iupdate>

  return tot;
    80004186:	0009851b          	sext.w	a0,s3
}
    8000418a:	70a6                	ld	ra,104(sp)
    8000418c:	7406                	ld	s0,96(sp)
    8000418e:	64e6                	ld	s1,88(sp)
    80004190:	6946                	ld	s2,80(sp)
    80004192:	69a6                	ld	s3,72(sp)
    80004194:	6a06                	ld	s4,64(sp)
    80004196:	7ae2                	ld	s5,56(sp)
    80004198:	7b42                	ld	s6,48(sp)
    8000419a:	7ba2                	ld	s7,40(sp)
    8000419c:	7c02                	ld	s8,32(sp)
    8000419e:	6ce2                	ld	s9,24(sp)
    800041a0:	6d42                	ld	s10,16(sp)
    800041a2:	6da2                	ld	s11,8(sp)
    800041a4:	6165                	addi	sp,sp,112
    800041a6:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a8:	89da                	mv	s3,s6
    800041aa:	bfc9                	j	8000417c <writei+0xe2>
    return -1;
    800041ac:	557d                	li	a0,-1
}
    800041ae:	8082                	ret
    return -1;
    800041b0:	557d                	li	a0,-1
    800041b2:	bfe1                	j	8000418a <writei+0xf0>
    return -1;
    800041b4:	557d                	li	a0,-1
    800041b6:	bfd1                	j	8000418a <writei+0xf0>

00000000800041b8 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800041b8:	1141                	addi	sp,sp,-16
    800041ba:	e406                	sd	ra,8(sp)
    800041bc:	e022                	sd	s0,0(sp)
    800041be:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800041c0:	4639                	li	a2,14
    800041c2:	ffffd097          	auipc	ra,0xffffd
    800041c6:	d88080e7          	jalr	-632(ra) # 80000f4a <strncmp>
}
    800041ca:	60a2                	ld	ra,8(sp)
    800041cc:	6402                	ld	s0,0(sp)
    800041ce:	0141                	addi	sp,sp,16
    800041d0:	8082                	ret

00000000800041d2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800041d2:	7139                	addi	sp,sp,-64
    800041d4:	fc06                	sd	ra,56(sp)
    800041d6:	f822                	sd	s0,48(sp)
    800041d8:	f426                	sd	s1,40(sp)
    800041da:	f04a                	sd	s2,32(sp)
    800041dc:	ec4e                	sd	s3,24(sp)
    800041de:	e852                	sd	s4,16(sp)
    800041e0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800041e2:	04451703          	lh	a4,68(a0)
    800041e6:	4785                	li	a5,1
    800041e8:	00f71a63          	bne	a4,a5,800041fc <dirlookup+0x2a>
    800041ec:	892a                	mv	s2,a0
    800041ee:	89ae                	mv	s3,a1
    800041f0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f2:	457c                	lw	a5,76(a0)
    800041f4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041f6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041f8:	e79d                	bnez	a5,80004226 <dirlookup+0x54>
    800041fa:	a8a5                	j	80004272 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041fc:	00004517          	auipc	a0,0x4
    80004200:	52c50513          	addi	a0,a0,1324 # 80008728 <syscalls+0x1c8>
    80004204:	ffffc097          	auipc	ra,0xffffc
    80004208:	338080e7          	jalr	824(ra) # 8000053c <panic>
      panic("dirlookup read");
    8000420c:	00004517          	auipc	a0,0x4
    80004210:	53450513          	addi	a0,a0,1332 # 80008740 <syscalls+0x1e0>
    80004214:	ffffc097          	auipc	ra,0xffffc
    80004218:	328080e7          	jalr	808(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000421c:	24c1                	addiw	s1,s1,16
    8000421e:	04c92783          	lw	a5,76(s2)
    80004222:	04f4f763          	bgeu	s1,a5,80004270 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004226:	4741                	li	a4,16
    80004228:	86a6                	mv	a3,s1
    8000422a:	fc040613          	addi	a2,s0,-64
    8000422e:	4581                	li	a1,0
    80004230:	854a                	mv	a0,s2
    80004232:	00000097          	auipc	ra,0x0
    80004236:	d70080e7          	jalr	-656(ra) # 80003fa2 <readi>
    8000423a:	47c1                	li	a5,16
    8000423c:	fcf518e3          	bne	a0,a5,8000420c <dirlookup+0x3a>
    if(de.inum == 0)
    80004240:	fc045783          	lhu	a5,-64(s0)
    80004244:	dfe1                	beqz	a5,8000421c <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004246:	fc240593          	addi	a1,s0,-62
    8000424a:	854e                	mv	a0,s3
    8000424c:	00000097          	auipc	ra,0x0
    80004250:	f6c080e7          	jalr	-148(ra) # 800041b8 <namecmp>
    80004254:	f561                	bnez	a0,8000421c <dirlookup+0x4a>
      if(poff)
    80004256:	000a0463          	beqz	s4,8000425e <dirlookup+0x8c>
        *poff = off;
    8000425a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000425e:	fc045583          	lhu	a1,-64(s0)
    80004262:	00092503          	lw	a0,0(s2)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	754080e7          	jalr	1876(ra) # 800039ba <iget>
    8000426e:	a011                	j	80004272 <dirlookup+0xa0>
  return 0;
    80004270:	4501                	li	a0,0
}
    80004272:	70e2                	ld	ra,56(sp)
    80004274:	7442                	ld	s0,48(sp)
    80004276:	74a2                	ld	s1,40(sp)
    80004278:	7902                	ld	s2,32(sp)
    8000427a:	69e2                	ld	s3,24(sp)
    8000427c:	6a42                	ld	s4,16(sp)
    8000427e:	6121                	addi	sp,sp,64
    80004280:	8082                	ret

0000000080004282 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004282:	711d                	addi	sp,sp,-96
    80004284:	ec86                	sd	ra,88(sp)
    80004286:	e8a2                	sd	s0,80(sp)
    80004288:	e4a6                	sd	s1,72(sp)
    8000428a:	e0ca                	sd	s2,64(sp)
    8000428c:	fc4e                	sd	s3,56(sp)
    8000428e:	f852                	sd	s4,48(sp)
    80004290:	f456                	sd	s5,40(sp)
    80004292:	f05a                	sd	s6,32(sp)
    80004294:	ec5e                	sd	s7,24(sp)
    80004296:	e862                	sd	s8,16(sp)
    80004298:	e466                	sd	s9,8(sp)
    8000429a:	1080                	addi	s0,sp,96
    8000429c:	84aa                	mv	s1,a0
    8000429e:	8b2e                	mv	s6,a1
    800042a0:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800042a2:	00054703          	lbu	a4,0(a0)
    800042a6:	02f00793          	li	a5,47
    800042aa:	02f70263          	beq	a4,a5,800042ce <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800042ae:	ffffe097          	auipc	ra,0xffffe
    800042b2:	a50080e7          	jalr	-1456(ra) # 80001cfe <myproc>
    800042b6:	15053503          	ld	a0,336(a0)
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	9f6080e7          	jalr	-1546(ra) # 80003cb0 <idup>
    800042c2:	8a2a                	mv	s4,a0
  while(*path == '/')
    800042c4:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800042c8:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800042ca:	4b85                	li	s7,1
    800042cc:	a875                	j	80004388 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800042ce:	4585                	li	a1,1
    800042d0:	4505                	li	a0,1
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	6e8080e7          	jalr	1768(ra) # 800039ba <iget>
    800042da:	8a2a                	mv	s4,a0
    800042dc:	b7e5                	j	800042c4 <namex+0x42>
      iunlockput(ip);
    800042de:	8552                	mv	a0,s4
    800042e0:	00000097          	auipc	ra,0x0
    800042e4:	c70080e7          	jalr	-912(ra) # 80003f50 <iunlockput>
      return 0;
    800042e8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800042ea:	8552                	mv	a0,s4
    800042ec:	60e6                	ld	ra,88(sp)
    800042ee:	6446                	ld	s0,80(sp)
    800042f0:	64a6                	ld	s1,72(sp)
    800042f2:	6906                	ld	s2,64(sp)
    800042f4:	79e2                	ld	s3,56(sp)
    800042f6:	7a42                	ld	s4,48(sp)
    800042f8:	7aa2                	ld	s5,40(sp)
    800042fa:	7b02                	ld	s6,32(sp)
    800042fc:	6be2                	ld	s7,24(sp)
    800042fe:	6c42                	ld	s8,16(sp)
    80004300:	6ca2                	ld	s9,8(sp)
    80004302:	6125                	addi	sp,sp,96
    80004304:	8082                	ret
      iunlock(ip);
    80004306:	8552                	mv	a0,s4
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	aa8080e7          	jalr	-1368(ra) # 80003db0 <iunlock>
      return ip;
    80004310:	bfe9                	j	800042ea <namex+0x68>
      iunlockput(ip);
    80004312:	8552                	mv	a0,s4
    80004314:	00000097          	auipc	ra,0x0
    80004318:	c3c080e7          	jalr	-964(ra) # 80003f50 <iunlockput>
      return 0;
    8000431c:	8a4e                	mv	s4,s3
    8000431e:	b7f1                	j	800042ea <namex+0x68>
  len = path - s;
    80004320:	40998633          	sub	a2,s3,s1
    80004324:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004328:	099c5863          	bge	s8,s9,800043b8 <namex+0x136>
    memmove(name, s, DIRSIZ);
    8000432c:	4639                	li	a2,14
    8000432e:	85a6                	mv	a1,s1
    80004330:	8556                	mv	a0,s5
    80004332:	ffffd097          	auipc	ra,0xffffd
    80004336:	ba4080e7          	jalr	-1116(ra) # 80000ed6 <memmove>
    8000433a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000433c:	0004c783          	lbu	a5,0(s1)
    80004340:	01279763          	bne	a5,s2,8000434e <namex+0xcc>
    path++;
    80004344:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004346:	0004c783          	lbu	a5,0(s1)
    8000434a:	ff278de3          	beq	a5,s2,80004344 <namex+0xc2>
    ilock(ip);
    8000434e:	8552                	mv	a0,s4
    80004350:	00000097          	auipc	ra,0x0
    80004354:	99e080e7          	jalr	-1634(ra) # 80003cee <ilock>
    if(ip->type != T_DIR){
    80004358:	044a1783          	lh	a5,68(s4)
    8000435c:	f97791e3          	bne	a5,s7,800042de <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004360:	000b0563          	beqz	s6,8000436a <namex+0xe8>
    80004364:	0004c783          	lbu	a5,0(s1)
    80004368:	dfd9                	beqz	a5,80004306 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000436a:	4601                	li	a2,0
    8000436c:	85d6                	mv	a1,s5
    8000436e:	8552                	mv	a0,s4
    80004370:	00000097          	auipc	ra,0x0
    80004374:	e62080e7          	jalr	-414(ra) # 800041d2 <dirlookup>
    80004378:	89aa                	mv	s3,a0
    8000437a:	dd41                	beqz	a0,80004312 <namex+0x90>
    iunlockput(ip);
    8000437c:	8552                	mv	a0,s4
    8000437e:	00000097          	auipc	ra,0x0
    80004382:	bd2080e7          	jalr	-1070(ra) # 80003f50 <iunlockput>
    ip = next;
    80004386:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004388:	0004c783          	lbu	a5,0(s1)
    8000438c:	01279763          	bne	a5,s2,8000439a <namex+0x118>
    path++;
    80004390:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004392:	0004c783          	lbu	a5,0(s1)
    80004396:	ff278de3          	beq	a5,s2,80004390 <namex+0x10e>
  if(*path == 0)
    8000439a:	cb9d                	beqz	a5,800043d0 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000439c:	0004c783          	lbu	a5,0(s1)
    800043a0:	89a6                	mv	s3,s1
  len = path - s;
    800043a2:	4c81                	li	s9,0
    800043a4:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800043a6:	01278963          	beq	a5,s2,800043b8 <namex+0x136>
    800043aa:	dbbd                	beqz	a5,80004320 <namex+0x9e>
    path++;
    800043ac:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800043ae:	0009c783          	lbu	a5,0(s3)
    800043b2:	ff279ce3          	bne	a5,s2,800043aa <namex+0x128>
    800043b6:	b7ad                	j	80004320 <namex+0x9e>
    memmove(name, s, len);
    800043b8:	2601                	sext.w	a2,a2
    800043ba:	85a6                	mv	a1,s1
    800043bc:	8556                	mv	a0,s5
    800043be:	ffffd097          	auipc	ra,0xffffd
    800043c2:	b18080e7          	jalr	-1256(ra) # 80000ed6 <memmove>
    name[len] = 0;
    800043c6:	9cd6                	add	s9,s9,s5
    800043c8:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800043cc:	84ce                	mv	s1,s3
    800043ce:	b7bd                	j	8000433c <namex+0xba>
  if(nameiparent){
    800043d0:	f00b0de3          	beqz	s6,800042ea <namex+0x68>
    iput(ip);
    800043d4:	8552                	mv	a0,s4
    800043d6:	00000097          	auipc	ra,0x0
    800043da:	ad2080e7          	jalr	-1326(ra) # 80003ea8 <iput>
    return 0;
    800043de:	4a01                	li	s4,0
    800043e0:	b729                	j	800042ea <namex+0x68>

00000000800043e2 <dirlink>:
{
    800043e2:	7139                	addi	sp,sp,-64
    800043e4:	fc06                	sd	ra,56(sp)
    800043e6:	f822                	sd	s0,48(sp)
    800043e8:	f426                	sd	s1,40(sp)
    800043ea:	f04a                	sd	s2,32(sp)
    800043ec:	ec4e                	sd	s3,24(sp)
    800043ee:	e852                	sd	s4,16(sp)
    800043f0:	0080                	addi	s0,sp,64
    800043f2:	892a                	mv	s2,a0
    800043f4:	8a2e                	mv	s4,a1
    800043f6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043f8:	4601                	li	a2,0
    800043fa:	00000097          	auipc	ra,0x0
    800043fe:	dd8080e7          	jalr	-552(ra) # 800041d2 <dirlookup>
    80004402:	e93d                	bnez	a0,80004478 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004404:	04c92483          	lw	s1,76(s2)
    80004408:	c49d                	beqz	s1,80004436 <dirlink+0x54>
    8000440a:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000440c:	4741                	li	a4,16
    8000440e:	86a6                	mv	a3,s1
    80004410:	fc040613          	addi	a2,s0,-64
    80004414:	4581                	li	a1,0
    80004416:	854a                	mv	a0,s2
    80004418:	00000097          	auipc	ra,0x0
    8000441c:	b8a080e7          	jalr	-1142(ra) # 80003fa2 <readi>
    80004420:	47c1                	li	a5,16
    80004422:	06f51163          	bne	a0,a5,80004484 <dirlink+0xa2>
    if(de.inum == 0)
    80004426:	fc045783          	lhu	a5,-64(s0)
    8000442a:	c791                	beqz	a5,80004436 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000442c:	24c1                	addiw	s1,s1,16
    8000442e:	04c92783          	lw	a5,76(s2)
    80004432:	fcf4ede3          	bltu	s1,a5,8000440c <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004436:	4639                	li	a2,14
    80004438:	85d2                	mv	a1,s4
    8000443a:	fc240513          	addi	a0,s0,-62
    8000443e:	ffffd097          	auipc	ra,0xffffd
    80004442:	b48080e7          	jalr	-1208(ra) # 80000f86 <strncpy>
  de.inum = inum;
    80004446:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000444a:	4741                	li	a4,16
    8000444c:	86a6                	mv	a3,s1
    8000444e:	fc040613          	addi	a2,s0,-64
    80004452:	4581                	li	a1,0
    80004454:	854a                	mv	a0,s2
    80004456:	00000097          	auipc	ra,0x0
    8000445a:	c44080e7          	jalr	-956(ra) # 8000409a <writei>
    8000445e:	1541                	addi	a0,a0,-16
    80004460:	00a03533          	snez	a0,a0
    80004464:	40a00533          	neg	a0,a0
}
    80004468:	70e2                	ld	ra,56(sp)
    8000446a:	7442                	ld	s0,48(sp)
    8000446c:	74a2                	ld	s1,40(sp)
    8000446e:	7902                	ld	s2,32(sp)
    80004470:	69e2                	ld	s3,24(sp)
    80004472:	6a42                	ld	s4,16(sp)
    80004474:	6121                	addi	sp,sp,64
    80004476:	8082                	ret
    iput(ip);
    80004478:	00000097          	auipc	ra,0x0
    8000447c:	a30080e7          	jalr	-1488(ra) # 80003ea8 <iput>
    return -1;
    80004480:	557d                	li	a0,-1
    80004482:	b7dd                	j	80004468 <dirlink+0x86>
      panic("dirlink read");
    80004484:	00004517          	auipc	a0,0x4
    80004488:	2cc50513          	addi	a0,a0,716 # 80008750 <syscalls+0x1f0>
    8000448c:	ffffc097          	auipc	ra,0xffffc
    80004490:	0b0080e7          	jalr	176(ra) # 8000053c <panic>

0000000080004494 <namei>:

struct inode*
namei(char *path)
{
    80004494:	1101                	addi	sp,sp,-32
    80004496:	ec06                	sd	ra,24(sp)
    80004498:	e822                	sd	s0,16(sp)
    8000449a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000449c:	fe040613          	addi	a2,s0,-32
    800044a0:	4581                	li	a1,0
    800044a2:	00000097          	auipc	ra,0x0
    800044a6:	de0080e7          	jalr	-544(ra) # 80004282 <namex>
}
    800044aa:	60e2                	ld	ra,24(sp)
    800044ac:	6442                	ld	s0,16(sp)
    800044ae:	6105                	addi	sp,sp,32
    800044b0:	8082                	ret

00000000800044b2 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800044b2:	1141                	addi	sp,sp,-16
    800044b4:	e406                	sd	ra,8(sp)
    800044b6:	e022                	sd	s0,0(sp)
    800044b8:	0800                	addi	s0,sp,16
    800044ba:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800044bc:	4585                	li	a1,1
    800044be:	00000097          	auipc	ra,0x0
    800044c2:	dc4080e7          	jalr	-572(ra) # 80004282 <namex>
}
    800044c6:	60a2                	ld	ra,8(sp)
    800044c8:	6402                	ld	s0,0(sp)
    800044ca:	0141                	addi	sp,sp,16
    800044cc:	8082                	ret

00000000800044ce <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800044ce:	1101                	addi	sp,sp,-32
    800044d0:	ec06                	sd	ra,24(sp)
    800044d2:	e822                	sd	s0,16(sp)
    800044d4:	e426                	sd	s1,8(sp)
    800044d6:	e04a                	sd	s2,0(sp)
    800044d8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800044da:	0045c917          	auipc	s2,0x45c
    800044de:	7a690913          	addi	s2,s2,1958 # 80460c80 <log>
    800044e2:	01892583          	lw	a1,24(s2)
    800044e6:	02892503          	lw	a0,40(s2)
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	ff4080e7          	jalr	-12(ra) # 800034de <bread>
    800044f2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044f4:	02c92603          	lw	a2,44(s2)
    800044f8:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044fa:	00c05f63          	blez	a2,80004518 <write_head+0x4a>
    800044fe:	0045c717          	auipc	a4,0x45c
    80004502:	7b270713          	addi	a4,a4,1970 # 80460cb0 <log+0x30>
    80004506:	87aa                	mv	a5,a0
    80004508:	060a                	slli	a2,a2,0x2
    8000450a:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    8000450c:	4314                	lw	a3,0(a4)
    8000450e:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80004510:	0711                	addi	a4,a4,4
    80004512:	0791                	addi	a5,a5,4
    80004514:	fec79ce3          	bne	a5,a2,8000450c <write_head+0x3e>
  }
  bwrite(buf);
    80004518:	8526                	mv	a0,s1
    8000451a:	fffff097          	auipc	ra,0xfffff
    8000451e:	0b6080e7          	jalr	182(ra) # 800035d0 <bwrite>
  brelse(buf);
    80004522:	8526                	mv	a0,s1
    80004524:	fffff097          	auipc	ra,0xfffff
    80004528:	0ea080e7          	jalr	234(ra) # 8000360e <brelse>
}
    8000452c:	60e2                	ld	ra,24(sp)
    8000452e:	6442                	ld	s0,16(sp)
    80004530:	64a2                	ld	s1,8(sp)
    80004532:	6902                	ld	s2,0(sp)
    80004534:	6105                	addi	sp,sp,32
    80004536:	8082                	ret

0000000080004538 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004538:	0045c797          	auipc	a5,0x45c
    8000453c:	7747a783          	lw	a5,1908(a5) # 80460cac <log+0x2c>
    80004540:	0af05d63          	blez	a5,800045fa <install_trans+0xc2>
{
    80004544:	7139                	addi	sp,sp,-64
    80004546:	fc06                	sd	ra,56(sp)
    80004548:	f822                	sd	s0,48(sp)
    8000454a:	f426                	sd	s1,40(sp)
    8000454c:	f04a                	sd	s2,32(sp)
    8000454e:	ec4e                	sd	s3,24(sp)
    80004550:	e852                	sd	s4,16(sp)
    80004552:	e456                	sd	s5,8(sp)
    80004554:	e05a                	sd	s6,0(sp)
    80004556:	0080                	addi	s0,sp,64
    80004558:	8b2a                	mv	s6,a0
    8000455a:	0045ca97          	auipc	s5,0x45c
    8000455e:	756a8a93          	addi	s5,s5,1878 # 80460cb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004562:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004564:	0045c997          	auipc	s3,0x45c
    80004568:	71c98993          	addi	s3,s3,1820 # 80460c80 <log>
    8000456c:	a00d                	j	8000458e <install_trans+0x56>
    brelse(lbuf);
    8000456e:	854a                	mv	a0,s2
    80004570:	fffff097          	auipc	ra,0xfffff
    80004574:	09e080e7          	jalr	158(ra) # 8000360e <brelse>
    brelse(dbuf);
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	094080e7          	jalr	148(ra) # 8000360e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004582:	2a05                	addiw	s4,s4,1
    80004584:	0a91                	addi	s5,s5,4
    80004586:	02c9a783          	lw	a5,44(s3)
    8000458a:	04fa5e63          	bge	s4,a5,800045e6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000458e:	0189a583          	lw	a1,24(s3)
    80004592:	014585bb          	addw	a1,a1,s4
    80004596:	2585                	addiw	a1,a1,1
    80004598:	0289a503          	lw	a0,40(s3)
    8000459c:	fffff097          	auipc	ra,0xfffff
    800045a0:	f42080e7          	jalr	-190(ra) # 800034de <bread>
    800045a4:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800045a6:	000aa583          	lw	a1,0(s5)
    800045aa:	0289a503          	lw	a0,40(s3)
    800045ae:	fffff097          	auipc	ra,0xfffff
    800045b2:	f30080e7          	jalr	-208(ra) # 800034de <bread>
    800045b6:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800045b8:	40000613          	li	a2,1024
    800045bc:	05890593          	addi	a1,s2,88
    800045c0:	05850513          	addi	a0,a0,88
    800045c4:	ffffd097          	auipc	ra,0xffffd
    800045c8:	912080e7          	jalr	-1774(ra) # 80000ed6 <memmove>
    bwrite(dbuf);  // write dst to disk
    800045cc:	8526                	mv	a0,s1
    800045ce:	fffff097          	auipc	ra,0xfffff
    800045d2:	002080e7          	jalr	2(ra) # 800035d0 <bwrite>
    if(recovering == 0)
    800045d6:	f80b1ce3          	bnez	s6,8000456e <install_trans+0x36>
      bunpin(dbuf);
    800045da:	8526                	mv	a0,s1
    800045dc:	fffff097          	auipc	ra,0xfffff
    800045e0:	10a080e7          	jalr	266(ra) # 800036e6 <bunpin>
    800045e4:	b769                	j	8000456e <install_trans+0x36>
}
    800045e6:	70e2                	ld	ra,56(sp)
    800045e8:	7442                	ld	s0,48(sp)
    800045ea:	74a2                	ld	s1,40(sp)
    800045ec:	7902                	ld	s2,32(sp)
    800045ee:	69e2                	ld	s3,24(sp)
    800045f0:	6a42                	ld	s4,16(sp)
    800045f2:	6aa2                	ld	s5,8(sp)
    800045f4:	6b02                	ld	s6,0(sp)
    800045f6:	6121                	addi	sp,sp,64
    800045f8:	8082                	ret
    800045fa:	8082                	ret

00000000800045fc <initlog>:
{
    800045fc:	7179                	addi	sp,sp,-48
    800045fe:	f406                	sd	ra,40(sp)
    80004600:	f022                	sd	s0,32(sp)
    80004602:	ec26                	sd	s1,24(sp)
    80004604:	e84a                	sd	s2,16(sp)
    80004606:	e44e                	sd	s3,8(sp)
    80004608:	1800                	addi	s0,sp,48
    8000460a:	892a                	mv	s2,a0
    8000460c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000460e:	0045c497          	auipc	s1,0x45c
    80004612:	67248493          	addi	s1,s1,1650 # 80460c80 <log>
    80004616:	00004597          	auipc	a1,0x4
    8000461a:	14a58593          	addi	a1,a1,330 # 80008760 <syscalls+0x200>
    8000461e:	8526                	mv	a0,s1
    80004620:	ffffc097          	auipc	ra,0xffffc
    80004624:	6ce080e7          	jalr	1742(ra) # 80000cee <initlock>
  log.start = sb->logstart;
    80004628:	0149a583          	lw	a1,20(s3)
    8000462c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000462e:	0109a783          	lw	a5,16(s3)
    80004632:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004634:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004638:	854a                	mv	a0,s2
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	ea4080e7          	jalr	-348(ra) # 800034de <bread>
  log.lh.n = lh->n;
    80004642:	4d30                	lw	a2,88(a0)
    80004644:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004646:	00c05f63          	blez	a2,80004664 <initlog+0x68>
    8000464a:	87aa                	mv	a5,a0
    8000464c:	0045c717          	auipc	a4,0x45c
    80004650:	66470713          	addi	a4,a4,1636 # 80460cb0 <log+0x30>
    80004654:	060a                	slli	a2,a2,0x2
    80004656:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004658:	4ff4                	lw	a3,92(a5)
    8000465a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000465c:	0791                	addi	a5,a5,4
    8000465e:	0711                	addi	a4,a4,4
    80004660:	fec79ce3          	bne	a5,a2,80004658 <initlog+0x5c>
  brelse(buf);
    80004664:	fffff097          	auipc	ra,0xfffff
    80004668:	faa080e7          	jalr	-86(ra) # 8000360e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000466c:	4505                	li	a0,1
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	eca080e7          	jalr	-310(ra) # 80004538 <install_trans>
  log.lh.n = 0;
    80004676:	0045c797          	auipc	a5,0x45c
    8000467a:	6207ab23          	sw	zero,1590(a5) # 80460cac <log+0x2c>
  write_head(); // clear the log
    8000467e:	00000097          	auipc	ra,0x0
    80004682:	e50080e7          	jalr	-432(ra) # 800044ce <write_head>
}
    80004686:	70a2                	ld	ra,40(sp)
    80004688:	7402                	ld	s0,32(sp)
    8000468a:	64e2                	ld	s1,24(sp)
    8000468c:	6942                	ld	s2,16(sp)
    8000468e:	69a2                	ld	s3,8(sp)
    80004690:	6145                	addi	sp,sp,48
    80004692:	8082                	ret

0000000080004694 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004694:	1101                	addi	sp,sp,-32
    80004696:	ec06                	sd	ra,24(sp)
    80004698:	e822                	sd	s0,16(sp)
    8000469a:	e426                	sd	s1,8(sp)
    8000469c:	e04a                	sd	s2,0(sp)
    8000469e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800046a0:	0045c517          	auipc	a0,0x45c
    800046a4:	5e050513          	addi	a0,a0,1504 # 80460c80 <log>
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	6d6080e7          	jalr	1750(ra) # 80000d7e <acquire>
  while(1){
    if(log.committing){
    800046b0:	0045c497          	auipc	s1,0x45c
    800046b4:	5d048493          	addi	s1,s1,1488 # 80460c80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046b8:	4979                	li	s2,30
    800046ba:	a039                	j	800046c8 <begin_op+0x34>
      sleep(&log, &log.lock);
    800046bc:	85a6                	mv	a1,s1
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffe097          	auipc	ra,0xffffe
    800046c4:	da6080e7          	jalr	-602(ra) # 80002466 <sleep>
    if(log.committing){
    800046c8:	50dc                	lw	a5,36(s1)
    800046ca:	fbed                	bnez	a5,800046bc <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800046cc:	5098                	lw	a4,32(s1)
    800046ce:	2705                	addiw	a4,a4,1
    800046d0:	0027179b          	slliw	a5,a4,0x2
    800046d4:	9fb9                	addw	a5,a5,a4
    800046d6:	0017979b          	slliw	a5,a5,0x1
    800046da:	54d4                	lw	a3,44(s1)
    800046dc:	9fb5                	addw	a5,a5,a3
    800046de:	00f95963          	bge	s2,a5,800046f0 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800046e2:	85a6                	mv	a1,s1
    800046e4:	8526                	mv	a0,s1
    800046e6:	ffffe097          	auipc	ra,0xffffe
    800046ea:	d80080e7          	jalr	-640(ra) # 80002466 <sleep>
    800046ee:	bfe9                	j	800046c8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800046f0:	0045c517          	auipc	a0,0x45c
    800046f4:	59050513          	addi	a0,a0,1424 # 80460c80 <log>
    800046f8:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800046fa:	ffffc097          	auipc	ra,0xffffc
    800046fe:	738080e7          	jalr	1848(ra) # 80000e32 <release>
      break;
    }
  }
}
    80004702:	60e2                	ld	ra,24(sp)
    80004704:	6442                	ld	s0,16(sp)
    80004706:	64a2                	ld	s1,8(sp)
    80004708:	6902                	ld	s2,0(sp)
    8000470a:	6105                	addi	sp,sp,32
    8000470c:	8082                	ret

000000008000470e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000470e:	7139                	addi	sp,sp,-64
    80004710:	fc06                	sd	ra,56(sp)
    80004712:	f822                	sd	s0,48(sp)
    80004714:	f426                	sd	s1,40(sp)
    80004716:	f04a                	sd	s2,32(sp)
    80004718:	ec4e                	sd	s3,24(sp)
    8000471a:	e852                	sd	s4,16(sp)
    8000471c:	e456                	sd	s5,8(sp)
    8000471e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004720:	0045c497          	auipc	s1,0x45c
    80004724:	56048493          	addi	s1,s1,1376 # 80460c80 <log>
    80004728:	8526                	mv	a0,s1
    8000472a:	ffffc097          	auipc	ra,0xffffc
    8000472e:	654080e7          	jalr	1620(ra) # 80000d7e <acquire>
  log.outstanding -= 1;
    80004732:	509c                	lw	a5,32(s1)
    80004734:	37fd                	addiw	a5,a5,-1
    80004736:	0007891b          	sext.w	s2,a5
    8000473a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000473c:	50dc                	lw	a5,36(s1)
    8000473e:	e7b9                	bnez	a5,8000478c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004740:	04091e63          	bnez	s2,8000479c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004744:	0045c497          	auipc	s1,0x45c
    80004748:	53c48493          	addi	s1,s1,1340 # 80460c80 <log>
    8000474c:	4785                	li	a5,1
    8000474e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004750:	8526                	mv	a0,s1
    80004752:	ffffc097          	auipc	ra,0xffffc
    80004756:	6e0080e7          	jalr	1760(ra) # 80000e32 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000475a:	54dc                	lw	a5,44(s1)
    8000475c:	06f04763          	bgtz	a5,800047ca <end_op+0xbc>
    acquire(&log.lock);
    80004760:	0045c497          	auipc	s1,0x45c
    80004764:	52048493          	addi	s1,s1,1312 # 80460c80 <log>
    80004768:	8526                	mv	a0,s1
    8000476a:	ffffc097          	auipc	ra,0xffffc
    8000476e:	614080e7          	jalr	1556(ra) # 80000d7e <acquire>
    log.committing = 0;
    80004772:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004776:	8526                	mv	a0,s1
    80004778:	ffffe097          	auipc	ra,0xffffe
    8000477c:	d52080e7          	jalr	-686(ra) # 800024ca <wakeup>
    release(&log.lock);
    80004780:	8526                	mv	a0,s1
    80004782:	ffffc097          	auipc	ra,0xffffc
    80004786:	6b0080e7          	jalr	1712(ra) # 80000e32 <release>
}
    8000478a:	a03d                	j	800047b8 <end_op+0xaa>
    panic("log.committing");
    8000478c:	00004517          	auipc	a0,0x4
    80004790:	fdc50513          	addi	a0,a0,-36 # 80008768 <syscalls+0x208>
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	da8080e7          	jalr	-600(ra) # 8000053c <panic>
    wakeup(&log);
    8000479c:	0045c497          	auipc	s1,0x45c
    800047a0:	4e448493          	addi	s1,s1,1252 # 80460c80 <log>
    800047a4:	8526                	mv	a0,s1
    800047a6:	ffffe097          	auipc	ra,0xffffe
    800047aa:	d24080e7          	jalr	-732(ra) # 800024ca <wakeup>
  release(&log.lock);
    800047ae:	8526                	mv	a0,s1
    800047b0:	ffffc097          	auipc	ra,0xffffc
    800047b4:	682080e7          	jalr	1666(ra) # 80000e32 <release>
}
    800047b8:	70e2                	ld	ra,56(sp)
    800047ba:	7442                	ld	s0,48(sp)
    800047bc:	74a2                	ld	s1,40(sp)
    800047be:	7902                	ld	s2,32(sp)
    800047c0:	69e2                	ld	s3,24(sp)
    800047c2:	6a42                	ld	s4,16(sp)
    800047c4:	6aa2                	ld	s5,8(sp)
    800047c6:	6121                	addi	sp,sp,64
    800047c8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800047ca:	0045ca97          	auipc	s5,0x45c
    800047ce:	4e6a8a93          	addi	s5,s5,1254 # 80460cb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800047d2:	0045ca17          	auipc	s4,0x45c
    800047d6:	4aea0a13          	addi	s4,s4,1198 # 80460c80 <log>
    800047da:	018a2583          	lw	a1,24(s4)
    800047de:	012585bb          	addw	a1,a1,s2
    800047e2:	2585                	addiw	a1,a1,1
    800047e4:	028a2503          	lw	a0,40(s4)
    800047e8:	fffff097          	auipc	ra,0xfffff
    800047ec:	cf6080e7          	jalr	-778(ra) # 800034de <bread>
    800047f0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800047f2:	000aa583          	lw	a1,0(s5)
    800047f6:	028a2503          	lw	a0,40(s4)
    800047fa:	fffff097          	auipc	ra,0xfffff
    800047fe:	ce4080e7          	jalr	-796(ra) # 800034de <bread>
    80004802:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004804:	40000613          	li	a2,1024
    80004808:	05850593          	addi	a1,a0,88
    8000480c:	05848513          	addi	a0,s1,88
    80004810:	ffffc097          	auipc	ra,0xffffc
    80004814:	6c6080e7          	jalr	1734(ra) # 80000ed6 <memmove>
    bwrite(to);  // write the log
    80004818:	8526                	mv	a0,s1
    8000481a:	fffff097          	auipc	ra,0xfffff
    8000481e:	db6080e7          	jalr	-586(ra) # 800035d0 <bwrite>
    brelse(from);
    80004822:	854e                	mv	a0,s3
    80004824:	fffff097          	auipc	ra,0xfffff
    80004828:	dea080e7          	jalr	-534(ra) # 8000360e <brelse>
    brelse(to);
    8000482c:	8526                	mv	a0,s1
    8000482e:	fffff097          	auipc	ra,0xfffff
    80004832:	de0080e7          	jalr	-544(ra) # 8000360e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004836:	2905                	addiw	s2,s2,1
    80004838:	0a91                	addi	s5,s5,4
    8000483a:	02ca2783          	lw	a5,44(s4)
    8000483e:	f8f94ee3          	blt	s2,a5,800047da <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004842:	00000097          	auipc	ra,0x0
    80004846:	c8c080e7          	jalr	-884(ra) # 800044ce <write_head>
    install_trans(0); // Now install writes to home locations
    8000484a:	4501                	li	a0,0
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	cec080e7          	jalr	-788(ra) # 80004538 <install_trans>
    log.lh.n = 0;
    80004854:	0045c797          	auipc	a5,0x45c
    80004858:	4407ac23          	sw	zero,1112(a5) # 80460cac <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000485c:	00000097          	auipc	ra,0x0
    80004860:	c72080e7          	jalr	-910(ra) # 800044ce <write_head>
    80004864:	bdf5                	j	80004760 <end_op+0x52>

0000000080004866 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004866:	1101                	addi	sp,sp,-32
    80004868:	ec06                	sd	ra,24(sp)
    8000486a:	e822                	sd	s0,16(sp)
    8000486c:	e426                	sd	s1,8(sp)
    8000486e:	e04a                	sd	s2,0(sp)
    80004870:	1000                	addi	s0,sp,32
    80004872:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004874:	0045c917          	auipc	s2,0x45c
    80004878:	40c90913          	addi	s2,s2,1036 # 80460c80 <log>
    8000487c:	854a                	mv	a0,s2
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	500080e7          	jalr	1280(ra) # 80000d7e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004886:	02c92603          	lw	a2,44(s2)
    8000488a:	47f5                	li	a5,29
    8000488c:	06c7c563          	blt	a5,a2,800048f6 <log_write+0x90>
    80004890:	0045c797          	auipc	a5,0x45c
    80004894:	40c7a783          	lw	a5,1036(a5) # 80460c9c <log+0x1c>
    80004898:	37fd                	addiw	a5,a5,-1
    8000489a:	04f65e63          	bge	a2,a5,800048f6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000489e:	0045c797          	auipc	a5,0x45c
    800048a2:	4027a783          	lw	a5,1026(a5) # 80460ca0 <log+0x20>
    800048a6:	06f05063          	blez	a5,80004906 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800048aa:	4781                	li	a5,0
    800048ac:	06c05563          	blez	a2,80004916 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048b0:	44cc                	lw	a1,12(s1)
    800048b2:	0045c717          	auipc	a4,0x45c
    800048b6:	3fe70713          	addi	a4,a4,1022 # 80460cb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800048ba:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800048bc:	4314                	lw	a3,0(a4)
    800048be:	04b68c63          	beq	a3,a1,80004916 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800048c2:	2785                	addiw	a5,a5,1
    800048c4:	0711                	addi	a4,a4,4
    800048c6:	fef61be3          	bne	a2,a5,800048bc <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800048ca:	0621                	addi	a2,a2,8
    800048cc:	060a                	slli	a2,a2,0x2
    800048ce:	0045c797          	auipc	a5,0x45c
    800048d2:	3b278793          	addi	a5,a5,946 # 80460c80 <log>
    800048d6:	97b2                	add	a5,a5,a2
    800048d8:	44d8                	lw	a4,12(s1)
    800048da:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800048dc:	8526                	mv	a0,s1
    800048de:	fffff097          	auipc	ra,0xfffff
    800048e2:	dcc080e7          	jalr	-564(ra) # 800036aa <bpin>
    log.lh.n++;
    800048e6:	0045c717          	auipc	a4,0x45c
    800048ea:	39a70713          	addi	a4,a4,922 # 80460c80 <log>
    800048ee:	575c                	lw	a5,44(a4)
    800048f0:	2785                	addiw	a5,a5,1
    800048f2:	d75c                	sw	a5,44(a4)
    800048f4:	a82d                	j	8000492e <log_write+0xc8>
    panic("too big a transaction");
    800048f6:	00004517          	auipc	a0,0x4
    800048fa:	e8250513          	addi	a0,a0,-382 # 80008778 <syscalls+0x218>
    800048fe:	ffffc097          	auipc	ra,0xffffc
    80004902:	c3e080e7          	jalr	-962(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004906:	00004517          	auipc	a0,0x4
    8000490a:	e8a50513          	addi	a0,a0,-374 # 80008790 <syscalls+0x230>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	c2e080e7          	jalr	-978(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004916:	00878693          	addi	a3,a5,8
    8000491a:	068a                	slli	a3,a3,0x2
    8000491c:	0045c717          	auipc	a4,0x45c
    80004920:	36470713          	addi	a4,a4,868 # 80460c80 <log>
    80004924:	9736                	add	a4,a4,a3
    80004926:	44d4                	lw	a3,12(s1)
    80004928:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000492a:	faf609e3          	beq	a2,a5,800048dc <log_write+0x76>
  }
  release(&log.lock);
    8000492e:	0045c517          	auipc	a0,0x45c
    80004932:	35250513          	addi	a0,a0,850 # 80460c80 <log>
    80004936:	ffffc097          	auipc	ra,0xffffc
    8000493a:	4fc080e7          	jalr	1276(ra) # 80000e32 <release>
}
    8000493e:	60e2                	ld	ra,24(sp)
    80004940:	6442                	ld	s0,16(sp)
    80004942:	64a2                	ld	s1,8(sp)
    80004944:	6902                	ld	s2,0(sp)
    80004946:	6105                	addi	sp,sp,32
    80004948:	8082                	ret

000000008000494a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000494a:	1101                	addi	sp,sp,-32
    8000494c:	ec06                	sd	ra,24(sp)
    8000494e:	e822                	sd	s0,16(sp)
    80004950:	e426                	sd	s1,8(sp)
    80004952:	e04a                	sd	s2,0(sp)
    80004954:	1000                	addi	s0,sp,32
    80004956:	84aa                	mv	s1,a0
    80004958:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000495a:	00004597          	auipc	a1,0x4
    8000495e:	e5658593          	addi	a1,a1,-426 # 800087b0 <syscalls+0x250>
    80004962:	0521                	addi	a0,a0,8
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	38a080e7          	jalr	906(ra) # 80000cee <initlock>
  lk->name = name;
    8000496c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004970:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004974:	0204a423          	sw	zero,40(s1)
}
    80004978:	60e2                	ld	ra,24(sp)
    8000497a:	6442                	ld	s0,16(sp)
    8000497c:	64a2                	ld	s1,8(sp)
    8000497e:	6902                	ld	s2,0(sp)
    80004980:	6105                	addi	sp,sp,32
    80004982:	8082                	ret

0000000080004984 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004984:	1101                	addi	sp,sp,-32
    80004986:	ec06                	sd	ra,24(sp)
    80004988:	e822                	sd	s0,16(sp)
    8000498a:	e426                	sd	s1,8(sp)
    8000498c:	e04a                	sd	s2,0(sp)
    8000498e:	1000                	addi	s0,sp,32
    80004990:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004992:	00850913          	addi	s2,a0,8
    80004996:	854a                	mv	a0,s2
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	3e6080e7          	jalr	998(ra) # 80000d7e <acquire>
  while (lk->locked) {
    800049a0:	409c                	lw	a5,0(s1)
    800049a2:	cb89                	beqz	a5,800049b4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800049a4:	85ca                	mv	a1,s2
    800049a6:	8526                	mv	a0,s1
    800049a8:	ffffe097          	auipc	ra,0xffffe
    800049ac:	abe080e7          	jalr	-1346(ra) # 80002466 <sleep>
  while (lk->locked) {
    800049b0:	409c                	lw	a5,0(s1)
    800049b2:	fbed                	bnez	a5,800049a4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800049b4:	4785                	li	a5,1
    800049b6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800049b8:	ffffd097          	auipc	ra,0xffffd
    800049bc:	346080e7          	jalr	838(ra) # 80001cfe <myproc>
    800049c0:	591c                	lw	a5,48(a0)
    800049c2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800049c4:	854a                	mv	a0,s2
    800049c6:	ffffc097          	auipc	ra,0xffffc
    800049ca:	46c080e7          	jalr	1132(ra) # 80000e32 <release>
}
    800049ce:	60e2                	ld	ra,24(sp)
    800049d0:	6442                	ld	s0,16(sp)
    800049d2:	64a2                	ld	s1,8(sp)
    800049d4:	6902                	ld	s2,0(sp)
    800049d6:	6105                	addi	sp,sp,32
    800049d8:	8082                	ret

00000000800049da <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800049da:	1101                	addi	sp,sp,-32
    800049dc:	ec06                	sd	ra,24(sp)
    800049de:	e822                	sd	s0,16(sp)
    800049e0:	e426                	sd	s1,8(sp)
    800049e2:	e04a                	sd	s2,0(sp)
    800049e4:	1000                	addi	s0,sp,32
    800049e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800049e8:	00850913          	addi	s2,a0,8
    800049ec:	854a                	mv	a0,s2
    800049ee:	ffffc097          	auipc	ra,0xffffc
    800049f2:	390080e7          	jalr	912(ra) # 80000d7e <acquire>
  lk->locked = 0;
    800049f6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049fa:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049fe:	8526                	mv	a0,s1
    80004a00:	ffffe097          	auipc	ra,0xffffe
    80004a04:	aca080e7          	jalr	-1334(ra) # 800024ca <wakeup>
  release(&lk->lk);
    80004a08:	854a                	mv	a0,s2
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	428080e7          	jalr	1064(ra) # 80000e32 <release>
}
    80004a12:	60e2                	ld	ra,24(sp)
    80004a14:	6442                	ld	s0,16(sp)
    80004a16:	64a2                	ld	s1,8(sp)
    80004a18:	6902                	ld	s2,0(sp)
    80004a1a:	6105                	addi	sp,sp,32
    80004a1c:	8082                	ret

0000000080004a1e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004a1e:	7179                	addi	sp,sp,-48
    80004a20:	f406                	sd	ra,40(sp)
    80004a22:	f022                	sd	s0,32(sp)
    80004a24:	ec26                	sd	s1,24(sp)
    80004a26:	e84a                	sd	s2,16(sp)
    80004a28:	e44e                	sd	s3,8(sp)
    80004a2a:	1800                	addi	s0,sp,48
    80004a2c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004a2e:	00850913          	addi	s2,a0,8
    80004a32:	854a                	mv	a0,s2
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	34a080e7          	jalr	842(ra) # 80000d7e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a3c:	409c                	lw	a5,0(s1)
    80004a3e:	ef99                	bnez	a5,80004a5c <holdingsleep+0x3e>
    80004a40:	4481                	li	s1,0
  release(&lk->lk);
    80004a42:	854a                	mv	a0,s2
    80004a44:	ffffc097          	auipc	ra,0xffffc
    80004a48:	3ee080e7          	jalr	1006(ra) # 80000e32 <release>
  return r;
}
    80004a4c:	8526                	mv	a0,s1
    80004a4e:	70a2                	ld	ra,40(sp)
    80004a50:	7402                	ld	s0,32(sp)
    80004a52:	64e2                	ld	s1,24(sp)
    80004a54:	6942                	ld	s2,16(sp)
    80004a56:	69a2                	ld	s3,8(sp)
    80004a58:	6145                	addi	sp,sp,48
    80004a5a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a5c:	0284a983          	lw	s3,40(s1)
    80004a60:	ffffd097          	auipc	ra,0xffffd
    80004a64:	29e080e7          	jalr	670(ra) # 80001cfe <myproc>
    80004a68:	5904                	lw	s1,48(a0)
    80004a6a:	413484b3          	sub	s1,s1,s3
    80004a6e:	0014b493          	seqz	s1,s1
    80004a72:	bfc1                	j	80004a42 <holdingsleep+0x24>

0000000080004a74 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a74:	1141                	addi	sp,sp,-16
    80004a76:	e406                	sd	ra,8(sp)
    80004a78:	e022                	sd	s0,0(sp)
    80004a7a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a7c:	00004597          	auipc	a1,0x4
    80004a80:	d4458593          	addi	a1,a1,-700 # 800087c0 <syscalls+0x260>
    80004a84:	0045c517          	auipc	a0,0x45c
    80004a88:	34450513          	addi	a0,a0,836 # 80460dc8 <ftable>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	262080e7          	jalr	610(ra) # 80000cee <initlock>
}
    80004a94:	60a2                	ld	ra,8(sp)
    80004a96:	6402                	ld	s0,0(sp)
    80004a98:	0141                	addi	sp,sp,16
    80004a9a:	8082                	ret

0000000080004a9c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a9c:	1101                	addi	sp,sp,-32
    80004a9e:	ec06                	sd	ra,24(sp)
    80004aa0:	e822                	sd	s0,16(sp)
    80004aa2:	e426                	sd	s1,8(sp)
    80004aa4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004aa6:	0045c517          	auipc	a0,0x45c
    80004aaa:	32250513          	addi	a0,a0,802 # 80460dc8 <ftable>
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	2d0080e7          	jalr	720(ra) # 80000d7e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ab6:	0045c497          	auipc	s1,0x45c
    80004aba:	32a48493          	addi	s1,s1,810 # 80460de0 <ftable+0x18>
    80004abe:	0045d717          	auipc	a4,0x45d
    80004ac2:	2c270713          	addi	a4,a4,706 # 80461d80 <disk>
    if(f->ref == 0){
    80004ac6:	40dc                	lw	a5,4(s1)
    80004ac8:	cf99                	beqz	a5,80004ae6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004aca:	02848493          	addi	s1,s1,40
    80004ace:	fee49ce3          	bne	s1,a4,80004ac6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ad2:	0045c517          	auipc	a0,0x45c
    80004ad6:	2f650513          	addi	a0,a0,758 # 80460dc8 <ftable>
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	358080e7          	jalr	856(ra) # 80000e32 <release>
  return 0;
    80004ae2:	4481                	li	s1,0
    80004ae4:	a819                	j	80004afa <filealloc+0x5e>
      f->ref = 1;
    80004ae6:	4785                	li	a5,1
    80004ae8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004aea:	0045c517          	auipc	a0,0x45c
    80004aee:	2de50513          	addi	a0,a0,734 # 80460dc8 <ftable>
    80004af2:	ffffc097          	auipc	ra,0xffffc
    80004af6:	340080e7          	jalr	832(ra) # 80000e32 <release>
}
    80004afa:	8526                	mv	a0,s1
    80004afc:	60e2                	ld	ra,24(sp)
    80004afe:	6442                	ld	s0,16(sp)
    80004b00:	64a2                	ld	s1,8(sp)
    80004b02:	6105                	addi	sp,sp,32
    80004b04:	8082                	ret

0000000080004b06 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004b06:	1101                	addi	sp,sp,-32
    80004b08:	ec06                	sd	ra,24(sp)
    80004b0a:	e822                	sd	s0,16(sp)
    80004b0c:	e426                	sd	s1,8(sp)
    80004b0e:	1000                	addi	s0,sp,32
    80004b10:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004b12:	0045c517          	auipc	a0,0x45c
    80004b16:	2b650513          	addi	a0,a0,694 # 80460dc8 <ftable>
    80004b1a:	ffffc097          	auipc	ra,0xffffc
    80004b1e:	264080e7          	jalr	612(ra) # 80000d7e <acquire>
  if(f->ref < 1)
    80004b22:	40dc                	lw	a5,4(s1)
    80004b24:	02f05263          	blez	a5,80004b48 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004b28:	2785                	addiw	a5,a5,1
    80004b2a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004b2c:	0045c517          	auipc	a0,0x45c
    80004b30:	29c50513          	addi	a0,a0,668 # 80460dc8 <ftable>
    80004b34:	ffffc097          	auipc	ra,0xffffc
    80004b38:	2fe080e7          	jalr	766(ra) # 80000e32 <release>
  return f;
}
    80004b3c:	8526                	mv	a0,s1
    80004b3e:	60e2                	ld	ra,24(sp)
    80004b40:	6442                	ld	s0,16(sp)
    80004b42:	64a2                	ld	s1,8(sp)
    80004b44:	6105                	addi	sp,sp,32
    80004b46:	8082                	ret
    panic("filedup");
    80004b48:	00004517          	auipc	a0,0x4
    80004b4c:	c8050513          	addi	a0,a0,-896 # 800087c8 <syscalls+0x268>
    80004b50:	ffffc097          	auipc	ra,0xffffc
    80004b54:	9ec080e7          	jalr	-1556(ra) # 8000053c <panic>

0000000080004b58 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b58:	7139                	addi	sp,sp,-64
    80004b5a:	fc06                	sd	ra,56(sp)
    80004b5c:	f822                	sd	s0,48(sp)
    80004b5e:	f426                	sd	s1,40(sp)
    80004b60:	f04a                	sd	s2,32(sp)
    80004b62:	ec4e                	sd	s3,24(sp)
    80004b64:	e852                	sd	s4,16(sp)
    80004b66:	e456                	sd	s5,8(sp)
    80004b68:	0080                	addi	s0,sp,64
    80004b6a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b6c:	0045c517          	auipc	a0,0x45c
    80004b70:	25c50513          	addi	a0,a0,604 # 80460dc8 <ftable>
    80004b74:	ffffc097          	auipc	ra,0xffffc
    80004b78:	20a080e7          	jalr	522(ra) # 80000d7e <acquire>
  if(f->ref < 1)
    80004b7c:	40dc                	lw	a5,4(s1)
    80004b7e:	06f05163          	blez	a5,80004be0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b82:	37fd                	addiw	a5,a5,-1
    80004b84:	0007871b          	sext.w	a4,a5
    80004b88:	c0dc                	sw	a5,4(s1)
    80004b8a:	06e04363          	bgtz	a4,80004bf0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b8e:	0004a903          	lw	s2,0(s1)
    80004b92:	0094ca83          	lbu	s5,9(s1)
    80004b96:	0104ba03          	ld	s4,16(s1)
    80004b9a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b9e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004ba2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ba6:	0045c517          	auipc	a0,0x45c
    80004baa:	22250513          	addi	a0,a0,546 # 80460dc8 <ftable>
    80004bae:	ffffc097          	auipc	ra,0xffffc
    80004bb2:	284080e7          	jalr	644(ra) # 80000e32 <release>

  if(ff.type == FD_PIPE){
    80004bb6:	4785                	li	a5,1
    80004bb8:	04f90d63          	beq	s2,a5,80004c12 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004bbc:	3979                	addiw	s2,s2,-2
    80004bbe:	4785                	li	a5,1
    80004bc0:	0527e063          	bltu	a5,s2,80004c00 <fileclose+0xa8>
    begin_op();
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	ad0080e7          	jalr	-1328(ra) # 80004694 <begin_op>
    iput(ff.ip);
    80004bcc:	854e                	mv	a0,s3
    80004bce:	fffff097          	auipc	ra,0xfffff
    80004bd2:	2da080e7          	jalr	730(ra) # 80003ea8 <iput>
    end_op();
    80004bd6:	00000097          	auipc	ra,0x0
    80004bda:	b38080e7          	jalr	-1224(ra) # 8000470e <end_op>
    80004bde:	a00d                	j	80004c00 <fileclose+0xa8>
    panic("fileclose");
    80004be0:	00004517          	auipc	a0,0x4
    80004be4:	bf050513          	addi	a0,a0,-1040 # 800087d0 <syscalls+0x270>
    80004be8:	ffffc097          	auipc	ra,0xffffc
    80004bec:	954080e7          	jalr	-1708(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004bf0:	0045c517          	auipc	a0,0x45c
    80004bf4:	1d850513          	addi	a0,a0,472 # 80460dc8 <ftable>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	23a080e7          	jalr	570(ra) # 80000e32 <release>
  }
}
    80004c00:	70e2                	ld	ra,56(sp)
    80004c02:	7442                	ld	s0,48(sp)
    80004c04:	74a2                	ld	s1,40(sp)
    80004c06:	7902                	ld	s2,32(sp)
    80004c08:	69e2                	ld	s3,24(sp)
    80004c0a:	6a42                	ld	s4,16(sp)
    80004c0c:	6aa2                	ld	s5,8(sp)
    80004c0e:	6121                	addi	sp,sp,64
    80004c10:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004c12:	85d6                	mv	a1,s5
    80004c14:	8552                	mv	a0,s4
    80004c16:	00000097          	auipc	ra,0x0
    80004c1a:	348080e7          	jalr	840(ra) # 80004f5e <pipeclose>
    80004c1e:	b7cd                	j	80004c00 <fileclose+0xa8>

0000000080004c20 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004c20:	715d                	addi	sp,sp,-80
    80004c22:	e486                	sd	ra,72(sp)
    80004c24:	e0a2                	sd	s0,64(sp)
    80004c26:	fc26                	sd	s1,56(sp)
    80004c28:	f84a                	sd	s2,48(sp)
    80004c2a:	f44e                	sd	s3,40(sp)
    80004c2c:	0880                	addi	s0,sp,80
    80004c2e:	84aa                	mv	s1,a0
    80004c30:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004c32:	ffffd097          	auipc	ra,0xffffd
    80004c36:	0cc080e7          	jalr	204(ra) # 80001cfe <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004c3a:	409c                	lw	a5,0(s1)
    80004c3c:	37f9                	addiw	a5,a5,-2
    80004c3e:	4705                	li	a4,1
    80004c40:	04f76763          	bltu	a4,a5,80004c8e <filestat+0x6e>
    80004c44:	892a                	mv	s2,a0
    ilock(f->ip);
    80004c46:	6c88                	ld	a0,24(s1)
    80004c48:	fffff097          	auipc	ra,0xfffff
    80004c4c:	0a6080e7          	jalr	166(ra) # 80003cee <ilock>
    stati(f->ip, &st);
    80004c50:	fb840593          	addi	a1,s0,-72
    80004c54:	6c88                	ld	a0,24(s1)
    80004c56:	fffff097          	auipc	ra,0xfffff
    80004c5a:	322080e7          	jalr	802(ra) # 80003f78 <stati>
    iunlock(f->ip);
    80004c5e:	6c88                	ld	a0,24(s1)
    80004c60:	fffff097          	auipc	ra,0xfffff
    80004c64:	150080e7          	jalr	336(ra) # 80003db0 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c68:	46e1                	li	a3,24
    80004c6a:	fb840613          	addi	a2,s0,-72
    80004c6e:	85ce                	mv	a1,s3
    80004c70:	05093503          	ld	a0,80(s2)
    80004c74:	ffffd097          	auipc	ra,0xffffd
    80004c78:	c56080e7          	jalr	-938(ra) # 800018ca <copyout>
    80004c7c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c80:	60a6                	ld	ra,72(sp)
    80004c82:	6406                	ld	s0,64(sp)
    80004c84:	74e2                	ld	s1,56(sp)
    80004c86:	7942                	ld	s2,48(sp)
    80004c88:	79a2                	ld	s3,40(sp)
    80004c8a:	6161                	addi	sp,sp,80
    80004c8c:	8082                	ret
  return -1;
    80004c8e:	557d                	li	a0,-1
    80004c90:	bfc5                	j	80004c80 <filestat+0x60>

0000000080004c92 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c92:	7179                	addi	sp,sp,-48
    80004c94:	f406                	sd	ra,40(sp)
    80004c96:	f022                	sd	s0,32(sp)
    80004c98:	ec26                	sd	s1,24(sp)
    80004c9a:	e84a                	sd	s2,16(sp)
    80004c9c:	e44e                	sd	s3,8(sp)
    80004c9e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ca0:	00854783          	lbu	a5,8(a0)
    80004ca4:	c3d5                	beqz	a5,80004d48 <fileread+0xb6>
    80004ca6:	84aa                	mv	s1,a0
    80004ca8:	89ae                	mv	s3,a1
    80004caa:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cac:	411c                	lw	a5,0(a0)
    80004cae:	4705                	li	a4,1
    80004cb0:	04e78963          	beq	a5,a4,80004d02 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cb4:	470d                	li	a4,3
    80004cb6:	04e78d63          	beq	a5,a4,80004d10 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cba:	4709                	li	a4,2
    80004cbc:	06e79e63          	bne	a5,a4,80004d38 <fileread+0xa6>
    ilock(f->ip);
    80004cc0:	6d08                	ld	a0,24(a0)
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	02c080e7          	jalr	44(ra) # 80003cee <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004cca:	874a                	mv	a4,s2
    80004ccc:	5094                	lw	a3,32(s1)
    80004cce:	864e                	mv	a2,s3
    80004cd0:	4585                	li	a1,1
    80004cd2:	6c88                	ld	a0,24(s1)
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	2ce080e7          	jalr	718(ra) # 80003fa2 <readi>
    80004cdc:	892a                	mv	s2,a0
    80004cde:	00a05563          	blez	a0,80004ce8 <fileread+0x56>
      f->off += r;
    80004ce2:	509c                	lw	a5,32(s1)
    80004ce4:	9fa9                	addw	a5,a5,a0
    80004ce6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ce8:	6c88                	ld	a0,24(s1)
    80004cea:	fffff097          	auipc	ra,0xfffff
    80004cee:	0c6080e7          	jalr	198(ra) # 80003db0 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004cf2:	854a                	mv	a0,s2
    80004cf4:	70a2                	ld	ra,40(sp)
    80004cf6:	7402                	ld	s0,32(sp)
    80004cf8:	64e2                	ld	s1,24(sp)
    80004cfa:	6942                	ld	s2,16(sp)
    80004cfc:	69a2                	ld	s3,8(sp)
    80004cfe:	6145                	addi	sp,sp,48
    80004d00:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004d02:	6908                	ld	a0,16(a0)
    80004d04:	00000097          	auipc	ra,0x0
    80004d08:	3c2080e7          	jalr	962(ra) # 800050c6 <piperead>
    80004d0c:	892a                	mv	s2,a0
    80004d0e:	b7d5                	j	80004cf2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004d10:	02451783          	lh	a5,36(a0)
    80004d14:	03079693          	slli	a3,a5,0x30
    80004d18:	92c1                	srli	a3,a3,0x30
    80004d1a:	4725                	li	a4,9
    80004d1c:	02d76863          	bltu	a4,a3,80004d4c <fileread+0xba>
    80004d20:	0792                	slli	a5,a5,0x4
    80004d22:	0045c717          	auipc	a4,0x45c
    80004d26:	00670713          	addi	a4,a4,6 # 80460d28 <devsw>
    80004d2a:	97ba                	add	a5,a5,a4
    80004d2c:	639c                	ld	a5,0(a5)
    80004d2e:	c38d                	beqz	a5,80004d50 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004d30:	4505                	li	a0,1
    80004d32:	9782                	jalr	a5
    80004d34:	892a                	mv	s2,a0
    80004d36:	bf75                	j	80004cf2 <fileread+0x60>
    panic("fileread");
    80004d38:	00004517          	auipc	a0,0x4
    80004d3c:	aa850513          	addi	a0,a0,-1368 # 800087e0 <syscalls+0x280>
    80004d40:	ffffb097          	auipc	ra,0xffffb
    80004d44:	7fc080e7          	jalr	2044(ra) # 8000053c <panic>
    return -1;
    80004d48:	597d                	li	s2,-1
    80004d4a:	b765                	j	80004cf2 <fileread+0x60>
      return -1;
    80004d4c:	597d                	li	s2,-1
    80004d4e:	b755                	j	80004cf2 <fileread+0x60>
    80004d50:	597d                	li	s2,-1
    80004d52:	b745                	j	80004cf2 <fileread+0x60>

0000000080004d54 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004d54:	00954783          	lbu	a5,9(a0)
    80004d58:	10078e63          	beqz	a5,80004e74 <filewrite+0x120>
{
    80004d5c:	715d                	addi	sp,sp,-80
    80004d5e:	e486                	sd	ra,72(sp)
    80004d60:	e0a2                	sd	s0,64(sp)
    80004d62:	fc26                	sd	s1,56(sp)
    80004d64:	f84a                	sd	s2,48(sp)
    80004d66:	f44e                	sd	s3,40(sp)
    80004d68:	f052                	sd	s4,32(sp)
    80004d6a:	ec56                	sd	s5,24(sp)
    80004d6c:	e85a                	sd	s6,16(sp)
    80004d6e:	e45e                	sd	s7,8(sp)
    80004d70:	e062                	sd	s8,0(sp)
    80004d72:	0880                	addi	s0,sp,80
    80004d74:	892a                	mv	s2,a0
    80004d76:	8b2e                	mv	s6,a1
    80004d78:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d7a:	411c                	lw	a5,0(a0)
    80004d7c:	4705                	li	a4,1
    80004d7e:	02e78263          	beq	a5,a4,80004da2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d82:	470d                	li	a4,3
    80004d84:	02e78563          	beq	a5,a4,80004dae <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d88:	4709                	li	a4,2
    80004d8a:	0ce79d63          	bne	a5,a4,80004e64 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d8e:	0ac05b63          	blez	a2,80004e44 <filewrite+0xf0>
    int i = 0;
    80004d92:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004d94:	6b85                	lui	s7,0x1
    80004d96:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d9a:	6c05                	lui	s8,0x1
    80004d9c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004da0:	a851                	j	80004e34 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004da2:	6908                	ld	a0,16(a0)
    80004da4:	00000097          	auipc	ra,0x0
    80004da8:	22a080e7          	jalr	554(ra) # 80004fce <pipewrite>
    80004dac:	a045                	j	80004e4c <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004dae:	02451783          	lh	a5,36(a0)
    80004db2:	03079693          	slli	a3,a5,0x30
    80004db6:	92c1                	srli	a3,a3,0x30
    80004db8:	4725                	li	a4,9
    80004dba:	0ad76f63          	bltu	a4,a3,80004e78 <filewrite+0x124>
    80004dbe:	0792                	slli	a5,a5,0x4
    80004dc0:	0045c717          	auipc	a4,0x45c
    80004dc4:	f6870713          	addi	a4,a4,-152 # 80460d28 <devsw>
    80004dc8:	97ba                	add	a5,a5,a4
    80004dca:	679c                	ld	a5,8(a5)
    80004dcc:	cbc5                	beqz	a5,80004e7c <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004dce:	4505                	li	a0,1
    80004dd0:	9782                	jalr	a5
    80004dd2:	a8ad                	j	80004e4c <filewrite+0xf8>
      if(n1 > max)
    80004dd4:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004dd8:	00000097          	auipc	ra,0x0
    80004ddc:	8bc080e7          	jalr	-1860(ra) # 80004694 <begin_op>
      ilock(f->ip);
    80004de0:	01893503          	ld	a0,24(s2)
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	f0a080e7          	jalr	-246(ra) # 80003cee <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004dec:	8756                	mv	a4,s5
    80004dee:	02092683          	lw	a3,32(s2)
    80004df2:	01698633          	add	a2,s3,s6
    80004df6:	4585                	li	a1,1
    80004df8:	01893503          	ld	a0,24(s2)
    80004dfc:	fffff097          	auipc	ra,0xfffff
    80004e00:	29e080e7          	jalr	670(ra) # 8000409a <writei>
    80004e04:	84aa                	mv	s1,a0
    80004e06:	00a05763          	blez	a0,80004e14 <filewrite+0xc0>
        f->off += r;
    80004e0a:	02092783          	lw	a5,32(s2)
    80004e0e:	9fa9                	addw	a5,a5,a0
    80004e10:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004e14:	01893503          	ld	a0,24(s2)
    80004e18:	fffff097          	auipc	ra,0xfffff
    80004e1c:	f98080e7          	jalr	-104(ra) # 80003db0 <iunlock>
      end_op();
    80004e20:	00000097          	auipc	ra,0x0
    80004e24:	8ee080e7          	jalr	-1810(ra) # 8000470e <end_op>

      if(r != n1){
    80004e28:	009a9f63          	bne	s5,s1,80004e46 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004e2c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004e30:	0149db63          	bge	s3,s4,80004e46 <filewrite+0xf2>
      int n1 = n - i;
    80004e34:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004e38:	0004879b          	sext.w	a5,s1
    80004e3c:	f8fbdce3          	bge	s7,a5,80004dd4 <filewrite+0x80>
    80004e40:	84e2                	mv	s1,s8
    80004e42:	bf49                	j	80004dd4 <filewrite+0x80>
    int i = 0;
    80004e44:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004e46:	033a1d63          	bne	s4,s3,80004e80 <filewrite+0x12c>
    80004e4a:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004e4c:	60a6                	ld	ra,72(sp)
    80004e4e:	6406                	ld	s0,64(sp)
    80004e50:	74e2                	ld	s1,56(sp)
    80004e52:	7942                	ld	s2,48(sp)
    80004e54:	79a2                	ld	s3,40(sp)
    80004e56:	7a02                	ld	s4,32(sp)
    80004e58:	6ae2                	ld	s5,24(sp)
    80004e5a:	6b42                	ld	s6,16(sp)
    80004e5c:	6ba2                	ld	s7,8(sp)
    80004e5e:	6c02                	ld	s8,0(sp)
    80004e60:	6161                	addi	sp,sp,80
    80004e62:	8082                	ret
    panic("filewrite");
    80004e64:	00004517          	auipc	a0,0x4
    80004e68:	98c50513          	addi	a0,a0,-1652 # 800087f0 <syscalls+0x290>
    80004e6c:	ffffb097          	auipc	ra,0xffffb
    80004e70:	6d0080e7          	jalr	1744(ra) # 8000053c <panic>
    return -1;
    80004e74:	557d                	li	a0,-1
}
    80004e76:	8082                	ret
      return -1;
    80004e78:	557d                	li	a0,-1
    80004e7a:	bfc9                	j	80004e4c <filewrite+0xf8>
    80004e7c:	557d                	li	a0,-1
    80004e7e:	b7f9                	j	80004e4c <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004e80:	557d                	li	a0,-1
    80004e82:	b7e9                	j	80004e4c <filewrite+0xf8>

0000000080004e84 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e84:	7179                	addi	sp,sp,-48
    80004e86:	f406                	sd	ra,40(sp)
    80004e88:	f022                	sd	s0,32(sp)
    80004e8a:	ec26                	sd	s1,24(sp)
    80004e8c:	e84a                	sd	s2,16(sp)
    80004e8e:	e44e                	sd	s3,8(sp)
    80004e90:	e052                	sd	s4,0(sp)
    80004e92:	1800                	addi	s0,sp,48
    80004e94:	84aa                	mv	s1,a0
    80004e96:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e98:	0005b023          	sd	zero,0(a1)
    80004e9c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	bfc080e7          	jalr	-1028(ra) # 80004a9c <filealloc>
    80004ea8:	e088                	sd	a0,0(s1)
    80004eaa:	c551                	beqz	a0,80004f36 <pipealloc+0xb2>
    80004eac:	00000097          	auipc	ra,0x0
    80004eb0:	bf0080e7          	jalr	-1040(ra) # 80004a9c <filealloc>
    80004eb4:	00aa3023          	sd	a0,0(s4)
    80004eb8:	c92d                	beqz	a0,80004f2a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	d72080e7          	jalr	-654(ra) # 80000c2c <kalloc>
    80004ec2:	892a                	mv	s2,a0
    80004ec4:	c125                	beqz	a0,80004f24 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ec6:	4985                	li	s3,1
    80004ec8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004ecc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ed0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ed4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ed8:	00004597          	auipc	a1,0x4
    80004edc:	92858593          	addi	a1,a1,-1752 # 80008800 <syscalls+0x2a0>
    80004ee0:	ffffc097          	auipc	ra,0xffffc
    80004ee4:	e0e080e7          	jalr	-498(ra) # 80000cee <initlock>
  (*f0)->type = FD_PIPE;
    80004ee8:	609c                	ld	a5,0(s1)
    80004eea:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004eee:	609c                	ld	a5,0(s1)
    80004ef0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ef4:	609c                	ld	a5,0(s1)
    80004ef6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004efa:	609c                	ld	a5,0(s1)
    80004efc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004f00:	000a3783          	ld	a5,0(s4)
    80004f04:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004f08:	000a3783          	ld	a5,0(s4)
    80004f0c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004f10:	000a3783          	ld	a5,0(s4)
    80004f14:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004f18:	000a3783          	ld	a5,0(s4)
    80004f1c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004f20:	4501                	li	a0,0
    80004f22:	a025                	j	80004f4a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004f24:	6088                	ld	a0,0(s1)
    80004f26:	e501                	bnez	a0,80004f2e <pipealloc+0xaa>
    80004f28:	a039                	j	80004f36 <pipealloc+0xb2>
    80004f2a:	6088                	ld	a0,0(s1)
    80004f2c:	c51d                	beqz	a0,80004f5a <pipealloc+0xd6>
    fileclose(*f0);
    80004f2e:	00000097          	auipc	ra,0x0
    80004f32:	c2a080e7          	jalr	-982(ra) # 80004b58 <fileclose>
  if(*f1)
    80004f36:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004f3a:	557d                	li	a0,-1
  if(*f1)
    80004f3c:	c799                	beqz	a5,80004f4a <pipealloc+0xc6>
    fileclose(*f1);
    80004f3e:	853e                	mv	a0,a5
    80004f40:	00000097          	auipc	ra,0x0
    80004f44:	c18080e7          	jalr	-1000(ra) # 80004b58 <fileclose>
  return -1;
    80004f48:	557d                	li	a0,-1
}
    80004f4a:	70a2                	ld	ra,40(sp)
    80004f4c:	7402                	ld	s0,32(sp)
    80004f4e:	64e2                	ld	s1,24(sp)
    80004f50:	6942                	ld	s2,16(sp)
    80004f52:	69a2                	ld	s3,8(sp)
    80004f54:	6a02                	ld	s4,0(sp)
    80004f56:	6145                	addi	sp,sp,48
    80004f58:	8082                	ret
  return -1;
    80004f5a:	557d                	li	a0,-1
    80004f5c:	b7fd                	j	80004f4a <pipealloc+0xc6>

0000000080004f5e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f5e:	1101                	addi	sp,sp,-32
    80004f60:	ec06                	sd	ra,24(sp)
    80004f62:	e822                	sd	s0,16(sp)
    80004f64:	e426                	sd	s1,8(sp)
    80004f66:	e04a                	sd	s2,0(sp)
    80004f68:	1000                	addi	s0,sp,32
    80004f6a:	84aa                	mv	s1,a0
    80004f6c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	e10080e7          	jalr	-496(ra) # 80000d7e <acquire>
  if(writable){
    80004f76:	02090d63          	beqz	s2,80004fb0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004f7a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f7e:	21848513          	addi	a0,s1,536
    80004f82:	ffffd097          	auipc	ra,0xffffd
    80004f86:	548080e7          	jalr	1352(ra) # 800024ca <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f8a:	2204b783          	ld	a5,544(s1)
    80004f8e:	eb95                	bnez	a5,80004fc2 <pipeclose+0x64>
    release(&pi->lock);
    80004f90:	8526                	mv	a0,s1
    80004f92:	ffffc097          	auipc	ra,0xffffc
    80004f96:	ea0080e7          	jalr	-352(ra) # 80000e32 <release>
    kfree((char*)pi);
    80004f9a:	8526                	mv	a0,s1
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	af8080e7          	jalr	-1288(ra) # 80000a94 <kfree>
  } else
    release(&pi->lock);
}
    80004fa4:	60e2                	ld	ra,24(sp)
    80004fa6:	6442                	ld	s0,16(sp)
    80004fa8:	64a2                	ld	s1,8(sp)
    80004faa:	6902                	ld	s2,0(sp)
    80004fac:	6105                	addi	sp,sp,32
    80004fae:	8082                	ret
    pi->readopen = 0;
    80004fb0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004fb4:	21c48513          	addi	a0,s1,540
    80004fb8:	ffffd097          	auipc	ra,0xffffd
    80004fbc:	512080e7          	jalr	1298(ra) # 800024ca <wakeup>
    80004fc0:	b7e9                	j	80004f8a <pipeclose+0x2c>
    release(&pi->lock);
    80004fc2:	8526                	mv	a0,s1
    80004fc4:	ffffc097          	auipc	ra,0xffffc
    80004fc8:	e6e080e7          	jalr	-402(ra) # 80000e32 <release>
}
    80004fcc:	bfe1                	j	80004fa4 <pipeclose+0x46>

0000000080004fce <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004fce:	711d                	addi	sp,sp,-96
    80004fd0:	ec86                	sd	ra,88(sp)
    80004fd2:	e8a2                	sd	s0,80(sp)
    80004fd4:	e4a6                	sd	s1,72(sp)
    80004fd6:	e0ca                	sd	s2,64(sp)
    80004fd8:	fc4e                	sd	s3,56(sp)
    80004fda:	f852                	sd	s4,48(sp)
    80004fdc:	f456                	sd	s5,40(sp)
    80004fde:	f05a                	sd	s6,32(sp)
    80004fe0:	ec5e                	sd	s7,24(sp)
    80004fe2:	e862                	sd	s8,16(sp)
    80004fe4:	1080                	addi	s0,sp,96
    80004fe6:	84aa                	mv	s1,a0
    80004fe8:	8aae                	mv	s5,a1
    80004fea:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004fec:	ffffd097          	auipc	ra,0xffffd
    80004ff0:	d12080e7          	jalr	-750(ra) # 80001cfe <myproc>
    80004ff4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ff6:	8526                	mv	a0,s1
    80004ff8:	ffffc097          	auipc	ra,0xffffc
    80004ffc:	d86080e7          	jalr	-634(ra) # 80000d7e <acquire>
  while(i < n){
    80005000:	0b405663          	blez	s4,800050ac <pipewrite+0xde>
  int i = 0;
    80005004:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005006:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005008:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000500c:	21c48b93          	addi	s7,s1,540
    80005010:	a089                	j	80005052 <pipewrite+0x84>
      release(&pi->lock);
    80005012:	8526                	mv	a0,s1
    80005014:	ffffc097          	auipc	ra,0xffffc
    80005018:	e1e080e7          	jalr	-482(ra) # 80000e32 <release>
      return -1;
    8000501c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000501e:	854a                	mv	a0,s2
    80005020:	60e6                	ld	ra,88(sp)
    80005022:	6446                	ld	s0,80(sp)
    80005024:	64a6                	ld	s1,72(sp)
    80005026:	6906                	ld	s2,64(sp)
    80005028:	79e2                	ld	s3,56(sp)
    8000502a:	7a42                	ld	s4,48(sp)
    8000502c:	7aa2                	ld	s5,40(sp)
    8000502e:	7b02                	ld	s6,32(sp)
    80005030:	6be2                	ld	s7,24(sp)
    80005032:	6c42                	ld	s8,16(sp)
    80005034:	6125                	addi	sp,sp,96
    80005036:	8082                	ret
      wakeup(&pi->nread);
    80005038:	8562                	mv	a0,s8
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	490080e7          	jalr	1168(ra) # 800024ca <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005042:	85a6                	mv	a1,s1
    80005044:	855e                	mv	a0,s7
    80005046:	ffffd097          	auipc	ra,0xffffd
    8000504a:	420080e7          	jalr	1056(ra) # 80002466 <sleep>
  while(i < n){
    8000504e:	07495063          	bge	s2,s4,800050ae <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005052:	2204a783          	lw	a5,544(s1)
    80005056:	dfd5                	beqz	a5,80005012 <pipewrite+0x44>
    80005058:	854e                	mv	a0,s3
    8000505a:	ffffd097          	auipc	ra,0xffffd
    8000505e:	6b4080e7          	jalr	1716(ra) # 8000270e <killed>
    80005062:	f945                	bnez	a0,80005012 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005064:	2184a783          	lw	a5,536(s1)
    80005068:	21c4a703          	lw	a4,540(s1)
    8000506c:	2007879b          	addiw	a5,a5,512
    80005070:	fcf704e3          	beq	a4,a5,80005038 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005074:	4685                	li	a3,1
    80005076:	01590633          	add	a2,s2,s5
    8000507a:	faf40593          	addi	a1,s0,-81
    8000507e:	0509b503          	ld	a0,80(s3)
    80005082:	ffffd097          	auipc	ra,0xffffd
    80005086:	8d4080e7          	jalr	-1836(ra) # 80001956 <copyin>
    8000508a:	03650263          	beq	a0,s6,800050ae <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000508e:	21c4a783          	lw	a5,540(s1)
    80005092:	0017871b          	addiw	a4,a5,1
    80005096:	20e4ae23          	sw	a4,540(s1)
    8000509a:	1ff7f793          	andi	a5,a5,511
    8000509e:	97a6                	add	a5,a5,s1
    800050a0:	faf44703          	lbu	a4,-81(s0)
    800050a4:	00e78c23          	sb	a4,24(a5)
      i++;
    800050a8:	2905                	addiw	s2,s2,1
    800050aa:	b755                	j	8000504e <pipewrite+0x80>
  int i = 0;
    800050ac:	4901                	li	s2,0
  wakeup(&pi->nread);
    800050ae:	21848513          	addi	a0,s1,536
    800050b2:	ffffd097          	auipc	ra,0xffffd
    800050b6:	418080e7          	jalr	1048(ra) # 800024ca <wakeup>
  release(&pi->lock);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ffffc097          	auipc	ra,0xffffc
    800050c0:	d76080e7          	jalr	-650(ra) # 80000e32 <release>
  return i;
    800050c4:	bfa9                	j	8000501e <pipewrite+0x50>

00000000800050c6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800050c6:	715d                	addi	sp,sp,-80
    800050c8:	e486                	sd	ra,72(sp)
    800050ca:	e0a2                	sd	s0,64(sp)
    800050cc:	fc26                	sd	s1,56(sp)
    800050ce:	f84a                	sd	s2,48(sp)
    800050d0:	f44e                	sd	s3,40(sp)
    800050d2:	f052                	sd	s4,32(sp)
    800050d4:	ec56                	sd	s5,24(sp)
    800050d6:	e85a                	sd	s6,16(sp)
    800050d8:	0880                	addi	s0,sp,80
    800050da:	84aa                	mv	s1,a0
    800050dc:	892e                	mv	s2,a1
    800050de:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800050e0:	ffffd097          	auipc	ra,0xffffd
    800050e4:	c1e080e7          	jalr	-994(ra) # 80001cfe <myproc>
    800050e8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800050ea:	8526                	mv	a0,s1
    800050ec:	ffffc097          	auipc	ra,0xffffc
    800050f0:	c92080e7          	jalr	-878(ra) # 80000d7e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050f4:	2184a703          	lw	a4,536(s1)
    800050f8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050fc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005100:	02f71763          	bne	a4,a5,8000512e <piperead+0x68>
    80005104:	2244a783          	lw	a5,548(s1)
    80005108:	c39d                	beqz	a5,8000512e <piperead+0x68>
    if(killed(pr)){
    8000510a:	8552                	mv	a0,s4
    8000510c:	ffffd097          	auipc	ra,0xffffd
    80005110:	602080e7          	jalr	1538(ra) # 8000270e <killed>
    80005114:	e949                	bnez	a0,800051a6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005116:	85a6                	mv	a1,s1
    80005118:	854e                	mv	a0,s3
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	34c080e7          	jalr	844(ra) # 80002466 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005122:	2184a703          	lw	a4,536(s1)
    80005126:	21c4a783          	lw	a5,540(s1)
    8000512a:	fcf70de3          	beq	a4,a5,80005104 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000512e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005130:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005132:	05505463          	blez	s5,8000517a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005136:	2184a783          	lw	a5,536(s1)
    8000513a:	21c4a703          	lw	a4,540(s1)
    8000513e:	02f70e63          	beq	a4,a5,8000517a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005142:	0017871b          	addiw	a4,a5,1
    80005146:	20e4ac23          	sw	a4,536(s1)
    8000514a:	1ff7f793          	andi	a5,a5,511
    8000514e:	97a6                	add	a5,a5,s1
    80005150:	0187c783          	lbu	a5,24(a5)
    80005154:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005158:	4685                	li	a3,1
    8000515a:	fbf40613          	addi	a2,s0,-65
    8000515e:	85ca                	mv	a1,s2
    80005160:	050a3503          	ld	a0,80(s4)
    80005164:	ffffc097          	auipc	ra,0xffffc
    80005168:	766080e7          	jalr	1894(ra) # 800018ca <copyout>
    8000516c:	01650763          	beq	a0,s6,8000517a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005170:	2985                	addiw	s3,s3,1
    80005172:	0905                	addi	s2,s2,1
    80005174:	fd3a91e3          	bne	s5,s3,80005136 <piperead+0x70>
    80005178:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000517a:	21c48513          	addi	a0,s1,540
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	34c080e7          	jalr	844(ra) # 800024ca <wakeup>
  release(&pi->lock);
    80005186:	8526                	mv	a0,s1
    80005188:	ffffc097          	auipc	ra,0xffffc
    8000518c:	caa080e7          	jalr	-854(ra) # 80000e32 <release>
  return i;
}
    80005190:	854e                	mv	a0,s3
    80005192:	60a6                	ld	ra,72(sp)
    80005194:	6406                	ld	s0,64(sp)
    80005196:	74e2                	ld	s1,56(sp)
    80005198:	7942                	ld	s2,48(sp)
    8000519a:	79a2                	ld	s3,40(sp)
    8000519c:	7a02                	ld	s4,32(sp)
    8000519e:	6ae2                	ld	s5,24(sp)
    800051a0:	6b42                	ld	s6,16(sp)
    800051a2:	6161                	addi	sp,sp,80
    800051a4:	8082                	ret
      release(&pi->lock);
    800051a6:	8526                	mv	a0,s1
    800051a8:	ffffc097          	auipc	ra,0xffffc
    800051ac:	c8a080e7          	jalr	-886(ra) # 80000e32 <release>
      return -1;
    800051b0:	59fd                	li	s3,-1
    800051b2:	bff9                	j	80005190 <piperead+0xca>

00000000800051b4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800051b4:	1141                	addi	sp,sp,-16
    800051b6:	e422                	sd	s0,8(sp)
    800051b8:	0800                	addi	s0,sp,16
    800051ba:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800051bc:	8905                	andi	a0,a0,1
    800051be:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800051c0:	8b89                	andi	a5,a5,2
    800051c2:	c399                	beqz	a5,800051c8 <flags2perm+0x14>
      perm |= PTE_W;
    800051c4:	00456513          	ori	a0,a0,4
    return perm;
}
    800051c8:	6422                	ld	s0,8(sp)
    800051ca:	0141                	addi	sp,sp,16
    800051cc:	8082                	ret

00000000800051ce <exec>:

int
exec(char *path, char **argv)
{
    800051ce:	df010113          	addi	sp,sp,-528
    800051d2:	20113423          	sd	ra,520(sp)
    800051d6:	20813023          	sd	s0,512(sp)
    800051da:	ffa6                	sd	s1,504(sp)
    800051dc:	fbca                	sd	s2,496(sp)
    800051de:	f7ce                	sd	s3,488(sp)
    800051e0:	f3d2                	sd	s4,480(sp)
    800051e2:	efd6                	sd	s5,472(sp)
    800051e4:	ebda                	sd	s6,464(sp)
    800051e6:	e7de                	sd	s7,456(sp)
    800051e8:	e3e2                	sd	s8,448(sp)
    800051ea:	ff66                	sd	s9,440(sp)
    800051ec:	fb6a                	sd	s10,432(sp)
    800051ee:	f76e                	sd	s11,424(sp)
    800051f0:	0c00                	addi	s0,sp,528
    800051f2:	892a                	mv	s2,a0
    800051f4:	dea43c23          	sd	a0,-520(s0)
    800051f8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	b02080e7          	jalr	-1278(ra) # 80001cfe <myproc>
    80005204:	84aa                	mv	s1,a0

  begin_op();
    80005206:	fffff097          	auipc	ra,0xfffff
    8000520a:	48e080e7          	jalr	1166(ra) # 80004694 <begin_op>

  if((ip = namei(path)) == 0){
    8000520e:	854a                	mv	a0,s2
    80005210:	fffff097          	auipc	ra,0xfffff
    80005214:	284080e7          	jalr	644(ra) # 80004494 <namei>
    80005218:	c92d                	beqz	a0,8000528a <exec+0xbc>
    8000521a:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000521c:	fffff097          	auipc	ra,0xfffff
    80005220:	ad2080e7          	jalr	-1326(ra) # 80003cee <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005224:	04000713          	li	a4,64
    80005228:	4681                	li	a3,0
    8000522a:	e5040613          	addi	a2,s0,-432
    8000522e:	4581                	li	a1,0
    80005230:	8552                	mv	a0,s4
    80005232:	fffff097          	auipc	ra,0xfffff
    80005236:	d70080e7          	jalr	-656(ra) # 80003fa2 <readi>
    8000523a:	04000793          	li	a5,64
    8000523e:	00f51a63          	bne	a0,a5,80005252 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005242:	e5042703          	lw	a4,-432(s0)
    80005246:	464c47b7          	lui	a5,0x464c4
    8000524a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000524e:	04f70463          	beq	a4,a5,80005296 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005252:	8552                	mv	a0,s4
    80005254:	fffff097          	auipc	ra,0xfffff
    80005258:	cfc080e7          	jalr	-772(ra) # 80003f50 <iunlockput>
    end_op();
    8000525c:	fffff097          	auipc	ra,0xfffff
    80005260:	4b2080e7          	jalr	1202(ra) # 8000470e <end_op>
  }
  return -1;
    80005264:	557d                	li	a0,-1
}
    80005266:	20813083          	ld	ra,520(sp)
    8000526a:	20013403          	ld	s0,512(sp)
    8000526e:	74fe                	ld	s1,504(sp)
    80005270:	795e                	ld	s2,496(sp)
    80005272:	79be                	ld	s3,488(sp)
    80005274:	7a1e                	ld	s4,480(sp)
    80005276:	6afe                	ld	s5,472(sp)
    80005278:	6b5e                	ld	s6,464(sp)
    8000527a:	6bbe                	ld	s7,456(sp)
    8000527c:	6c1e                	ld	s8,448(sp)
    8000527e:	7cfa                	ld	s9,440(sp)
    80005280:	7d5a                	ld	s10,432(sp)
    80005282:	7dba                	ld	s11,424(sp)
    80005284:	21010113          	addi	sp,sp,528
    80005288:	8082                	ret
    end_op();
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	484080e7          	jalr	1156(ra) # 8000470e <end_op>
    return -1;
    80005292:	557d                	li	a0,-1
    80005294:	bfc9                	j	80005266 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005296:	8526                	mv	a0,s1
    80005298:	ffffd097          	auipc	ra,0xffffd
    8000529c:	b2a080e7          	jalr	-1238(ra) # 80001dc2 <proc_pagetable>
    800052a0:	8b2a                	mv	s6,a0
    800052a2:	d945                	beqz	a0,80005252 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052a4:	e7042d03          	lw	s10,-400(s0)
    800052a8:	e8845783          	lhu	a5,-376(s0)
    800052ac:	10078463          	beqz	a5,800053b4 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800052b0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052b2:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800052b4:	6c85                	lui	s9,0x1
    800052b6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800052ba:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800052be:	6a85                	lui	s5,0x1
    800052c0:	a0b5                	j	8000532c <exec+0x15e>
      panic("loadseg: address should exist");
    800052c2:	00003517          	auipc	a0,0x3
    800052c6:	54650513          	addi	a0,a0,1350 # 80008808 <syscalls+0x2a8>
    800052ca:	ffffb097          	auipc	ra,0xffffb
    800052ce:	272080e7          	jalr	626(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800052d2:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800052d4:	8726                	mv	a4,s1
    800052d6:	012c06bb          	addw	a3,s8,s2
    800052da:	4581                	li	a1,0
    800052dc:	8552                	mv	a0,s4
    800052de:	fffff097          	auipc	ra,0xfffff
    800052e2:	cc4080e7          	jalr	-828(ra) # 80003fa2 <readi>
    800052e6:	2501                	sext.w	a0,a0
    800052e8:	24a49863          	bne	s1,a0,80005538 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800052ec:	012a893b          	addw	s2,s5,s2
    800052f0:	03397563          	bgeu	s2,s3,8000531a <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800052f4:	02091593          	slli	a1,s2,0x20
    800052f8:	9181                	srli	a1,a1,0x20
    800052fa:	95de                	add	a1,a1,s7
    800052fc:	855a                	mv	a0,s6
    800052fe:	ffffc097          	auipc	ra,0xffffc
    80005302:	f04080e7          	jalr	-252(ra) # 80001202 <walkaddr>
    80005306:	862a                	mv	a2,a0
    if(pa == 0)
    80005308:	dd4d                	beqz	a0,800052c2 <exec+0xf4>
    if(sz - i < PGSIZE)
    8000530a:	412984bb          	subw	s1,s3,s2
    8000530e:	0004879b          	sext.w	a5,s1
    80005312:	fcfcf0e3          	bgeu	s9,a5,800052d2 <exec+0x104>
    80005316:	84d6                	mv	s1,s5
    80005318:	bf6d                	j	800052d2 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000531a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000531e:	2d85                	addiw	s11,s11,1
    80005320:	038d0d1b          	addiw	s10,s10,56
    80005324:	e8845783          	lhu	a5,-376(s0)
    80005328:	08fdd763          	bge	s11,a5,800053b6 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000532c:	2d01                	sext.w	s10,s10
    8000532e:	03800713          	li	a4,56
    80005332:	86ea                	mv	a3,s10
    80005334:	e1840613          	addi	a2,s0,-488
    80005338:	4581                	li	a1,0
    8000533a:	8552                	mv	a0,s4
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	c66080e7          	jalr	-922(ra) # 80003fa2 <readi>
    80005344:	03800793          	li	a5,56
    80005348:	1ef51663          	bne	a0,a5,80005534 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000534c:	e1842783          	lw	a5,-488(s0)
    80005350:	4705                	li	a4,1
    80005352:	fce796e3          	bne	a5,a4,8000531e <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005356:	e4043483          	ld	s1,-448(s0)
    8000535a:	e3843783          	ld	a5,-456(s0)
    8000535e:	1ef4e863          	bltu	s1,a5,8000554e <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005362:	e2843783          	ld	a5,-472(s0)
    80005366:	94be                	add	s1,s1,a5
    80005368:	1ef4e663          	bltu	s1,a5,80005554 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000536c:	df043703          	ld	a4,-528(s0)
    80005370:	8ff9                	and	a5,a5,a4
    80005372:	1e079463          	bnez	a5,8000555a <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005376:	e1c42503          	lw	a0,-484(s0)
    8000537a:	00000097          	auipc	ra,0x0
    8000537e:	e3a080e7          	jalr	-454(ra) # 800051b4 <flags2perm>
    80005382:	86aa                	mv	a3,a0
    80005384:	8626                	mv	a2,s1
    80005386:	85ca                	mv	a1,s2
    80005388:	855a                	mv	a0,s6
    8000538a:	ffffc097          	auipc	ra,0xffffc
    8000538e:	22c080e7          	jalr	556(ra) # 800015b6 <uvmalloc>
    80005392:	e0a43423          	sd	a0,-504(s0)
    80005396:	1c050563          	beqz	a0,80005560 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000539a:	e2843b83          	ld	s7,-472(s0)
    8000539e:	e2042c03          	lw	s8,-480(s0)
    800053a2:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053a6:	00098463          	beqz	s3,800053ae <exec+0x1e0>
    800053aa:	4901                	li	s2,0
    800053ac:	b7a1                	j	800052f4 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053ae:	e0843903          	ld	s2,-504(s0)
    800053b2:	b7b5                	j	8000531e <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053b4:	4901                	li	s2,0
  iunlockput(ip);
    800053b6:	8552                	mv	a0,s4
    800053b8:	fffff097          	auipc	ra,0xfffff
    800053bc:	b98080e7          	jalr	-1128(ra) # 80003f50 <iunlockput>
  end_op();
    800053c0:	fffff097          	auipc	ra,0xfffff
    800053c4:	34e080e7          	jalr	846(ra) # 8000470e <end_op>
  p = myproc();
    800053c8:	ffffd097          	auipc	ra,0xffffd
    800053cc:	936080e7          	jalr	-1738(ra) # 80001cfe <myproc>
    800053d0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800053d2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800053d6:	6985                	lui	s3,0x1
    800053d8:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800053da:	99ca                	add	s3,s3,s2
    800053dc:	77fd                	lui	a5,0xfffff
    800053de:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800053e2:	4691                	li	a3,4
    800053e4:	6609                	lui	a2,0x2
    800053e6:	964e                	add	a2,a2,s3
    800053e8:	85ce                	mv	a1,s3
    800053ea:	855a                	mv	a0,s6
    800053ec:	ffffc097          	auipc	ra,0xffffc
    800053f0:	1ca080e7          	jalr	458(ra) # 800015b6 <uvmalloc>
    800053f4:	892a                	mv	s2,a0
    800053f6:	e0a43423          	sd	a0,-504(s0)
    800053fa:	e509                	bnez	a0,80005404 <exec+0x236>
  if(pagetable)
    800053fc:	e1343423          	sd	s3,-504(s0)
    80005400:	4a01                	li	s4,0
    80005402:	aa1d                	j	80005538 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005404:	75f9                	lui	a1,0xffffe
    80005406:	95aa                	add	a1,a1,a0
    80005408:	855a                	mv	a0,s6
    8000540a:	ffffc097          	auipc	ra,0xffffc
    8000540e:	48e080e7          	jalr	1166(ra) # 80001898 <uvmclear>
  stackbase = sp - PGSIZE;
    80005412:	7bfd                	lui	s7,0xfffff
    80005414:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005416:	e0043783          	ld	a5,-512(s0)
    8000541a:	6388                	ld	a0,0(a5)
    8000541c:	c52d                	beqz	a0,80005486 <exec+0x2b8>
    8000541e:	e9040993          	addi	s3,s0,-368
    80005422:	f9040c13          	addi	s8,s0,-112
    80005426:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005428:	ffffc097          	auipc	ra,0xffffc
    8000542c:	bcc080e7          	jalr	-1076(ra) # 80000ff4 <strlen>
    80005430:	0015079b          	addiw	a5,a0,1
    80005434:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005438:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000543c:	13796563          	bltu	s2,s7,80005566 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005440:	e0043d03          	ld	s10,-512(s0)
    80005444:	000d3a03          	ld	s4,0(s10)
    80005448:	8552                	mv	a0,s4
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	baa080e7          	jalr	-1110(ra) # 80000ff4 <strlen>
    80005452:	0015069b          	addiw	a3,a0,1
    80005456:	8652                	mv	a2,s4
    80005458:	85ca                	mv	a1,s2
    8000545a:	855a                	mv	a0,s6
    8000545c:	ffffc097          	auipc	ra,0xffffc
    80005460:	46e080e7          	jalr	1134(ra) # 800018ca <copyout>
    80005464:	10054363          	bltz	a0,8000556a <exec+0x39c>
    ustack[argc] = sp;
    80005468:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000546c:	0485                	addi	s1,s1,1
    8000546e:	008d0793          	addi	a5,s10,8
    80005472:	e0f43023          	sd	a5,-512(s0)
    80005476:	008d3503          	ld	a0,8(s10)
    8000547a:	c909                	beqz	a0,8000548c <exec+0x2be>
    if(argc >= MAXARG)
    8000547c:	09a1                	addi	s3,s3,8
    8000547e:	fb8995e3          	bne	s3,s8,80005428 <exec+0x25a>
  ip = 0;
    80005482:	4a01                	li	s4,0
    80005484:	a855                	j	80005538 <exec+0x36a>
  sp = sz;
    80005486:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000548a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000548c:	00349793          	slli	a5,s1,0x3
    80005490:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fb9d0d0>
    80005494:	97a2                	add	a5,a5,s0
    80005496:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000549a:	00148693          	addi	a3,s1,1
    8000549e:	068e                	slli	a3,a3,0x3
    800054a0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800054a4:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800054a8:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800054ac:	f57968e3          	bltu	s2,s7,800053fc <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800054b0:	e9040613          	addi	a2,s0,-368
    800054b4:	85ca                	mv	a1,s2
    800054b6:	855a                	mv	a0,s6
    800054b8:	ffffc097          	auipc	ra,0xffffc
    800054bc:	412080e7          	jalr	1042(ra) # 800018ca <copyout>
    800054c0:	0a054763          	bltz	a0,8000556e <exec+0x3a0>
  p->trapframe->a1 = sp;
    800054c4:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800054c8:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800054cc:	df843783          	ld	a5,-520(s0)
    800054d0:	0007c703          	lbu	a4,0(a5)
    800054d4:	cf11                	beqz	a4,800054f0 <exec+0x322>
    800054d6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800054d8:	02f00693          	li	a3,47
    800054dc:	a039                	j	800054ea <exec+0x31c>
      last = s+1;
    800054de:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800054e2:	0785                	addi	a5,a5,1
    800054e4:	fff7c703          	lbu	a4,-1(a5)
    800054e8:	c701                	beqz	a4,800054f0 <exec+0x322>
    if(*s == '/')
    800054ea:	fed71ce3          	bne	a4,a3,800054e2 <exec+0x314>
    800054ee:	bfc5                	j	800054de <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800054f0:	4641                	li	a2,16
    800054f2:	df843583          	ld	a1,-520(s0)
    800054f6:	158a8513          	addi	a0,s5,344
    800054fa:	ffffc097          	auipc	ra,0xffffc
    800054fe:	ac8080e7          	jalr	-1336(ra) # 80000fc2 <safestrcpy>
  oldpagetable = p->pagetable;
    80005502:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005506:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000550a:	e0843783          	ld	a5,-504(s0)
    8000550e:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005512:	058ab783          	ld	a5,88(s5)
    80005516:	e6843703          	ld	a4,-408(s0)
    8000551a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000551c:	058ab783          	ld	a5,88(s5)
    80005520:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005524:	85e6                	mv	a1,s9
    80005526:	ffffd097          	auipc	ra,0xffffd
    8000552a:	938080e7          	jalr	-1736(ra) # 80001e5e <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000552e:	0004851b          	sext.w	a0,s1
    80005532:	bb15                	j	80005266 <exec+0x98>
    80005534:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005538:	e0843583          	ld	a1,-504(s0)
    8000553c:	855a                	mv	a0,s6
    8000553e:	ffffd097          	auipc	ra,0xffffd
    80005542:	920080e7          	jalr	-1760(ra) # 80001e5e <proc_freepagetable>
  return -1;
    80005546:	557d                	li	a0,-1
  if(ip){
    80005548:	d00a0fe3          	beqz	s4,80005266 <exec+0x98>
    8000554c:	b319                	j	80005252 <exec+0x84>
    8000554e:	e1243423          	sd	s2,-504(s0)
    80005552:	b7dd                	j	80005538 <exec+0x36a>
    80005554:	e1243423          	sd	s2,-504(s0)
    80005558:	b7c5                	j	80005538 <exec+0x36a>
    8000555a:	e1243423          	sd	s2,-504(s0)
    8000555e:	bfe9                	j	80005538 <exec+0x36a>
    80005560:	e1243423          	sd	s2,-504(s0)
    80005564:	bfd1                	j	80005538 <exec+0x36a>
  ip = 0;
    80005566:	4a01                	li	s4,0
    80005568:	bfc1                	j	80005538 <exec+0x36a>
    8000556a:	4a01                	li	s4,0
  if(pagetable)
    8000556c:	b7f1                	j	80005538 <exec+0x36a>
  sz = sz1;
    8000556e:	e0843983          	ld	s3,-504(s0)
    80005572:	b569                	j	800053fc <exec+0x22e>

0000000080005574 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005574:	7179                	addi	sp,sp,-48
    80005576:	f406                	sd	ra,40(sp)
    80005578:	f022                	sd	s0,32(sp)
    8000557a:	ec26                	sd	s1,24(sp)
    8000557c:	e84a                	sd	s2,16(sp)
    8000557e:	1800                	addi	s0,sp,48
    80005580:	892e                	mv	s2,a1
    80005582:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005584:	fdc40593          	addi	a1,s0,-36
    80005588:	ffffe097          	auipc	ra,0xffffe
    8000558c:	aaa080e7          	jalr	-1366(ra) # 80003032 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005590:	fdc42703          	lw	a4,-36(s0)
    80005594:	47bd                	li	a5,15
    80005596:	02e7eb63          	bltu	a5,a4,800055cc <argfd+0x58>
    8000559a:	ffffc097          	auipc	ra,0xffffc
    8000559e:	764080e7          	jalr	1892(ra) # 80001cfe <myproc>
    800055a2:	fdc42703          	lw	a4,-36(s0)
    800055a6:	01a70793          	addi	a5,a4,26
    800055aa:	078e                	slli	a5,a5,0x3
    800055ac:	953e                	add	a0,a0,a5
    800055ae:	611c                	ld	a5,0(a0)
    800055b0:	c385                	beqz	a5,800055d0 <argfd+0x5c>
    return -1;
  if(pfd)
    800055b2:	00090463          	beqz	s2,800055ba <argfd+0x46>
    *pfd = fd;
    800055b6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800055ba:	4501                	li	a0,0
  if(pf)
    800055bc:	c091                	beqz	s1,800055c0 <argfd+0x4c>
    *pf = f;
    800055be:	e09c                	sd	a5,0(s1)
}
    800055c0:	70a2                	ld	ra,40(sp)
    800055c2:	7402                	ld	s0,32(sp)
    800055c4:	64e2                	ld	s1,24(sp)
    800055c6:	6942                	ld	s2,16(sp)
    800055c8:	6145                	addi	sp,sp,48
    800055ca:	8082                	ret
    return -1;
    800055cc:	557d                	li	a0,-1
    800055ce:	bfcd                	j	800055c0 <argfd+0x4c>
    800055d0:	557d                	li	a0,-1
    800055d2:	b7fd                	j	800055c0 <argfd+0x4c>

00000000800055d4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800055d4:	1101                	addi	sp,sp,-32
    800055d6:	ec06                	sd	ra,24(sp)
    800055d8:	e822                	sd	s0,16(sp)
    800055da:	e426                	sd	s1,8(sp)
    800055dc:	1000                	addi	s0,sp,32
    800055de:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800055e0:	ffffc097          	auipc	ra,0xffffc
    800055e4:	71e080e7          	jalr	1822(ra) # 80001cfe <myproc>
    800055e8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800055ea:	0d050793          	addi	a5,a0,208
    800055ee:	4501                	li	a0,0
    800055f0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800055f2:	6398                	ld	a4,0(a5)
    800055f4:	cb19                	beqz	a4,8000560a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055f6:	2505                	addiw	a0,a0,1
    800055f8:	07a1                	addi	a5,a5,8
    800055fa:	fed51ce3          	bne	a0,a3,800055f2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055fe:	557d                	li	a0,-1
}
    80005600:	60e2                	ld	ra,24(sp)
    80005602:	6442                	ld	s0,16(sp)
    80005604:	64a2                	ld	s1,8(sp)
    80005606:	6105                	addi	sp,sp,32
    80005608:	8082                	ret
      p->ofile[fd] = f;
    8000560a:	01a50793          	addi	a5,a0,26
    8000560e:	078e                	slli	a5,a5,0x3
    80005610:	963e                	add	a2,a2,a5
    80005612:	e204                	sd	s1,0(a2)
      return fd;
    80005614:	b7f5                	j	80005600 <fdalloc+0x2c>

0000000080005616 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005616:	715d                	addi	sp,sp,-80
    80005618:	e486                	sd	ra,72(sp)
    8000561a:	e0a2                	sd	s0,64(sp)
    8000561c:	fc26                	sd	s1,56(sp)
    8000561e:	f84a                	sd	s2,48(sp)
    80005620:	f44e                	sd	s3,40(sp)
    80005622:	f052                	sd	s4,32(sp)
    80005624:	ec56                	sd	s5,24(sp)
    80005626:	e85a                	sd	s6,16(sp)
    80005628:	0880                	addi	s0,sp,80
    8000562a:	8b2e                	mv	s6,a1
    8000562c:	89b2                	mv	s3,a2
    8000562e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005630:	fb040593          	addi	a1,s0,-80
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	e7e080e7          	jalr	-386(ra) # 800044b2 <nameiparent>
    8000563c:	84aa                	mv	s1,a0
    8000563e:	14050b63          	beqz	a0,80005794 <create+0x17e>
    return 0;

  ilock(dp);
    80005642:	ffffe097          	auipc	ra,0xffffe
    80005646:	6ac080e7          	jalr	1708(ra) # 80003cee <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000564a:	4601                	li	a2,0
    8000564c:	fb040593          	addi	a1,s0,-80
    80005650:	8526                	mv	a0,s1
    80005652:	fffff097          	auipc	ra,0xfffff
    80005656:	b80080e7          	jalr	-1152(ra) # 800041d2 <dirlookup>
    8000565a:	8aaa                	mv	s5,a0
    8000565c:	c921                	beqz	a0,800056ac <create+0x96>
    iunlockput(dp);
    8000565e:	8526                	mv	a0,s1
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	8f0080e7          	jalr	-1808(ra) # 80003f50 <iunlockput>
    ilock(ip);
    80005668:	8556                	mv	a0,s5
    8000566a:	ffffe097          	auipc	ra,0xffffe
    8000566e:	684080e7          	jalr	1668(ra) # 80003cee <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005672:	4789                	li	a5,2
    80005674:	02fb1563          	bne	s6,a5,8000569e <create+0x88>
    80005678:	044ad783          	lhu	a5,68(s5)
    8000567c:	37f9                	addiw	a5,a5,-2
    8000567e:	17c2                	slli	a5,a5,0x30
    80005680:	93c1                	srli	a5,a5,0x30
    80005682:	4705                	li	a4,1
    80005684:	00f76d63          	bltu	a4,a5,8000569e <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005688:	8556                	mv	a0,s5
    8000568a:	60a6                	ld	ra,72(sp)
    8000568c:	6406                	ld	s0,64(sp)
    8000568e:	74e2                	ld	s1,56(sp)
    80005690:	7942                	ld	s2,48(sp)
    80005692:	79a2                	ld	s3,40(sp)
    80005694:	7a02                	ld	s4,32(sp)
    80005696:	6ae2                	ld	s5,24(sp)
    80005698:	6b42                	ld	s6,16(sp)
    8000569a:	6161                	addi	sp,sp,80
    8000569c:	8082                	ret
    iunlockput(ip);
    8000569e:	8556                	mv	a0,s5
    800056a0:	fffff097          	auipc	ra,0xfffff
    800056a4:	8b0080e7          	jalr	-1872(ra) # 80003f50 <iunlockput>
    return 0;
    800056a8:	4a81                	li	s5,0
    800056aa:	bff9                	j	80005688 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800056ac:	85da                	mv	a1,s6
    800056ae:	4088                	lw	a0,0(s1)
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	4a6080e7          	jalr	1190(ra) # 80003b56 <ialloc>
    800056b8:	8a2a                	mv	s4,a0
    800056ba:	c529                	beqz	a0,80005704 <create+0xee>
  ilock(ip);
    800056bc:	ffffe097          	auipc	ra,0xffffe
    800056c0:	632080e7          	jalr	1586(ra) # 80003cee <ilock>
  ip->major = major;
    800056c4:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800056c8:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800056cc:	4905                	li	s2,1
    800056ce:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800056d2:	8552                	mv	a0,s4
    800056d4:	ffffe097          	auipc	ra,0xffffe
    800056d8:	54e080e7          	jalr	1358(ra) # 80003c22 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800056dc:	032b0b63          	beq	s6,s2,80005712 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800056e0:	004a2603          	lw	a2,4(s4)
    800056e4:	fb040593          	addi	a1,s0,-80
    800056e8:	8526                	mv	a0,s1
    800056ea:	fffff097          	auipc	ra,0xfffff
    800056ee:	cf8080e7          	jalr	-776(ra) # 800043e2 <dirlink>
    800056f2:	06054f63          	bltz	a0,80005770 <create+0x15a>
  iunlockput(dp);
    800056f6:	8526                	mv	a0,s1
    800056f8:	fffff097          	auipc	ra,0xfffff
    800056fc:	858080e7          	jalr	-1960(ra) # 80003f50 <iunlockput>
  return ip;
    80005700:	8ad2                	mv	s5,s4
    80005702:	b759                	j	80005688 <create+0x72>
    iunlockput(dp);
    80005704:	8526                	mv	a0,s1
    80005706:	fffff097          	auipc	ra,0xfffff
    8000570a:	84a080e7          	jalr	-1974(ra) # 80003f50 <iunlockput>
    return 0;
    8000570e:	8ad2                	mv	s5,s4
    80005710:	bfa5                	j	80005688 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005712:	004a2603          	lw	a2,4(s4)
    80005716:	00003597          	auipc	a1,0x3
    8000571a:	11258593          	addi	a1,a1,274 # 80008828 <syscalls+0x2c8>
    8000571e:	8552                	mv	a0,s4
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	cc2080e7          	jalr	-830(ra) # 800043e2 <dirlink>
    80005728:	04054463          	bltz	a0,80005770 <create+0x15a>
    8000572c:	40d0                	lw	a2,4(s1)
    8000572e:	00003597          	auipc	a1,0x3
    80005732:	10258593          	addi	a1,a1,258 # 80008830 <syscalls+0x2d0>
    80005736:	8552                	mv	a0,s4
    80005738:	fffff097          	auipc	ra,0xfffff
    8000573c:	caa080e7          	jalr	-854(ra) # 800043e2 <dirlink>
    80005740:	02054863          	bltz	a0,80005770 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005744:	004a2603          	lw	a2,4(s4)
    80005748:	fb040593          	addi	a1,s0,-80
    8000574c:	8526                	mv	a0,s1
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	c94080e7          	jalr	-876(ra) # 800043e2 <dirlink>
    80005756:	00054d63          	bltz	a0,80005770 <create+0x15a>
    dp->nlink++;  // for ".."
    8000575a:	04a4d783          	lhu	a5,74(s1)
    8000575e:	2785                	addiw	a5,a5,1
    80005760:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005764:	8526                	mv	a0,s1
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	4bc080e7          	jalr	1212(ra) # 80003c22 <iupdate>
    8000576e:	b761                	j	800056f6 <create+0xe0>
  ip->nlink = 0;
    80005770:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005774:	8552                	mv	a0,s4
    80005776:	ffffe097          	auipc	ra,0xffffe
    8000577a:	4ac080e7          	jalr	1196(ra) # 80003c22 <iupdate>
  iunlockput(ip);
    8000577e:	8552                	mv	a0,s4
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	7d0080e7          	jalr	2000(ra) # 80003f50 <iunlockput>
  iunlockput(dp);
    80005788:	8526                	mv	a0,s1
    8000578a:	ffffe097          	auipc	ra,0xffffe
    8000578e:	7c6080e7          	jalr	1990(ra) # 80003f50 <iunlockput>
  return 0;
    80005792:	bddd                	j	80005688 <create+0x72>
    return 0;
    80005794:	8aaa                	mv	s5,a0
    80005796:	bdcd                	j	80005688 <create+0x72>

0000000080005798 <sys_dup>:
{
    80005798:	7179                	addi	sp,sp,-48
    8000579a:	f406                	sd	ra,40(sp)
    8000579c:	f022                	sd	s0,32(sp)
    8000579e:	ec26                	sd	s1,24(sp)
    800057a0:	e84a                	sd	s2,16(sp)
    800057a2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800057a4:	fd840613          	addi	a2,s0,-40
    800057a8:	4581                	li	a1,0
    800057aa:	4501                	li	a0,0
    800057ac:	00000097          	auipc	ra,0x0
    800057b0:	dc8080e7          	jalr	-568(ra) # 80005574 <argfd>
    return -1;
    800057b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800057b6:	02054363          	bltz	a0,800057dc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800057ba:	fd843903          	ld	s2,-40(s0)
    800057be:	854a                	mv	a0,s2
    800057c0:	00000097          	auipc	ra,0x0
    800057c4:	e14080e7          	jalr	-492(ra) # 800055d4 <fdalloc>
    800057c8:	84aa                	mv	s1,a0
    return -1;
    800057ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800057cc:	00054863          	bltz	a0,800057dc <sys_dup+0x44>
  filedup(f);
    800057d0:	854a                	mv	a0,s2
    800057d2:	fffff097          	auipc	ra,0xfffff
    800057d6:	334080e7          	jalr	820(ra) # 80004b06 <filedup>
  return fd;
    800057da:	87a6                	mv	a5,s1
}
    800057dc:	853e                	mv	a0,a5
    800057de:	70a2                	ld	ra,40(sp)
    800057e0:	7402                	ld	s0,32(sp)
    800057e2:	64e2                	ld	s1,24(sp)
    800057e4:	6942                	ld	s2,16(sp)
    800057e6:	6145                	addi	sp,sp,48
    800057e8:	8082                	ret

00000000800057ea <sys_read>:
{
    800057ea:	7179                	addi	sp,sp,-48
    800057ec:	f406                	sd	ra,40(sp)
    800057ee:	f022                	sd	s0,32(sp)
    800057f0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057f2:	fd840593          	addi	a1,s0,-40
    800057f6:	4505                	li	a0,1
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	85a080e7          	jalr	-1958(ra) # 80003052 <argaddr>
  argint(2, &n);
    80005800:	fe440593          	addi	a1,s0,-28
    80005804:	4509                	li	a0,2
    80005806:	ffffe097          	auipc	ra,0xffffe
    8000580a:	82c080e7          	jalr	-2004(ra) # 80003032 <argint>
  if(argfd(0, 0, &f) < 0)
    8000580e:	fe840613          	addi	a2,s0,-24
    80005812:	4581                	li	a1,0
    80005814:	4501                	li	a0,0
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	d5e080e7          	jalr	-674(ra) # 80005574 <argfd>
    8000581e:	87aa                	mv	a5,a0
    return -1;
    80005820:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005822:	0007cc63          	bltz	a5,8000583a <sys_read+0x50>
  return fileread(f, p, n);
    80005826:	fe442603          	lw	a2,-28(s0)
    8000582a:	fd843583          	ld	a1,-40(s0)
    8000582e:	fe843503          	ld	a0,-24(s0)
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	460080e7          	jalr	1120(ra) # 80004c92 <fileread>
}
    8000583a:	70a2                	ld	ra,40(sp)
    8000583c:	7402                	ld	s0,32(sp)
    8000583e:	6145                	addi	sp,sp,48
    80005840:	8082                	ret

0000000080005842 <sys_write>:
{
    80005842:	7179                	addi	sp,sp,-48
    80005844:	f406                	sd	ra,40(sp)
    80005846:	f022                	sd	s0,32(sp)
    80005848:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000584a:	fd840593          	addi	a1,s0,-40
    8000584e:	4505                	li	a0,1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	802080e7          	jalr	-2046(ra) # 80003052 <argaddr>
  argint(2, &n);
    80005858:	fe440593          	addi	a1,s0,-28
    8000585c:	4509                	li	a0,2
    8000585e:	ffffd097          	auipc	ra,0xffffd
    80005862:	7d4080e7          	jalr	2004(ra) # 80003032 <argint>
  if(argfd(0, 0, &f) < 0)
    80005866:	fe840613          	addi	a2,s0,-24
    8000586a:	4581                	li	a1,0
    8000586c:	4501                	li	a0,0
    8000586e:	00000097          	auipc	ra,0x0
    80005872:	d06080e7          	jalr	-762(ra) # 80005574 <argfd>
    80005876:	87aa                	mv	a5,a0
    return -1;
    80005878:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000587a:	0007cc63          	bltz	a5,80005892 <sys_write+0x50>
  return filewrite(f, p, n);
    8000587e:	fe442603          	lw	a2,-28(s0)
    80005882:	fd843583          	ld	a1,-40(s0)
    80005886:	fe843503          	ld	a0,-24(s0)
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	4ca080e7          	jalr	1226(ra) # 80004d54 <filewrite>
}
    80005892:	70a2                	ld	ra,40(sp)
    80005894:	7402                	ld	s0,32(sp)
    80005896:	6145                	addi	sp,sp,48
    80005898:	8082                	ret

000000008000589a <sys_close>:
{
    8000589a:	1101                	addi	sp,sp,-32
    8000589c:	ec06                	sd	ra,24(sp)
    8000589e:	e822                	sd	s0,16(sp)
    800058a0:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800058a2:	fe040613          	addi	a2,s0,-32
    800058a6:	fec40593          	addi	a1,s0,-20
    800058aa:	4501                	li	a0,0
    800058ac:	00000097          	auipc	ra,0x0
    800058b0:	cc8080e7          	jalr	-824(ra) # 80005574 <argfd>
    return -1;
    800058b4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800058b6:	02054463          	bltz	a0,800058de <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800058ba:	ffffc097          	auipc	ra,0xffffc
    800058be:	444080e7          	jalr	1092(ra) # 80001cfe <myproc>
    800058c2:	fec42783          	lw	a5,-20(s0)
    800058c6:	07e9                	addi	a5,a5,26
    800058c8:	078e                	slli	a5,a5,0x3
    800058ca:	953e                	add	a0,a0,a5
    800058cc:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800058d0:	fe043503          	ld	a0,-32(s0)
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	284080e7          	jalr	644(ra) # 80004b58 <fileclose>
  return 0;
    800058dc:	4781                	li	a5,0
}
    800058de:	853e                	mv	a0,a5
    800058e0:	60e2                	ld	ra,24(sp)
    800058e2:	6442                	ld	s0,16(sp)
    800058e4:	6105                	addi	sp,sp,32
    800058e6:	8082                	ret

00000000800058e8 <sys_fstat>:
{
    800058e8:	1101                	addi	sp,sp,-32
    800058ea:	ec06                	sd	ra,24(sp)
    800058ec:	e822                	sd	s0,16(sp)
    800058ee:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800058f0:	fe040593          	addi	a1,s0,-32
    800058f4:	4505                	li	a0,1
    800058f6:	ffffd097          	auipc	ra,0xffffd
    800058fa:	75c080e7          	jalr	1884(ra) # 80003052 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058fe:	fe840613          	addi	a2,s0,-24
    80005902:	4581                	li	a1,0
    80005904:	4501                	li	a0,0
    80005906:	00000097          	auipc	ra,0x0
    8000590a:	c6e080e7          	jalr	-914(ra) # 80005574 <argfd>
    8000590e:	87aa                	mv	a5,a0
    return -1;
    80005910:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005912:	0007ca63          	bltz	a5,80005926 <sys_fstat+0x3e>
  return filestat(f, st);
    80005916:	fe043583          	ld	a1,-32(s0)
    8000591a:	fe843503          	ld	a0,-24(s0)
    8000591e:	fffff097          	auipc	ra,0xfffff
    80005922:	302080e7          	jalr	770(ra) # 80004c20 <filestat>
}
    80005926:	60e2                	ld	ra,24(sp)
    80005928:	6442                	ld	s0,16(sp)
    8000592a:	6105                	addi	sp,sp,32
    8000592c:	8082                	ret

000000008000592e <sys_link>:
{
    8000592e:	7169                	addi	sp,sp,-304
    80005930:	f606                	sd	ra,296(sp)
    80005932:	f222                	sd	s0,288(sp)
    80005934:	ee26                	sd	s1,280(sp)
    80005936:	ea4a                	sd	s2,272(sp)
    80005938:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000593a:	08000613          	li	a2,128
    8000593e:	ed040593          	addi	a1,s0,-304
    80005942:	4501                	li	a0,0
    80005944:	ffffd097          	auipc	ra,0xffffd
    80005948:	72e080e7          	jalr	1838(ra) # 80003072 <argstr>
    return -1;
    8000594c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000594e:	10054e63          	bltz	a0,80005a6a <sys_link+0x13c>
    80005952:	08000613          	li	a2,128
    80005956:	f5040593          	addi	a1,s0,-176
    8000595a:	4505                	li	a0,1
    8000595c:	ffffd097          	auipc	ra,0xffffd
    80005960:	716080e7          	jalr	1814(ra) # 80003072 <argstr>
    return -1;
    80005964:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005966:	10054263          	bltz	a0,80005a6a <sys_link+0x13c>
  begin_op();
    8000596a:	fffff097          	auipc	ra,0xfffff
    8000596e:	d2a080e7          	jalr	-726(ra) # 80004694 <begin_op>
  if((ip = namei(old)) == 0){
    80005972:	ed040513          	addi	a0,s0,-304
    80005976:	fffff097          	auipc	ra,0xfffff
    8000597a:	b1e080e7          	jalr	-1250(ra) # 80004494 <namei>
    8000597e:	84aa                	mv	s1,a0
    80005980:	c551                	beqz	a0,80005a0c <sys_link+0xde>
  ilock(ip);
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	36c080e7          	jalr	876(ra) # 80003cee <ilock>
  if(ip->type == T_DIR){
    8000598a:	04449703          	lh	a4,68(s1)
    8000598e:	4785                	li	a5,1
    80005990:	08f70463          	beq	a4,a5,80005a18 <sys_link+0xea>
  ip->nlink++;
    80005994:	04a4d783          	lhu	a5,74(s1)
    80005998:	2785                	addiw	a5,a5,1
    8000599a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	282080e7          	jalr	642(ra) # 80003c22 <iupdate>
  iunlock(ip);
    800059a8:	8526                	mv	a0,s1
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	406080e7          	jalr	1030(ra) # 80003db0 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800059b2:	fd040593          	addi	a1,s0,-48
    800059b6:	f5040513          	addi	a0,s0,-176
    800059ba:	fffff097          	auipc	ra,0xfffff
    800059be:	af8080e7          	jalr	-1288(ra) # 800044b2 <nameiparent>
    800059c2:	892a                	mv	s2,a0
    800059c4:	c935                	beqz	a0,80005a38 <sys_link+0x10a>
  ilock(dp);
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	328080e7          	jalr	808(ra) # 80003cee <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800059ce:	00092703          	lw	a4,0(s2)
    800059d2:	409c                	lw	a5,0(s1)
    800059d4:	04f71d63          	bne	a4,a5,80005a2e <sys_link+0x100>
    800059d8:	40d0                	lw	a2,4(s1)
    800059da:	fd040593          	addi	a1,s0,-48
    800059de:	854a                	mv	a0,s2
    800059e0:	fffff097          	auipc	ra,0xfffff
    800059e4:	a02080e7          	jalr	-1534(ra) # 800043e2 <dirlink>
    800059e8:	04054363          	bltz	a0,80005a2e <sys_link+0x100>
  iunlockput(dp);
    800059ec:	854a                	mv	a0,s2
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	562080e7          	jalr	1378(ra) # 80003f50 <iunlockput>
  iput(ip);
    800059f6:	8526                	mv	a0,s1
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	4b0080e7          	jalr	1200(ra) # 80003ea8 <iput>
  end_op();
    80005a00:	fffff097          	auipc	ra,0xfffff
    80005a04:	d0e080e7          	jalr	-754(ra) # 8000470e <end_op>
  return 0;
    80005a08:	4781                	li	a5,0
    80005a0a:	a085                	j	80005a6a <sys_link+0x13c>
    end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	d02080e7          	jalr	-766(ra) # 8000470e <end_op>
    return -1;
    80005a14:	57fd                	li	a5,-1
    80005a16:	a891                	j	80005a6a <sys_link+0x13c>
    iunlockput(ip);
    80005a18:	8526                	mv	a0,s1
    80005a1a:	ffffe097          	auipc	ra,0xffffe
    80005a1e:	536080e7          	jalr	1334(ra) # 80003f50 <iunlockput>
    end_op();
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	cec080e7          	jalr	-788(ra) # 8000470e <end_op>
    return -1;
    80005a2a:	57fd                	li	a5,-1
    80005a2c:	a83d                	j	80005a6a <sys_link+0x13c>
    iunlockput(dp);
    80005a2e:	854a                	mv	a0,s2
    80005a30:	ffffe097          	auipc	ra,0xffffe
    80005a34:	520080e7          	jalr	1312(ra) # 80003f50 <iunlockput>
  ilock(ip);
    80005a38:	8526                	mv	a0,s1
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	2b4080e7          	jalr	692(ra) # 80003cee <ilock>
  ip->nlink--;
    80005a42:	04a4d783          	lhu	a5,74(s1)
    80005a46:	37fd                	addiw	a5,a5,-1
    80005a48:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a4c:	8526                	mv	a0,s1
    80005a4e:	ffffe097          	auipc	ra,0xffffe
    80005a52:	1d4080e7          	jalr	468(ra) # 80003c22 <iupdate>
  iunlockput(ip);
    80005a56:	8526                	mv	a0,s1
    80005a58:	ffffe097          	auipc	ra,0xffffe
    80005a5c:	4f8080e7          	jalr	1272(ra) # 80003f50 <iunlockput>
  end_op();
    80005a60:	fffff097          	auipc	ra,0xfffff
    80005a64:	cae080e7          	jalr	-850(ra) # 8000470e <end_op>
  return -1;
    80005a68:	57fd                	li	a5,-1
}
    80005a6a:	853e                	mv	a0,a5
    80005a6c:	70b2                	ld	ra,296(sp)
    80005a6e:	7412                	ld	s0,288(sp)
    80005a70:	64f2                	ld	s1,280(sp)
    80005a72:	6952                	ld	s2,272(sp)
    80005a74:	6155                	addi	sp,sp,304
    80005a76:	8082                	ret

0000000080005a78 <sys_unlink>:
{
    80005a78:	7151                	addi	sp,sp,-240
    80005a7a:	f586                	sd	ra,232(sp)
    80005a7c:	f1a2                	sd	s0,224(sp)
    80005a7e:	eda6                	sd	s1,216(sp)
    80005a80:	e9ca                	sd	s2,208(sp)
    80005a82:	e5ce                	sd	s3,200(sp)
    80005a84:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a86:	08000613          	li	a2,128
    80005a8a:	f3040593          	addi	a1,s0,-208
    80005a8e:	4501                	li	a0,0
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	5e2080e7          	jalr	1506(ra) # 80003072 <argstr>
    80005a98:	18054163          	bltz	a0,80005c1a <sys_unlink+0x1a2>
  begin_op();
    80005a9c:	fffff097          	auipc	ra,0xfffff
    80005aa0:	bf8080e7          	jalr	-1032(ra) # 80004694 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005aa4:	fb040593          	addi	a1,s0,-80
    80005aa8:	f3040513          	addi	a0,s0,-208
    80005aac:	fffff097          	auipc	ra,0xfffff
    80005ab0:	a06080e7          	jalr	-1530(ra) # 800044b2 <nameiparent>
    80005ab4:	84aa                	mv	s1,a0
    80005ab6:	c979                	beqz	a0,80005b8c <sys_unlink+0x114>
  ilock(dp);
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	236080e7          	jalr	566(ra) # 80003cee <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005ac0:	00003597          	auipc	a1,0x3
    80005ac4:	d6858593          	addi	a1,a1,-664 # 80008828 <syscalls+0x2c8>
    80005ac8:	fb040513          	addi	a0,s0,-80
    80005acc:	ffffe097          	auipc	ra,0xffffe
    80005ad0:	6ec080e7          	jalr	1772(ra) # 800041b8 <namecmp>
    80005ad4:	14050a63          	beqz	a0,80005c28 <sys_unlink+0x1b0>
    80005ad8:	00003597          	auipc	a1,0x3
    80005adc:	d5858593          	addi	a1,a1,-680 # 80008830 <syscalls+0x2d0>
    80005ae0:	fb040513          	addi	a0,s0,-80
    80005ae4:	ffffe097          	auipc	ra,0xffffe
    80005ae8:	6d4080e7          	jalr	1748(ra) # 800041b8 <namecmp>
    80005aec:	12050e63          	beqz	a0,80005c28 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005af0:	f2c40613          	addi	a2,s0,-212
    80005af4:	fb040593          	addi	a1,s0,-80
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	6d8080e7          	jalr	1752(ra) # 800041d2 <dirlookup>
    80005b02:	892a                	mv	s2,a0
    80005b04:	12050263          	beqz	a0,80005c28 <sys_unlink+0x1b0>
  ilock(ip);
    80005b08:	ffffe097          	auipc	ra,0xffffe
    80005b0c:	1e6080e7          	jalr	486(ra) # 80003cee <ilock>
  if(ip->nlink < 1)
    80005b10:	04a91783          	lh	a5,74(s2)
    80005b14:	08f05263          	blez	a5,80005b98 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005b18:	04491703          	lh	a4,68(s2)
    80005b1c:	4785                	li	a5,1
    80005b1e:	08f70563          	beq	a4,a5,80005ba8 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005b22:	4641                	li	a2,16
    80005b24:	4581                	li	a1,0
    80005b26:	fc040513          	addi	a0,s0,-64
    80005b2a:	ffffb097          	auipc	ra,0xffffb
    80005b2e:	350080e7          	jalr	848(ra) # 80000e7a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b32:	4741                	li	a4,16
    80005b34:	f2c42683          	lw	a3,-212(s0)
    80005b38:	fc040613          	addi	a2,s0,-64
    80005b3c:	4581                	li	a1,0
    80005b3e:	8526                	mv	a0,s1
    80005b40:	ffffe097          	auipc	ra,0xffffe
    80005b44:	55a080e7          	jalr	1370(ra) # 8000409a <writei>
    80005b48:	47c1                	li	a5,16
    80005b4a:	0af51563          	bne	a0,a5,80005bf4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005b4e:	04491703          	lh	a4,68(s2)
    80005b52:	4785                	li	a5,1
    80005b54:	0af70863          	beq	a4,a5,80005c04 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b58:	8526                	mv	a0,s1
    80005b5a:	ffffe097          	auipc	ra,0xffffe
    80005b5e:	3f6080e7          	jalr	1014(ra) # 80003f50 <iunlockput>
  ip->nlink--;
    80005b62:	04a95783          	lhu	a5,74(s2)
    80005b66:	37fd                	addiw	a5,a5,-1
    80005b68:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b6c:	854a                	mv	a0,s2
    80005b6e:	ffffe097          	auipc	ra,0xffffe
    80005b72:	0b4080e7          	jalr	180(ra) # 80003c22 <iupdate>
  iunlockput(ip);
    80005b76:	854a                	mv	a0,s2
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	3d8080e7          	jalr	984(ra) # 80003f50 <iunlockput>
  end_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	b8e080e7          	jalr	-1138(ra) # 8000470e <end_op>
  return 0;
    80005b88:	4501                	li	a0,0
    80005b8a:	a84d                	j	80005c3c <sys_unlink+0x1c4>
    end_op();
    80005b8c:	fffff097          	auipc	ra,0xfffff
    80005b90:	b82080e7          	jalr	-1150(ra) # 8000470e <end_op>
    return -1;
    80005b94:	557d                	li	a0,-1
    80005b96:	a05d                	j	80005c3c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b98:	00003517          	auipc	a0,0x3
    80005b9c:	ca050513          	addi	a0,a0,-864 # 80008838 <syscalls+0x2d8>
    80005ba0:	ffffb097          	auipc	ra,0xffffb
    80005ba4:	99c080e7          	jalr	-1636(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ba8:	04c92703          	lw	a4,76(s2)
    80005bac:	02000793          	li	a5,32
    80005bb0:	f6e7f9e3          	bgeu	a5,a4,80005b22 <sys_unlink+0xaa>
    80005bb4:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bb8:	4741                	li	a4,16
    80005bba:	86ce                	mv	a3,s3
    80005bbc:	f1840613          	addi	a2,s0,-232
    80005bc0:	4581                	li	a1,0
    80005bc2:	854a                	mv	a0,s2
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	3de080e7          	jalr	990(ra) # 80003fa2 <readi>
    80005bcc:	47c1                	li	a5,16
    80005bce:	00f51b63          	bne	a0,a5,80005be4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005bd2:	f1845783          	lhu	a5,-232(s0)
    80005bd6:	e7a1                	bnez	a5,80005c1e <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005bd8:	29c1                	addiw	s3,s3,16
    80005bda:	04c92783          	lw	a5,76(s2)
    80005bde:	fcf9ede3          	bltu	s3,a5,80005bb8 <sys_unlink+0x140>
    80005be2:	b781                	j	80005b22 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005be4:	00003517          	auipc	a0,0x3
    80005be8:	c6c50513          	addi	a0,a0,-916 # 80008850 <syscalls+0x2f0>
    80005bec:	ffffb097          	auipc	ra,0xffffb
    80005bf0:	950080e7          	jalr	-1712(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005bf4:	00003517          	auipc	a0,0x3
    80005bf8:	c7450513          	addi	a0,a0,-908 # 80008868 <syscalls+0x308>
    80005bfc:	ffffb097          	auipc	ra,0xffffb
    80005c00:	940080e7          	jalr	-1728(ra) # 8000053c <panic>
    dp->nlink--;
    80005c04:	04a4d783          	lhu	a5,74(s1)
    80005c08:	37fd                	addiw	a5,a5,-1
    80005c0a:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005c0e:	8526                	mv	a0,s1
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	012080e7          	jalr	18(ra) # 80003c22 <iupdate>
    80005c18:	b781                	j	80005b58 <sys_unlink+0xe0>
    return -1;
    80005c1a:	557d                	li	a0,-1
    80005c1c:	a005                	j	80005c3c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005c1e:	854a                	mv	a0,s2
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	330080e7          	jalr	816(ra) # 80003f50 <iunlockput>
  iunlockput(dp);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	326080e7          	jalr	806(ra) # 80003f50 <iunlockput>
  end_op();
    80005c32:	fffff097          	auipc	ra,0xfffff
    80005c36:	adc080e7          	jalr	-1316(ra) # 8000470e <end_op>
  return -1;
    80005c3a:	557d                	li	a0,-1
}
    80005c3c:	70ae                	ld	ra,232(sp)
    80005c3e:	740e                	ld	s0,224(sp)
    80005c40:	64ee                	ld	s1,216(sp)
    80005c42:	694e                	ld	s2,208(sp)
    80005c44:	69ae                	ld	s3,200(sp)
    80005c46:	616d                	addi	sp,sp,240
    80005c48:	8082                	ret

0000000080005c4a <sys_open>:

uint64
sys_open(void)
{
    80005c4a:	7131                	addi	sp,sp,-192
    80005c4c:	fd06                	sd	ra,184(sp)
    80005c4e:	f922                	sd	s0,176(sp)
    80005c50:	f526                	sd	s1,168(sp)
    80005c52:	f14a                	sd	s2,160(sp)
    80005c54:	ed4e                	sd	s3,152(sp)
    80005c56:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c58:	f4c40593          	addi	a1,s0,-180
    80005c5c:	4505                	li	a0,1
    80005c5e:	ffffd097          	auipc	ra,0xffffd
    80005c62:	3d4080e7          	jalr	980(ra) # 80003032 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c66:	08000613          	li	a2,128
    80005c6a:	f5040593          	addi	a1,s0,-176
    80005c6e:	4501                	li	a0,0
    80005c70:	ffffd097          	auipc	ra,0xffffd
    80005c74:	402080e7          	jalr	1026(ra) # 80003072 <argstr>
    80005c78:	87aa                	mv	a5,a0
    return -1;
    80005c7a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c7c:	0a07c863          	bltz	a5,80005d2c <sys_open+0xe2>

  begin_op();
    80005c80:	fffff097          	auipc	ra,0xfffff
    80005c84:	a14080e7          	jalr	-1516(ra) # 80004694 <begin_op>

  if(omode & O_CREATE){
    80005c88:	f4c42783          	lw	a5,-180(s0)
    80005c8c:	2007f793          	andi	a5,a5,512
    80005c90:	cbdd                	beqz	a5,80005d46 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005c92:	4681                	li	a3,0
    80005c94:	4601                	li	a2,0
    80005c96:	4589                	li	a1,2
    80005c98:	f5040513          	addi	a0,s0,-176
    80005c9c:	00000097          	auipc	ra,0x0
    80005ca0:	97a080e7          	jalr	-1670(ra) # 80005616 <create>
    80005ca4:	84aa                	mv	s1,a0
    if(ip == 0){
    80005ca6:	c951                	beqz	a0,80005d3a <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005ca8:	04449703          	lh	a4,68(s1)
    80005cac:	478d                	li	a5,3
    80005cae:	00f71763          	bne	a4,a5,80005cbc <sys_open+0x72>
    80005cb2:	0464d703          	lhu	a4,70(s1)
    80005cb6:	47a5                	li	a5,9
    80005cb8:	0ce7ec63          	bltu	a5,a4,80005d90 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005cbc:	fffff097          	auipc	ra,0xfffff
    80005cc0:	de0080e7          	jalr	-544(ra) # 80004a9c <filealloc>
    80005cc4:	892a                	mv	s2,a0
    80005cc6:	c56d                	beqz	a0,80005db0 <sys_open+0x166>
    80005cc8:	00000097          	auipc	ra,0x0
    80005ccc:	90c080e7          	jalr	-1780(ra) # 800055d4 <fdalloc>
    80005cd0:	89aa                	mv	s3,a0
    80005cd2:	0c054a63          	bltz	a0,80005da6 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005cd6:	04449703          	lh	a4,68(s1)
    80005cda:	478d                	li	a5,3
    80005cdc:	0ef70563          	beq	a4,a5,80005dc6 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ce0:	4789                	li	a5,2
    80005ce2:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005ce6:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005cea:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005cee:	f4c42783          	lw	a5,-180(s0)
    80005cf2:	0017c713          	xori	a4,a5,1
    80005cf6:	8b05                	andi	a4,a4,1
    80005cf8:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005cfc:	0037f713          	andi	a4,a5,3
    80005d00:	00e03733          	snez	a4,a4
    80005d04:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005d08:	4007f793          	andi	a5,a5,1024
    80005d0c:	c791                	beqz	a5,80005d18 <sys_open+0xce>
    80005d0e:	04449703          	lh	a4,68(s1)
    80005d12:	4789                	li	a5,2
    80005d14:	0cf70063          	beq	a4,a5,80005dd4 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005d18:	8526                	mv	a0,s1
    80005d1a:	ffffe097          	auipc	ra,0xffffe
    80005d1e:	096080e7          	jalr	150(ra) # 80003db0 <iunlock>
  end_op();
    80005d22:	fffff097          	auipc	ra,0xfffff
    80005d26:	9ec080e7          	jalr	-1556(ra) # 8000470e <end_op>

  return fd;
    80005d2a:	854e                	mv	a0,s3
}
    80005d2c:	70ea                	ld	ra,184(sp)
    80005d2e:	744a                	ld	s0,176(sp)
    80005d30:	74aa                	ld	s1,168(sp)
    80005d32:	790a                	ld	s2,160(sp)
    80005d34:	69ea                	ld	s3,152(sp)
    80005d36:	6129                	addi	sp,sp,192
    80005d38:	8082                	ret
      end_op();
    80005d3a:	fffff097          	auipc	ra,0xfffff
    80005d3e:	9d4080e7          	jalr	-1580(ra) # 8000470e <end_op>
      return -1;
    80005d42:	557d                	li	a0,-1
    80005d44:	b7e5                	j	80005d2c <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005d46:	f5040513          	addi	a0,s0,-176
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	74a080e7          	jalr	1866(ra) # 80004494 <namei>
    80005d52:	84aa                	mv	s1,a0
    80005d54:	c905                	beqz	a0,80005d84 <sys_open+0x13a>
    ilock(ip);
    80005d56:	ffffe097          	auipc	ra,0xffffe
    80005d5a:	f98080e7          	jalr	-104(ra) # 80003cee <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d5e:	04449703          	lh	a4,68(s1)
    80005d62:	4785                	li	a5,1
    80005d64:	f4f712e3          	bne	a4,a5,80005ca8 <sys_open+0x5e>
    80005d68:	f4c42783          	lw	a5,-180(s0)
    80005d6c:	dba1                	beqz	a5,80005cbc <sys_open+0x72>
      iunlockput(ip);
    80005d6e:	8526                	mv	a0,s1
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	1e0080e7          	jalr	480(ra) # 80003f50 <iunlockput>
      end_op();
    80005d78:	fffff097          	auipc	ra,0xfffff
    80005d7c:	996080e7          	jalr	-1642(ra) # 8000470e <end_op>
      return -1;
    80005d80:	557d                	li	a0,-1
    80005d82:	b76d                	j	80005d2c <sys_open+0xe2>
      end_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	98a080e7          	jalr	-1654(ra) # 8000470e <end_op>
      return -1;
    80005d8c:	557d                	li	a0,-1
    80005d8e:	bf79                	j	80005d2c <sys_open+0xe2>
    iunlockput(ip);
    80005d90:	8526                	mv	a0,s1
    80005d92:	ffffe097          	auipc	ra,0xffffe
    80005d96:	1be080e7          	jalr	446(ra) # 80003f50 <iunlockput>
    end_op();
    80005d9a:	fffff097          	auipc	ra,0xfffff
    80005d9e:	974080e7          	jalr	-1676(ra) # 8000470e <end_op>
    return -1;
    80005da2:	557d                	li	a0,-1
    80005da4:	b761                	j	80005d2c <sys_open+0xe2>
      fileclose(f);
    80005da6:	854a                	mv	a0,s2
    80005da8:	fffff097          	auipc	ra,0xfffff
    80005dac:	db0080e7          	jalr	-592(ra) # 80004b58 <fileclose>
    iunlockput(ip);
    80005db0:	8526                	mv	a0,s1
    80005db2:	ffffe097          	auipc	ra,0xffffe
    80005db6:	19e080e7          	jalr	414(ra) # 80003f50 <iunlockput>
    end_op();
    80005dba:	fffff097          	auipc	ra,0xfffff
    80005dbe:	954080e7          	jalr	-1708(ra) # 8000470e <end_op>
    return -1;
    80005dc2:	557d                	li	a0,-1
    80005dc4:	b7a5                	j	80005d2c <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005dc6:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005dca:	04649783          	lh	a5,70(s1)
    80005dce:	02f91223          	sh	a5,36(s2)
    80005dd2:	bf21                	j	80005cea <sys_open+0xa0>
    itrunc(ip);
    80005dd4:	8526                	mv	a0,s1
    80005dd6:	ffffe097          	auipc	ra,0xffffe
    80005dda:	026080e7          	jalr	38(ra) # 80003dfc <itrunc>
    80005dde:	bf2d                	j	80005d18 <sys_open+0xce>

0000000080005de0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005de0:	7175                	addi	sp,sp,-144
    80005de2:	e506                	sd	ra,136(sp)
    80005de4:	e122                	sd	s0,128(sp)
    80005de6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005de8:	fffff097          	auipc	ra,0xfffff
    80005dec:	8ac080e7          	jalr	-1876(ra) # 80004694 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005df0:	08000613          	li	a2,128
    80005df4:	f7040593          	addi	a1,s0,-144
    80005df8:	4501                	li	a0,0
    80005dfa:	ffffd097          	auipc	ra,0xffffd
    80005dfe:	278080e7          	jalr	632(ra) # 80003072 <argstr>
    80005e02:	02054963          	bltz	a0,80005e34 <sys_mkdir+0x54>
    80005e06:	4681                	li	a3,0
    80005e08:	4601                	li	a2,0
    80005e0a:	4585                	li	a1,1
    80005e0c:	f7040513          	addi	a0,s0,-144
    80005e10:	00000097          	auipc	ra,0x0
    80005e14:	806080e7          	jalr	-2042(ra) # 80005616 <create>
    80005e18:	cd11                	beqz	a0,80005e34 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	136080e7          	jalr	310(ra) # 80003f50 <iunlockput>
  end_op();
    80005e22:	fffff097          	auipc	ra,0xfffff
    80005e26:	8ec080e7          	jalr	-1812(ra) # 8000470e <end_op>
  return 0;
    80005e2a:	4501                	li	a0,0
}
    80005e2c:	60aa                	ld	ra,136(sp)
    80005e2e:	640a                	ld	s0,128(sp)
    80005e30:	6149                	addi	sp,sp,144
    80005e32:	8082                	ret
    end_op();
    80005e34:	fffff097          	auipc	ra,0xfffff
    80005e38:	8da080e7          	jalr	-1830(ra) # 8000470e <end_op>
    return -1;
    80005e3c:	557d                	li	a0,-1
    80005e3e:	b7fd                	j	80005e2c <sys_mkdir+0x4c>

0000000080005e40 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005e40:	7135                	addi	sp,sp,-160
    80005e42:	ed06                	sd	ra,152(sp)
    80005e44:	e922                	sd	s0,144(sp)
    80005e46:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	84c080e7          	jalr	-1972(ra) # 80004694 <begin_op>
  argint(1, &major);
    80005e50:	f6c40593          	addi	a1,s0,-148
    80005e54:	4505                	li	a0,1
    80005e56:	ffffd097          	auipc	ra,0xffffd
    80005e5a:	1dc080e7          	jalr	476(ra) # 80003032 <argint>
  argint(2, &minor);
    80005e5e:	f6840593          	addi	a1,s0,-152
    80005e62:	4509                	li	a0,2
    80005e64:	ffffd097          	auipc	ra,0xffffd
    80005e68:	1ce080e7          	jalr	462(ra) # 80003032 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e6c:	08000613          	li	a2,128
    80005e70:	f7040593          	addi	a1,s0,-144
    80005e74:	4501                	li	a0,0
    80005e76:	ffffd097          	auipc	ra,0xffffd
    80005e7a:	1fc080e7          	jalr	508(ra) # 80003072 <argstr>
    80005e7e:	02054b63          	bltz	a0,80005eb4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e82:	f6841683          	lh	a3,-152(s0)
    80005e86:	f6c41603          	lh	a2,-148(s0)
    80005e8a:	458d                	li	a1,3
    80005e8c:	f7040513          	addi	a0,s0,-144
    80005e90:	fffff097          	auipc	ra,0xfffff
    80005e94:	786080e7          	jalr	1926(ra) # 80005616 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e98:	cd11                	beqz	a0,80005eb4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e9a:	ffffe097          	auipc	ra,0xffffe
    80005e9e:	0b6080e7          	jalr	182(ra) # 80003f50 <iunlockput>
  end_op();
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	86c080e7          	jalr	-1940(ra) # 8000470e <end_op>
  return 0;
    80005eaa:	4501                	li	a0,0
}
    80005eac:	60ea                	ld	ra,152(sp)
    80005eae:	644a                	ld	s0,144(sp)
    80005eb0:	610d                	addi	sp,sp,160
    80005eb2:	8082                	ret
    end_op();
    80005eb4:	fffff097          	auipc	ra,0xfffff
    80005eb8:	85a080e7          	jalr	-1958(ra) # 8000470e <end_op>
    return -1;
    80005ebc:	557d                	li	a0,-1
    80005ebe:	b7fd                	j	80005eac <sys_mknod+0x6c>

0000000080005ec0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005ec0:	7135                	addi	sp,sp,-160
    80005ec2:	ed06                	sd	ra,152(sp)
    80005ec4:	e922                	sd	s0,144(sp)
    80005ec6:	e526                	sd	s1,136(sp)
    80005ec8:	e14a                	sd	s2,128(sp)
    80005eca:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005ecc:	ffffc097          	auipc	ra,0xffffc
    80005ed0:	e32080e7          	jalr	-462(ra) # 80001cfe <myproc>
    80005ed4:	892a                	mv	s2,a0
  
  begin_op();
    80005ed6:	ffffe097          	auipc	ra,0xffffe
    80005eda:	7be080e7          	jalr	1982(ra) # 80004694 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005ede:	08000613          	li	a2,128
    80005ee2:	f6040593          	addi	a1,s0,-160
    80005ee6:	4501                	li	a0,0
    80005ee8:	ffffd097          	auipc	ra,0xffffd
    80005eec:	18a080e7          	jalr	394(ra) # 80003072 <argstr>
    80005ef0:	04054b63          	bltz	a0,80005f46 <sys_chdir+0x86>
    80005ef4:	f6040513          	addi	a0,s0,-160
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	59c080e7          	jalr	1436(ra) # 80004494 <namei>
    80005f00:	84aa                	mv	s1,a0
    80005f02:	c131                	beqz	a0,80005f46 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005f04:	ffffe097          	auipc	ra,0xffffe
    80005f08:	dea080e7          	jalr	-534(ra) # 80003cee <ilock>
  if(ip->type != T_DIR){
    80005f0c:	04449703          	lh	a4,68(s1)
    80005f10:	4785                	li	a5,1
    80005f12:	04f71063          	bne	a4,a5,80005f52 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005f16:	8526                	mv	a0,s1
    80005f18:	ffffe097          	auipc	ra,0xffffe
    80005f1c:	e98080e7          	jalr	-360(ra) # 80003db0 <iunlock>
  iput(p->cwd);
    80005f20:	15093503          	ld	a0,336(s2)
    80005f24:	ffffe097          	auipc	ra,0xffffe
    80005f28:	f84080e7          	jalr	-124(ra) # 80003ea8 <iput>
  end_op();
    80005f2c:	ffffe097          	auipc	ra,0xffffe
    80005f30:	7e2080e7          	jalr	2018(ra) # 8000470e <end_op>
  p->cwd = ip;
    80005f34:	14993823          	sd	s1,336(s2)
  return 0;
    80005f38:	4501                	li	a0,0
}
    80005f3a:	60ea                	ld	ra,152(sp)
    80005f3c:	644a                	ld	s0,144(sp)
    80005f3e:	64aa                	ld	s1,136(sp)
    80005f40:	690a                	ld	s2,128(sp)
    80005f42:	610d                	addi	sp,sp,160
    80005f44:	8082                	ret
    end_op();
    80005f46:	ffffe097          	auipc	ra,0xffffe
    80005f4a:	7c8080e7          	jalr	1992(ra) # 8000470e <end_op>
    return -1;
    80005f4e:	557d                	li	a0,-1
    80005f50:	b7ed                	j	80005f3a <sys_chdir+0x7a>
    iunlockput(ip);
    80005f52:	8526                	mv	a0,s1
    80005f54:	ffffe097          	auipc	ra,0xffffe
    80005f58:	ffc080e7          	jalr	-4(ra) # 80003f50 <iunlockput>
    end_op();
    80005f5c:	ffffe097          	auipc	ra,0xffffe
    80005f60:	7b2080e7          	jalr	1970(ra) # 8000470e <end_op>
    return -1;
    80005f64:	557d                	li	a0,-1
    80005f66:	bfd1                	j	80005f3a <sys_chdir+0x7a>

0000000080005f68 <sys_exec>:

uint64
sys_exec(void)
{
    80005f68:	7121                	addi	sp,sp,-448
    80005f6a:	ff06                	sd	ra,440(sp)
    80005f6c:	fb22                	sd	s0,432(sp)
    80005f6e:	f726                	sd	s1,424(sp)
    80005f70:	f34a                	sd	s2,416(sp)
    80005f72:	ef4e                	sd	s3,408(sp)
    80005f74:	eb52                	sd	s4,400(sp)
    80005f76:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f78:	e4840593          	addi	a1,s0,-440
    80005f7c:	4505                	li	a0,1
    80005f7e:	ffffd097          	auipc	ra,0xffffd
    80005f82:	0d4080e7          	jalr	212(ra) # 80003052 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f86:	08000613          	li	a2,128
    80005f8a:	f5040593          	addi	a1,s0,-176
    80005f8e:	4501                	li	a0,0
    80005f90:	ffffd097          	auipc	ra,0xffffd
    80005f94:	0e2080e7          	jalr	226(ra) # 80003072 <argstr>
    80005f98:	87aa                	mv	a5,a0
    return -1;
    80005f9a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f9c:	0c07c263          	bltz	a5,80006060 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005fa0:	10000613          	li	a2,256
    80005fa4:	4581                	li	a1,0
    80005fa6:	e5040513          	addi	a0,s0,-432
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	ed0080e7          	jalr	-304(ra) # 80000e7a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005fb2:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005fb6:	89a6                	mv	s3,s1
    80005fb8:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005fba:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005fbe:	00391513          	slli	a0,s2,0x3
    80005fc2:	e4040593          	addi	a1,s0,-448
    80005fc6:	e4843783          	ld	a5,-440(s0)
    80005fca:	953e                	add	a0,a0,a5
    80005fcc:	ffffd097          	auipc	ra,0xffffd
    80005fd0:	fc8080e7          	jalr	-56(ra) # 80002f94 <fetchaddr>
    80005fd4:	02054a63          	bltz	a0,80006008 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005fd8:	e4043783          	ld	a5,-448(s0)
    80005fdc:	c3b9                	beqz	a5,80006022 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005fde:	ffffb097          	auipc	ra,0xffffb
    80005fe2:	c4e080e7          	jalr	-946(ra) # 80000c2c <kalloc>
    80005fe6:	85aa                	mv	a1,a0
    80005fe8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005fec:	cd11                	beqz	a0,80006008 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005fee:	6605                	lui	a2,0x1
    80005ff0:	e4043503          	ld	a0,-448(s0)
    80005ff4:	ffffd097          	auipc	ra,0xffffd
    80005ff8:	ff2080e7          	jalr	-14(ra) # 80002fe6 <fetchstr>
    80005ffc:	00054663          	bltz	a0,80006008 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80006000:	0905                	addi	s2,s2,1
    80006002:	09a1                	addi	s3,s3,8
    80006004:	fb491de3          	bne	s2,s4,80005fbe <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006008:	f5040913          	addi	s2,s0,-176
    8000600c:	6088                	ld	a0,0(s1)
    8000600e:	c921                	beqz	a0,8000605e <sys_exec+0xf6>
    kfree(argv[i]);
    80006010:	ffffb097          	auipc	ra,0xffffb
    80006014:	a84080e7          	jalr	-1404(ra) # 80000a94 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006018:	04a1                	addi	s1,s1,8
    8000601a:	ff2499e3          	bne	s1,s2,8000600c <sys_exec+0xa4>
  return -1;
    8000601e:	557d                	li	a0,-1
    80006020:	a081                	j	80006060 <sys_exec+0xf8>
      argv[i] = 0;
    80006022:	0009079b          	sext.w	a5,s2
    80006026:	078e                	slli	a5,a5,0x3
    80006028:	fd078793          	addi	a5,a5,-48
    8000602c:	97a2                	add	a5,a5,s0
    8000602e:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006032:	e5040593          	addi	a1,s0,-432
    80006036:	f5040513          	addi	a0,s0,-176
    8000603a:	fffff097          	auipc	ra,0xfffff
    8000603e:	194080e7          	jalr	404(ra) # 800051ce <exec>
    80006042:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006044:	f5040993          	addi	s3,s0,-176
    80006048:	6088                	ld	a0,0(s1)
    8000604a:	c901                	beqz	a0,8000605a <sys_exec+0xf2>
    kfree(argv[i]);
    8000604c:	ffffb097          	auipc	ra,0xffffb
    80006050:	a48080e7          	jalr	-1464(ra) # 80000a94 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006054:	04a1                	addi	s1,s1,8
    80006056:	ff3499e3          	bne	s1,s3,80006048 <sys_exec+0xe0>
  return ret;
    8000605a:	854a                	mv	a0,s2
    8000605c:	a011                	j	80006060 <sys_exec+0xf8>
  return -1;
    8000605e:	557d                	li	a0,-1
}
    80006060:	70fa                	ld	ra,440(sp)
    80006062:	745a                	ld	s0,432(sp)
    80006064:	74ba                	ld	s1,424(sp)
    80006066:	791a                	ld	s2,416(sp)
    80006068:	69fa                	ld	s3,408(sp)
    8000606a:	6a5a                	ld	s4,400(sp)
    8000606c:	6139                	addi	sp,sp,448
    8000606e:	8082                	ret

0000000080006070 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006070:	7139                	addi	sp,sp,-64
    80006072:	fc06                	sd	ra,56(sp)
    80006074:	f822                	sd	s0,48(sp)
    80006076:	f426                	sd	s1,40(sp)
    80006078:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000607a:	ffffc097          	auipc	ra,0xffffc
    8000607e:	c84080e7          	jalr	-892(ra) # 80001cfe <myproc>
    80006082:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006084:	fd840593          	addi	a1,s0,-40
    80006088:	4501                	li	a0,0
    8000608a:	ffffd097          	auipc	ra,0xffffd
    8000608e:	fc8080e7          	jalr	-56(ra) # 80003052 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006092:	fc840593          	addi	a1,s0,-56
    80006096:	fd040513          	addi	a0,s0,-48
    8000609a:	fffff097          	auipc	ra,0xfffff
    8000609e:	dea080e7          	jalr	-534(ra) # 80004e84 <pipealloc>
    return -1;
    800060a2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800060a4:	0c054463          	bltz	a0,8000616c <sys_pipe+0xfc>
  fd0 = -1;
    800060a8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800060ac:	fd043503          	ld	a0,-48(s0)
    800060b0:	fffff097          	auipc	ra,0xfffff
    800060b4:	524080e7          	jalr	1316(ra) # 800055d4 <fdalloc>
    800060b8:	fca42223          	sw	a0,-60(s0)
    800060bc:	08054b63          	bltz	a0,80006152 <sys_pipe+0xe2>
    800060c0:	fc843503          	ld	a0,-56(s0)
    800060c4:	fffff097          	auipc	ra,0xfffff
    800060c8:	510080e7          	jalr	1296(ra) # 800055d4 <fdalloc>
    800060cc:	fca42023          	sw	a0,-64(s0)
    800060d0:	06054863          	bltz	a0,80006140 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060d4:	4691                	li	a3,4
    800060d6:	fc440613          	addi	a2,s0,-60
    800060da:	fd843583          	ld	a1,-40(s0)
    800060de:	68a8                	ld	a0,80(s1)
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	7ea080e7          	jalr	2026(ra) # 800018ca <copyout>
    800060e8:	02054063          	bltz	a0,80006108 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800060ec:	4691                	li	a3,4
    800060ee:	fc040613          	addi	a2,s0,-64
    800060f2:	fd843583          	ld	a1,-40(s0)
    800060f6:	0591                	addi	a1,a1,4
    800060f8:	68a8                	ld	a0,80(s1)
    800060fa:	ffffb097          	auipc	ra,0xffffb
    800060fe:	7d0080e7          	jalr	2000(ra) # 800018ca <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006102:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006104:	06055463          	bgez	a0,8000616c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006108:	fc442783          	lw	a5,-60(s0)
    8000610c:	07e9                	addi	a5,a5,26
    8000610e:	078e                	slli	a5,a5,0x3
    80006110:	97a6                	add	a5,a5,s1
    80006112:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006116:	fc042783          	lw	a5,-64(s0)
    8000611a:	07e9                	addi	a5,a5,26
    8000611c:	078e                	slli	a5,a5,0x3
    8000611e:	94be                	add	s1,s1,a5
    80006120:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006124:	fd043503          	ld	a0,-48(s0)
    80006128:	fffff097          	auipc	ra,0xfffff
    8000612c:	a30080e7          	jalr	-1488(ra) # 80004b58 <fileclose>
    fileclose(wf);
    80006130:	fc843503          	ld	a0,-56(s0)
    80006134:	fffff097          	auipc	ra,0xfffff
    80006138:	a24080e7          	jalr	-1500(ra) # 80004b58 <fileclose>
    return -1;
    8000613c:	57fd                	li	a5,-1
    8000613e:	a03d                	j	8000616c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006140:	fc442783          	lw	a5,-60(s0)
    80006144:	0007c763          	bltz	a5,80006152 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006148:	07e9                	addi	a5,a5,26
    8000614a:	078e                	slli	a5,a5,0x3
    8000614c:	97a6                	add	a5,a5,s1
    8000614e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006152:	fd043503          	ld	a0,-48(s0)
    80006156:	fffff097          	auipc	ra,0xfffff
    8000615a:	a02080e7          	jalr	-1534(ra) # 80004b58 <fileclose>
    fileclose(wf);
    8000615e:	fc843503          	ld	a0,-56(s0)
    80006162:	fffff097          	auipc	ra,0xfffff
    80006166:	9f6080e7          	jalr	-1546(ra) # 80004b58 <fileclose>
    return -1;
    8000616a:	57fd                	li	a5,-1
}
    8000616c:	853e                	mv	a0,a5
    8000616e:	70e2                	ld	ra,56(sp)
    80006170:	7442                	ld	s0,48(sp)
    80006172:	74a2                	ld	s1,40(sp)
    80006174:	6121                	addi	sp,sp,64
    80006176:	8082                	ret
	...

0000000080006180 <kernelvec>:
    80006180:	7111                	addi	sp,sp,-256
    80006182:	e006                	sd	ra,0(sp)
    80006184:	e40a                	sd	sp,8(sp)
    80006186:	e80e                	sd	gp,16(sp)
    80006188:	ec12                	sd	tp,24(sp)
    8000618a:	f016                	sd	t0,32(sp)
    8000618c:	f41a                	sd	t1,40(sp)
    8000618e:	f81e                	sd	t2,48(sp)
    80006190:	fc22                	sd	s0,56(sp)
    80006192:	e0a6                	sd	s1,64(sp)
    80006194:	e4aa                	sd	a0,72(sp)
    80006196:	e8ae                	sd	a1,80(sp)
    80006198:	ecb2                	sd	a2,88(sp)
    8000619a:	f0b6                	sd	a3,96(sp)
    8000619c:	f4ba                	sd	a4,104(sp)
    8000619e:	f8be                	sd	a5,112(sp)
    800061a0:	fcc2                	sd	a6,120(sp)
    800061a2:	e146                	sd	a7,128(sp)
    800061a4:	e54a                	sd	s2,136(sp)
    800061a6:	e94e                	sd	s3,144(sp)
    800061a8:	ed52                	sd	s4,152(sp)
    800061aa:	f156                	sd	s5,160(sp)
    800061ac:	f55a                	sd	s6,168(sp)
    800061ae:	f95e                	sd	s7,176(sp)
    800061b0:	fd62                	sd	s8,184(sp)
    800061b2:	e1e6                	sd	s9,192(sp)
    800061b4:	e5ea                	sd	s10,200(sp)
    800061b6:	e9ee                	sd	s11,208(sp)
    800061b8:	edf2                	sd	t3,216(sp)
    800061ba:	f1f6                	sd	t4,224(sp)
    800061bc:	f5fa                	sd	t5,232(sp)
    800061be:	f9fe                	sd	t6,240(sp)
    800061c0:	b19fc0ef          	jal	ra,80002cd8 <kerneltrap>
    800061c4:	6082                	ld	ra,0(sp)
    800061c6:	6122                	ld	sp,8(sp)
    800061c8:	61c2                	ld	gp,16(sp)
    800061ca:	7282                	ld	t0,32(sp)
    800061cc:	7322                	ld	t1,40(sp)
    800061ce:	73c2                	ld	t2,48(sp)
    800061d0:	7462                	ld	s0,56(sp)
    800061d2:	6486                	ld	s1,64(sp)
    800061d4:	6526                	ld	a0,72(sp)
    800061d6:	65c6                	ld	a1,80(sp)
    800061d8:	6666                	ld	a2,88(sp)
    800061da:	7686                	ld	a3,96(sp)
    800061dc:	7726                	ld	a4,104(sp)
    800061de:	77c6                	ld	a5,112(sp)
    800061e0:	7866                	ld	a6,120(sp)
    800061e2:	688a                	ld	a7,128(sp)
    800061e4:	692a                	ld	s2,136(sp)
    800061e6:	69ca                	ld	s3,144(sp)
    800061e8:	6a6a                	ld	s4,152(sp)
    800061ea:	7a8a                	ld	s5,160(sp)
    800061ec:	7b2a                	ld	s6,168(sp)
    800061ee:	7bca                	ld	s7,176(sp)
    800061f0:	7c6a                	ld	s8,184(sp)
    800061f2:	6c8e                	ld	s9,192(sp)
    800061f4:	6d2e                	ld	s10,200(sp)
    800061f6:	6dce                	ld	s11,208(sp)
    800061f8:	6e6e                	ld	t3,216(sp)
    800061fa:	7e8e                	ld	t4,224(sp)
    800061fc:	7f2e                	ld	t5,232(sp)
    800061fe:	7fce                	ld	t6,240(sp)
    80006200:	6111                	addi	sp,sp,256
    80006202:	10200073          	sret
    80006206:	00000013          	nop
    8000620a:	00000013          	nop
    8000620e:	0001                	nop

0000000080006210 <timervec>:
    80006210:	34051573          	csrrw	a0,mscratch,a0
    80006214:	e10c                	sd	a1,0(a0)
    80006216:	e510                	sd	a2,8(a0)
    80006218:	e914                	sd	a3,16(a0)
    8000621a:	6d0c                	ld	a1,24(a0)
    8000621c:	7110                	ld	a2,32(a0)
    8000621e:	6194                	ld	a3,0(a1)
    80006220:	96b2                	add	a3,a3,a2
    80006222:	e194                	sd	a3,0(a1)
    80006224:	4589                	li	a1,2
    80006226:	14459073          	csrw	sip,a1
    8000622a:	6914                	ld	a3,16(a0)
    8000622c:	6510                	ld	a2,8(a0)
    8000622e:	610c                	ld	a1,0(a0)
    80006230:	34051573          	csrrw	a0,mscratch,a0
    80006234:	30200073          	mret
	...

000000008000623a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000623a:	1141                	addi	sp,sp,-16
    8000623c:	e422                	sd	s0,8(sp)
    8000623e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006240:	0c0007b7          	lui	a5,0xc000
    80006244:	4705                	li	a4,1
    80006246:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006248:	c3d8                	sw	a4,4(a5)
}
    8000624a:	6422                	ld	s0,8(sp)
    8000624c:	0141                	addi	sp,sp,16
    8000624e:	8082                	ret

0000000080006250 <plicinithart>:

void
plicinithart(void)
{
    80006250:	1141                	addi	sp,sp,-16
    80006252:	e406                	sd	ra,8(sp)
    80006254:	e022                	sd	s0,0(sp)
    80006256:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006258:	ffffc097          	auipc	ra,0xffffc
    8000625c:	a7a080e7          	jalr	-1414(ra) # 80001cd2 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006260:	0085171b          	slliw	a4,a0,0x8
    80006264:	0c0027b7          	lui	a5,0xc002
    80006268:	97ba                	add	a5,a5,a4
    8000626a:	40200713          	li	a4,1026
    8000626e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006272:	00d5151b          	slliw	a0,a0,0xd
    80006276:	0c2017b7          	lui	a5,0xc201
    8000627a:	97aa                	add	a5,a5,a0
    8000627c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006280:	60a2                	ld	ra,8(sp)
    80006282:	6402                	ld	s0,0(sp)
    80006284:	0141                	addi	sp,sp,16
    80006286:	8082                	ret

0000000080006288 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006288:	1141                	addi	sp,sp,-16
    8000628a:	e406                	sd	ra,8(sp)
    8000628c:	e022                	sd	s0,0(sp)
    8000628e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006290:	ffffc097          	auipc	ra,0xffffc
    80006294:	a42080e7          	jalr	-1470(ra) # 80001cd2 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006298:	00d5151b          	slliw	a0,a0,0xd
    8000629c:	0c2017b7          	lui	a5,0xc201
    800062a0:	97aa                	add	a5,a5,a0
  return irq;
}
    800062a2:	43c8                	lw	a0,4(a5)
    800062a4:	60a2                	ld	ra,8(sp)
    800062a6:	6402                	ld	s0,0(sp)
    800062a8:	0141                	addi	sp,sp,16
    800062aa:	8082                	ret

00000000800062ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800062ac:	1101                	addi	sp,sp,-32
    800062ae:	ec06                	sd	ra,24(sp)
    800062b0:	e822                	sd	s0,16(sp)
    800062b2:	e426                	sd	s1,8(sp)
    800062b4:	1000                	addi	s0,sp,32
    800062b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800062b8:	ffffc097          	auipc	ra,0xffffc
    800062bc:	a1a080e7          	jalr	-1510(ra) # 80001cd2 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800062c0:	00d5151b          	slliw	a0,a0,0xd
    800062c4:	0c2017b7          	lui	a5,0xc201
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	c3c4                	sw	s1,4(a5)
}
    800062cc:	60e2                	ld	ra,24(sp)
    800062ce:	6442                	ld	s0,16(sp)
    800062d0:	64a2                	ld	s1,8(sp)
    800062d2:	6105                	addi	sp,sp,32
    800062d4:	8082                	ret

00000000800062d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800062d6:	1141                	addi	sp,sp,-16
    800062d8:	e406                	sd	ra,8(sp)
    800062da:	e022                	sd	s0,0(sp)
    800062dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800062de:	479d                	li	a5,7
    800062e0:	04a7cc63          	blt	a5,a0,80006338 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800062e4:	0045c797          	auipc	a5,0x45c
    800062e8:	a9c78793          	addi	a5,a5,-1380 # 80461d80 <disk>
    800062ec:	97aa                	add	a5,a5,a0
    800062ee:	0187c783          	lbu	a5,24(a5)
    800062f2:	ebb9                	bnez	a5,80006348 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062f4:	00451693          	slli	a3,a0,0x4
    800062f8:	0045c797          	auipc	a5,0x45c
    800062fc:	a8878793          	addi	a5,a5,-1400 # 80461d80 <disk>
    80006300:	6398                	ld	a4,0(a5)
    80006302:	9736                	add	a4,a4,a3
    80006304:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006308:	6398                	ld	a4,0(a5)
    8000630a:	9736                	add	a4,a4,a3
    8000630c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006310:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006314:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006318:	97aa                	add	a5,a5,a0
    8000631a:	4705                	li	a4,1
    8000631c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006320:	0045c517          	auipc	a0,0x45c
    80006324:	a7850513          	addi	a0,a0,-1416 # 80461d98 <disk+0x18>
    80006328:	ffffc097          	auipc	ra,0xffffc
    8000632c:	1a2080e7          	jalr	418(ra) # 800024ca <wakeup>
}
    80006330:	60a2                	ld	ra,8(sp)
    80006332:	6402                	ld	s0,0(sp)
    80006334:	0141                	addi	sp,sp,16
    80006336:	8082                	ret
    panic("free_desc 1");
    80006338:	00002517          	auipc	a0,0x2
    8000633c:	54050513          	addi	a0,a0,1344 # 80008878 <syscalls+0x318>
    80006340:	ffffa097          	auipc	ra,0xffffa
    80006344:	1fc080e7          	jalr	508(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006348:	00002517          	auipc	a0,0x2
    8000634c:	54050513          	addi	a0,a0,1344 # 80008888 <syscalls+0x328>
    80006350:	ffffa097          	auipc	ra,0xffffa
    80006354:	1ec080e7          	jalr	492(ra) # 8000053c <panic>

0000000080006358 <virtio_disk_init>:
{
    80006358:	1101                	addi	sp,sp,-32
    8000635a:	ec06                	sd	ra,24(sp)
    8000635c:	e822                	sd	s0,16(sp)
    8000635e:	e426                	sd	s1,8(sp)
    80006360:	e04a                	sd	s2,0(sp)
    80006362:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006364:	00002597          	auipc	a1,0x2
    80006368:	53458593          	addi	a1,a1,1332 # 80008898 <syscalls+0x338>
    8000636c:	0045c517          	auipc	a0,0x45c
    80006370:	b3c50513          	addi	a0,a0,-1220 # 80461ea8 <disk+0x128>
    80006374:	ffffb097          	auipc	ra,0xffffb
    80006378:	97a080e7          	jalr	-1670(ra) # 80000cee <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000637c:	100017b7          	lui	a5,0x10001
    80006380:	4398                	lw	a4,0(a5)
    80006382:	2701                	sext.w	a4,a4
    80006384:	747277b7          	lui	a5,0x74727
    80006388:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000638c:	14f71b63          	bne	a4,a5,800064e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006390:	100017b7          	lui	a5,0x10001
    80006394:	43dc                	lw	a5,4(a5)
    80006396:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006398:	4709                	li	a4,2
    8000639a:	14e79463          	bne	a5,a4,800064e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000639e:	100017b7          	lui	a5,0x10001
    800063a2:	479c                	lw	a5,8(a5)
    800063a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800063a6:	12e79e63          	bne	a5,a4,800064e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800063aa:	100017b7          	lui	a5,0x10001
    800063ae:	47d8                	lw	a4,12(a5)
    800063b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800063b2:	554d47b7          	lui	a5,0x554d4
    800063b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800063ba:	12f71463          	bne	a4,a5,800064e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063be:	100017b7          	lui	a5,0x10001
    800063c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800063c6:	4705                	li	a4,1
    800063c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063ca:	470d                	li	a4,3
    800063cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800063ce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800063d0:	c7ffe6b7          	lui	a3,0xc7ffe
    800063d4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47b9c89f>
    800063d8:	8f75                	and	a4,a4,a3
    800063da:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800063dc:	472d                	li	a4,11
    800063de:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800063e0:	5bbc                	lw	a5,112(a5)
    800063e2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800063e6:	8ba1                	andi	a5,a5,8
    800063e8:	10078563          	beqz	a5,800064f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800063ec:	100017b7          	lui	a5,0x10001
    800063f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063f4:	43fc                	lw	a5,68(a5)
    800063f6:	2781                	sext.w	a5,a5
    800063f8:	10079563          	bnez	a5,80006502 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063fc:	100017b7          	lui	a5,0x10001
    80006400:	5bdc                	lw	a5,52(a5)
    80006402:	2781                	sext.w	a5,a5
  if(max == 0)
    80006404:	10078763          	beqz	a5,80006512 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006408:	471d                	li	a4,7
    8000640a:	10f77c63          	bgeu	a4,a5,80006522 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000640e:	ffffb097          	auipc	ra,0xffffb
    80006412:	81e080e7          	jalr	-2018(ra) # 80000c2c <kalloc>
    80006416:	0045c497          	auipc	s1,0x45c
    8000641a:	96a48493          	addi	s1,s1,-1686 # 80461d80 <disk>
    8000641e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006420:	ffffb097          	auipc	ra,0xffffb
    80006424:	80c080e7          	jalr	-2036(ra) # 80000c2c <kalloc>
    80006428:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000642a:	ffffb097          	auipc	ra,0xffffb
    8000642e:	802080e7          	jalr	-2046(ra) # 80000c2c <kalloc>
    80006432:	87aa                	mv	a5,a0
    80006434:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006436:	6088                	ld	a0,0(s1)
    80006438:	cd6d                	beqz	a0,80006532 <virtio_disk_init+0x1da>
    8000643a:	0045c717          	auipc	a4,0x45c
    8000643e:	94e73703          	ld	a4,-1714(a4) # 80461d88 <disk+0x8>
    80006442:	cb65                	beqz	a4,80006532 <virtio_disk_init+0x1da>
    80006444:	c7fd                	beqz	a5,80006532 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006446:	6605                	lui	a2,0x1
    80006448:	4581                	li	a1,0
    8000644a:	ffffb097          	auipc	ra,0xffffb
    8000644e:	a30080e7          	jalr	-1488(ra) # 80000e7a <memset>
  memset(disk.avail, 0, PGSIZE);
    80006452:	0045c497          	auipc	s1,0x45c
    80006456:	92e48493          	addi	s1,s1,-1746 # 80461d80 <disk>
    8000645a:	6605                	lui	a2,0x1
    8000645c:	4581                	li	a1,0
    8000645e:	6488                	ld	a0,8(s1)
    80006460:	ffffb097          	auipc	ra,0xffffb
    80006464:	a1a080e7          	jalr	-1510(ra) # 80000e7a <memset>
  memset(disk.used, 0, PGSIZE);
    80006468:	6605                	lui	a2,0x1
    8000646a:	4581                	li	a1,0
    8000646c:	6888                	ld	a0,16(s1)
    8000646e:	ffffb097          	auipc	ra,0xffffb
    80006472:	a0c080e7          	jalr	-1524(ra) # 80000e7a <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006476:	100017b7          	lui	a5,0x10001
    8000647a:	4721                	li	a4,8
    8000647c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000647e:	4098                	lw	a4,0(s1)
    80006480:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006484:	40d8                	lw	a4,4(s1)
    80006486:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000648a:	6498                	ld	a4,8(s1)
    8000648c:	0007069b          	sext.w	a3,a4
    80006490:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006494:	9701                	srai	a4,a4,0x20
    80006496:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000649a:	6898                	ld	a4,16(s1)
    8000649c:	0007069b          	sext.w	a3,a4
    800064a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800064a4:	9701                	srai	a4,a4,0x20
    800064a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800064aa:	4705                	li	a4,1
    800064ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800064ae:	00e48c23          	sb	a4,24(s1)
    800064b2:	00e48ca3          	sb	a4,25(s1)
    800064b6:	00e48d23          	sb	a4,26(s1)
    800064ba:	00e48da3          	sb	a4,27(s1)
    800064be:	00e48e23          	sb	a4,28(s1)
    800064c2:	00e48ea3          	sb	a4,29(s1)
    800064c6:	00e48f23          	sb	a4,30(s1)
    800064ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800064ce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d2:	0727a823          	sw	s2,112(a5)
}
    800064d6:	60e2                	ld	ra,24(sp)
    800064d8:	6442                	ld	s0,16(sp)
    800064da:	64a2                	ld	s1,8(sp)
    800064dc:	6902                	ld	s2,0(sp)
    800064de:	6105                	addi	sp,sp,32
    800064e0:	8082                	ret
    panic("could not find virtio disk");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	3c650513          	addi	a0,a0,966 # 800088a8 <syscalls+0x348>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	052080e7          	jalr	82(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800064f2:	00002517          	auipc	a0,0x2
    800064f6:	3d650513          	addi	a0,a0,982 # 800088c8 <syscalls+0x368>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	042080e7          	jalr	66(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006502:	00002517          	auipc	a0,0x2
    80006506:	3e650513          	addi	a0,a0,998 # 800088e8 <syscalls+0x388>
    8000650a:	ffffa097          	auipc	ra,0xffffa
    8000650e:	032080e7          	jalr	50(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006512:	00002517          	auipc	a0,0x2
    80006516:	3f650513          	addi	a0,a0,1014 # 80008908 <syscalls+0x3a8>
    8000651a:	ffffa097          	auipc	ra,0xffffa
    8000651e:	022080e7          	jalr	34(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006522:	00002517          	auipc	a0,0x2
    80006526:	40650513          	addi	a0,a0,1030 # 80008928 <syscalls+0x3c8>
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	012080e7          	jalr	18(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006532:	00002517          	auipc	a0,0x2
    80006536:	41650513          	addi	a0,a0,1046 # 80008948 <syscalls+0x3e8>
    8000653a:	ffffa097          	auipc	ra,0xffffa
    8000653e:	002080e7          	jalr	2(ra) # 8000053c <panic>

0000000080006542 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006542:	7159                	addi	sp,sp,-112
    80006544:	f486                	sd	ra,104(sp)
    80006546:	f0a2                	sd	s0,96(sp)
    80006548:	eca6                	sd	s1,88(sp)
    8000654a:	e8ca                	sd	s2,80(sp)
    8000654c:	e4ce                	sd	s3,72(sp)
    8000654e:	e0d2                	sd	s4,64(sp)
    80006550:	fc56                	sd	s5,56(sp)
    80006552:	f85a                	sd	s6,48(sp)
    80006554:	f45e                	sd	s7,40(sp)
    80006556:	f062                	sd	s8,32(sp)
    80006558:	ec66                	sd	s9,24(sp)
    8000655a:	e86a                	sd	s10,16(sp)
    8000655c:	1880                	addi	s0,sp,112
    8000655e:	8a2a                	mv	s4,a0
    80006560:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006562:	00c52c83          	lw	s9,12(a0)
    80006566:	001c9c9b          	slliw	s9,s9,0x1
    8000656a:	1c82                	slli	s9,s9,0x20
    8000656c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006570:	0045c517          	auipc	a0,0x45c
    80006574:	93850513          	addi	a0,a0,-1736 # 80461ea8 <disk+0x128>
    80006578:	ffffb097          	auipc	ra,0xffffb
    8000657c:	806080e7          	jalr	-2042(ra) # 80000d7e <acquire>
  for(int i = 0; i < 3; i++){
    80006580:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006582:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006584:	0045bb17          	auipc	s6,0x45b
    80006588:	7fcb0b13          	addi	s6,s6,2044 # 80461d80 <disk>
  for(int i = 0; i < 3; i++){
    8000658c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000658e:	0045cc17          	auipc	s8,0x45c
    80006592:	91ac0c13          	addi	s8,s8,-1766 # 80461ea8 <disk+0x128>
    80006596:	a095                	j	800065fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006598:	00fb0733          	add	a4,s6,a5
    8000659c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800065a0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800065a2:	0207c563          	bltz	a5,800065cc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800065a6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800065a8:	0591                	addi	a1,a1,4
    800065aa:	05560d63          	beq	a2,s5,80006604 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800065ae:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800065b0:	0045b717          	auipc	a4,0x45b
    800065b4:	7d070713          	addi	a4,a4,2000 # 80461d80 <disk>
    800065b8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800065ba:	01874683          	lbu	a3,24(a4)
    800065be:	fee9                	bnez	a3,80006598 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800065c0:	2785                	addiw	a5,a5,1
    800065c2:	0705                	addi	a4,a4,1
    800065c4:	fe979be3          	bne	a5,s1,800065ba <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800065c8:	57fd                	li	a5,-1
    800065ca:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800065cc:	00c05e63          	blez	a2,800065e8 <virtio_disk_rw+0xa6>
    800065d0:	060a                	slli	a2,a2,0x2
    800065d2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800065d6:	0009a503          	lw	a0,0(s3)
    800065da:	00000097          	auipc	ra,0x0
    800065de:	cfc080e7          	jalr	-772(ra) # 800062d6 <free_desc>
      for(int j = 0; j < i; j++)
    800065e2:	0991                	addi	s3,s3,4
    800065e4:	ffa999e3          	bne	s3,s10,800065d6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800065e8:	85e2                	mv	a1,s8
    800065ea:	0045b517          	auipc	a0,0x45b
    800065ee:	7ae50513          	addi	a0,a0,1966 # 80461d98 <disk+0x18>
    800065f2:	ffffc097          	auipc	ra,0xffffc
    800065f6:	e74080e7          	jalr	-396(ra) # 80002466 <sleep>
  for(int i = 0; i < 3; i++){
    800065fa:	f9040993          	addi	s3,s0,-112
{
    800065fe:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006600:	864a                	mv	a2,s2
    80006602:	b775                	j	800065ae <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006604:	f9042503          	lw	a0,-112(s0)
    80006608:	00a50713          	addi	a4,a0,10
    8000660c:	0712                	slli	a4,a4,0x4

  if(write)
    8000660e:	0045b797          	auipc	a5,0x45b
    80006612:	77278793          	addi	a5,a5,1906 # 80461d80 <disk>
    80006616:	00e786b3          	add	a3,a5,a4
    8000661a:	01703633          	snez	a2,s7
    8000661e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006620:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006624:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006628:	f6070613          	addi	a2,a4,-160
    8000662c:	6394                	ld	a3,0(a5)
    8000662e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006630:	00870593          	addi	a1,a4,8
    80006634:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006636:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006638:	0007b803          	ld	a6,0(a5)
    8000663c:	9642                	add	a2,a2,a6
    8000663e:	46c1                	li	a3,16
    80006640:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006642:	4585                	li	a1,1
    80006644:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006648:	f9442683          	lw	a3,-108(s0)
    8000664c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006650:	0692                	slli	a3,a3,0x4
    80006652:	9836                	add	a6,a6,a3
    80006654:	058a0613          	addi	a2,s4,88
    80006658:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000665c:	0007b803          	ld	a6,0(a5)
    80006660:	96c2                	add	a3,a3,a6
    80006662:	40000613          	li	a2,1024
    80006666:	c690                	sw	a2,8(a3)
  if(write)
    80006668:	001bb613          	seqz	a2,s7
    8000666c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006670:	00166613          	ori	a2,a2,1
    80006674:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006678:	f9842603          	lw	a2,-104(s0)
    8000667c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006680:	00250693          	addi	a3,a0,2
    80006684:	0692                	slli	a3,a3,0x4
    80006686:	96be                	add	a3,a3,a5
    80006688:	58fd                	li	a7,-1
    8000668a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000668e:	0612                	slli	a2,a2,0x4
    80006690:	9832                	add	a6,a6,a2
    80006692:	f9070713          	addi	a4,a4,-112
    80006696:	973e                	add	a4,a4,a5
    80006698:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000669c:	6398                	ld	a4,0(a5)
    8000669e:	9732                	add	a4,a4,a2
    800066a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800066a2:	4609                	li	a2,2
    800066a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800066a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800066ac:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800066b0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800066b4:	6794                	ld	a3,8(a5)
    800066b6:	0026d703          	lhu	a4,2(a3)
    800066ba:	8b1d                	andi	a4,a4,7
    800066bc:	0706                	slli	a4,a4,0x1
    800066be:	96ba                	add	a3,a3,a4
    800066c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800066c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800066c8:	6798                	ld	a4,8(a5)
    800066ca:	00275783          	lhu	a5,2(a4)
    800066ce:	2785                	addiw	a5,a5,1
    800066d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800066d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800066d8:	100017b7          	lui	a5,0x10001
    800066dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800066e0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800066e4:	0045b917          	auipc	s2,0x45b
    800066e8:	7c490913          	addi	s2,s2,1988 # 80461ea8 <disk+0x128>
  while(b->disk == 1) {
    800066ec:	4485                	li	s1,1
    800066ee:	00b79c63          	bne	a5,a1,80006706 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066f2:	85ca                	mv	a1,s2
    800066f4:	8552                	mv	a0,s4
    800066f6:	ffffc097          	auipc	ra,0xffffc
    800066fa:	d70080e7          	jalr	-656(ra) # 80002466 <sleep>
  while(b->disk == 1) {
    800066fe:	004a2783          	lw	a5,4(s4)
    80006702:	fe9788e3          	beq	a5,s1,800066f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006706:	f9042903          	lw	s2,-112(s0)
    8000670a:	00290713          	addi	a4,s2,2
    8000670e:	0712                	slli	a4,a4,0x4
    80006710:	0045b797          	auipc	a5,0x45b
    80006714:	67078793          	addi	a5,a5,1648 # 80461d80 <disk>
    80006718:	97ba                	add	a5,a5,a4
    8000671a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000671e:	0045b997          	auipc	s3,0x45b
    80006722:	66298993          	addi	s3,s3,1634 # 80461d80 <disk>
    80006726:	00491713          	slli	a4,s2,0x4
    8000672a:	0009b783          	ld	a5,0(s3)
    8000672e:	97ba                	add	a5,a5,a4
    80006730:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006734:	854a                	mv	a0,s2
    80006736:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000673a:	00000097          	auipc	ra,0x0
    8000673e:	b9c080e7          	jalr	-1124(ra) # 800062d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006742:	8885                	andi	s1,s1,1
    80006744:	f0ed                	bnez	s1,80006726 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006746:	0045b517          	auipc	a0,0x45b
    8000674a:	76250513          	addi	a0,a0,1890 # 80461ea8 <disk+0x128>
    8000674e:	ffffa097          	auipc	ra,0xffffa
    80006752:	6e4080e7          	jalr	1764(ra) # 80000e32 <release>
}
    80006756:	70a6                	ld	ra,104(sp)
    80006758:	7406                	ld	s0,96(sp)
    8000675a:	64e6                	ld	s1,88(sp)
    8000675c:	6946                	ld	s2,80(sp)
    8000675e:	69a6                	ld	s3,72(sp)
    80006760:	6a06                	ld	s4,64(sp)
    80006762:	7ae2                	ld	s5,56(sp)
    80006764:	7b42                	ld	s6,48(sp)
    80006766:	7ba2                	ld	s7,40(sp)
    80006768:	7c02                	ld	s8,32(sp)
    8000676a:	6ce2                	ld	s9,24(sp)
    8000676c:	6d42                	ld	s10,16(sp)
    8000676e:	6165                	addi	sp,sp,112
    80006770:	8082                	ret

0000000080006772 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006772:	1101                	addi	sp,sp,-32
    80006774:	ec06                	sd	ra,24(sp)
    80006776:	e822                	sd	s0,16(sp)
    80006778:	e426                	sd	s1,8(sp)
    8000677a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000677c:	0045b497          	auipc	s1,0x45b
    80006780:	60448493          	addi	s1,s1,1540 # 80461d80 <disk>
    80006784:	0045b517          	auipc	a0,0x45b
    80006788:	72450513          	addi	a0,a0,1828 # 80461ea8 <disk+0x128>
    8000678c:	ffffa097          	auipc	ra,0xffffa
    80006790:	5f2080e7          	jalr	1522(ra) # 80000d7e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006794:	10001737          	lui	a4,0x10001
    80006798:	533c                	lw	a5,96(a4)
    8000679a:	8b8d                	andi	a5,a5,3
    8000679c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000679e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800067a2:	689c                	ld	a5,16(s1)
    800067a4:	0204d703          	lhu	a4,32(s1)
    800067a8:	0027d783          	lhu	a5,2(a5)
    800067ac:	04f70863          	beq	a4,a5,800067fc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800067b0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800067b4:	6898                	ld	a4,16(s1)
    800067b6:	0204d783          	lhu	a5,32(s1)
    800067ba:	8b9d                	andi	a5,a5,7
    800067bc:	078e                	slli	a5,a5,0x3
    800067be:	97ba                	add	a5,a5,a4
    800067c0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800067c2:	00278713          	addi	a4,a5,2
    800067c6:	0712                	slli	a4,a4,0x4
    800067c8:	9726                	add	a4,a4,s1
    800067ca:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800067ce:	e721                	bnez	a4,80006816 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800067d0:	0789                	addi	a5,a5,2
    800067d2:	0792                	slli	a5,a5,0x4
    800067d4:	97a6                	add	a5,a5,s1
    800067d6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800067d8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800067dc:	ffffc097          	auipc	ra,0xffffc
    800067e0:	cee080e7          	jalr	-786(ra) # 800024ca <wakeup>

    disk.used_idx += 1;
    800067e4:	0204d783          	lhu	a5,32(s1)
    800067e8:	2785                	addiw	a5,a5,1
    800067ea:	17c2                	slli	a5,a5,0x30
    800067ec:	93c1                	srli	a5,a5,0x30
    800067ee:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067f2:	6898                	ld	a4,16(s1)
    800067f4:	00275703          	lhu	a4,2(a4)
    800067f8:	faf71ce3          	bne	a4,a5,800067b0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067fc:	0045b517          	auipc	a0,0x45b
    80006800:	6ac50513          	addi	a0,a0,1708 # 80461ea8 <disk+0x128>
    80006804:	ffffa097          	auipc	ra,0xffffa
    80006808:	62e080e7          	jalr	1582(ra) # 80000e32 <release>
}
    8000680c:	60e2                	ld	ra,24(sp)
    8000680e:	6442                	ld	s0,16(sp)
    80006810:	64a2                	ld	s1,8(sp)
    80006812:	6105                	addi	sp,sp,32
    80006814:	8082                	ret
      panic("virtio_disk_intr status");
    80006816:	00002517          	auipc	a0,0x2
    8000681a:	14a50513          	addi	a0,a0,330 # 80008960 <syscalls+0x400>
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	d1e080e7          	jalr	-738(ra) # 8000053c <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
