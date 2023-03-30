
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
    80000066:	15e78793          	addi	a5,a5,350 # 800061c0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc93f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	f3878793          	addi	a5,a5,-200 # 80000fe4 <main>
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
    8000012e:	760080e7          	jalr	1888(ra) # 8000288a <either_copyin>
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
    80000190:	bb8080e7          	jalr	-1096(ra) # 80000d44 <acquire>
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
    800001b8:	b10080e7          	jalr	-1264(ra) # 80001cc4 <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	518080e7          	jalr	1304(ra) # 800026d4 <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	262080e7          	jalr	610(ra) # 8000242c <sleep>
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
    80000214:	624080e7          	jalr	1572(ra) # 80002834 <either_copyout>
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
    80000234:	bc8080e7          	jalr	-1080(ra) # 80000df8 <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	95250513          	addi	a0,a0,-1710 # 80010b90 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	bb2080e7          	jalr	-1102(ra) # 80000df8 <release>
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
    800002d4:	a74080e7          	jalr	-1420(ra) # 80000d44 <acquire>

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
    800002f2:	5f2080e7          	jalr	1522(ra) # 800028e0 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	89a50513          	addi	a0,a0,-1894 # 80010b90 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	afa080e7          	jalr	-1286(ra) # 80000df8 <release>
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
    80000446:	04e080e7          	jalr	78(ra) # 80002490 <wakeup>
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
    80000468:	850080e7          	jalr	-1968(ra) # 80000cb4 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	8b478793          	addi	a5,a5,-1868 # 80240d28 <devsw>
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
    80000614:	734080e7          	jalr	1844(ra) # 80000d44 <acquire>
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
    80000772:	68a080e7          	jalr	1674(ra) # 80000df8 <release>
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
    80000798:	520080e7          	jalr	1312(ra) # 80000cb4 <initlock>
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
    800007ee:	4ca080e7          	jalr	1226(ra) # 80000cb4 <initlock>
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
    8000080a:	4f2080e7          	jalr	1266(ra) # 80000cf8 <push_off>

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
    80000838:	564080e7          	jalr	1380(ra) # 80000d98 <pop_off>
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
    800008a6:	bee080e7          	jalr	-1042(ra) # 80002490 <wakeup>
    
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
    800008ea:	45e080e7          	jalr	1118(ra) # 80000d44 <acquire>
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
    80000930:	b00080e7          	jalr	-1280(ra) # 8000242c <sleep>
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
    8000096c:	490080e7          	jalr	1168(ra) # 80000df8 <release>
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
    800009d6:	372080e7          	jalr	882(ra) # 80000d44 <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	414080e7          	jalr	1044(ra) # 80000df8 <release>
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
    80000a02:	84aa                	mv	s1,a0
    acquire(&kmem.lock);
    80000a04:	00010917          	auipc	s2,0x10
    80000a08:	28c90913          	addi	s2,s2,652 # 80010c90 <kmem>
    80000a0c:	854a                	mv	a0,s2
    80000a0e:	00000097          	auipc	ra,0x0
    80000a12:	336080e7          	jalr	822(ra) # 80000d44 <acquire>
    ref_count[pa / PGSIZE]++;
    80000a16:	80b1                	srli	s1,s1,0xc
    80000a18:	048a                	slli	s1,s1,0x2
    80000a1a:	00010797          	auipc	a5,0x10
    80000a1e:	29678793          	addi	a5,a5,662 # 80010cb0 <ref_count>
    80000a22:	97a6                	add	a5,a5,s1
    80000a24:	4398                	lw	a4,0(a5)
    80000a26:	2705                	addiw	a4,a4,1
    80000a28:	c398                	sw	a4,0(a5)
    release(&kmem.lock);
    80000a2a:	854a                	mv	a0,s2
    80000a2c:	00000097          	auipc	ra,0x0
    80000a30:	3cc080e7          	jalr	972(ra) # 80000df8 <release>
}
    80000a34:	60e2                	ld	ra,24(sp)
    80000a36:	6442                	ld	s0,16(sp)
    80000a38:	64a2                	ld	s1,8(sp)
    80000a3a:	6902                	ld	s2,0(sp)
    80000a3c:	6105                	addi	sp,sp,32
    80000a3e:	8082                	ret

0000000080000a40 <decrement_refcount>:

int decrement_refcount(uint64 pa) {
    80000a40:	1101                	addi	sp,sp,-32
    80000a42:	ec06                	sd	ra,24(sp)
    80000a44:	e822                	sd	s0,16(sp)
    80000a46:	e426                	sd	s1,8(sp)
    80000a48:	e04a                	sd	s2,0(sp)
    80000a4a:	1000                	addi	s0,sp,32
    80000a4c:	84aa                	mv	s1,a0
    acquire(&kmem.lock);
    80000a4e:	00010917          	auipc	s2,0x10
    80000a52:	24290913          	addi	s2,s2,578 # 80010c90 <kmem>
    80000a56:	854a                	mv	a0,s2
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	2ec080e7          	jalr	748(ra) # 80000d44 <acquire>
    ref_count[pa / PGSIZE]--;
    80000a60:	80b1                	srli	s1,s1,0xc
    80000a62:	048a                	slli	s1,s1,0x2
    80000a64:	00010797          	auipc	a5,0x10
    80000a68:	24c78793          	addi	a5,a5,588 # 80010cb0 <ref_count>
    80000a6c:	94be                	add	s1,s1,a5
    80000a6e:	409c                	lw	a5,0(s1)
    80000a70:	37fd                	addiw	a5,a5,-1
    80000a72:	c09c                	sw	a5,0(s1)
    release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	382080e7          	jalr	898(ra) # 80000df8 <release>

    // Check if we have refs still
    if (ref_count[pa / PGSIZE] > 0) {
    80000a7e:	4088                	lw	a0,0(s1)
        return 1;
    }
    return 0;
    
}
    80000a80:	00a03533          	snez	a0,a0
    80000a84:	60e2                	ld	ra,24(sp)
    80000a86:	6442                	ld	s0,16(sp)
    80000a88:	64a2                	ld	s1,8(sp)
    80000a8a:	6902                	ld	s2,0(sp)
    80000a8c:	6105                	addi	sp,sp,32
    80000a8e:	8082                	ret

0000000080000a90 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a90:	1101                	addi	sp,sp,-32
    80000a92:	ec06                	sd	ra,24(sp)
    80000a94:	e822                	sd	s0,16(sp)
    80000a96:	e426                	sd	s1,8(sp)
    80000a98:	e04a                	sd	s2,0(sp)
    80000a9a:	1000                	addi	s0,sp,32
    80000a9c:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a9e:	00008797          	auipc	a5,0x8
    80000aa2:	f827b783          	ld	a5,-126(a5) # 80008a20 <MAX_PAGES>
    80000aa6:	c799                	beqz	a5,80000ab4 <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000aa8:	00008717          	auipc	a4,0x8
    80000aac:	f7073703          	ld	a4,-144(a4) # 80008a18 <FREE_PAGES>
    80000ab0:	02f77c63          	bgeu	a4,a5,80000ae8 <kfree+0x58>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) {
    80000ab4:	03449793          	slli	a5,s1,0x34
    80000ab8:	e3b5                	bnez	a5,80000b1c <kfree+0x8c>
    80000aba:	00241797          	auipc	a5,0x241
    80000abe:	40678793          	addi	a5,a5,1030 # 80241ec0 <end>
    80000ac2:	04f4ed63          	bltu	s1,a5,80000b1c <kfree+0x8c>
    80000ac6:	47c5                	li	a5,17
    80000ac8:	07ee                	slli	a5,a5,0x1b
    80000aca:	04f4f963          	bgeu	s1,a5,80000b1c <kfree+0x8c>
        panic("kfree");
    }

    // We check if we still have some references to the page before continuing
    // If page has refs, we return, otherwise we continue to free it
    if (decrement_refcount((uint64) pa) > 0) {
    80000ace:	8526                	mv	a0,s1
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	f70080e7          	jalr	-144(ra) # 80000a40 <decrement_refcount>
    80000ad8:	04a05a63          	blez	a0,80000b2c <kfree+0x9c>
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    FREE_PAGES++;
    release(&kmem.lock);
}
    80000adc:	60e2                	ld	ra,24(sp)
    80000ade:	6442                	ld	s0,16(sp)
    80000ae0:	64a2                	ld	s1,8(sp)
    80000ae2:	6902                	ld	s2,0(sp)
    80000ae4:	6105                	addi	sp,sp,32
    80000ae6:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000ae8:	05200693          	li	a3,82
    80000aec:	00007617          	auipc	a2,0x7
    80000af0:	51c60613          	addi	a2,a2,1308 # 80008008 <__func__.1>
    80000af4:	00007597          	auipc	a1,0x7
    80000af8:	57c58593          	addi	a1,a1,1404 # 80008070 <digits+0x20>
    80000afc:	00007517          	auipc	a0,0x7
    80000b00:	58450513          	addi	a0,a0,1412 # 80008080 <digits+0x30>
    80000b04:	00000097          	auipc	ra,0x0
    80000b08:	a94080e7          	jalr	-1388(ra) # 80000598 <printf>
    80000b0c:	00007517          	auipc	a0,0x7
    80000b10:	58450513          	addi	a0,a0,1412 # 80008090 <digits+0x40>
    80000b14:	00000097          	auipc	ra,0x0
    80000b18:	a28080e7          	jalr	-1496(ra) # 8000053c <panic>
        panic("kfree");
    80000b1c:	00007517          	auipc	a0,0x7
    80000b20:	58450513          	addi	a0,a0,1412 # 800080a0 <digits+0x50>
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	a18080e7          	jalr	-1512(ra) # 8000053c <panic>
    memset(pa, 1, PGSIZE);
    80000b2c:	6605                	lui	a2,0x1
    80000b2e:	4585                	li	a1,1
    80000b30:	8526                	mv	a0,s1
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	30e080e7          	jalr	782(ra) # 80000e40 <memset>
    acquire(&kmem.lock);
    80000b3a:	00010917          	auipc	s2,0x10
    80000b3e:	15690913          	addi	s2,s2,342 # 80010c90 <kmem>
    80000b42:	854a                	mv	a0,s2
    80000b44:	00000097          	auipc	ra,0x0
    80000b48:	200080e7          	jalr	512(ra) # 80000d44 <acquire>
    r->next = kmem.freelist;
    80000b4c:	01893783          	ld	a5,24(s2)
    80000b50:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000b52:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000b56:	00008717          	auipc	a4,0x8
    80000b5a:	ec270713          	addi	a4,a4,-318 # 80008a18 <FREE_PAGES>
    80000b5e:	631c                	ld	a5,0(a4)
    80000b60:	0785                	addi	a5,a5,1
    80000b62:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000b64:	854a                	mv	a0,s2
    80000b66:	00000097          	auipc	ra,0x0
    80000b6a:	292080e7          	jalr	658(ra) # 80000df8 <release>
    80000b6e:	b7bd                	j	80000adc <kfree+0x4c>

0000000080000b70 <freerange>:
{
    80000b70:	7179                	addi	sp,sp,-48
    80000b72:	f406                	sd	ra,40(sp)
    80000b74:	f022                	sd	s0,32(sp)
    80000b76:	ec26                	sd	s1,24(sp)
    80000b78:	e84a                	sd	s2,16(sp)
    80000b7a:	e44e                	sd	s3,8(sp)
    80000b7c:	e052                	sd	s4,0(sp)
    80000b7e:	1800                	addi	s0,sp,48
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000b80:	6785                	lui	a5,0x1
    80000b82:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000b86:	00e504b3          	add	s1,a0,a4
    80000b8a:	777d                	lui	a4,0xfffff
    80000b8c:	8cf9                	and	s1,s1,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b8e:	94be                	add	s1,s1,a5
    80000b90:	0095ee63          	bltu	a1,s1,80000bac <freerange+0x3c>
    80000b94:	892e                	mv	s2,a1
        kfree(p);
    80000b96:	7a7d                	lui	s4,0xfffff
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000b98:	6985                	lui	s3,0x1
        kfree(p);
    80000b9a:	01448533          	add	a0,s1,s4
    80000b9e:	00000097          	auipc	ra,0x0
    80000ba2:	ef2080e7          	jalr	-270(ra) # 80000a90 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000ba6:	94ce                	add	s1,s1,s3
    80000ba8:	fe9979e3          	bgeu	s2,s1,80000b9a <freerange+0x2a>
}
    80000bac:	70a2                	ld	ra,40(sp)
    80000bae:	7402                	ld	s0,32(sp)
    80000bb0:	64e2                	ld	s1,24(sp)
    80000bb2:	6942                	ld	s2,16(sp)
    80000bb4:	69a2                	ld	s3,8(sp)
    80000bb6:	6a02                	ld	s4,0(sp)
    80000bb8:	6145                	addi	sp,sp,48
    80000bba:	8082                	ret

0000000080000bbc <kinit>:
{
    80000bbc:	1141                	addi	sp,sp,-16
    80000bbe:	e406                	sd	ra,8(sp)
    80000bc0:	e022                	sd	s0,0(sp)
    80000bc2:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000bc4:	00007597          	auipc	a1,0x7
    80000bc8:	4e458593          	addi	a1,a1,1252 # 800080a8 <digits+0x58>
    80000bcc:	00010517          	auipc	a0,0x10
    80000bd0:	0c450513          	addi	a0,a0,196 # 80010c90 <kmem>
    80000bd4:	00000097          	auipc	ra,0x0
    80000bd8:	0e0080e7          	jalr	224(ra) # 80000cb4 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000bdc:	45c5                	li	a1,17
    80000bde:	05ee                	slli	a1,a1,0x1b
    80000be0:	00241517          	auipc	a0,0x241
    80000be4:	2e050513          	addi	a0,a0,736 # 80241ec0 <end>
    80000be8:	00000097          	auipc	ra,0x0
    80000bec:	f88080e7          	jalr	-120(ra) # 80000b70 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000bf0:	00008797          	auipc	a5,0x8
    80000bf4:	e287b783          	ld	a5,-472(a5) # 80008a18 <FREE_PAGES>
    80000bf8:	00008717          	auipc	a4,0x8
    80000bfc:	e2f73423          	sd	a5,-472(a4) # 80008a20 <MAX_PAGES>
}
    80000c00:	60a2                	ld	ra,8(sp)
    80000c02:	6402                	ld	s0,0(sp)
    80000c04:	0141                	addi	sp,sp,16
    80000c06:	8082                	ret

0000000080000c08 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c08:	1101                	addi	sp,sp,-32
    80000c0a:	ec06                	sd	ra,24(sp)
    80000c0c:	e822                	sd	s0,16(sp)
    80000c0e:	e426                	sd	s1,8(sp)
    80000c10:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000c12:	00008797          	auipc	a5,0x8
    80000c16:	e067b783          	ld	a5,-506(a5) # 80008a18 <FREE_PAGES>
    80000c1a:	cbb1                	beqz	a5,80000c6e <kalloc+0x66>
    struct run *r;

    acquire(&kmem.lock);
    80000c1c:	00010497          	auipc	s1,0x10
    80000c20:	07448493          	addi	s1,s1,116 # 80010c90 <kmem>
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	11e080e7          	jalr	286(ra) # 80000d44 <acquire>
    r = kmem.freelist;
    80000c2e:	6c84                	ld	s1,24(s1)
    if (r) {
    80000c30:	c8ad                	beqz	s1,80000ca2 <kalloc+0x9a>
        kmem.freelist = r->next;
    80000c32:	609c                	ld	a5,0(s1)
    80000c34:	00010517          	auipc	a0,0x10
    80000c38:	05c50513          	addi	a0,a0,92 # 80010c90 <kmem>
    80000c3c:	ed1c                	sd	a5,24(a0)
        
    } 
    release(&kmem.lock);
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	1ba080e7          	jalr	442(ra) # 80000df8 <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000c46:	6605                	lui	a2,0x1
    80000c48:	4595                	li	a1,5
    80000c4a:	8526                	mv	a0,s1
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	1f4080e7          	jalr	500(ra) # 80000e40 <memset>
    FREE_PAGES--;
    80000c54:	00008717          	auipc	a4,0x8
    80000c58:	dc470713          	addi	a4,a4,-572 # 80008a18 <FREE_PAGES>
    80000c5c:	631c                	ld	a5,0(a4)
    80000c5e:	17fd                	addi	a5,a5,-1
    80000c60:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000c62:	8526                	mv	a0,s1
    80000c64:	60e2                	ld	ra,24(sp)
    80000c66:	6442                	ld	s0,16(sp)
    80000c68:	64a2                	ld	s1,8(sp)
    80000c6a:	6105                	addi	sp,sp,32
    80000c6c:	8082                	ret
    assert(FREE_PAGES > 0);
    80000c6e:	07100693          	li	a3,113
    80000c72:	00007617          	auipc	a2,0x7
    80000c76:	38e60613          	addi	a2,a2,910 # 80008000 <etext>
    80000c7a:	00007597          	auipc	a1,0x7
    80000c7e:	3f658593          	addi	a1,a1,1014 # 80008070 <digits+0x20>
    80000c82:	00007517          	auipc	a0,0x7
    80000c86:	3fe50513          	addi	a0,a0,1022 # 80008080 <digits+0x30>
    80000c8a:	00000097          	auipc	ra,0x0
    80000c8e:	90e080e7          	jalr	-1778(ra) # 80000598 <printf>
    80000c92:	00007517          	auipc	a0,0x7
    80000c96:	3fe50513          	addi	a0,a0,1022 # 80008090 <digits+0x40>
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	8a2080e7          	jalr	-1886(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000ca2:	00010517          	auipc	a0,0x10
    80000ca6:	fee50513          	addi	a0,a0,-18 # 80010c90 <kmem>
    80000caa:	00000097          	auipc	ra,0x0
    80000cae:	14e080e7          	jalr	334(ra) # 80000df8 <release>
    if (r)
    80000cb2:	b74d                	j	80000c54 <kalloc+0x4c>

0000000080000cb4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000cb4:	1141                	addi	sp,sp,-16
    80000cb6:	e422                	sd	s0,8(sp)
    80000cb8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000cba:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000cbc:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000cc0:	00053823          	sd	zero,16(a0)
}
    80000cc4:	6422                	ld	s0,8(sp)
    80000cc6:	0141                	addi	sp,sp,16
    80000cc8:	8082                	ret

0000000080000cca <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000cca:	411c                	lw	a5,0(a0)
    80000ccc:	e399                	bnez	a5,80000cd2 <holding+0x8>
    80000cce:	4501                	li	a0,0
  return r;
}
    80000cd0:	8082                	ret
{
    80000cd2:	1101                	addi	sp,sp,-32
    80000cd4:	ec06                	sd	ra,24(sp)
    80000cd6:	e822                	sd	s0,16(sp)
    80000cd8:	e426                	sd	s1,8(sp)
    80000cda:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cdc:	6904                	ld	s1,16(a0)
    80000cde:	00001097          	auipc	ra,0x1
    80000ce2:	fca080e7          	jalr	-54(ra) # 80001ca8 <mycpu>
    80000ce6:	40a48533          	sub	a0,s1,a0
    80000cea:	00153513          	seqz	a0,a0
}
    80000cee:	60e2                	ld	ra,24(sp)
    80000cf0:	6442                	ld	s0,16(sp)
    80000cf2:	64a2                	ld	s1,8(sp)
    80000cf4:	6105                	addi	sp,sp,32
    80000cf6:	8082                	ret

0000000080000cf8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cf8:	1101                	addi	sp,sp,-32
    80000cfa:	ec06                	sd	ra,24(sp)
    80000cfc:	e822                	sd	s0,16(sp)
    80000cfe:	e426                	sd	s1,8(sp)
    80000d00:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d02:	100024f3          	csrr	s1,sstatus
    80000d06:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d0a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d0c:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d10:	00001097          	auipc	ra,0x1
    80000d14:	f98080e7          	jalr	-104(ra) # 80001ca8 <mycpu>
    80000d18:	5d3c                	lw	a5,120(a0)
    80000d1a:	cf89                	beqz	a5,80000d34 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d1c:	00001097          	auipc	ra,0x1
    80000d20:	f8c080e7          	jalr	-116(ra) # 80001ca8 <mycpu>
    80000d24:	5d3c                	lw	a5,120(a0)
    80000d26:	2785                	addiw	a5,a5,1
    80000d28:	dd3c                	sw	a5,120(a0)
}
    80000d2a:	60e2                	ld	ra,24(sp)
    80000d2c:	6442                	ld	s0,16(sp)
    80000d2e:	64a2                	ld	s1,8(sp)
    80000d30:	6105                	addi	sp,sp,32
    80000d32:	8082                	ret
    mycpu()->intena = old;
    80000d34:	00001097          	auipc	ra,0x1
    80000d38:	f74080e7          	jalr	-140(ra) # 80001ca8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d3c:	8085                	srli	s1,s1,0x1
    80000d3e:	8885                	andi	s1,s1,1
    80000d40:	dd64                	sw	s1,124(a0)
    80000d42:	bfe9                	j	80000d1c <push_off+0x24>

0000000080000d44 <acquire>:
{
    80000d44:	1101                	addi	sp,sp,-32
    80000d46:	ec06                	sd	ra,24(sp)
    80000d48:	e822                	sd	s0,16(sp)
    80000d4a:	e426                	sd	s1,8(sp)
    80000d4c:	1000                	addi	s0,sp,32
    80000d4e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d50:	00000097          	auipc	ra,0x0
    80000d54:	fa8080e7          	jalr	-88(ra) # 80000cf8 <push_off>
  if(holding(lk))
    80000d58:	8526                	mv	a0,s1
    80000d5a:	00000097          	auipc	ra,0x0
    80000d5e:	f70080e7          	jalr	-144(ra) # 80000cca <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d62:	4705                	li	a4,1
  if(holding(lk))
    80000d64:	e115                	bnez	a0,80000d88 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d66:	87ba                	mv	a5,a4
    80000d68:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d6c:	2781                	sext.w	a5,a5
    80000d6e:	ffe5                	bnez	a5,80000d66 <acquire+0x22>
  __sync_synchronize();
    80000d70:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d74:	00001097          	auipc	ra,0x1
    80000d78:	f34080e7          	jalr	-204(ra) # 80001ca8 <mycpu>
    80000d7c:	e888                	sd	a0,16(s1)
}
    80000d7e:	60e2                	ld	ra,24(sp)
    80000d80:	6442                	ld	s0,16(sp)
    80000d82:	64a2                	ld	s1,8(sp)
    80000d84:	6105                	addi	sp,sp,32
    80000d86:	8082                	ret
    panic("acquire");
    80000d88:	00007517          	auipc	a0,0x7
    80000d8c:	32850513          	addi	a0,a0,808 # 800080b0 <digits+0x60>
    80000d90:	fffff097          	auipc	ra,0xfffff
    80000d94:	7ac080e7          	jalr	1964(ra) # 8000053c <panic>

0000000080000d98 <pop_off>:

void
pop_off(void)
{
    80000d98:	1141                	addi	sp,sp,-16
    80000d9a:	e406                	sd	ra,8(sp)
    80000d9c:	e022                	sd	s0,0(sp)
    80000d9e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000da0:	00001097          	auipc	ra,0x1
    80000da4:	f08080e7          	jalr	-248(ra) # 80001ca8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000da8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000dac:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000dae:	e78d                	bnez	a5,80000dd8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000db0:	5d3c                	lw	a5,120(a0)
    80000db2:	02f05b63          	blez	a5,80000de8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000db6:	37fd                	addiw	a5,a5,-1
    80000db8:	0007871b          	sext.w	a4,a5
    80000dbc:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000dbe:	eb09                	bnez	a4,80000dd0 <pop_off+0x38>
    80000dc0:	5d7c                	lw	a5,124(a0)
    80000dc2:	c799                	beqz	a5,80000dd0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dc4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000dc8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000dcc:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000dd0:	60a2                	ld	ra,8(sp)
    80000dd2:	6402                	ld	s0,0(sp)
    80000dd4:	0141                	addi	sp,sp,16
    80000dd6:	8082                	ret
    panic("pop_off - interruptible");
    80000dd8:	00007517          	auipc	a0,0x7
    80000ddc:	2e050513          	addi	a0,a0,736 # 800080b8 <digits+0x68>
    80000de0:	fffff097          	auipc	ra,0xfffff
    80000de4:	75c080e7          	jalr	1884(ra) # 8000053c <panic>
    panic("pop_off");
    80000de8:	00007517          	auipc	a0,0x7
    80000dec:	2e850513          	addi	a0,a0,744 # 800080d0 <digits+0x80>
    80000df0:	fffff097          	auipc	ra,0xfffff
    80000df4:	74c080e7          	jalr	1868(ra) # 8000053c <panic>

0000000080000df8 <release>:
{
    80000df8:	1101                	addi	sp,sp,-32
    80000dfa:	ec06                	sd	ra,24(sp)
    80000dfc:	e822                	sd	s0,16(sp)
    80000dfe:	e426                	sd	s1,8(sp)
    80000e00:	1000                	addi	s0,sp,32
    80000e02:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e04:	00000097          	auipc	ra,0x0
    80000e08:	ec6080e7          	jalr	-314(ra) # 80000cca <holding>
    80000e0c:	c115                	beqz	a0,80000e30 <release+0x38>
  lk->cpu = 0;
    80000e0e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e12:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e16:	0f50000f          	fence	iorw,ow
    80000e1a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e1e:	00000097          	auipc	ra,0x0
    80000e22:	f7a080e7          	jalr	-134(ra) # 80000d98 <pop_off>
}
    80000e26:	60e2                	ld	ra,24(sp)
    80000e28:	6442                	ld	s0,16(sp)
    80000e2a:	64a2                	ld	s1,8(sp)
    80000e2c:	6105                	addi	sp,sp,32
    80000e2e:	8082                	ret
    panic("release");
    80000e30:	00007517          	auipc	a0,0x7
    80000e34:	2a850513          	addi	a0,a0,680 # 800080d8 <digits+0x88>
    80000e38:	fffff097          	auipc	ra,0xfffff
    80000e3c:	704080e7          	jalr	1796(ra) # 8000053c <panic>

0000000080000e40 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e40:	1141                	addi	sp,sp,-16
    80000e42:	e422                	sd	s0,8(sp)
    80000e44:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e46:	ca19                	beqz	a2,80000e5c <memset+0x1c>
    80000e48:	87aa                	mv	a5,a0
    80000e4a:	1602                	slli	a2,a2,0x20
    80000e4c:	9201                	srli	a2,a2,0x20
    80000e4e:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000e52:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000e56:	0785                	addi	a5,a5,1
    80000e58:	fee79de3          	bne	a5,a4,80000e52 <memset+0x12>
  }
  return dst;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e68:	ca05                	beqz	a2,80000e98 <memcmp+0x36>
    80000e6a:	fff6069b          	addiw	a3,a2,-1
    80000e6e:	1682                	slli	a3,a3,0x20
    80000e70:	9281                	srli	a3,a3,0x20
    80000e72:	0685                	addi	a3,a3,1
    80000e74:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e76:	00054783          	lbu	a5,0(a0)
    80000e7a:	0005c703          	lbu	a4,0(a1)
    80000e7e:	00e79863          	bne	a5,a4,80000e8e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e82:	0505                	addi	a0,a0,1
    80000e84:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e86:	fed518e3          	bne	a0,a3,80000e76 <memcmp+0x14>
  }

  return 0;
    80000e8a:	4501                	li	a0,0
    80000e8c:	a019                	j	80000e92 <memcmp+0x30>
      return *s1 - *s2;
    80000e8e:	40e7853b          	subw	a0,a5,a4
}
    80000e92:	6422                	ld	s0,8(sp)
    80000e94:	0141                	addi	sp,sp,16
    80000e96:	8082                	ret
  return 0;
    80000e98:	4501                	li	a0,0
    80000e9a:	bfe5                	j	80000e92 <memcmp+0x30>

0000000080000e9c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e9c:	1141                	addi	sp,sp,-16
    80000e9e:	e422                	sd	s0,8(sp)
    80000ea0:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000ea2:	c205                	beqz	a2,80000ec2 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000ea4:	02a5e263          	bltu	a1,a0,80000ec8 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000ea8:	1602                	slli	a2,a2,0x20
    80000eaa:	9201                	srli	a2,a2,0x20
    80000eac:	00c587b3          	add	a5,a1,a2
{
    80000eb0:	872a                	mv	a4,a0
      *d++ = *s++;
    80000eb2:	0585                	addi	a1,a1,1
    80000eb4:	0705                	addi	a4,a4,1
    80000eb6:	fff5c683          	lbu	a3,-1(a1)
    80000eba:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000ebe:	fef59ae3          	bne	a1,a5,80000eb2 <memmove+0x16>

  return dst;
}
    80000ec2:	6422                	ld	s0,8(sp)
    80000ec4:	0141                	addi	sp,sp,16
    80000ec6:	8082                	ret
  if(s < d && s + n > d){
    80000ec8:	02061693          	slli	a3,a2,0x20
    80000ecc:	9281                	srli	a3,a3,0x20
    80000ece:	00d58733          	add	a4,a1,a3
    80000ed2:	fce57be3          	bgeu	a0,a4,80000ea8 <memmove+0xc>
    d += n;
    80000ed6:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000ed8:	fff6079b          	addiw	a5,a2,-1
    80000edc:	1782                	slli	a5,a5,0x20
    80000ede:	9381                	srli	a5,a5,0x20
    80000ee0:	fff7c793          	not	a5,a5
    80000ee4:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ee6:	177d                	addi	a4,a4,-1
    80000ee8:	16fd                	addi	a3,a3,-1
    80000eea:	00074603          	lbu	a2,0(a4)
    80000eee:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000ef2:	fee79ae3          	bne	a5,a4,80000ee6 <memmove+0x4a>
    80000ef6:	b7f1                	j	80000ec2 <memmove+0x26>

0000000080000ef8 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ef8:	1141                	addi	sp,sp,-16
    80000efa:	e406                	sd	ra,8(sp)
    80000efc:	e022                	sd	s0,0(sp)
    80000efe:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f00:	00000097          	auipc	ra,0x0
    80000f04:	f9c080e7          	jalr	-100(ra) # 80000e9c <memmove>
}
    80000f08:	60a2                	ld	ra,8(sp)
    80000f0a:	6402                	ld	s0,0(sp)
    80000f0c:	0141                	addi	sp,sp,16
    80000f0e:	8082                	ret

0000000080000f10 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000f10:	1141                	addi	sp,sp,-16
    80000f12:	e422                	sd	s0,8(sp)
    80000f14:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000f16:	ce11                	beqz	a2,80000f32 <strncmp+0x22>
    80000f18:	00054783          	lbu	a5,0(a0)
    80000f1c:	cf89                	beqz	a5,80000f36 <strncmp+0x26>
    80000f1e:	0005c703          	lbu	a4,0(a1)
    80000f22:	00f71a63          	bne	a4,a5,80000f36 <strncmp+0x26>
    n--, p++, q++;
    80000f26:	367d                	addiw	a2,a2,-1
    80000f28:	0505                	addi	a0,a0,1
    80000f2a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f2c:	f675                	bnez	a2,80000f18 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f2e:	4501                	li	a0,0
    80000f30:	a809                	j	80000f42 <strncmp+0x32>
    80000f32:	4501                	li	a0,0
    80000f34:	a039                	j	80000f42 <strncmp+0x32>
  if(n == 0)
    80000f36:	ca09                	beqz	a2,80000f48 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f38:	00054503          	lbu	a0,0(a0)
    80000f3c:	0005c783          	lbu	a5,0(a1)
    80000f40:	9d1d                	subw	a0,a0,a5
}
    80000f42:	6422                	ld	s0,8(sp)
    80000f44:	0141                	addi	sp,sp,16
    80000f46:	8082                	ret
    return 0;
    80000f48:	4501                	li	a0,0
    80000f4a:	bfe5                	j	80000f42 <strncmp+0x32>

0000000080000f4c <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f4c:	1141                	addi	sp,sp,-16
    80000f4e:	e422                	sd	s0,8(sp)
    80000f50:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f52:	87aa                	mv	a5,a0
    80000f54:	86b2                	mv	a3,a2
    80000f56:	367d                	addiw	a2,a2,-1
    80000f58:	00d05963          	blez	a3,80000f6a <strncpy+0x1e>
    80000f5c:	0785                	addi	a5,a5,1
    80000f5e:	0005c703          	lbu	a4,0(a1)
    80000f62:	fee78fa3          	sb	a4,-1(a5)
    80000f66:	0585                	addi	a1,a1,1
    80000f68:	f775                	bnez	a4,80000f54 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f6a:	873e                	mv	a4,a5
    80000f6c:	9fb5                	addw	a5,a5,a3
    80000f6e:	37fd                	addiw	a5,a5,-1
    80000f70:	00c05963          	blez	a2,80000f82 <strncpy+0x36>
    *s++ = 0;
    80000f74:	0705                	addi	a4,a4,1
    80000f76:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000f7a:	40e786bb          	subw	a3,a5,a4
    80000f7e:	fed04be3          	bgtz	a3,80000f74 <strncpy+0x28>
  return os;
}
    80000f82:	6422                	ld	s0,8(sp)
    80000f84:	0141                	addi	sp,sp,16
    80000f86:	8082                	ret

0000000080000f88 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f88:	1141                	addi	sp,sp,-16
    80000f8a:	e422                	sd	s0,8(sp)
    80000f8c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f8e:	02c05363          	blez	a2,80000fb4 <safestrcpy+0x2c>
    80000f92:	fff6069b          	addiw	a3,a2,-1
    80000f96:	1682                	slli	a3,a3,0x20
    80000f98:	9281                	srli	a3,a3,0x20
    80000f9a:	96ae                	add	a3,a3,a1
    80000f9c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f9e:	00d58963          	beq	a1,a3,80000fb0 <safestrcpy+0x28>
    80000fa2:	0585                	addi	a1,a1,1
    80000fa4:	0785                	addi	a5,a5,1
    80000fa6:	fff5c703          	lbu	a4,-1(a1)
    80000faa:	fee78fa3          	sb	a4,-1(a5)
    80000fae:	fb65                	bnez	a4,80000f9e <safestrcpy+0x16>
    ;
  *s = 0;
    80000fb0:	00078023          	sb	zero,0(a5)
  return os;
}
    80000fb4:	6422                	ld	s0,8(sp)
    80000fb6:	0141                	addi	sp,sp,16
    80000fb8:	8082                	ret

0000000080000fba <strlen>:

int
strlen(const char *s)
{
    80000fba:	1141                	addi	sp,sp,-16
    80000fbc:	e422                	sd	s0,8(sp)
    80000fbe:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000fc0:	00054783          	lbu	a5,0(a0)
    80000fc4:	cf91                	beqz	a5,80000fe0 <strlen+0x26>
    80000fc6:	0505                	addi	a0,a0,1
    80000fc8:	87aa                	mv	a5,a0
    80000fca:	86be                	mv	a3,a5
    80000fcc:	0785                	addi	a5,a5,1
    80000fce:	fff7c703          	lbu	a4,-1(a5)
    80000fd2:	ff65                	bnez	a4,80000fca <strlen+0x10>
    80000fd4:	40a6853b          	subw	a0,a3,a0
    80000fd8:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000fda:	6422                	ld	s0,8(sp)
    80000fdc:	0141                	addi	sp,sp,16
    80000fde:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fe0:	4501                	li	a0,0
    80000fe2:	bfe5                	j	80000fda <strlen+0x20>

0000000080000fe4 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fe4:	1141                	addi	sp,sp,-16
    80000fe6:	e406                	sd	ra,8(sp)
    80000fe8:	e022                	sd	s0,0(sp)
    80000fea:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fec:	00001097          	auipc	ra,0x1
    80000ff0:	cac080e7          	jalr	-852(ra) # 80001c98 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ff4:	00008717          	auipc	a4,0x8
    80000ff8:	a3470713          	addi	a4,a4,-1484 # 80008a28 <started>
  if(cpuid() == 0){
    80000ffc:	c139                	beqz	a0,80001042 <main+0x5e>
    while(started == 0)
    80000ffe:	431c                	lw	a5,0(a4)
    80001000:	2781                	sext.w	a5,a5
    80001002:	dff5                	beqz	a5,80000ffe <main+0x1a>
      ;
    __sync_synchronize();
    80001004:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001008:	00001097          	auipc	ra,0x1
    8000100c:	c90080e7          	jalr	-880(ra) # 80001c98 <cpuid>
    80001010:	85aa                	mv	a1,a0
    80001012:	00007517          	auipc	a0,0x7
    80001016:	0e650513          	addi	a0,a0,230 # 800080f8 <digits+0xa8>
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	57e080e7          	jalr	1406(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    80001022:	00000097          	auipc	ra,0x0
    80001026:	0d8080e7          	jalr	216(ra) # 800010fa <kvminithart>
    trapinithart();   // install kernel trap vector
    8000102a:	00002097          	auipc	ra,0x2
    8000102e:	ada080e7          	jalr	-1318(ra) # 80002b04 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001032:	00005097          	auipc	ra,0x5
    80001036:	1ce080e7          	jalr	462(ra) # 80006200 <plicinithart>
  }

  scheduler();        
    8000103a:	00001097          	auipc	ra,0x1
    8000103e:	2d0080e7          	jalr	720(ra) # 8000230a <scheduler>
    consoleinit();
    80001042:	fffff097          	auipc	ra,0xfffff
    80001046:	40a080e7          	jalr	1034(ra) # 8000044c <consoleinit>
    printfinit();
    8000104a:	fffff097          	auipc	ra,0xfffff
    8000104e:	72e080e7          	jalr	1838(ra) # 80000778 <printfinit>
    printf("\n");
    80001052:	00007517          	auipc	a0,0x7
    80001056:	03650513          	addi	a0,a0,54 # 80008088 <digits+0x38>
    8000105a:	fffff097          	auipc	ra,0xfffff
    8000105e:	53e080e7          	jalr	1342(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    80001062:	00007517          	auipc	a0,0x7
    80001066:	07e50513          	addi	a0,a0,126 # 800080e0 <digits+0x90>
    8000106a:	fffff097          	auipc	ra,0xfffff
    8000106e:	52e080e7          	jalr	1326(ra) # 80000598 <printf>
    printf("\n");
    80001072:	00007517          	auipc	a0,0x7
    80001076:	01650513          	addi	a0,a0,22 # 80008088 <digits+0x38>
    8000107a:	fffff097          	auipc	ra,0xfffff
    8000107e:	51e080e7          	jalr	1310(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80001082:	00000097          	auipc	ra,0x0
    80001086:	b3a080e7          	jalr	-1222(ra) # 80000bbc <kinit>
    kvminit();       // create kernel page table
    8000108a:	00000097          	auipc	ra,0x0
    8000108e:	326080e7          	jalr	806(ra) # 800013b0 <kvminit>
    kvminithart();   // turn on paging
    80001092:	00000097          	auipc	ra,0x0
    80001096:	068080e7          	jalr	104(ra) # 800010fa <kvminithart>
    procinit();      // process table
    8000109a:	00001097          	auipc	ra,0x1
    8000109e:	b26080e7          	jalr	-1242(ra) # 80001bc0 <procinit>
    trapinit();      // trap vectors
    800010a2:	00002097          	auipc	ra,0x2
    800010a6:	a3a080e7          	jalr	-1478(ra) # 80002adc <trapinit>
    trapinithart();  // install kernel trap vector
    800010aa:	00002097          	auipc	ra,0x2
    800010ae:	a5a080e7          	jalr	-1446(ra) # 80002b04 <trapinithart>
    plicinit();      // set up interrupt controller
    800010b2:	00005097          	auipc	ra,0x5
    800010b6:	138080e7          	jalr	312(ra) # 800061ea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800010ba:	00005097          	auipc	ra,0x5
    800010be:	146080e7          	jalr	326(ra) # 80006200 <plicinithart>
    binit();         // buffer cache
    800010c2:	00002097          	auipc	ra,0x2
    800010c6:	33a080e7          	jalr	826(ra) # 800033fc <binit>
    iinit();         // inode table
    800010ca:	00003097          	auipc	ra,0x3
    800010ce:	9d8080e7          	jalr	-1576(ra) # 80003aa2 <iinit>
    fileinit();      // file table
    800010d2:	00004097          	auipc	ra,0x4
    800010d6:	94e080e7          	jalr	-1714(ra) # 80004a20 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010da:	00005097          	auipc	ra,0x5
    800010de:	22e080e7          	jalr	558(ra) # 80006308 <virtio_disk_init>
    userinit();      // first user process
    800010e2:	00001097          	auipc	ra,0x1
    800010e6:	eba080e7          	jalr	-326(ra) # 80001f9c <userinit>
    __sync_synchronize();
    800010ea:	0ff0000f          	fence
    started = 1;
    800010ee:	4785                	li	a5,1
    800010f0:	00008717          	auipc	a4,0x8
    800010f4:	92f72c23          	sw	a5,-1736(a4) # 80008a28 <started>
    800010f8:	b789                	j	8000103a <main+0x56>

00000000800010fa <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010fa:	1141                	addi	sp,sp,-16
    800010fc:	e422                	sd	s0,8(sp)
    800010fe:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001100:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001104:	00008797          	auipc	a5,0x8
    80001108:	92c7b783          	ld	a5,-1748(a5) # 80008a30 <kernel_pagetable>
    8000110c:	83b1                	srli	a5,a5,0xc
    8000110e:	577d                	li	a4,-1
    80001110:	177e                	slli	a4,a4,0x3f
    80001112:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001114:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001118:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000111c:	6422                	ld	s0,8(sp)
    8000111e:	0141                	addi	sp,sp,16
    80001120:	8082                	ret

0000000080001122 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001122:	7139                	addi	sp,sp,-64
    80001124:	fc06                	sd	ra,56(sp)
    80001126:	f822                	sd	s0,48(sp)
    80001128:	f426                	sd	s1,40(sp)
    8000112a:	f04a                	sd	s2,32(sp)
    8000112c:	ec4e                	sd	s3,24(sp)
    8000112e:	e852                	sd	s4,16(sp)
    80001130:	e456                	sd	s5,8(sp)
    80001132:	e05a                	sd	s6,0(sp)
    80001134:	0080                	addi	s0,sp,64
    80001136:	84aa                	mv	s1,a0
    80001138:	89ae                	mv	s3,a1
    8000113a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000113c:	57fd                	li	a5,-1
    8000113e:	83e9                	srli	a5,a5,0x1a
    80001140:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001142:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001144:	04b7f263          	bgeu	a5,a1,80001188 <walk+0x66>
    panic("walk");
    80001148:	00007517          	auipc	a0,0x7
    8000114c:	fc850513          	addi	a0,a0,-56 # 80008110 <digits+0xc0>
    80001150:	fffff097          	auipc	ra,0xfffff
    80001154:	3ec080e7          	jalr	1004(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001158:	060a8663          	beqz	s5,800011c4 <walk+0xa2>
    8000115c:	00000097          	auipc	ra,0x0
    80001160:	aac080e7          	jalr	-1364(ra) # 80000c08 <kalloc>
    80001164:	84aa                	mv	s1,a0
    80001166:	c529                	beqz	a0,800011b0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001168:	6605                	lui	a2,0x1
    8000116a:	4581                	li	a1,0
    8000116c:	00000097          	auipc	ra,0x0
    80001170:	cd4080e7          	jalr	-812(ra) # 80000e40 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001174:	00c4d793          	srli	a5,s1,0xc
    80001178:	07aa                	slli	a5,a5,0xa
    8000117a:	0017e793          	ori	a5,a5,1
    8000117e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001182:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7fdbd137>
    80001184:	036a0063          	beq	s4,s6,800011a4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001188:	0149d933          	srl	s2,s3,s4
    8000118c:	1ff97913          	andi	s2,s2,511
    80001190:	090e                	slli	s2,s2,0x3
    80001192:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001194:	00093483          	ld	s1,0(s2)
    80001198:	0014f793          	andi	a5,s1,1
    8000119c:	dfd5                	beqz	a5,80001158 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000119e:	80a9                	srli	s1,s1,0xa
    800011a0:	04b2                	slli	s1,s1,0xc
    800011a2:	b7c5                	j	80001182 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800011a4:	00c9d513          	srli	a0,s3,0xc
    800011a8:	1ff57513          	andi	a0,a0,511
    800011ac:	050e                	slli	a0,a0,0x3
    800011ae:	9526                	add	a0,a0,s1
}
    800011b0:	70e2                	ld	ra,56(sp)
    800011b2:	7442                	ld	s0,48(sp)
    800011b4:	74a2                	ld	s1,40(sp)
    800011b6:	7902                	ld	s2,32(sp)
    800011b8:	69e2                	ld	s3,24(sp)
    800011ba:	6a42                	ld	s4,16(sp)
    800011bc:	6aa2                	ld	s5,8(sp)
    800011be:	6b02                	ld	s6,0(sp)
    800011c0:	6121                	addi	sp,sp,64
    800011c2:	8082                	ret
        return 0;
    800011c4:	4501                	li	a0,0
    800011c6:	b7ed                	j	800011b0 <walk+0x8e>

00000000800011c8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011c8:	57fd                	li	a5,-1
    800011ca:	83e9                	srli	a5,a5,0x1a
    800011cc:	00b7f463          	bgeu	a5,a1,800011d4 <walkaddr+0xc>
    return 0;
    800011d0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011d2:	8082                	ret
{
    800011d4:	1141                	addi	sp,sp,-16
    800011d6:	e406                	sd	ra,8(sp)
    800011d8:	e022                	sd	s0,0(sp)
    800011da:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011dc:	4601                	li	a2,0
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f44080e7          	jalr	-188(ra) # 80001122 <walk>
  if(pte == 0)
    800011e6:	c105                	beqz	a0,80001206 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011e8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011ea:	0117f693          	andi	a3,a5,17
    800011ee:	4745                	li	a4,17
    return 0;
    800011f0:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011f2:	00e68663          	beq	a3,a4,800011fe <walkaddr+0x36>
}
    800011f6:	60a2                	ld	ra,8(sp)
    800011f8:	6402                	ld	s0,0(sp)
    800011fa:	0141                	addi	sp,sp,16
    800011fc:	8082                	ret
  pa = PTE2PA(*pte);
    800011fe:	83a9                	srli	a5,a5,0xa
    80001200:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001204:	bfcd                	j	800011f6 <walkaddr+0x2e>
    return 0;
    80001206:	4501                	li	a0,0
    80001208:	b7fd                	j	800011f6 <walkaddr+0x2e>

000000008000120a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000120a:	715d                	addi	sp,sp,-80
    8000120c:	e486                	sd	ra,72(sp)
    8000120e:	e0a2                	sd	s0,64(sp)
    80001210:	fc26                	sd	s1,56(sp)
    80001212:	f84a                	sd	s2,48(sp)
    80001214:	f44e                	sd	s3,40(sp)
    80001216:	f052                	sd	s4,32(sp)
    80001218:	ec56                	sd	s5,24(sp)
    8000121a:	e85a                	sd	s6,16(sp)
    8000121c:	e45e                	sd	s7,8(sp)
    8000121e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001220:	c639                	beqz	a2,8000126e <mappages+0x64>
    80001222:	8aaa                	mv	s5,a0
    80001224:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001226:	777d                	lui	a4,0xfffff
    80001228:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000122c:	fff58993          	addi	s3,a1,-1
    80001230:	99b2                	add	s3,s3,a2
    80001232:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001236:	893e                	mv	s2,a5
    80001238:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000123c:	6b85                	lui	s7,0x1
    8000123e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001242:	4605                	li	a2,1
    80001244:	85ca                	mv	a1,s2
    80001246:	8556                	mv	a0,s5
    80001248:	00000097          	auipc	ra,0x0
    8000124c:	eda080e7          	jalr	-294(ra) # 80001122 <walk>
    80001250:	cd1d                	beqz	a0,8000128e <mappages+0x84>
    if(*pte & PTE_V)
    80001252:	611c                	ld	a5,0(a0)
    80001254:	8b85                	andi	a5,a5,1
    80001256:	e785                	bnez	a5,8000127e <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001258:	80b1                	srli	s1,s1,0xc
    8000125a:	04aa                	slli	s1,s1,0xa
    8000125c:	0164e4b3          	or	s1,s1,s6
    80001260:	0014e493          	ori	s1,s1,1
    80001264:	e104                	sd	s1,0(a0)
    if(a == last)
    80001266:	05390063          	beq	s2,s3,800012a6 <mappages+0x9c>
    a += PGSIZE;
    8000126a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000126c:	bfc9                	j	8000123e <mappages+0x34>
    panic("mappages: size");
    8000126e:	00007517          	auipc	a0,0x7
    80001272:	eaa50513          	addi	a0,a0,-342 # 80008118 <digits+0xc8>
    80001276:	fffff097          	auipc	ra,0xfffff
    8000127a:	2c6080e7          	jalr	710(ra) # 8000053c <panic>
      panic("mappages: remap");
    8000127e:	00007517          	auipc	a0,0x7
    80001282:	eaa50513          	addi	a0,a0,-342 # 80008128 <digits+0xd8>
    80001286:	fffff097          	auipc	ra,0xfffff
    8000128a:	2b6080e7          	jalr	694(ra) # 8000053c <panic>
      return -1;
    8000128e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001290:	60a6                	ld	ra,72(sp)
    80001292:	6406                	ld	s0,64(sp)
    80001294:	74e2                	ld	s1,56(sp)
    80001296:	7942                	ld	s2,48(sp)
    80001298:	79a2                	ld	s3,40(sp)
    8000129a:	7a02                	ld	s4,32(sp)
    8000129c:	6ae2                	ld	s5,24(sp)
    8000129e:	6b42                	ld	s6,16(sp)
    800012a0:	6ba2                	ld	s7,8(sp)
    800012a2:	6161                	addi	sp,sp,80
    800012a4:	8082                	ret
  return 0;
    800012a6:	4501                	li	a0,0
    800012a8:	b7e5                	j	80001290 <mappages+0x86>

00000000800012aa <kvmmap>:
{
    800012aa:	1141                	addi	sp,sp,-16
    800012ac:	e406                	sd	ra,8(sp)
    800012ae:	e022                	sd	s0,0(sp)
    800012b0:	0800                	addi	s0,sp,16
    800012b2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800012b4:	86b2                	mv	a3,a2
    800012b6:	863e                	mv	a2,a5
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f52080e7          	jalr	-174(ra) # 8000120a <mappages>
    800012c0:	e509                	bnez	a0,800012ca <kvmmap+0x20>
}
    800012c2:	60a2                	ld	ra,8(sp)
    800012c4:	6402                	ld	s0,0(sp)
    800012c6:	0141                	addi	sp,sp,16
    800012c8:	8082                	ret
    panic("kvmmap");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e6e50513          	addi	a0,a0,-402 # 80008138 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26a080e7          	jalr	618(ra) # 8000053c <panic>

00000000800012da <kvmmake>:
{
    800012da:	1101                	addi	sp,sp,-32
    800012dc:	ec06                	sd	ra,24(sp)
    800012de:	e822                	sd	s0,16(sp)
    800012e0:	e426                	sd	s1,8(sp)
    800012e2:	e04a                	sd	s2,0(sp)
    800012e4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012e6:	00000097          	auipc	ra,0x0
    800012ea:	922080e7          	jalr	-1758(ra) # 80000c08 <kalloc>
    800012ee:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012f0:	6605                	lui	a2,0x1
    800012f2:	4581                	li	a1,0
    800012f4:	00000097          	auipc	ra,0x0
    800012f8:	b4c080e7          	jalr	-1204(ra) # 80000e40 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012fc:	4719                	li	a4,6
    800012fe:	6685                	lui	a3,0x1
    80001300:	10000637          	lui	a2,0x10000
    80001304:	100005b7          	lui	a1,0x10000
    80001308:	8526                	mv	a0,s1
    8000130a:	00000097          	auipc	ra,0x0
    8000130e:	fa0080e7          	jalr	-96(ra) # 800012aa <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001312:	4719                	li	a4,6
    80001314:	6685                	lui	a3,0x1
    80001316:	10001637          	lui	a2,0x10001
    8000131a:	100015b7          	lui	a1,0x10001
    8000131e:	8526                	mv	a0,s1
    80001320:	00000097          	auipc	ra,0x0
    80001324:	f8a080e7          	jalr	-118(ra) # 800012aa <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001328:	4719                	li	a4,6
    8000132a:	004006b7          	lui	a3,0x400
    8000132e:	0c000637          	lui	a2,0xc000
    80001332:	0c0005b7          	lui	a1,0xc000
    80001336:	8526                	mv	a0,s1
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	f72080e7          	jalr	-142(ra) # 800012aa <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001340:	00007917          	auipc	s2,0x7
    80001344:	cc090913          	addi	s2,s2,-832 # 80008000 <etext>
    80001348:	4729                	li	a4,10
    8000134a:	80007697          	auipc	a3,0x80007
    8000134e:	cb668693          	addi	a3,a3,-842 # 8000 <_entry-0x7fff8000>
    80001352:	4605                	li	a2,1
    80001354:	067e                	slli	a2,a2,0x1f
    80001356:	85b2                	mv	a1,a2
    80001358:	8526                	mv	a0,s1
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f50080e7          	jalr	-176(ra) # 800012aa <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001362:	4719                	li	a4,6
    80001364:	46c5                	li	a3,17
    80001366:	06ee                	slli	a3,a3,0x1b
    80001368:	412686b3          	sub	a3,a3,s2
    8000136c:	864a                	mv	a2,s2
    8000136e:	85ca                	mv	a1,s2
    80001370:	8526                	mv	a0,s1
    80001372:	00000097          	auipc	ra,0x0
    80001376:	f38080e7          	jalr	-200(ra) # 800012aa <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000137a:	4729                	li	a4,10
    8000137c:	6685                	lui	a3,0x1
    8000137e:	00006617          	auipc	a2,0x6
    80001382:	c8260613          	addi	a2,a2,-894 # 80007000 <_trampoline>
    80001386:	040005b7          	lui	a1,0x4000
    8000138a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000138c:	05b2                	slli	a1,a1,0xc
    8000138e:	8526                	mv	a0,s1
    80001390:	00000097          	auipc	ra,0x0
    80001394:	f1a080e7          	jalr	-230(ra) # 800012aa <kvmmap>
  proc_mapstacks(kpgtbl);
    80001398:	8526                	mv	a0,s1
    8000139a:	00000097          	auipc	ra,0x0
    8000139e:	790080e7          	jalr	1936(ra) # 80001b2a <proc_mapstacks>
}
    800013a2:	8526                	mv	a0,s1
    800013a4:	60e2                	ld	ra,24(sp)
    800013a6:	6442                	ld	s0,16(sp)
    800013a8:	64a2                	ld	s1,8(sp)
    800013aa:	6902                	ld	s2,0(sp)
    800013ac:	6105                	addi	sp,sp,32
    800013ae:	8082                	ret

00000000800013b0 <kvminit>:
{
    800013b0:	1141                	addi	sp,sp,-16
    800013b2:	e406                	sd	ra,8(sp)
    800013b4:	e022                	sd	s0,0(sp)
    800013b6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800013b8:	00000097          	auipc	ra,0x0
    800013bc:	f22080e7          	jalr	-222(ra) # 800012da <kvmmake>
    800013c0:	00007797          	auipc	a5,0x7
    800013c4:	66a7b823          	sd	a0,1648(a5) # 80008a30 <kernel_pagetable>
}
    800013c8:	60a2                	ld	ra,8(sp)
    800013ca:	6402                	ld	s0,0(sp)
    800013cc:	0141                	addi	sp,sp,16
    800013ce:	8082                	ret

00000000800013d0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800013d0:	715d                	addi	sp,sp,-80
    800013d2:	e486                	sd	ra,72(sp)
    800013d4:	e0a2                	sd	s0,64(sp)
    800013d6:	fc26                	sd	s1,56(sp)
    800013d8:	f84a                	sd	s2,48(sp)
    800013da:	f44e                	sd	s3,40(sp)
    800013dc:	f052                	sd	s4,32(sp)
    800013de:	ec56                	sd	s5,24(sp)
    800013e0:	e85a                	sd	s6,16(sp)
    800013e2:	e45e                	sd	s7,8(sp)
    800013e4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013e6:	03459793          	slli	a5,a1,0x34
    800013ea:	e795                	bnez	a5,80001416 <uvmunmap+0x46>
    800013ec:	8a2a                	mv	s4,a0
    800013ee:	892e                	mv	s2,a1
    800013f0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013f2:	0632                	slli	a2,a2,0xc
    800013f4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013f8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013fa:	6b05                	lui	s6,0x1
    800013fc:	0735e263          	bltu	a1,s3,80001460 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001400:	60a6                	ld	ra,72(sp)
    80001402:	6406                	ld	s0,64(sp)
    80001404:	74e2                	ld	s1,56(sp)
    80001406:	7942                	ld	s2,48(sp)
    80001408:	79a2                	ld	s3,40(sp)
    8000140a:	7a02                	ld	s4,32(sp)
    8000140c:	6ae2                	ld	s5,24(sp)
    8000140e:	6b42                	ld	s6,16(sp)
    80001410:	6ba2                	ld	s7,8(sp)
    80001412:	6161                	addi	sp,sp,80
    80001414:	8082                	ret
    panic("uvmunmap: not aligned");
    80001416:	00007517          	auipc	a0,0x7
    8000141a:	d2a50513          	addi	a0,a0,-726 # 80008140 <digits+0xf0>
    8000141e:	fffff097          	auipc	ra,0xfffff
    80001422:	11e080e7          	jalr	286(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    80001426:	00007517          	auipc	a0,0x7
    8000142a:	d3250513          	addi	a0,a0,-718 # 80008158 <digits+0x108>
    8000142e:	fffff097          	auipc	ra,0xfffff
    80001432:	10e080e7          	jalr	270(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    80001436:	00007517          	auipc	a0,0x7
    8000143a:	d3250513          	addi	a0,a0,-718 # 80008168 <digits+0x118>
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	0fe080e7          	jalr	254(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    80001446:	00007517          	auipc	a0,0x7
    8000144a:	d3a50513          	addi	a0,a0,-710 # 80008180 <digits+0x130>
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	0ee080e7          	jalr	238(ra) # 8000053c <panic>
    *pte = 0;
    80001456:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000145a:	995a                	add	s2,s2,s6
    8000145c:	fb3972e3          	bgeu	s2,s3,80001400 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001460:	4601                	li	a2,0
    80001462:	85ca                	mv	a1,s2
    80001464:	8552                	mv	a0,s4
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	cbc080e7          	jalr	-836(ra) # 80001122 <walk>
    8000146e:	84aa                	mv	s1,a0
    80001470:	d95d                	beqz	a0,80001426 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001472:	6108                	ld	a0,0(a0)
    80001474:	00157793          	andi	a5,a0,1
    80001478:	dfdd                	beqz	a5,80001436 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000147a:	3ff57793          	andi	a5,a0,1023
    8000147e:	fd7784e3          	beq	a5,s7,80001446 <uvmunmap+0x76>
    if(do_free){
    80001482:	fc0a8ae3          	beqz	s5,80001456 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001486:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001488:	0532                	slli	a0,a0,0xc
    8000148a:	fffff097          	auipc	ra,0xfffff
    8000148e:	606080e7          	jalr	1542(ra) # 80000a90 <kfree>
    80001492:	b7d1                	j	80001456 <uvmunmap+0x86>

0000000080001494 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001494:	1101                	addi	sp,sp,-32
    80001496:	ec06                	sd	ra,24(sp)
    80001498:	e822                	sd	s0,16(sp)
    8000149a:	e426                	sd	s1,8(sp)
    8000149c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000149e:	fffff097          	auipc	ra,0xfffff
    800014a2:	76a080e7          	jalr	1898(ra) # 80000c08 <kalloc>
    800014a6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800014a8:	c519                	beqz	a0,800014b6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800014aa:	6605                	lui	a2,0x1
    800014ac:	4581                	li	a1,0
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	992080e7          	jalr	-1646(ra) # 80000e40 <memset>
  return pagetable;
}
    800014b6:	8526                	mv	a0,s1
    800014b8:	60e2                	ld	ra,24(sp)
    800014ba:	6442                	ld	s0,16(sp)
    800014bc:	64a2                	ld	s1,8(sp)
    800014be:	6105                	addi	sp,sp,32
    800014c0:	8082                	ret

00000000800014c2 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800014d2:	6785                	lui	a5,0x1
    800014d4:	04f67863          	bgeu	a2,a5,80001524 <uvmfirst+0x62>
    800014d8:	8a2a                	mv	s4,a0
    800014da:	89ae                	mv	s3,a1
    800014dc:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800014de:	fffff097          	auipc	ra,0xfffff
    800014e2:	72a080e7          	jalr	1834(ra) # 80000c08 <kalloc>
    800014e6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014e8:	6605                	lui	a2,0x1
    800014ea:	4581                	li	a1,0
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	954080e7          	jalr	-1708(ra) # 80000e40 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014f4:	4779                	li	a4,30
    800014f6:	86ca                	mv	a3,s2
    800014f8:	6605                	lui	a2,0x1
    800014fa:	4581                	li	a1,0
    800014fc:	8552                	mv	a0,s4
    800014fe:	00000097          	auipc	ra,0x0
    80001502:	d0c080e7          	jalr	-756(ra) # 8000120a <mappages>
  memmove(mem, src, sz);
    80001506:	8626                	mv	a2,s1
    80001508:	85ce                	mv	a1,s3
    8000150a:	854a                	mv	a0,s2
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	990080e7          	jalr	-1648(ra) # 80000e9c <memmove>
}
    80001514:	70a2                	ld	ra,40(sp)
    80001516:	7402                	ld	s0,32(sp)
    80001518:	64e2                	ld	s1,24(sp)
    8000151a:	6942                	ld	s2,16(sp)
    8000151c:	69a2                	ld	s3,8(sp)
    8000151e:	6a02                	ld	s4,0(sp)
    80001520:	6145                	addi	sp,sp,48
    80001522:	8082                	ret
    panic("uvmfirst: more than a page");
    80001524:	00007517          	auipc	a0,0x7
    80001528:	c7450513          	addi	a0,a0,-908 # 80008198 <digits+0x148>
    8000152c:	fffff097          	auipc	ra,0xfffff
    80001530:	010080e7          	jalr	16(ra) # 8000053c <panic>

0000000080001534 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001534:	1101                	addi	sp,sp,-32
    80001536:	ec06                	sd	ra,24(sp)
    80001538:	e822                	sd	s0,16(sp)
    8000153a:	e426                	sd	s1,8(sp)
    8000153c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000153e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001540:	00b67d63          	bgeu	a2,a1,8000155a <uvmdealloc+0x26>
    80001544:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001546:	6785                	lui	a5,0x1
    80001548:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000154a:	00f60733          	add	a4,a2,a5
    8000154e:	76fd                	lui	a3,0xfffff
    80001550:	8f75                	and	a4,a4,a3
    80001552:	97ae                	add	a5,a5,a1
    80001554:	8ff5                	and	a5,a5,a3
    80001556:	00f76863          	bltu	a4,a5,80001566 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000155a:	8526                	mv	a0,s1
    8000155c:	60e2                	ld	ra,24(sp)
    8000155e:	6442                	ld	s0,16(sp)
    80001560:	64a2                	ld	s1,8(sp)
    80001562:	6105                	addi	sp,sp,32
    80001564:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001566:	8f99                	sub	a5,a5,a4
    80001568:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000156a:	4685                	li	a3,1
    8000156c:	0007861b          	sext.w	a2,a5
    80001570:	85ba                	mv	a1,a4
    80001572:	00000097          	auipc	ra,0x0
    80001576:	e5e080e7          	jalr	-418(ra) # 800013d0 <uvmunmap>
    8000157a:	b7c5                	j	8000155a <uvmdealloc+0x26>

000000008000157c <uvmalloc>:
  if(newsz < oldsz)
    8000157c:	0ab66563          	bltu	a2,a1,80001626 <uvmalloc+0xaa>
{
    80001580:	7139                	addi	sp,sp,-64
    80001582:	fc06                	sd	ra,56(sp)
    80001584:	f822                	sd	s0,48(sp)
    80001586:	f426                	sd	s1,40(sp)
    80001588:	f04a                	sd	s2,32(sp)
    8000158a:	ec4e                	sd	s3,24(sp)
    8000158c:	e852                	sd	s4,16(sp)
    8000158e:	e456                	sd	s5,8(sp)
    80001590:	e05a                	sd	s6,0(sp)
    80001592:	0080                	addi	s0,sp,64
    80001594:	8aaa                	mv	s5,a0
    80001596:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001598:	6785                	lui	a5,0x1
    8000159a:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000159c:	95be                	add	a1,a1,a5
    8000159e:	77fd                	lui	a5,0xfffff
    800015a0:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a4:	08c9f363          	bgeu	s3,a2,8000162a <uvmalloc+0xae>
    800015a8:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015aa:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	65a080e7          	jalr	1626(ra) # 80000c08 <kalloc>
    800015b6:	84aa                	mv	s1,a0
    if(mem == 0){
    800015b8:	c51d                	beqz	a0,800015e6 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    800015ba:	6605                	lui	a2,0x1
    800015bc:	4581                	li	a1,0
    800015be:	00000097          	auipc	ra,0x0
    800015c2:	882080e7          	jalr	-1918(ra) # 80000e40 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800015c6:	875a                	mv	a4,s6
    800015c8:	86a6                	mv	a3,s1
    800015ca:	6605                	lui	a2,0x1
    800015cc:	85ca                	mv	a1,s2
    800015ce:	8556                	mv	a0,s5
    800015d0:	00000097          	auipc	ra,0x0
    800015d4:	c3a080e7          	jalr	-966(ra) # 8000120a <mappages>
    800015d8:	e90d                	bnez	a0,8000160a <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015da:	6785                	lui	a5,0x1
    800015dc:	993e                	add	s2,s2,a5
    800015de:	fd4968e3          	bltu	s2,s4,800015ae <uvmalloc+0x32>
  return newsz;
    800015e2:	8552                	mv	a0,s4
    800015e4:	a809                	j	800015f6 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800015e6:	864e                	mv	a2,s3
    800015e8:	85ca                	mv	a1,s2
    800015ea:	8556                	mv	a0,s5
    800015ec:	00000097          	auipc	ra,0x0
    800015f0:	f48080e7          	jalr	-184(ra) # 80001534 <uvmdealloc>
      return 0;
    800015f4:	4501                	li	a0,0
}
    800015f6:	70e2                	ld	ra,56(sp)
    800015f8:	7442                	ld	s0,48(sp)
    800015fa:	74a2                	ld	s1,40(sp)
    800015fc:	7902                	ld	s2,32(sp)
    800015fe:	69e2                	ld	s3,24(sp)
    80001600:	6a42                	ld	s4,16(sp)
    80001602:	6aa2                	ld	s5,8(sp)
    80001604:	6b02                	ld	s6,0(sp)
    80001606:	6121                	addi	sp,sp,64
    80001608:	8082                	ret
      kfree(mem);
    8000160a:	8526                	mv	a0,s1
    8000160c:	fffff097          	auipc	ra,0xfffff
    80001610:	484080e7          	jalr	1156(ra) # 80000a90 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001614:	864e                	mv	a2,s3
    80001616:	85ca                	mv	a1,s2
    80001618:	8556                	mv	a0,s5
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	f1a080e7          	jalr	-230(ra) # 80001534 <uvmdealloc>
      return 0;
    80001622:	4501                	li	a0,0
    80001624:	bfc9                	j	800015f6 <uvmalloc+0x7a>
    return oldsz;
    80001626:	852e                	mv	a0,a1
}
    80001628:	8082                	ret
  return newsz;
    8000162a:	8532                	mv	a0,a2
    8000162c:	b7e9                	j	800015f6 <uvmalloc+0x7a>

000000008000162e <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000162e:	7179                	addi	sp,sp,-48
    80001630:	f406                	sd	ra,40(sp)
    80001632:	f022                	sd	s0,32(sp)
    80001634:	ec26                	sd	s1,24(sp)
    80001636:	e84a                	sd	s2,16(sp)
    80001638:	e44e                	sd	s3,8(sp)
    8000163a:	e052                	sd	s4,0(sp)
    8000163c:	1800                	addi	s0,sp,48
    8000163e:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001640:	84aa                	mv	s1,a0
    80001642:	6905                	lui	s2,0x1
    80001644:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001646:	4985                	li	s3,1
    80001648:	a829                	j	80001662 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000164a:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000164c:	00c79513          	slli	a0,a5,0xc
    80001650:	00000097          	auipc	ra,0x0
    80001654:	fde080e7          	jalr	-34(ra) # 8000162e <freewalk>
      pagetable[i] = 0;
    80001658:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000165c:	04a1                	addi	s1,s1,8
    8000165e:	03248163          	beq	s1,s2,80001680 <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001662:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001664:	00f7f713          	andi	a4,a5,15
    80001668:	ff3701e3          	beq	a4,s3,8000164a <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000166c:	8b85                	andi	a5,a5,1
    8000166e:	d7fd                	beqz	a5,8000165c <freewalk+0x2e>
      panic("freewalk: leaf");
    80001670:	00007517          	auipc	a0,0x7
    80001674:	b4850513          	addi	a0,a0,-1208 # 800081b8 <digits+0x168>
    80001678:	fffff097          	auipc	ra,0xfffff
    8000167c:	ec4080e7          	jalr	-316(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001680:	8552                	mv	a0,s4
    80001682:	fffff097          	auipc	ra,0xfffff
    80001686:	40e080e7          	jalr	1038(ra) # 80000a90 <kfree>
}
    8000168a:	70a2                	ld	ra,40(sp)
    8000168c:	7402                	ld	s0,32(sp)
    8000168e:	64e2                	ld	s1,24(sp)
    80001690:	6942                	ld	s2,16(sp)
    80001692:	69a2                	ld	s3,8(sp)
    80001694:	6a02                	ld	s4,0(sp)
    80001696:	6145                	addi	sp,sp,48
    80001698:	8082                	ret

000000008000169a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000169a:	1101                	addi	sp,sp,-32
    8000169c:	ec06                	sd	ra,24(sp)
    8000169e:	e822                	sd	s0,16(sp)
    800016a0:	e426                	sd	s1,8(sp)
    800016a2:	1000                	addi	s0,sp,32
    800016a4:	84aa                	mv	s1,a0
  if(sz > 0)
    800016a6:	e999                	bnez	a1,800016bc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800016a8:	8526                	mv	a0,s1
    800016aa:	00000097          	auipc	ra,0x0
    800016ae:	f84080e7          	jalr	-124(ra) # 8000162e <freewalk>
}
    800016b2:	60e2                	ld	ra,24(sp)
    800016b4:	6442                	ld	s0,16(sp)
    800016b6:	64a2                	ld	s1,8(sp)
    800016b8:	6105                	addi	sp,sp,32
    800016ba:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800016bc:	6785                	lui	a5,0x1
    800016be:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800016c0:	95be                	add	a1,a1,a5
    800016c2:	4685                	li	a3,1
    800016c4:	00c5d613          	srli	a2,a1,0xc
    800016c8:	4581                	li	a1,0
    800016ca:	00000097          	auipc	ra,0x0
    800016ce:	d06080e7          	jalr	-762(ra) # 800013d0 <uvmunmap>
    800016d2:	bfd9                	j	800016a8 <uvmfree+0xe>

00000000800016d4 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800016d4:	c679                	beqz	a2,800017a2 <uvmcopy+0xce>
{
    800016d6:	715d                	addi	sp,sp,-80
    800016d8:	e486                	sd	ra,72(sp)
    800016da:	e0a2                	sd	s0,64(sp)
    800016dc:	fc26                	sd	s1,56(sp)
    800016de:	f84a                	sd	s2,48(sp)
    800016e0:	f44e                	sd	s3,40(sp)
    800016e2:	f052                	sd	s4,32(sp)
    800016e4:	ec56                	sd	s5,24(sp)
    800016e6:	e85a                	sd	s6,16(sp)
    800016e8:	e45e                	sd	s7,8(sp)
    800016ea:	0880                	addi	s0,sp,80
    800016ec:	8b2a                	mv	s6,a0
    800016ee:	8aae                	mv	s5,a1
    800016f0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016f2:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800016f4:	4601                	li	a2,0
    800016f6:	85ce                	mv	a1,s3
    800016f8:	855a                	mv	a0,s6
    800016fa:	00000097          	auipc	ra,0x0
    800016fe:	a28080e7          	jalr	-1496(ra) # 80001122 <walk>
    80001702:	c531                	beqz	a0,8000174e <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001704:	6118                	ld	a4,0(a0)
    80001706:	00177793          	andi	a5,a4,1
    8000170a:	cbb1                	beqz	a5,8000175e <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000170c:	00a75593          	srli	a1,a4,0xa
    80001710:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001714:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001718:	fffff097          	auipc	ra,0xfffff
    8000171c:	4f0080e7          	jalr	1264(ra) # 80000c08 <kalloc>
    80001720:	892a                	mv	s2,a0
    80001722:	c939                	beqz	a0,80001778 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001724:	6605                	lui	a2,0x1
    80001726:	85de                	mv	a1,s7
    80001728:	fffff097          	auipc	ra,0xfffff
    8000172c:	774080e7          	jalr	1908(ra) # 80000e9c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001730:	8726                	mv	a4,s1
    80001732:	86ca                	mv	a3,s2
    80001734:	6605                	lui	a2,0x1
    80001736:	85ce                	mv	a1,s3
    80001738:	8556                	mv	a0,s5
    8000173a:	00000097          	auipc	ra,0x0
    8000173e:	ad0080e7          	jalr	-1328(ra) # 8000120a <mappages>
    80001742:	e515                	bnez	a0,8000176e <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001744:	6785                	lui	a5,0x1
    80001746:	99be                	add	s3,s3,a5
    80001748:	fb49e6e3          	bltu	s3,s4,800016f4 <uvmcopy+0x20>
    8000174c:	a081                	j	8000178c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000174e:	00007517          	auipc	a0,0x7
    80001752:	a7a50513          	addi	a0,a0,-1414 # 800081c8 <digits+0x178>
    80001756:	fffff097          	auipc	ra,0xfffff
    8000175a:	de6080e7          	jalr	-538(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    8000175e:	00007517          	auipc	a0,0x7
    80001762:	a8a50513          	addi	a0,a0,-1398 # 800081e8 <digits+0x198>
    80001766:	fffff097          	auipc	ra,0xfffff
    8000176a:	dd6080e7          	jalr	-554(ra) # 8000053c <panic>
      kfree(mem);
    8000176e:	854a                	mv	a0,s2
    80001770:	fffff097          	auipc	ra,0xfffff
    80001774:	320080e7          	jalr	800(ra) # 80000a90 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001778:	4685                	li	a3,1
    8000177a:	00c9d613          	srli	a2,s3,0xc
    8000177e:	4581                	li	a1,0
    80001780:	8556                	mv	a0,s5
    80001782:	00000097          	auipc	ra,0x0
    80001786:	c4e080e7          	jalr	-946(ra) # 800013d0 <uvmunmap>
  return -1;
    8000178a:	557d                	li	a0,-1
}
    8000178c:	60a6                	ld	ra,72(sp)
    8000178e:	6406                	ld	s0,64(sp)
    80001790:	74e2                	ld	s1,56(sp)
    80001792:	7942                	ld	s2,48(sp)
    80001794:	79a2                	ld	s3,40(sp)
    80001796:	7a02                	ld	s4,32(sp)
    80001798:	6ae2                	ld	s5,24(sp)
    8000179a:	6b42                	ld	s6,16(sp)
    8000179c:	6ba2                	ld	s7,8(sp)
    8000179e:	6161                	addi	sp,sp,80
    800017a0:	8082                	ret
  return 0;
    800017a2:	4501                	li	a0,0
}
    800017a4:	8082                	ret

00000000800017a6 <uvmshare>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  //struct spinlock lock;

  for(i = 0; i < sz; i += PGSIZE){
    800017a6:	ca55                	beqz	a2,8000185a <uvmshare+0xb4>
int uvmshare(pagetable_t old, pagetable_t new, uint64 sz) {
    800017a8:	7139                	addi	sp,sp,-64
    800017aa:	fc06                	sd	ra,56(sp)
    800017ac:	f822                	sd	s0,48(sp)
    800017ae:	f426                	sd	s1,40(sp)
    800017b0:	f04a                	sd	s2,32(sp)
    800017b2:	ec4e                	sd	s3,24(sp)
    800017b4:	e852                	sd	s4,16(sp)
    800017b6:	e456                	sd	s5,8(sp)
    800017b8:	e05a                	sd	s6,0(sp)
    800017ba:	0080                	addi	s0,sp,64
    800017bc:	8b2a                	mv	s6,a0
    800017be:	8aae                	mv	s5,a1
    800017c0:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800017c2:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    800017c4:	4601                	li	a2,0
    800017c6:	85ca                	mv	a1,s2
    800017c8:	855a                	mv	a0,s6
    800017ca:	00000097          	auipc	ra,0x0
    800017ce:	958080e7          	jalr	-1704(ra) # 80001122 <walk>
    800017d2:	c121                	beqz	a0,80001812 <uvmshare+0x6c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017d4:	6118                	ld	a4,0(a0)
    800017d6:	00177793          	andi	a5,a4,1
    800017da:	c7a1                	beqz	a5,80001822 <uvmshare+0x7c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017dc:	00a75993          	srli	s3,a4,0xa
    800017e0:	09b2                	slli	s3,s3,0xc
    // Remove write permission flag
    *pte = (*pte & (~PTE_W));
    800017e2:	ffb77493          	andi	s1,a4,-5
    800017e6:	e104                	sd	s1,0(a0)

    flags = PTE_FLAGS(*pte);

    // Increment the refcount
    increment_refcount(pa); 
    800017e8:	854e                	mv	a0,s3
    800017ea:	fffff097          	auipc	ra,0xfffff
    800017ee:	20c080e7          	jalr	524(ra) # 800009f6 <increment_refcount>

    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    800017f2:	3fb4f713          	andi	a4,s1,1019
    800017f6:	86ce                	mv	a3,s3
    800017f8:	6605                	lui	a2,0x1
    800017fa:	85ca                	mv	a1,s2
    800017fc:	8556                	mv	a0,s5
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	a0c080e7          	jalr	-1524(ra) # 8000120a <mappages>
    80001806:	e515                	bnez	a0,80001832 <uvmshare+0x8c>
  for(i = 0; i < sz; i += PGSIZE){
    80001808:	6785                	lui	a5,0x1
    8000180a:	993e                	add	s2,s2,a5
    8000180c:	fb496ce3          	bltu	s2,s4,800017c4 <uvmshare+0x1e>
    80001810:	a81d                	j	80001846 <uvmshare+0xa0>
      panic("uvmcopy: pte should exist");
    80001812:	00007517          	auipc	a0,0x7
    80001816:	9b650513          	addi	a0,a0,-1610 # 800081c8 <digits+0x178>
    8000181a:	fffff097          	auipc	ra,0xfffff
    8000181e:	d22080e7          	jalr	-734(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    80001822:	00007517          	auipc	a0,0x7
    80001826:	9c650513          	addi	a0,a0,-1594 # 800081e8 <digits+0x198>
    8000182a:	fffff097          	auipc	ra,0xfffff
    8000182e:	d12080e7          	jalr	-750(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001832:	4685                	li	a3,1
    80001834:	00c95613          	srli	a2,s2,0xc
    80001838:	4581                	li	a1,0
    8000183a:	8556                	mv	a0,s5
    8000183c:	00000097          	auipc	ra,0x0
    80001840:	b94080e7          	jalr	-1132(ra) # 800013d0 <uvmunmap>
  return -1;
    80001844:	557d                	li	a0,-1
}
    80001846:	70e2                	ld	ra,56(sp)
    80001848:	7442                	ld	s0,48(sp)
    8000184a:	74a2                	ld	s1,40(sp)
    8000184c:	7902                	ld	s2,32(sp)
    8000184e:	69e2                	ld	s3,24(sp)
    80001850:	6a42                	ld	s4,16(sp)
    80001852:	6aa2                	ld	s5,8(sp)
    80001854:	6b02                	ld	s6,0(sp)
    80001856:	6121                	addi	sp,sp,64
    80001858:	8082                	ret
  return 0;
    8000185a:	4501                	li	a0,0
}
    8000185c:	8082                	ret

000000008000185e <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000185e:	1141                	addi	sp,sp,-16
    80001860:	e406                	sd	ra,8(sp)
    80001862:	e022                	sd	s0,0(sp)
    80001864:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001866:	4601                	li	a2,0
    80001868:	00000097          	auipc	ra,0x0
    8000186c:	8ba080e7          	jalr	-1862(ra) # 80001122 <walk>
  if(pte == 0)
    80001870:	c901                	beqz	a0,80001880 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001872:	611c                	ld	a5,0(a0)
    80001874:	9bbd                	andi	a5,a5,-17
    80001876:	e11c                	sd	a5,0(a0)
}
    80001878:	60a2                	ld	ra,8(sp)
    8000187a:	6402                	ld	s0,0(sp)
    8000187c:	0141                	addi	sp,sp,16
    8000187e:	8082                	ret
    panic("uvmclear");
    80001880:	00007517          	auipc	a0,0x7
    80001884:	98850513          	addi	a0,a0,-1656 # 80008208 <digits+0x1b8>
    80001888:	fffff097          	auipc	ra,0xfffff
    8000188c:	cb4080e7          	jalr	-844(ra) # 8000053c <panic>

0000000080001890 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001890:	c6bd                	beqz	a3,800018fe <copyout+0x6e>
{
    80001892:	715d                	addi	sp,sp,-80
    80001894:	e486                	sd	ra,72(sp)
    80001896:	e0a2                	sd	s0,64(sp)
    80001898:	fc26                	sd	s1,56(sp)
    8000189a:	f84a                	sd	s2,48(sp)
    8000189c:	f44e                	sd	s3,40(sp)
    8000189e:	f052                	sd	s4,32(sp)
    800018a0:	ec56                	sd	s5,24(sp)
    800018a2:	e85a                	sd	s6,16(sp)
    800018a4:	e45e                	sd	s7,8(sp)
    800018a6:	e062                	sd	s8,0(sp)
    800018a8:	0880                	addi	s0,sp,80
    800018aa:	8b2a                	mv	s6,a0
    800018ac:	8c2e                	mv	s8,a1
    800018ae:	8a32                	mv	s4,a2
    800018b0:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018b2:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800018b4:	6a85                	lui	s5,0x1
    800018b6:	a015                	j	800018da <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018b8:	9562                	add	a0,a0,s8
    800018ba:	0004861b          	sext.w	a2,s1
    800018be:	85d2                	mv	a1,s4
    800018c0:	41250533          	sub	a0,a0,s2
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	5d8080e7          	jalr	1496(ra) # 80000e9c <memmove>

    len -= n;
    800018cc:	409989b3          	sub	s3,s3,s1
    src += n;
    800018d0:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800018d2:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800018d6:	02098263          	beqz	s3,800018fa <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800018da:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800018de:	85ca                	mv	a1,s2
    800018e0:	855a                	mv	a0,s6
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	8e6080e7          	jalr	-1818(ra) # 800011c8 <walkaddr>
    if(pa0 == 0)
    800018ea:	cd01                	beqz	a0,80001902 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800018ec:	418904b3          	sub	s1,s2,s8
    800018f0:	94d6                	add	s1,s1,s5
    800018f2:	fc99f3e3          	bgeu	s3,s1,800018b8 <copyout+0x28>
    800018f6:	84ce                	mv	s1,s3
    800018f8:	b7c1                	j	800018b8 <copyout+0x28>
  }
  return 0;
    800018fa:	4501                	li	a0,0
    800018fc:	a021                	j	80001904 <copyout+0x74>
    800018fe:	4501                	li	a0,0
}
    80001900:	8082                	ret
      return -1;
    80001902:	557d                	li	a0,-1
}
    80001904:	60a6                	ld	ra,72(sp)
    80001906:	6406                	ld	s0,64(sp)
    80001908:	74e2                	ld	s1,56(sp)
    8000190a:	7942                	ld	s2,48(sp)
    8000190c:	79a2                	ld	s3,40(sp)
    8000190e:	7a02                	ld	s4,32(sp)
    80001910:	6ae2                	ld	s5,24(sp)
    80001912:	6b42                	ld	s6,16(sp)
    80001914:	6ba2                	ld	s7,8(sp)
    80001916:	6c02                	ld	s8,0(sp)
    80001918:	6161                	addi	sp,sp,80
    8000191a:	8082                	ret

000000008000191c <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000191c:	caa5                	beqz	a3,8000198c <copyin+0x70>
{
    8000191e:	715d                	addi	sp,sp,-80
    80001920:	e486                	sd	ra,72(sp)
    80001922:	e0a2                	sd	s0,64(sp)
    80001924:	fc26                	sd	s1,56(sp)
    80001926:	f84a                	sd	s2,48(sp)
    80001928:	f44e                	sd	s3,40(sp)
    8000192a:	f052                	sd	s4,32(sp)
    8000192c:	ec56                	sd	s5,24(sp)
    8000192e:	e85a                	sd	s6,16(sp)
    80001930:	e45e                	sd	s7,8(sp)
    80001932:	e062                	sd	s8,0(sp)
    80001934:	0880                	addi	s0,sp,80
    80001936:	8b2a                	mv	s6,a0
    80001938:	8a2e                	mv	s4,a1
    8000193a:	8c32                	mv	s8,a2
    8000193c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000193e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001940:	6a85                	lui	s5,0x1
    80001942:	a01d                	j	80001968 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001944:	018505b3          	add	a1,a0,s8
    80001948:	0004861b          	sext.w	a2,s1
    8000194c:	412585b3          	sub	a1,a1,s2
    80001950:	8552                	mv	a0,s4
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	54a080e7          	jalr	1354(ra) # 80000e9c <memmove>

    len -= n;
    8000195a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000195e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001960:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001964:	02098263          	beqz	s3,80001988 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001968:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000196c:	85ca                	mv	a1,s2
    8000196e:	855a                	mv	a0,s6
    80001970:	00000097          	auipc	ra,0x0
    80001974:	858080e7          	jalr	-1960(ra) # 800011c8 <walkaddr>
    if(pa0 == 0)
    80001978:	cd01                	beqz	a0,80001990 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    8000197a:	418904b3          	sub	s1,s2,s8
    8000197e:	94d6                	add	s1,s1,s5
    80001980:	fc99f2e3          	bgeu	s3,s1,80001944 <copyin+0x28>
    80001984:	84ce                	mv	s1,s3
    80001986:	bf7d                	j	80001944 <copyin+0x28>
  }
  return 0;
    80001988:	4501                	li	a0,0
    8000198a:	a021                	j	80001992 <copyin+0x76>
    8000198c:	4501                	li	a0,0
}
    8000198e:	8082                	ret
      return -1;
    80001990:	557d                	li	a0,-1
}
    80001992:	60a6                	ld	ra,72(sp)
    80001994:	6406                	ld	s0,64(sp)
    80001996:	74e2                	ld	s1,56(sp)
    80001998:	7942                	ld	s2,48(sp)
    8000199a:	79a2                	ld	s3,40(sp)
    8000199c:	7a02                	ld	s4,32(sp)
    8000199e:	6ae2                	ld	s5,24(sp)
    800019a0:	6b42                	ld	s6,16(sp)
    800019a2:	6ba2                	ld	s7,8(sp)
    800019a4:	6c02                	ld	s8,0(sp)
    800019a6:	6161                	addi	sp,sp,80
    800019a8:	8082                	ret

00000000800019aa <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019aa:	c2dd                	beqz	a3,80001a50 <copyinstr+0xa6>
{
    800019ac:	715d                	addi	sp,sp,-80
    800019ae:	e486                	sd	ra,72(sp)
    800019b0:	e0a2                	sd	s0,64(sp)
    800019b2:	fc26                	sd	s1,56(sp)
    800019b4:	f84a                	sd	s2,48(sp)
    800019b6:	f44e                	sd	s3,40(sp)
    800019b8:	f052                	sd	s4,32(sp)
    800019ba:	ec56                	sd	s5,24(sp)
    800019bc:	e85a                	sd	s6,16(sp)
    800019be:	e45e                	sd	s7,8(sp)
    800019c0:	0880                	addi	s0,sp,80
    800019c2:	8a2a                	mv	s4,a0
    800019c4:	8b2e                	mv	s6,a1
    800019c6:	8bb2                	mv	s7,a2
    800019c8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800019ca:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019cc:	6985                	lui	s3,0x1
    800019ce:	a02d                	j	800019f8 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800019d0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800019d4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800019d6:	37fd                	addiw	a5,a5,-1
    800019d8:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800019dc:	60a6                	ld	ra,72(sp)
    800019de:	6406                	ld	s0,64(sp)
    800019e0:	74e2                	ld	s1,56(sp)
    800019e2:	7942                	ld	s2,48(sp)
    800019e4:	79a2                	ld	s3,40(sp)
    800019e6:	7a02                	ld	s4,32(sp)
    800019e8:	6ae2                	ld	s5,24(sp)
    800019ea:	6b42                	ld	s6,16(sp)
    800019ec:	6ba2                	ld	s7,8(sp)
    800019ee:	6161                	addi	sp,sp,80
    800019f0:	8082                	ret
    srcva = va0 + PGSIZE;
    800019f2:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800019f6:	c8a9                	beqz	s1,80001a48 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800019f8:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800019fc:	85ca                	mv	a1,s2
    800019fe:	8552                	mv	a0,s4
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	7c8080e7          	jalr	1992(ra) # 800011c8 <walkaddr>
    if(pa0 == 0)
    80001a08:	c131                	beqz	a0,80001a4c <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001a0a:	417906b3          	sub	a3,s2,s7
    80001a0e:	96ce                	add	a3,a3,s3
    80001a10:	00d4f363          	bgeu	s1,a3,80001a16 <copyinstr+0x6c>
    80001a14:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a16:	955e                	add	a0,a0,s7
    80001a18:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a1c:	daf9                	beqz	a3,800019f2 <copyinstr+0x48>
    80001a1e:	87da                	mv	a5,s6
    80001a20:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001a22:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001a26:	96da                	add	a3,a3,s6
    80001a28:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001a2a:	00f60733          	add	a4,a2,a5
    80001a2e:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbd140>
    80001a32:	df59                	beqz	a4,800019d0 <copyinstr+0x26>
        *dst = *p;
    80001a34:	00e78023          	sb	a4,0(a5)
      dst++;
    80001a38:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a3a:	fed797e3          	bne	a5,a3,80001a28 <copyinstr+0x7e>
    80001a3e:	14fd                	addi	s1,s1,-1
    80001a40:	94c2                	add	s1,s1,a6
      --max;
    80001a42:	8c8d                	sub	s1,s1,a1
      dst++;
    80001a44:	8b3e                	mv	s6,a5
    80001a46:	b775                	j	800019f2 <copyinstr+0x48>
    80001a48:	4781                	li	a5,0
    80001a4a:	b771                	j	800019d6 <copyinstr+0x2c>
      return -1;
    80001a4c:	557d                	li	a0,-1
    80001a4e:	b779                	j	800019dc <copyinstr+0x32>
  int got_null = 0;
    80001a50:	4781                	li	a5,0
  if(got_null){
    80001a52:	37fd                	addiw	a5,a5,-1
    80001a54:	0007851b          	sext.w	a0,a5
}
    80001a58:	8082                	ret

0000000080001a5a <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001a5a:	715d                	addi	sp,sp,-80
    80001a5c:	e486                	sd	ra,72(sp)
    80001a5e:	e0a2                	sd	s0,64(sp)
    80001a60:	fc26                	sd	s1,56(sp)
    80001a62:	f84a                	sd	s2,48(sp)
    80001a64:	f44e                	sd	s3,40(sp)
    80001a66:	f052                	sd	s4,32(sp)
    80001a68:	ec56                	sd	s5,24(sp)
    80001a6a:	e85a                	sd	s6,16(sp)
    80001a6c:	e45e                	sd	s7,8(sp)
    80001a6e:	e062                	sd	s8,0(sp)
    80001a70:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a72:	8792                	mv	a5,tp
    int id = r_tp();
    80001a74:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001a76:	0022fa97          	auipc	s5,0x22f
    80001a7a:	23aa8a93          	addi	s5,s5,570 # 80230cb0 <cpus>
    80001a7e:	00779713          	slli	a4,a5,0x7
    80001a82:	00ea86b3          	add	a3,s5,a4
    80001a86:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fdbd140>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001a8a:	0721                	addi	a4,a4,8
    80001a8c:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001a8e:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001a90:	00007c17          	auipc	s8,0x7
    80001a94:	ef8c0c13          	addi	s8,s8,-264 # 80008988 <sched_pointer>
    80001a98:	00000b97          	auipc	s7,0x0
    80001a9c:	fc2b8b93          	addi	s7,s7,-62 # 80001a5a <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001aa0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001aa4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001aa8:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001aac:	0022f497          	auipc	s1,0x22f
    80001ab0:	63448493          	addi	s1,s1,1588 # 802310e0 <proc>
            if (p->state == RUNNABLE)
    80001ab4:	498d                	li	s3,3
                p->state = RUNNING;
    80001ab6:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001ab8:	00235a17          	auipc	s4,0x235
    80001abc:	028a0a13          	addi	s4,s4,40 # 80236ae0 <tickslock>
    80001ac0:	a81d                	j	80001af6 <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001ac2:	8526                	mv	a0,s1
    80001ac4:	fffff097          	auipc	ra,0xfffff
    80001ac8:	334080e7          	jalr	820(ra) # 80000df8 <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001acc:	60a6                	ld	ra,72(sp)
    80001ace:	6406                	ld	s0,64(sp)
    80001ad0:	74e2                	ld	s1,56(sp)
    80001ad2:	7942                	ld	s2,48(sp)
    80001ad4:	79a2                	ld	s3,40(sp)
    80001ad6:	7a02                	ld	s4,32(sp)
    80001ad8:	6ae2                	ld	s5,24(sp)
    80001ada:	6b42                	ld	s6,16(sp)
    80001adc:	6ba2                	ld	s7,8(sp)
    80001ade:	6c02                	ld	s8,0(sp)
    80001ae0:	6161                	addi	sp,sp,80
    80001ae2:	8082                	ret
            release(&p->lock);
    80001ae4:	8526                	mv	a0,s1
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	312080e7          	jalr	786(ra) # 80000df8 <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001aee:	16848493          	addi	s1,s1,360
    80001af2:	fb4487e3          	beq	s1,s4,80001aa0 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001af6:	8526                	mv	a0,s1
    80001af8:	fffff097          	auipc	ra,0xfffff
    80001afc:	24c080e7          	jalr	588(ra) # 80000d44 <acquire>
            if (p->state == RUNNABLE)
    80001b00:	4c9c                	lw	a5,24(s1)
    80001b02:	ff3791e3          	bne	a5,s3,80001ae4 <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001b06:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001b0a:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001b0e:	06048593          	addi	a1,s1,96
    80001b12:	8556                	mv	a0,s5
    80001b14:	00001097          	auipc	ra,0x1
    80001b18:	f5e080e7          	jalr	-162(ra) # 80002a72 <swtch>
                if (sched_pointer != &rr_scheduler)
    80001b1c:	000c3783          	ld	a5,0(s8)
    80001b20:	fb7791e3          	bne	a5,s7,80001ac2 <rr_scheduler+0x68>
                c->proc = 0;
    80001b24:	00093023          	sd	zero,0(s2)
    80001b28:	bf75                	j	80001ae4 <rr_scheduler+0x8a>

0000000080001b2a <proc_mapstacks>:
{
    80001b2a:	7139                	addi	sp,sp,-64
    80001b2c:	fc06                	sd	ra,56(sp)
    80001b2e:	f822                	sd	s0,48(sp)
    80001b30:	f426                	sd	s1,40(sp)
    80001b32:	f04a                	sd	s2,32(sp)
    80001b34:	ec4e                	sd	s3,24(sp)
    80001b36:	e852                	sd	s4,16(sp)
    80001b38:	e456                	sd	s5,8(sp)
    80001b3a:	e05a                	sd	s6,0(sp)
    80001b3c:	0080                	addi	s0,sp,64
    80001b3e:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001b40:	0022f497          	auipc	s1,0x22f
    80001b44:	5a048493          	addi	s1,s1,1440 # 802310e0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001b48:	8b26                	mv	s6,s1
    80001b4a:	00006a97          	auipc	s5,0x6
    80001b4e:	4c6a8a93          	addi	s5,s5,1222 # 80008010 <__func__.1+0x8>
    80001b52:	04000937          	lui	s2,0x4000
    80001b56:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001b58:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001b5a:	00235a17          	auipc	s4,0x235
    80001b5e:	f86a0a13          	addi	s4,s4,-122 # 80236ae0 <tickslock>
        char *pa = kalloc();
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	0a6080e7          	jalr	166(ra) # 80000c08 <kalloc>
    80001b6a:	862a                	mv	a2,a0
        if (pa == 0)
    80001b6c:	c131                	beqz	a0,80001bb0 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001b6e:	416485b3          	sub	a1,s1,s6
    80001b72:	858d                	srai	a1,a1,0x3
    80001b74:	000ab783          	ld	a5,0(s5)
    80001b78:	02f585b3          	mul	a1,a1,a5
    80001b7c:	2585                	addiw	a1,a1,1
    80001b7e:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b82:	4719                	li	a4,6
    80001b84:	6685                	lui	a3,0x1
    80001b86:	40b905b3          	sub	a1,s2,a1
    80001b8a:	854e                	mv	a0,s3
    80001b8c:	fffff097          	auipc	ra,0xfffff
    80001b90:	71e080e7          	jalr	1822(ra) # 800012aa <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001b94:	16848493          	addi	s1,s1,360
    80001b98:	fd4495e3          	bne	s1,s4,80001b62 <proc_mapstacks+0x38>
}
    80001b9c:	70e2                	ld	ra,56(sp)
    80001b9e:	7442                	ld	s0,48(sp)
    80001ba0:	74a2                	ld	s1,40(sp)
    80001ba2:	7902                	ld	s2,32(sp)
    80001ba4:	69e2                	ld	s3,24(sp)
    80001ba6:	6a42                	ld	s4,16(sp)
    80001ba8:	6aa2                	ld	s5,8(sp)
    80001baa:	6b02                	ld	s6,0(sp)
    80001bac:	6121                	addi	sp,sp,64
    80001bae:	8082                	ret
            panic("kalloc");
    80001bb0:	00006517          	auipc	a0,0x6
    80001bb4:	66850513          	addi	a0,a0,1640 # 80008218 <digits+0x1c8>
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	984080e7          	jalr	-1660(ra) # 8000053c <panic>

0000000080001bc0 <procinit>:
{
    80001bc0:	7139                	addi	sp,sp,-64
    80001bc2:	fc06                	sd	ra,56(sp)
    80001bc4:	f822                	sd	s0,48(sp)
    80001bc6:	f426                	sd	s1,40(sp)
    80001bc8:	f04a                	sd	s2,32(sp)
    80001bca:	ec4e                	sd	s3,24(sp)
    80001bcc:	e852                	sd	s4,16(sp)
    80001bce:	e456                	sd	s5,8(sp)
    80001bd0:	e05a                	sd	s6,0(sp)
    80001bd2:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001bd4:	00006597          	auipc	a1,0x6
    80001bd8:	64c58593          	addi	a1,a1,1612 # 80008220 <digits+0x1d0>
    80001bdc:	0022f517          	auipc	a0,0x22f
    80001be0:	4d450513          	addi	a0,a0,1236 # 802310b0 <pid_lock>
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	0d0080e7          	jalr	208(ra) # 80000cb4 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001bec:	00006597          	auipc	a1,0x6
    80001bf0:	63c58593          	addi	a1,a1,1596 # 80008228 <digits+0x1d8>
    80001bf4:	0022f517          	auipc	a0,0x22f
    80001bf8:	4d450513          	addi	a0,a0,1236 # 802310c8 <wait_lock>
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0b8080e7          	jalr	184(ra) # 80000cb4 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001c04:	0022f497          	auipc	s1,0x22f
    80001c08:	4dc48493          	addi	s1,s1,1244 # 802310e0 <proc>
        initlock(&p->lock, "proc");
    80001c0c:	00006b17          	auipc	s6,0x6
    80001c10:	62cb0b13          	addi	s6,s6,1580 # 80008238 <digits+0x1e8>
        p->kstack = KSTACK((int)(p - proc));
    80001c14:	8aa6                	mv	s5,s1
    80001c16:	00006a17          	auipc	s4,0x6
    80001c1a:	3faa0a13          	addi	s4,s4,1018 # 80008010 <__func__.1+0x8>
    80001c1e:	04000937          	lui	s2,0x4000
    80001c22:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c24:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c26:	00235997          	auipc	s3,0x235
    80001c2a:	eba98993          	addi	s3,s3,-326 # 80236ae0 <tickslock>
        initlock(&p->lock, "proc");
    80001c2e:	85da                	mv	a1,s6
    80001c30:	8526                	mv	a0,s1
    80001c32:	fffff097          	auipc	ra,0xfffff
    80001c36:	082080e7          	jalr	130(ra) # 80000cb4 <initlock>
        p->state = UNUSED;
    80001c3a:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001c3e:	415487b3          	sub	a5,s1,s5
    80001c42:	878d                	srai	a5,a5,0x3
    80001c44:	000a3703          	ld	a4,0(s4)
    80001c48:	02e787b3          	mul	a5,a5,a4
    80001c4c:	2785                	addiw	a5,a5,1
    80001c4e:	00d7979b          	slliw	a5,a5,0xd
    80001c52:	40f907b3          	sub	a5,s2,a5
    80001c56:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001c58:	16848493          	addi	s1,s1,360
    80001c5c:	fd3499e3          	bne	s1,s3,80001c2e <procinit+0x6e>
}
    80001c60:	70e2                	ld	ra,56(sp)
    80001c62:	7442                	ld	s0,48(sp)
    80001c64:	74a2                	ld	s1,40(sp)
    80001c66:	7902                	ld	s2,32(sp)
    80001c68:	69e2                	ld	s3,24(sp)
    80001c6a:	6a42                	ld	s4,16(sp)
    80001c6c:	6aa2                	ld	s5,8(sp)
    80001c6e:	6b02                	ld	s6,0(sp)
    80001c70:	6121                	addi	sp,sp,64
    80001c72:	8082                	ret

0000000080001c74 <copy_array>:
{
    80001c74:	1141                	addi	sp,sp,-16
    80001c76:	e422                	sd	s0,8(sp)
    80001c78:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001c7a:	00c05c63          	blez	a2,80001c92 <copy_array+0x1e>
    80001c7e:	87aa                	mv	a5,a0
    80001c80:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001c82:	0007c703          	lbu	a4,0(a5)
    80001c86:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001c8a:	0785                	addi	a5,a5,1
    80001c8c:	0585                	addi	a1,a1,1
    80001c8e:	fea79ae3          	bne	a5,a0,80001c82 <copy_array+0xe>
}
    80001c92:	6422                	ld	s0,8(sp)
    80001c94:	0141                	addi	sp,sp,16
    80001c96:	8082                	ret

0000000080001c98 <cpuid>:
{
    80001c98:	1141                	addi	sp,sp,-16
    80001c9a:	e422                	sd	s0,8(sp)
    80001c9c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001c9e:	8512                	mv	a0,tp
}
    80001ca0:	2501                	sext.w	a0,a0
    80001ca2:	6422                	ld	s0,8(sp)
    80001ca4:	0141                	addi	sp,sp,16
    80001ca6:	8082                	ret

0000000080001ca8 <mycpu>:
{
    80001ca8:	1141                	addi	sp,sp,-16
    80001caa:	e422                	sd	s0,8(sp)
    80001cac:	0800                	addi	s0,sp,16
    80001cae:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001cb0:	2781                	sext.w	a5,a5
    80001cb2:	079e                	slli	a5,a5,0x7
}
    80001cb4:	0022f517          	auipc	a0,0x22f
    80001cb8:	ffc50513          	addi	a0,a0,-4 # 80230cb0 <cpus>
    80001cbc:	953e                	add	a0,a0,a5
    80001cbe:	6422                	ld	s0,8(sp)
    80001cc0:	0141                	addi	sp,sp,16
    80001cc2:	8082                	ret

0000000080001cc4 <myproc>:
{
    80001cc4:	1101                	addi	sp,sp,-32
    80001cc6:	ec06                	sd	ra,24(sp)
    80001cc8:	e822                	sd	s0,16(sp)
    80001cca:	e426                	sd	s1,8(sp)
    80001ccc:	1000                	addi	s0,sp,32
    push_off();
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	02a080e7          	jalr	42(ra) # 80000cf8 <push_off>
    80001cd6:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001cd8:	2781                	sext.w	a5,a5
    80001cda:	079e                	slli	a5,a5,0x7
    80001cdc:	0022f717          	auipc	a4,0x22f
    80001ce0:	fd470713          	addi	a4,a4,-44 # 80230cb0 <cpus>
    80001ce4:	97ba                	add	a5,a5,a4
    80001ce6:	6384                	ld	s1,0(a5)
    pop_off();
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	0b0080e7          	jalr	176(ra) # 80000d98 <pop_off>
}
    80001cf0:	8526                	mv	a0,s1
    80001cf2:	60e2                	ld	ra,24(sp)
    80001cf4:	6442                	ld	s0,16(sp)
    80001cf6:	64a2                	ld	s1,8(sp)
    80001cf8:	6105                	addi	sp,sp,32
    80001cfa:	8082                	ret

0000000080001cfc <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001cfc:	1141                	addi	sp,sp,-16
    80001cfe:	e406                	sd	ra,8(sp)
    80001d00:	e022                	sd	s0,0(sp)
    80001d02:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001d04:	00000097          	auipc	ra,0x0
    80001d08:	fc0080e7          	jalr	-64(ra) # 80001cc4 <myproc>
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	0ec080e7          	jalr	236(ra) # 80000df8 <release>

    if (first)
    80001d14:	00007797          	auipc	a5,0x7
    80001d18:	c6c7a783          	lw	a5,-916(a5) # 80008980 <first.1>
    80001d1c:	eb89                	bnez	a5,80001d2e <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001d1e:	00001097          	auipc	ra,0x1
    80001d22:	dfe080e7          	jalr	-514(ra) # 80002b1c <usertrapret>
}
    80001d26:	60a2                	ld	ra,8(sp)
    80001d28:	6402                	ld	s0,0(sp)
    80001d2a:	0141                	addi	sp,sp,16
    80001d2c:	8082                	ret
        first = 0;
    80001d2e:	00007797          	auipc	a5,0x7
    80001d32:	c407a923          	sw	zero,-942(a5) # 80008980 <first.1>
        fsinit(ROOTDEV);
    80001d36:	4505                	li	a0,1
    80001d38:	00002097          	auipc	ra,0x2
    80001d3c:	cea080e7          	jalr	-790(ra) # 80003a22 <fsinit>
    80001d40:	bff9                	j	80001d1e <forkret+0x22>

0000000080001d42 <allocpid>:
{
    80001d42:	1101                	addi	sp,sp,-32
    80001d44:	ec06                	sd	ra,24(sp)
    80001d46:	e822                	sd	s0,16(sp)
    80001d48:	e426                	sd	s1,8(sp)
    80001d4a:	e04a                	sd	s2,0(sp)
    80001d4c:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001d4e:	0022f917          	auipc	s2,0x22f
    80001d52:	36290913          	addi	s2,s2,866 # 802310b0 <pid_lock>
    80001d56:	854a                	mv	a0,s2
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	fec080e7          	jalr	-20(ra) # 80000d44 <acquire>
    pid = nextpid;
    80001d60:	00007797          	auipc	a5,0x7
    80001d64:	c3078793          	addi	a5,a5,-976 # 80008990 <nextpid>
    80001d68:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001d6a:	0014871b          	addiw	a4,s1,1
    80001d6e:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001d70:	854a                	mv	a0,s2
    80001d72:	fffff097          	auipc	ra,0xfffff
    80001d76:	086080e7          	jalr	134(ra) # 80000df8 <release>
}
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	60e2                	ld	ra,24(sp)
    80001d7e:	6442                	ld	s0,16(sp)
    80001d80:	64a2                	ld	s1,8(sp)
    80001d82:	6902                	ld	s2,0(sp)
    80001d84:	6105                	addi	sp,sp,32
    80001d86:	8082                	ret

0000000080001d88 <proc_pagetable>:
{
    80001d88:	1101                	addi	sp,sp,-32
    80001d8a:	ec06                	sd	ra,24(sp)
    80001d8c:	e822                	sd	s0,16(sp)
    80001d8e:	e426                	sd	s1,8(sp)
    80001d90:	e04a                	sd	s2,0(sp)
    80001d92:	1000                	addi	s0,sp,32
    80001d94:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	6fe080e7          	jalr	1790(ra) # 80001494 <uvmcreate>
    80001d9e:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001da0:	c121                	beqz	a0,80001de0 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001da2:	4729                	li	a4,10
    80001da4:	00005697          	auipc	a3,0x5
    80001da8:	25c68693          	addi	a3,a3,604 # 80007000 <_trampoline>
    80001dac:	6605                	lui	a2,0x1
    80001dae:	040005b7          	lui	a1,0x4000
    80001db2:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001db4:	05b2                	slli	a1,a1,0xc
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	454080e7          	jalr	1108(ra) # 8000120a <mappages>
    80001dbe:	02054863          	bltz	a0,80001dee <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001dc2:	4719                	li	a4,6
    80001dc4:	05893683          	ld	a3,88(s2)
    80001dc8:	6605                	lui	a2,0x1
    80001dca:	020005b7          	lui	a1,0x2000
    80001dce:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001dd0:	05b6                	slli	a1,a1,0xd
    80001dd2:	8526                	mv	a0,s1
    80001dd4:	fffff097          	auipc	ra,0xfffff
    80001dd8:	436080e7          	jalr	1078(ra) # 8000120a <mappages>
    80001ddc:	02054163          	bltz	a0,80001dfe <proc_pagetable+0x76>
}
    80001de0:	8526                	mv	a0,s1
    80001de2:	60e2                	ld	ra,24(sp)
    80001de4:	6442                	ld	s0,16(sp)
    80001de6:	64a2                	ld	s1,8(sp)
    80001de8:	6902                	ld	s2,0(sp)
    80001dea:	6105                	addi	sp,sp,32
    80001dec:	8082                	ret
        uvmfree(pagetable, 0);
    80001dee:	4581                	li	a1,0
    80001df0:	8526                	mv	a0,s1
    80001df2:	00000097          	auipc	ra,0x0
    80001df6:	8a8080e7          	jalr	-1880(ra) # 8000169a <uvmfree>
        return 0;
    80001dfa:	4481                	li	s1,0
    80001dfc:	b7d5                	j	80001de0 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001dfe:	4681                	li	a3,0
    80001e00:	4605                	li	a2,1
    80001e02:	040005b7          	lui	a1,0x4000
    80001e06:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e08:	05b2                	slli	a1,a1,0xc
    80001e0a:	8526                	mv	a0,s1
    80001e0c:	fffff097          	auipc	ra,0xfffff
    80001e10:	5c4080e7          	jalr	1476(ra) # 800013d0 <uvmunmap>
        uvmfree(pagetable, 0);
    80001e14:	4581                	li	a1,0
    80001e16:	8526                	mv	a0,s1
    80001e18:	00000097          	auipc	ra,0x0
    80001e1c:	882080e7          	jalr	-1918(ra) # 8000169a <uvmfree>
        return 0;
    80001e20:	4481                	li	s1,0
    80001e22:	bf7d                	j	80001de0 <proc_pagetable+0x58>

0000000080001e24 <proc_freepagetable>:
{
    80001e24:	1101                	addi	sp,sp,-32
    80001e26:	ec06                	sd	ra,24(sp)
    80001e28:	e822                	sd	s0,16(sp)
    80001e2a:	e426                	sd	s1,8(sp)
    80001e2c:	e04a                	sd	s2,0(sp)
    80001e2e:	1000                	addi	s0,sp,32
    80001e30:	84aa                	mv	s1,a0
    80001e32:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001e34:	4681                	li	a3,0
    80001e36:	4605                	li	a2,1
    80001e38:	040005b7          	lui	a1,0x4000
    80001e3c:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e3e:	05b2                	slli	a1,a1,0xc
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	590080e7          	jalr	1424(ra) # 800013d0 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001e48:	4681                	li	a3,0
    80001e4a:	4605                	li	a2,1
    80001e4c:	020005b7          	lui	a1,0x2000
    80001e50:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e52:	05b6                	slli	a1,a1,0xd
    80001e54:	8526                	mv	a0,s1
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	57a080e7          	jalr	1402(ra) # 800013d0 <uvmunmap>
    uvmfree(pagetable, sz);
    80001e5e:	85ca                	mv	a1,s2
    80001e60:	8526                	mv	a0,s1
    80001e62:	00000097          	auipc	ra,0x0
    80001e66:	838080e7          	jalr	-1992(ra) # 8000169a <uvmfree>
}
    80001e6a:	60e2                	ld	ra,24(sp)
    80001e6c:	6442                	ld	s0,16(sp)
    80001e6e:	64a2                	ld	s1,8(sp)
    80001e70:	6902                	ld	s2,0(sp)
    80001e72:	6105                	addi	sp,sp,32
    80001e74:	8082                	ret

0000000080001e76 <freeproc>:
{
    80001e76:	1101                	addi	sp,sp,-32
    80001e78:	ec06                	sd	ra,24(sp)
    80001e7a:	e822                	sd	s0,16(sp)
    80001e7c:	e426                	sd	s1,8(sp)
    80001e7e:	1000                	addi	s0,sp,32
    80001e80:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001e82:	6d28                	ld	a0,88(a0)
    80001e84:	c509                	beqz	a0,80001e8e <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	c0a080e7          	jalr	-1014(ra) # 80000a90 <kfree>
    p->trapframe = 0;
    80001e8e:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001e92:	68a8                	ld	a0,80(s1)
    80001e94:	c511                	beqz	a0,80001ea0 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001e96:	64ac                	ld	a1,72(s1)
    80001e98:	00000097          	auipc	ra,0x0
    80001e9c:	f8c080e7          	jalr	-116(ra) # 80001e24 <proc_freepagetable>
    p->pagetable = 0;
    80001ea0:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001ea4:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001ea8:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001eac:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001eb0:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001eb4:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001eb8:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001ebc:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001ec0:	0004ac23          	sw	zero,24(s1)
}
    80001ec4:	60e2                	ld	ra,24(sp)
    80001ec6:	6442                	ld	s0,16(sp)
    80001ec8:	64a2                	ld	s1,8(sp)
    80001eca:	6105                	addi	sp,sp,32
    80001ecc:	8082                	ret

0000000080001ece <allocproc>:
{
    80001ece:	1101                	addi	sp,sp,-32
    80001ed0:	ec06                	sd	ra,24(sp)
    80001ed2:	e822                	sd	s0,16(sp)
    80001ed4:	e426                	sd	s1,8(sp)
    80001ed6:	e04a                	sd	s2,0(sp)
    80001ed8:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001eda:	0022f497          	auipc	s1,0x22f
    80001ede:	20648493          	addi	s1,s1,518 # 802310e0 <proc>
    80001ee2:	00235917          	auipc	s2,0x235
    80001ee6:	bfe90913          	addi	s2,s2,-1026 # 80236ae0 <tickslock>
        acquire(&p->lock);
    80001eea:	8526                	mv	a0,s1
    80001eec:	fffff097          	auipc	ra,0xfffff
    80001ef0:	e58080e7          	jalr	-424(ra) # 80000d44 <acquire>
        if (p->state == UNUSED)
    80001ef4:	4c9c                	lw	a5,24(s1)
    80001ef6:	cf81                	beqz	a5,80001f0e <allocproc+0x40>
            release(&p->lock);
    80001ef8:	8526                	mv	a0,s1
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	efe080e7          	jalr	-258(ra) # 80000df8 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001f02:	16848493          	addi	s1,s1,360
    80001f06:	ff2492e3          	bne	s1,s2,80001eea <allocproc+0x1c>
    return 0;
    80001f0a:	4481                	li	s1,0
    80001f0c:	a889                	j	80001f5e <allocproc+0x90>
    p->pid = allocpid();
    80001f0e:	00000097          	auipc	ra,0x0
    80001f12:	e34080e7          	jalr	-460(ra) # 80001d42 <allocpid>
    80001f16:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001f18:	4785                	li	a5,1
    80001f1a:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	cec080e7          	jalr	-788(ra) # 80000c08 <kalloc>
    80001f24:	892a                	mv	s2,a0
    80001f26:	eca8                	sd	a0,88(s1)
    80001f28:	c131                	beqz	a0,80001f6c <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001f2a:	8526                	mv	a0,s1
    80001f2c:	00000097          	auipc	ra,0x0
    80001f30:	e5c080e7          	jalr	-420(ra) # 80001d88 <proc_pagetable>
    80001f34:	892a                	mv	s2,a0
    80001f36:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001f38:	c531                	beqz	a0,80001f84 <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001f3a:	07000613          	li	a2,112
    80001f3e:	4581                	li	a1,0
    80001f40:	06048513          	addi	a0,s1,96
    80001f44:	fffff097          	auipc	ra,0xfffff
    80001f48:	efc080e7          	jalr	-260(ra) # 80000e40 <memset>
    p->context.ra = (uint64)forkret;
    80001f4c:	00000797          	auipc	a5,0x0
    80001f50:	db078793          	addi	a5,a5,-592 # 80001cfc <forkret>
    80001f54:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001f56:	60bc                	ld	a5,64(s1)
    80001f58:	6705                	lui	a4,0x1
    80001f5a:	97ba                	add	a5,a5,a4
    80001f5c:	f4bc                	sd	a5,104(s1)
}
    80001f5e:	8526                	mv	a0,s1
    80001f60:	60e2                	ld	ra,24(sp)
    80001f62:	6442                	ld	s0,16(sp)
    80001f64:	64a2                	ld	s1,8(sp)
    80001f66:	6902                	ld	s2,0(sp)
    80001f68:	6105                	addi	sp,sp,32
    80001f6a:	8082                	ret
        freeproc(p);
    80001f6c:	8526                	mv	a0,s1
    80001f6e:	00000097          	auipc	ra,0x0
    80001f72:	f08080e7          	jalr	-248(ra) # 80001e76 <freeproc>
        release(&p->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	e80080e7          	jalr	-384(ra) # 80000df8 <release>
        return 0;
    80001f80:	84ca                	mv	s1,s2
    80001f82:	bff1                	j	80001f5e <allocproc+0x90>
        freeproc(p);
    80001f84:	8526                	mv	a0,s1
    80001f86:	00000097          	auipc	ra,0x0
    80001f8a:	ef0080e7          	jalr	-272(ra) # 80001e76 <freeproc>
        release(&p->lock);
    80001f8e:	8526                	mv	a0,s1
    80001f90:	fffff097          	auipc	ra,0xfffff
    80001f94:	e68080e7          	jalr	-408(ra) # 80000df8 <release>
        return 0;
    80001f98:	84ca                	mv	s1,s2
    80001f9a:	b7d1                	j	80001f5e <allocproc+0x90>

0000000080001f9c <userinit>:
{
    80001f9c:	1101                	addi	sp,sp,-32
    80001f9e:	ec06                	sd	ra,24(sp)
    80001fa0:	e822                	sd	s0,16(sp)
    80001fa2:	e426                	sd	s1,8(sp)
    80001fa4:	1000                	addi	s0,sp,32
    p = allocproc();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	f28080e7          	jalr	-216(ra) # 80001ece <allocproc>
    80001fae:	84aa                	mv	s1,a0
    initproc = p;
    80001fb0:	00007797          	auipc	a5,0x7
    80001fb4:	a8a7b423          	sd	a0,-1400(a5) # 80008a38 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001fb8:	03400613          	li	a2,52
    80001fbc:	00007597          	auipc	a1,0x7
    80001fc0:	9e458593          	addi	a1,a1,-1564 # 800089a0 <initcode>
    80001fc4:	6928                	ld	a0,80(a0)
    80001fc6:	fffff097          	auipc	ra,0xfffff
    80001fca:	4fc080e7          	jalr	1276(ra) # 800014c2 <uvmfirst>
    p->sz = PGSIZE;
    80001fce:	6785                	lui	a5,0x1
    80001fd0:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    80001fd2:	6cb8                	ld	a4,88(s1)
    80001fd4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001fd8:	6cb8                	ld	a4,88(s1)
    80001fda:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fdc:	4641                	li	a2,16
    80001fde:	00006597          	auipc	a1,0x6
    80001fe2:	26258593          	addi	a1,a1,610 # 80008240 <digits+0x1f0>
    80001fe6:	15848513          	addi	a0,s1,344
    80001fea:	fffff097          	auipc	ra,0xfffff
    80001fee:	f9e080e7          	jalr	-98(ra) # 80000f88 <safestrcpy>
    p->cwd = namei("/");
    80001ff2:	00006517          	auipc	a0,0x6
    80001ff6:	25e50513          	addi	a0,a0,606 # 80008250 <digits+0x200>
    80001ffa:	00002097          	auipc	ra,0x2
    80001ffe:	446080e7          	jalr	1094(ra) # 80004440 <namei>
    80002002:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    80002006:	478d                	li	a5,3
    80002008:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    8000200a:	8526                	mv	a0,s1
    8000200c:	fffff097          	auipc	ra,0xfffff
    80002010:	dec080e7          	jalr	-532(ra) # 80000df8 <release>
}
    80002014:	60e2                	ld	ra,24(sp)
    80002016:	6442                	ld	s0,16(sp)
    80002018:	64a2                	ld	s1,8(sp)
    8000201a:	6105                	addi	sp,sp,32
    8000201c:	8082                	ret

000000008000201e <growproc>:
{
    8000201e:	1101                	addi	sp,sp,-32
    80002020:	ec06                	sd	ra,24(sp)
    80002022:	e822                	sd	s0,16(sp)
    80002024:	e426                	sd	s1,8(sp)
    80002026:	e04a                	sd	s2,0(sp)
    80002028:	1000                	addi	s0,sp,32
    8000202a:	892a                	mv	s2,a0
    struct proc *p = myproc();
    8000202c:	00000097          	auipc	ra,0x0
    80002030:	c98080e7          	jalr	-872(ra) # 80001cc4 <myproc>
    80002034:	84aa                	mv	s1,a0
    sz = p->sz;
    80002036:	652c                	ld	a1,72(a0)
    if (n > 0)
    80002038:	01204c63          	bgtz	s2,80002050 <growproc+0x32>
    else if (n < 0)
    8000203c:	02094663          	bltz	s2,80002068 <growproc+0x4a>
    p->sz = sz;
    80002040:	e4ac                	sd	a1,72(s1)
    return 0;
    80002042:	4501                	li	a0,0
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6902                	ld	s2,0(sp)
    8000204c:	6105                	addi	sp,sp,32
    8000204e:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002050:	4691                	li	a3,4
    80002052:	00b90633          	add	a2,s2,a1
    80002056:	6928                	ld	a0,80(a0)
    80002058:	fffff097          	auipc	ra,0xfffff
    8000205c:	524080e7          	jalr	1316(ra) # 8000157c <uvmalloc>
    80002060:	85aa                	mv	a1,a0
    80002062:	fd79                	bnez	a0,80002040 <growproc+0x22>
            return -1;
    80002064:	557d                	li	a0,-1
    80002066:	bff9                	j	80002044 <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002068:	00b90633          	add	a2,s2,a1
    8000206c:	6928                	ld	a0,80(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	4c6080e7          	jalr	1222(ra) # 80001534 <uvmdealloc>
    80002076:	85aa                	mv	a1,a0
    80002078:	b7e1                	j	80002040 <growproc+0x22>

000000008000207a <ps>:
{
    8000207a:	715d                	addi	sp,sp,-80
    8000207c:	e486                	sd	ra,72(sp)
    8000207e:	e0a2                	sd	s0,64(sp)
    80002080:	fc26                	sd	s1,56(sp)
    80002082:	f84a                	sd	s2,48(sp)
    80002084:	f44e                	sd	s3,40(sp)
    80002086:	f052                	sd	s4,32(sp)
    80002088:	ec56                	sd	s5,24(sp)
    8000208a:	e85a                	sd	s6,16(sp)
    8000208c:	e45e                	sd	s7,8(sp)
    8000208e:	e062                	sd	s8,0(sp)
    80002090:	0880                	addi	s0,sp,80
    80002092:	84aa                	mv	s1,a0
    80002094:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80002096:	00000097          	auipc	ra,0x0
    8000209a:	c2e080e7          	jalr	-978(ra) # 80001cc4 <myproc>
    if (count == 0)
    8000209e:	120b8063          	beqz	s7,800021be <ps+0x144>
    void *result = (void *)myproc()->sz;
    800020a2:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    800020a6:	003b951b          	slliw	a0,s7,0x3
    800020aa:	0175053b          	addw	a0,a0,s7
    800020ae:	0025151b          	slliw	a0,a0,0x2
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	f6c080e7          	jalr	-148(ra) # 8000201e <growproc>
    800020ba:	10054463          	bltz	a0,800021c2 <ps+0x148>
    struct user_proc loc_result[count];
    800020be:	003b9a13          	slli	s4,s7,0x3
    800020c2:	9a5e                	add	s4,s4,s7
    800020c4:	0a0a                	slli	s4,s4,0x2
    800020c6:	00fa0793          	addi	a5,s4,15
    800020ca:	8391                	srli	a5,a5,0x4
    800020cc:	0792                	slli	a5,a5,0x4
    800020ce:	40f10133          	sub	sp,sp,a5
    800020d2:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    800020d4:	007e97b7          	lui	a5,0x7e9
    800020d8:	02f484b3          	mul	s1,s1,a5
    800020dc:	0022f797          	auipc	a5,0x22f
    800020e0:	00478793          	addi	a5,a5,4 # 802310e0 <proc>
    800020e4:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    800020e6:	00235797          	auipc	a5,0x235
    800020ea:	9fa78793          	addi	a5,a5,-1542 # 80236ae0 <tickslock>
    800020ee:	0cf4fc63          	bgeu	s1,a5,800021c6 <ps+0x14c>
        if (localCount == count)
    800020f2:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800020f6:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800020f8:	8c3e                	mv	s8,a5
    800020fa:	a069                	j	80002184 <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    800020fc:	00399793          	slli	a5,s3,0x3
    80002100:	97ce                	add	a5,a5,s3
    80002102:	078a                	slli	a5,a5,0x2
    80002104:	97d6                	add	a5,a5,s5
    80002106:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    8000210a:	8526                	mv	a0,s1
    8000210c:	fffff097          	auipc	ra,0xfffff
    80002110:	cec080e7          	jalr	-788(ra) # 80000df8 <release>
    if (localCount < count)
    80002114:	0179f963          	bgeu	s3,s7,80002126 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002118:	00399793          	slli	a5,s3,0x3
    8000211c:	97ce                	add	a5,a5,s3
    8000211e:	078a                	slli	a5,a5,0x2
    80002120:	97d6                	add	a5,a5,s5
    80002122:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80002126:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002128:	00000097          	auipc	ra,0x0
    8000212c:	b9c080e7          	jalr	-1124(ra) # 80001cc4 <myproc>
    80002130:	86d2                	mv	a3,s4
    80002132:	8656                	mv	a2,s5
    80002134:	85da                	mv	a1,s6
    80002136:	6928                	ld	a0,80(a0)
    80002138:	fffff097          	auipc	ra,0xfffff
    8000213c:	758080e7          	jalr	1880(ra) # 80001890 <copyout>
}
    80002140:	8526                	mv	a0,s1
    80002142:	fb040113          	addi	sp,s0,-80
    80002146:	60a6                	ld	ra,72(sp)
    80002148:	6406                	ld	s0,64(sp)
    8000214a:	74e2                	ld	s1,56(sp)
    8000214c:	7942                	ld	s2,48(sp)
    8000214e:	79a2                	ld	s3,40(sp)
    80002150:	7a02                	ld	s4,32(sp)
    80002152:	6ae2                	ld	s5,24(sp)
    80002154:	6b42                	ld	s6,16(sp)
    80002156:	6ba2                	ld	s7,8(sp)
    80002158:	6c02                	ld	s8,0(sp)
    8000215a:	6161                	addi	sp,sp,80
    8000215c:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    8000215e:	5b9c                	lw	a5,48(a5)
    80002160:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80002164:	8526                	mv	a0,s1
    80002166:	fffff097          	auipc	ra,0xfffff
    8000216a:	c92080e7          	jalr	-878(ra) # 80000df8 <release>
        localCount++;
    8000216e:	2985                	addiw	s3,s3,1
    80002170:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80002174:	16848493          	addi	s1,s1,360
    80002178:	f984fee3          	bgeu	s1,s8,80002114 <ps+0x9a>
        if (localCount == count)
    8000217c:	02490913          	addi	s2,s2,36
    80002180:	fb3b83e3          	beq	s7,s3,80002126 <ps+0xac>
        acquire(&p->lock);
    80002184:	8526                	mv	a0,s1
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	bbe080e7          	jalr	-1090(ra) # 80000d44 <acquire>
        if (p->state == UNUSED)
    8000218e:	4c9c                	lw	a5,24(s1)
    80002190:	d7b5                	beqz	a5,800020fc <ps+0x82>
        loc_result[localCount].state = p->state;
    80002192:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80002196:	549c                	lw	a5,40(s1)
    80002198:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    8000219c:	54dc                	lw	a5,44(s1)
    8000219e:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    800021a2:	589c                	lw	a5,48(s1)
    800021a4:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    800021a8:	4641                	li	a2,16
    800021aa:	85ca                	mv	a1,s2
    800021ac:	15848513          	addi	a0,s1,344
    800021b0:	00000097          	auipc	ra,0x0
    800021b4:	ac4080e7          	jalr	-1340(ra) # 80001c74 <copy_array>
        if (p->parent != 0) // init
    800021b8:	7c9c                	ld	a5,56(s1)
    800021ba:	f3d5                	bnez	a5,8000215e <ps+0xe4>
    800021bc:	b765                	j	80002164 <ps+0xea>
        return result;
    800021be:	4481                	li	s1,0
    800021c0:	b741                	j	80002140 <ps+0xc6>
        return result;
    800021c2:	4481                	li	s1,0
    800021c4:	bfb5                	j	80002140 <ps+0xc6>
        return result;
    800021c6:	4481                	li	s1,0
    800021c8:	bfa5                	j	80002140 <ps+0xc6>

00000000800021ca <fork>:
{
    800021ca:	7139                	addi	sp,sp,-64
    800021cc:	fc06                	sd	ra,56(sp)
    800021ce:	f822                	sd	s0,48(sp)
    800021d0:	f426                	sd	s1,40(sp)
    800021d2:	f04a                	sd	s2,32(sp)
    800021d4:	ec4e                	sd	s3,24(sp)
    800021d6:	e852                	sd	s4,16(sp)
    800021d8:	e456                	sd	s5,8(sp)
    800021da:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800021dc:	00000097          	auipc	ra,0x0
    800021e0:	ae8080e7          	jalr	-1304(ra) # 80001cc4 <myproc>
    800021e4:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800021e6:	00000097          	auipc	ra,0x0
    800021ea:	ce8080e7          	jalr	-792(ra) # 80001ece <allocproc>
    800021ee:	10050c63          	beqz	a0,80002306 <fork+0x13c>
    800021f2:	8a2a                	mv	s4,a0
    if (uvmshare(p->pagetable, np->pagetable, p->sz) < 0)
    800021f4:	048ab603          	ld	a2,72(s5)
    800021f8:	692c                	ld	a1,80(a0)
    800021fa:	050ab503          	ld	a0,80(s5)
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	5a8080e7          	jalr	1448(ra) # 800017a6 <uvmshare>
    80002206:	04054863          	bltz	a0,80002256 <fork+0x8c>
    np->sz = p->sz;
    8000220a:	048ab783          	ld	a5,72(s5)
    8000220e:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    80002212:	058ab683          	ld	a3,88(s5)
    80002216:	87b6                	mv	a5,a3
    80002218:	058a3703          	ld	a4,88(s4)
    8000221c:	12068693          	addi	a3,a3,288
    80002220:	0007b803          	ld	a6,0(a5)
    80002224:	6788                	ld	a0,8(a5)
    80002226:	6b8c                	ld	a1,16(a5)
    80002228:	6f90                	ld	a2,24(a5)
    8000222a:	01073023          	sd	a6,0(a4)
    8000222e:	e708                	sd	a0,8(a4)
    80002230:	eb0c                	sd	a1,16(a4)
    80002232:	ef10                	sd	a2,24(a4)
    80002234:	02078793          	addi	a5,a5,32
    80002238:	02070713          	addi	a4,a4,32
    8000223c:	fed792e3          	bne	a5,a3,80002220 <fork+0x56>
    np->trapframe->a0 = 0;
    80002240:	058a3783          	ld	a5,88(s4)
    80002244:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002248:	0d0a8493          	addi	s1,s5,208
    8000224c:	0d0a0913          	addi	s2,s4,208
    80002250:	150a8993          	addi	s3,s5,336
    80002254:	a00d                	j	80002276 <fork+0xac>
        freeproc(np);
    80002256:	8552                	mv	a0,s4
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	c1e080e7          	jalr	-994(ra) # 80001e76 <freeproc>
        release(&np->lock);
    80002260:	8552                	mv	a0,s4
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	b96080e7          	jalr	-1130(ra) # 80000df8 <release>
        return -1;
    8000226a:	597d                	li	s2,-1
    8000226c:	a059                	j	800022f2 <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    8000226e:	04a1                	addi	s1,s1,8
    80002270:	0921                	addi	s2,s2,8
    80002272:	01348b63          	beq	s1,s3,80002288 <fork+0xbe>
        if (p->ofile[i])
    80002276:	6088                	ld	a0,0(s1)
    80002278:	d97d                	beqz	a0,8000226e <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    8000227a:	00003097          	auipc	ra,0x3
    8000227e:	838080e7          	jalr	-1992(ra) # 80004ab2 <filedup>
    80002282:	00a93023          	sd	a0,0(s2)
    80002286:	b7e5                	j	8000226e <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002288:	150ab503          	ld	a0,336(s5)
    8000228c:	00002097          	auipc	ra,0x2
    80002290:	9d0080e7          	jalr	-1584(ra) # 80003c5c <idup>
    80002294:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002298:	4641                	li	a2,16
    8000229a:	158a8593          	addi	a1,s5,344
    8000229e:	158a0513          	addi	a0,s4,344
    800022a2:	fffff097          	auipc	ra,0xfffff
    800022a6:	ce6080e7          	jalr	-794(ra) # 80000f88 <safestrcpy>
    pid = np->pid;
    800022aa:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    800022ae:	8552                	mv	a0,s4
    800022b0:	fffff097          	auipc	ra,0xfffff
    800022b4:	b48080e7          	jalr	-1208(ra) # 80000df8 <release>
    acquire(&wait_lock);
    800022b8:	0022f497          	auipc	s1,0x22f
    800022bc:	e1048493          	addi	s1,s1,-496 # 802310c8 <wait_lock>
    800022c0:	8526                	mv	a0,s1
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	a82080e7          	jalr	-1406(ra) # 80000d44 <acquire>
    np->parent = p;
    800022ca:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	b28080e7          	jalr	-1240(ra) # 80000df8 <release>
    acquire(&np->lock);
    800022d8:	8552                	mv	a0,s4
    800022da:	fffff097          	auipc	ra,0xfffff
    800022de:	a6a080e7          	jalr	-1430(ra) # 80000d44 <acquire>
    np->state = RUNNABLE;
    800022e2:	478d                	li	a5,3
    800022e4:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800022e8:	8552                	mv	a0,s4
    800022ea:	fffff097          	auipc	ra,0xfffff
    800022ee:	b0e080e7          	jalr	-1266(ra) # 80000df8 <release>
}
    800022f2:	854a                	mv	a0,s2
    800022f4:	70e2                	ld	ra,56(sp)
    800022f6:	7442                	ld	s0,48(sp)
    800022f8:	74a2                	ld	s1,40(sp)
    800022fa:	7902                	ld	s2,32(sp)
    800022fc:	69e2                	ld	s3,24(sp)
    800022fe:	6a42                	ld	s4,16(sp)
    80002300:	6aa2                	ld	s5,8(sp)
    80002302:	6121                	addi	sp,sp,64
    80002304:	8082                	ret
        return -1;
    80002306:	597d                	li	s2,-1
    80002308:	b7ed                	j	800022f2 <fork+0x128>

000000008000230a <scheduler>:
{
    8000230a:	1101                	addi	sp,sp,-32
    8000230c:	ec06                	sd	ra,24(sp)
    8000230e:	e822                	sd	s0,16(sp)
    80002310:	e426                	sd	s1,8(sp)
    80002312:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    80002314:	00006497          	auipc	s1,0x6
    80002318:	67448493          	addi	s1,s1,1652 # 80008988 <sched_pointer>
    8000231c:	609c                	ld	a5,0(s1)
    8000231e:	9782                	jalr	a5
    while (1)
    80002320:	bff5                	j	8000231c <scheduler+0x12>

0000000080002322 <sched>:
{
    80002322:	7179                	addi	sp,sp,-48
    80002324:	f406                	sd	ra,40(sp)
    80002326:	f022                	sd	s0,32(sp)
    80002328:	ec26                	sd	s1,24(sp)
    8000232a:	e84a                	sd	s2,16(sp)
    8000232c:	e44e                	sd	s3,8(sp)
    8000232e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002330:	00000097          	auipc	ra,0x0
    80002334:	994080e7          	jalr	-1644(ra) # 80001cc4 <myproc>
    80002338:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	990080e7          	jalr	-1648(ra) # 80000cca <holding>
    80002342:	c53d                	beqz	a0,800023b0 <sched+0x8e>
    80002344:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002346:	2781                	sext.w	a5,a5
    80002348:	079e                	slli	a5,a5,0x7
    8000234a:	0022f717          	auipc	a4,0x22f
    8000234e:	96670713          	addi	a4,a4,-1690 # 80230cb0 <cpus>
    80002352:	97ba                	add	a5,a5,a4
    80002354:	5fb8                	lw	a4,120(a5)
    80002356:	4785                	li	a5,1
    80002358:	06f71463          	bne	a4,a5,800023c0 <sched+0x9e>
    if (p->state == RUNNING)
    8000235c:	4c98                	lw	a4,24(s1)
    8000235e:	4791                	li	a5,4
    80002360:	06f70863          	beq	a4,a5,800023d0 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002364:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002368:	8b89                	andi	a5,a5,2
    if (intr_get())
    8000236a:	ebbd                	bnez	a5,800023e0 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000236c:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    8000236e:	0022f917          	auipc	s2,0x22f
    80002372:	94290913          	addi	s2,s2,-1726 # 80230cb0 <cpus>
    80002376:	2781                	sext.w	a5,a5
    80002378:	079e                	slli	a5,a5,0x7
    8000237a:	97ca                	add	a5,a5,s2
    8000237c:	07c7a983          	lw	s3,124(a5)
    80002380:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    80002382:	2581                	sext.w	a1,a1
    80002384:	059e                	slli	a1,a1,0x7
    80002386:	05a1                	addi	a1,a1,8
    80002388:	95ca                	add	a1,a1,s2
    8000238a:	06048513          	addi	a0,s1,96
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	6e4080e7          	jalr	1764(ra) # 80002a72 <swtch>
    80002396:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002398:	2781                	sext.w	a5,a5
    8000239a:	079e                	slli	a5,a5,0x7
    8000239c:	993e                	add	s2,s2,a5
    8000239e:	07392e23          	sw	s3,124(s2)
}
    800023a2:	70a2                	ld	ra,40(sp)
    800023a4:	7402                	ld	s0,32(sp)
    800023a6:	64e2                	ld	s1,24(sp)
    800023a8:	6942                	ld	s2,16(sp)
    800023aa:	69a2                	ld	s3,8(sp)
    800023ac:	6145                	addi	sp,sp,48
    800023ae:	8082                	ret
        panic("sched p->lock");
    800023b0:	00006517          	auipc	a0,0x6
    800023b4:	ea850513          	addi	a0,a0,-344 # 80008258 <digits+0x208>
    800023b8:	ffffe097          	auipc	ra,0xffffe
    800023bc:	184080e7          	jalr	388(ra) # 8000053c <panic>
        panic("sched locks");
    800023c0:	00006517          	auipc	a0,0x6
    800023c4:	ea850513          	addi	a0,a0,-344 # 80008268 <digits+0x218>
    800023c8:	ffffe097          	auipc	ra,0xffffe
    800023cc:	174080e7          	jalr	372(ra) # 8000053c <panic>
        panic("sched running");
    800023d0:	00006517          	auipc	a0,0x6
    800023d4:	ea850513          	addi	a0,a0,-344 # 80008278 <digits+0x228>
    800023d8:	ffffe097          	auipc	ra,0xffffe
    800023dc:	164080e7          	jalr	356(ra) # 8000053c <panic>
        panic("sched interruptible");
    800023e0:	00006517          	auipc	a0,0x6
    800023e4:	ea850513          	addi	a0,a0,-344 # 80008288 <digits+0x238>
    800023e8:	ffffe097          	auipc	ra,0xffffe
    800023ec:	154080e7          	jalr	340(ra) # 8000053c <panic>

00000000800023f0 <yield>:
{
    800023f0:	1101                	addi	sp,sp,-32
    800023f2:	ec06                	sd	ra,24(sp)
    800023f4:	e822                	sd	s0,16(sp)
    800023f6:	e426                	sd	s1,8(sp)
    800023f8:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800023fa:	00000097          	auipc	ra,0x0
    800023fe:	8ca080e7          	jalr	-1846(ra) # 80001cc4 <myproc>
    80002402:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002404:	fffff097          	auipc	ra,0xfffff
    80002408:	940080e7          	jalr	-1728(ra) # 80000d44 <acquire>
    p->state = RUNNABLE;
    8000240c:	478d                	li	a5,3
    8000240e:	cc9c                	sw	a5,24(s1)
    sched();
    80002410:	00000097          	auipc	ra,0x0
    80002414:	f12080e7          	jalr	-238(ra) # 80002322 <sched>
    release(&p->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	9de080e7          	jalr	-1570(ra) # 80000df8 <release>
}
    80002422:	60e2                	ld	ra,24(sp)
    80002424:	6442                	ld	s0,16(sp)
    80002426:	64a2                	ld	s1,8(sp)
    80002428:	6105                	addi	sp,sp,32
    8000242a:	8082                	ret

000000008000242c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000242c:	7179                	addi	sp,sp,-48
    8000242e:	f406                	sd	ra,40(sp)
    80002430:	f022                	sd	s0,32(sp)
    80002432:	ec26                	sd	s1,24(sp)
    80002434:	e84a                	sd	s2,16(sp)
    80002436:	e44e                	sd	s3,8(sp)
    80002438:	1800                	addi	s0,sp,48
    8000243a:	89aa                	mv	s3,a0
    8000243c:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000243e:	00000097          	auipc	ra,0x0
    80002442:	886080e7          	jalr	-1914(ra) # 80001cc4 <myproc>
    80002446:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002448:	fffff097          	auipc	ra,0xfffff
    8000244c:	8fc080e7          	jalr	-1796(ra) # 80000d44 <acquire>
    release(lk);
    80002450:	854a                	mv	a0,s2
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	9a6080e7          	jalr	-1626(ra) # 80000df8 <release>

    // Go to sleep.
    p->chan = chan;
    8000245a:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    8000245e:	4789                	li	a5,2
    80002460:	cc9c                	sw	a5,24(s1)

    sched();
    80002462:	00000097          	auipc	ra,0x0
    80002466:	ec0080e7          	jalr	-320(ra) # 80002322 <sched>

    // Tidy up.
    p->chan = 0;
    8000246a:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    8000246e:	8526                	mv	a0,s1
    80002470:	fffff097          	auipc	ra,0xfffff
    80002474:	988080e7          	jalr	-1656(ra) # 80000df8 <release>
    acquire(lk);
    80002478:	854a                	mv	a0,s2
    8000247a:	fffff097          	auipc	ra,0xfffff
    8000247e:	8ca080e7          	jalr	-1846(ra) # 80000d44 <acquire>
}
    80002482:	70a2                	ld	ra,40(sp)
    80002484:	7402                	ld	s0,32(sp)
    80002486:	64e2                	ld	s1,24(sp)
    80002488:	6942                	ld	s2,16(sp)
    8000248a:	69a2                	ld	s3,8(sp)
    8000248c:	6145                	addi	sp,sp,48
    8000248e:	8082                	ret

0000000080002490 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002490:	7139                	addi	sp,sp,-64
    80002492:	fc06                	sd	ra,56(sp)
    80002494:	f822                	sd	s0,48(sp)
    80002496:	f426                	sd	s1,40(sp)
    80002498:	f04a                	sd	s2,32(sp)
    8000249a:	ec4e                	sd	s3,24(sp)
    8000249c:	e852                	sd	s4,16(sp)
    8000249e:	e456                	sd	s5,8(sp)
    800024a0:	0080                	addi	s0,sp,64
    800024a2:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024a4:	0022f497          	auipc	s1,0x22f
    800024a8:	c3c48493          	addi	s1,s1,-964 # 802310e0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800024ac:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800024ae:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800024b0:	00234917          	auipc	s2,0x234
    800024b4:	63090913          	addi	s2,s2,1584 # 80236ae0 <tickslock>
    800024b8:	a811                	j	800024cc <wakeup+0x3c>
            }
            release(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	93c080e7          	jalr	-1732(ra) # 80000df8 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800024c4:	16848493          	addi	s1,s1,360
    800024c8:	03248663          	beq	s1,s2,800024f4 <wakeup+0x64>
        if (p != myproc())
    800024cc:	fffff097          	auipc	ra,0xfffff
    800024d0:	7f8080e7          	jalr	2040(ra) # 80001cc4 <myproc>
    800024d4:	fea488e3          	beq	s1,a0,800024c4 <wakeup+0x34>
            acquire(&p->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	86a080e7          	jalr	-1942(ra) # 80000d44 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800024e2:	4c9c                	lw	a5,24(s1)
    800024e4:	fd379be3          	bne	a5,s3,800024ba <wakeup+0x2a>
    800024e8:	709c                	ld	a5,32(s1)
    800024ea:	fd4798e3          	bne	a5,s4,800024ba <wakeup+0x2a>
                p->state = RUNNABLE;
    800024ee:	0154ac23          	sw	s5,24(s1)
    800024f2:	b7e1                	j	800024ba <wakeup+0x2a>
        }
    }
}
    800024f4:	70e2                	ld	ra,56(sp)
    800024f6:	7442                	ld	s0,48(sp)
    800024f8:	74a2                	ld	s1,40(sp)
    800024fa:	7902                	ld	s2,32(sp)
    800024fc:	69e2                	ld	s3,24(sp)
    800024fe:	6a42                	ld	s4,16(sp)
    80002500:	6aa2                	ld	s5,8(sp)
    80002502:	6121                	addi	sp,sp,64
    80002504:	8082                	ret

0000000080002506 <reparent>:
{
    80002506:	7179                	addi	sp,sp,-48
    80002508:	f406                	sd	ra,40(sp)
    8000250a:	f022                	sd	s0,32(sp)
    8000250c:	ec26                	sd	s1,24(sp)
    8000250e:	e84a                	sd	s2,16(sp)
    80002510:	e44e                	sd	s3,8(sp)
    80002512:	e052                	sd	s4,0(sp)
    80002514:	1800                	addi	s0,sp,48
    80002516:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002518:	0022f497          	auipc	s1,0x22f
    8000251c:	bc848493          	addi	s1,s1,-1080 # 802310e0 <proc>
            pp->parent = initproc;
    80002520:	00006a17          	auipc	s4,0x6
    80002524:	518a0a13          	addi	s4,s4,1304 # 80008a38 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002528:	00234997          	auipc	s3,0x234
    8000252c:	5b898993          	addi	s3,s3,1464 # 80236ae0 <tickslock>
    80002530:	a029                	j	8000253a <reparent+0x34>
    80002532:	16848493          	addi	s1,s1,360
    80002536:	01348d63          	beq	s1,s3,80002550 <reparent+0x4a>
        if (pp->parent == p)
    8000253a:	7c9c                	ld	a5,56(s1)
    8000253c:	ff279be3          	bne	a5,s2,80002532 <reparent+0x2c>
            pp->parent = initproc;
    80002540:	000a3503          	ld	a0,0(s4)
    80002544:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    80002546:	00000097          	auipc	ra,0x0
    8000254a:	f4a080e7          	jalr	-182(ra) # 80002490 <wakeup>
    8000254e:	b7d5                	j	80002532 <reparent+0x2c>
}
    80002550:	70a2                	ld	ra,40(sp)
    80002552:	7402                	ld	s0,32(sp)
    80002554:	64e2                	ld	s1,24(sp)
    80002556:	6942                	ld	s2,16(sp)
    80002558:	69a2                	ld	s3,8(sp)
    8000255a:	6a02                	ld	s4,0(sp)
    8000255c:	6145                	addi	sp,sp,48
    8000255e:	8082                	ret

0000000080002560 <exit>:
{
    80002560:	7179                	addi	sp,sp,-48
    80002562:	f406                	sd	ra,40(sp)
    80002564:	f022                	sd	s0,32(sp)
    80002566:	ec26                	sd	s1,24(sp)
    80002568:	e84a                	sd	s2,16(sp)
    8000256a:	e44e                	sd	s3,8(sp)
    8000256c:	e052                	sd	s4,0(sp)
    8000256e:	1800                	addi	s0,sp,48
    80002570:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    80002572:	fffff097          	auipc	ra,0xfffff
    80002576:	752080e7          	jalr	1874(ra) # 80001cc4 <myproc>
    8000257a:	89aa                	mv	s3,a0
    if (p == initproc)
    8000257c:	00006797          	auipc	a5,0x6
    80002580:	4bc7b783          	ld	a5,1212(a5) # 80008a38 <initproc>
    80002584:	0d050493          	addi	s1,a0,208
    80002588:	15050913          	addi	s2,a0,336
    8000258c:	02a79363          	bne	a5,a0,800025b2 <exit+0x52>
        panic("init exiting");
    80002590:	00006517          	auipc	a0,0x6
    80002594:	d1050513          	addi	a0,a0,-752 # 800082a0 <digits+0x250>
    80002598:	ffffe097          	auipc	ra,0xffffe
    8000259c:	fa4080e7          	jalr	-92(ra) # 8000053c <panic>
            fileclose(f);
    800025a0:	00002097          	auipc	ra,0x2
    800025a4:	564080e7          	jalr	1380(ra) # 80004b04 <fileclose>
            p->ofile[fd] = 0;
    800025a8:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800025ac:	04a1                	addi	s1,s1,8
    800025ae:	01248563          	beq	s1,s2,800025b8 <exit+0x58>
        if (p->ofile[fd])
    800025b2:	6088                	ld	a0,0(s1)
    800025b4:	f575                	bnez	a0,800025a0 <exit+0x40>
    800025b6:	bfdd                	j	800025ac <exit+0x4c>
    begin_op();
    800025b8:	00002097          	auipc	ra,0x2
    800025bc:	088080e7          	jalr	136(ra) # 80004640 <begin_op>
    iput(p->cwd);
    800025c0:	1509b503          	ld	a0,336(s3)
    800025c4:	00002097          	auipc	ra,0x2
    800025c8:	890080e7          	jalr	-1904(ra) # 80003e54 <iput>
    end_op();
    800025cc:	00002097          	auipc	ra,0x2
    800025d0:	0ee080e7          	jalr	238(ra) # 800046ba <end_op>
    p->cwd = 0;
    800025d4:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800025d8:	0022f497          	auipc	s1,0x22f
    800025dc:	af048493          	addi	s1,s1,-1296 # 802310c8 <wait_lock>
    800025e0:	8526                	mv	a0,s1
    800025e2:	ffffe097          	auipc	ra,0xffffe
    800025e6:	762080e7          	jalr	1890(ra) # 80000d44 <acquire>
    reparent(p);
    800025ea:	854e                	mv	a0,s3
    800025ec:	00000097          	auipc	ra,0x0
    800025f0:	f1a080e7          	jalr	-230(ra) # 80002506 <reparent>
    wakeup(p->parent);
    800025f4:	0389b503          	ld	a0,56(s3)
    800025f8:	00000097          	auipc	ra,0x0
    800025fc:	e98080e7          	jalr	-360(ra) # 80002490 <wakeup>
    acquire(&p->lock);
    80002600:	854e                	mv	a0,s3
    80002602:	ffffe097          	auipc	ra,0xffffe
    80002606:	742080e7          	jalr	1858(ra) # 80000d44 <acquire>
    p->xstate = status;
    8000260a:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    8000260e:	4795                	li	a5,5
    80002610:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002614:	8526                	mv	a0,s1
    80002616:	ffffe097          	auipc	ra,0xffffe
    8000261a:	7e2080e7          	jalr	2018(ra) # 80000df8 <release>
    sched();
    8000261e:	00000097          	auipc	ra,0x0
    80002622:	d04080e7          	jalr	-764(ra) # 80002322 <sched>
    panic("zombie exit");
    80002626:	00006517          	auipc	a0,0x6
    8000262a:	c8a50513          	addi	a0,a0,-886 # 800082b0 <digits+0x260>
    8000262e:	ffffe097          	auipc	ra,0xffffe
    80002632:	f0e080e7          	jalr	-242(ra) # 8000053c <panic>

0000000080002636 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002636:	7179                	addi	sp,sp,-48
    80002638:	f406                	sd	ra,40(sp)
    8000263a:	f022                	sd	s0,32(sp)
    8000263c:	ec26                	sd	s1,24(sp)
    8000263e:	e84a                	sd	s2,16(sp)
    80002640:	e44e                	sd	s3,8(sp)
    80002642:	1800                	addi	s0,sp,48
    80002644:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002646:	0022f497          	auipc	s1,0x22f
    8000264a:	a9a48493          	addi	s1,s1,-1382 # 802310e0 <proc>
    8000264e:	00234997          	auipc	s3,0x234
    80002652:	49298993          	addi	s3,s3,1170 # 80236ae0 <tickslock>
    {
        acquire(&p->lock);
    80002656:	8526                	mv	a0,s1
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	6ec080e7          	jalr	1772(ra) # 80000d44 <acquire>
        if (p->pid == pid)
    80002660:	589c                	lw	a5,48(s1)
    80002662:	01278d63          	beq	a5,s2,8000267c <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	ffffe097          	auipc	ra,0xffffe
    8000266c:	790080e7          	jalr	1936(ra) # 80000df8 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002670:	16848493          	addi	s1,s1,360
    80002674:	ff3491e3          	bne	s1,s3,80002656 <kill+0x20>
    }
    return -1;
    80002678:	557d                	li	a0,-1
    8000267a:	a829                	j	80002694 <kill+0x5e>
            p->killed = 1;
    8000267c:	4785                	li	a5,1
    8000267e:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002680:	4c98                	lw	a4,24(s1)
    80002682:	4789                	li	a5,2
    80002684:	00f70f63          	beq	a4,a5,800026a2 <kill+0x6c>
            release(&p->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	76e080e7          	jalr	1902(ra) # 80000df8 <release>
            return 0;
    80002692:	4501                	li	a0,0
}
    80002694:	70a2                	ld	ra,40(sp)
    80002696:	7402                	ld	s0,32(sp)
    80002698:	64e2                	ld	s1,24(sp)
    8000269a:	6942                	ld	s2,16(sp)
    8000269c:	69a2                	ld	s3,8(sp)
    8000269e:	6145                	addi	sp,sp,48
    800026a0:	8082                	ret
                p->state = RUNNABLE;
    800026a2:	478d                	li	a5,3
    800026a4:	cc9c                	sw	a5,24(s1)
    800026a6:	b7cd                	j	80002688 <kill+0x52>

00000000800026a8 <setkilled>:

void setkilled(struct proc *p)
{
    800026a8:	1101                	addi	sp,sp,-32
    800026aa:	ec06                	sd	ra,24(sp)
    800026ac:	e822                	sd	s0,16(sp)
    800026ae:	e426                	sd	s1,8(sp)
    800026b0:	1000                	addi	s0,sp,32
    800026b2:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	690080e7          	jalr	1680(ra) # 80000d44 <acquire>
    p->killed = 1;
    800026bc:	4785                	li	a5,1
    800026be:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800026c0:	8526                	mv	a0,s1
    800026c2:	ffffe097          	auipc	ra,0xffffe
    800026c6:	736080e7          	jalr	1846(ra) # 80000df8 <release>
}
    800026ca:	60e2                	ld	ra,24(sp)
    800026cc:	6442                	ld	s0,16(sp)
    800026ce:	64a2                	ld	s1,8(sp)
    800026d0:	6105                	addi	sp,sp,32
    800026d2:	8082                	ret

00000000800026d4 <killed>:

int killed(struct proc *p)
{
    800026d4:	1101                	addi	sp,sp,-32
    800026d6:	ec06                	sd	ra,24(sp)
    800026d8:	e822                	sd	s0,16(sp)
    800026da:	e426                	sd	s1,8(sp)
    800026dc:	e04a                	sd	s2,0(sp)
    800026de:	1000                	addi	s0,sp,32
    800026e0:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	662080e7          	jalr	1634(ra) # 80000d44 <acquire>
    k = p->killed;
    800026ea:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800026ee:	8526                	mv	a0,s1
    800026f0:	ffffe097          	auipc	ra,0xffffe
    800026f4:	708080e7          	jalr	1800(ra) # 80000df8 <release>
    return k;
}
    800026f8:	854a                	mv	a0,s2
    800026fa:	60e2                	ld	ra,24(sp)
    800026fc:	6442                	ld	s0,16(sp)
    800026fe:	64a2                	ld	s1,8(sp)
    80002700:	6902                	ld	s2,0(sp)
    80002702:	6105                	addi	sp,sp,32
    80002704:	8082                	ret

0000000080002706 <wait>:
{
    80002706:	715d                	addi	sp,sp,-80
    80002708:	e486                	sd	ra,72(sp)
    8000270a:	e0a2                	sd	s0,64(sp)
    8000270c:	fc26                	sd	s1,56(sp)
    8000270e:	f84a                	sd	s2,48(sp)
    80002710:	f44e                	sd	s3,40(sp)
    80002712:	f052                	sd	s4,32(sp)
    80002714:	ec56                	sd	s5,24(sp)
    80002716:	e85a                	sd	s6,16(sp)
    80002718:	e45e                	sd	s7,8(sp)
    8000271a:	e062                	sd	s8,0(sp)
    8000271c:	0880                	addi	s0,sp,80
    8000271e:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002720:	fffff097          	auipc	ra,0xfffff
    80002724:	5a4080e7          	jalr	1444(ra) # 80001cc4 <myproc>
    80002728:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000272a:	0022f517          	auipc	a0,0x22f
    8000272e:	99e50513          	addi	a0,a0,-1634 # 802310c8 <wait_lock>
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	612080e7          	jalr	1554(ra) # 80000d44 <acquire>
        havekids = 0;
    8000273a:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000273c:	4a15                	li	s4,5
                havekids = 1;
    8000273e:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002740:	00234997          	auipc	s3,0x234
    80002744:	3a098993          	addi	s3,s3,928 # 80236ae0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002748:	0022fc17          	auipc	s8,0x22f
    8000274c:	980c0c13          	addi	s8,s8,-1664 # 802310c8 <wait_lock>
    80002750:	a0d1                	j	80002814 <wait+0x10e>
                    pid = pp->pid;
    80002752:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002756:	000b0e63          	beqz	s6,80002772 <wait+0x6c>
    8000275a:	4691                	li	a3,4
    8000275c:	02c48613          	addi	a2,s1,44
    80002760:	85da                	mv	a1,s6
    80002762:	05093503          	ld	a0,80(s2)
    80002766:	fffff097          	auipc	ra,0xfffff
    8000276a:	12a080e7          	jalr	298(ra) # 80001890 <copyout>
    8000276e:	04054163          	bltz	a0,800027b0 <wait+0xaa>
                    freeproc(pp);
    80002772:	8526                	mv	a0,s1
    80002774:	fffff097          	auipc	ra,0xfffff
    80002778:	702080e7          	jalr	1794(ra) # 80001e76 <freeproc>
                    release(&pp->lock);
    8000277c:	8526                	mv	a0,s1
    8000277e:	ffffe097          	auipc	ra,0xffffe
    80002782:	67a080e7          	jalr	1658(ra) # 80000df8 <release>
                    release(&wait_lock);
    80002786:	0022f517          	auipc	a0,0x22f
    8000278a:	94250513          	addi	a0,a0,-1726 # 802310c8 <wait_lock>
    8000278e:	ffffe097          	auipc	ra,0xffffe
    80002792:	66a080e7          	jalr	1642(ra) # 80000df8 <release>
}
    80002796:	854e                	mv	a0,s3
    80002798:	60a6                	ld	ra,72(sp)
    8000279a:	6406                	ld	s0,64(sp)
    8000279c:	74e2                	ld	s1,56(sp)
    8000279e:	7942                	ld	s2,48(sp)
    800027a0:	79a2                	ld	s3,40(sp)
    800027a2:	7a02                	ld	s4,32(sp)
    800027a4:	6ae2                	ld	s5,24(sp)
    800027a6:	6b42                	ld	s6,16(sp)
    800027a8:	6ba2                	ld	s7,8(sp)
    800027aa:	6c02                	ld	s8,0(sp)
    800027ac:	6161                	addi	sp,sp,80
    800027ae:	8082                	ret
                        release(&pp->lock);
    800027b0:	8526                	mv	a0,s1
    800027b2:	ffffe097          	auipc	ra,0xffffe
    800027b6:	646080e7          	jalr	1606(ra) # 80000df8 <release>
                        release(&wait_lock);
    800027ba:	0022f517          	auipc	a0,0x22f
    800027be:	90e50513          	addi	a0,a0,-1778 # 802310c8 <wait_lock>
    800027c2:	ffffe097          	auipc	ra,0xffffe
    800027c6:	636080e7          	jalr	1590(ra) # 80000df8 <release>
                        return -1;
    800027ca:	59fd                	li	s3,-1
    800027cc:	b7e9                	j	80002796 <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027ce:	16848493          	addi	s1,s1,360
    800027d2:	03348463          	beq	s1,s3,800027fa <wait+0xf4>
            if (pp->parent == p)
    800027d6:	7c9c                	ld	a5,56(s1)
    800027d8:	ff279be3          	bne	a5,s2,800027ce <wait+0xc8>
                acquire(&pp->lock);
    800027dc:	8526                	mv	a0,s1
    800027de:	ffffe097          	auipc	ra,0xffffe
    800027e2:	566080e7          	jalr	1382(ra) # 80000d44 <acquire>
                if (pp->state == ZOMBIE)
    800027e6:	4c9c                	lw	a5,24(s1)
    800027e8:	f74785e3          	beq	a5,s4,80002752 <wait+0x4c>
                release(&pp->lock);
    800027ec:	8526                	mv	a0,s1
    800027ee:	ffffe097          	auipc	ra,0xffffe
    800027f2:	60a080e7          	jalr	1546(ra) # 80000df8 <release>
                havekids = 1;
    800027f6:	8756                	mv	a4,s5
    800027f8:	bfd9                	j	800027ce <wait+0xc8>
        if (!havekids || killed(p))
    800027fa:	c31d                	beqz	a4,80002820 <wait+0x11a>
    800027fc:	854a                	mv	a0,s2
    800027fe:	00000097          	auipc	ra,0x0
    80002802:	ed6080e7          	jalr	-298(ra) # 800026d4 <killed>
    80002806:	ed09                	bnez	a0,80002820 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002808:	85e2                	mv	a1,s8
    8000280a:	854a                	mv	a0,s2
    8000280c:	00000097          	auipc	ra,0x0
    80002810:	c20080e7          	jalr	-992(ra) # 8000242c <sleep>
        havekids = 0;
    80002814:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002816:	0022f497          	auipc	s1,0x22f
    8000281a:	8ca48493          	addi	s1,s1,-1846 # 802310e0 <proc>
    8000281e:	bf65                	j	800027d6 <wait+0xd0>
            release(&wait_lock);
    80002820:	0022f517          	auipc	a0,0x22f
    80002824:	8a850513          	addi	a0,a0,-1880 # 802310c8 <wait_lock>
    80002828:	ffffe097          	auipc	ra,0xffffe
    8000282c:	5d0080e7          	jalr	1488(ra) # 80000df8 <release>
            return -1;
    80002830:	59fd                	li	s3,-1
    80002832:	b795                	j	80002796 <wait+0x90>

0000000080002834 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002834:	7179                	addi	sp,sp,-48
    80002836:	f406                	sd	ra,40(sp)
    80002838:	f022                	sd	s0,32(sp)
    8000283a:	ec26                	sd	s1,24(sp)
    8000283c:	e84a                	sd	s2,16(sp)
    8000283e:	e44e                	sd	s3,8(sp)
    80002840:	e052                	sd	s4,0(sp)
    80002842:	1800                	addi	s0,sp,48
    80002844:	84aa                	mv	s1,a0
    80002846:	892e                	mv	s2,a1
    80002848:	89b2                	mv	s3,a2
    8000284a:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000284c:	fffff097          	auipc	ra,0xfffff
    80002850:	478080e7          	jalr	1144(ra) # 80001cc4 <myproc>
    if (user_dst)
    80002854:	c08d                	beqz	s1,80002876 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002856:	86d2                	mv	a3,s4
    80002858:	864e                	mv	a2,s3
    8000285a:	85ca                	mv	a1,s2
    8000285c:	6928                	ld	a0,80(a0)
    8000285e:	fffff097          	auipc	ra,0xfffff
    80002862:	032080e7          	jalr	50(ra) # 80001890 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    80002866:	70a2                	ld	ra,40(sp)
    80002868:	7402                	ld	s0,32(sp)
    8000286a:	64e2                	ld	s1,24(sp)
    8000286c:	6942                	ld	s2,16(sp)
    8000286e:	69a2                	ld	s3,8(sp)
    80002870:	6a02                	ld	s4,0(sp)
    80002872:	6145                	addi	sp,sp,48
    80002874:	8082                	ret
        memmove((char *)dst, src, len);
    80002876:	000a061b          	sext.w	a2,s4
    8000287a:	85ce                	mv	a1,s3
    8000287c:	854a                	mv	a0,s2
    8000287e:	ffffe097          	auipc	ra,0xffffe
    80002882:	61e080e7          	jalr	1566(ra) # 80000e9c <memmove>
        return 0;
    80002886:	8526                	mv	a0,s1
    80002888:	bff9                	j	80002866 <either_copyout+0x32>

000000008000288a <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000288a:	7179                	addi	sp,sp,-48
    8000288c:	f406                	sd	ra,40(sp)
    8000288e:	f022                	sd	s0,32(sp)
    80002890:	ec26                	sd	s1,24(sp)
    80002892:	e84a                	sd	s2,16(sp)
    80002894:	e44e                	sd	s3,8(sp)
    80002896:	e052                	sd	s4,0(sp)
    80002898:	1800                	addi	s0,sp,48
    8000289a:	892a                	mv	s2,a0
    8000289c:	84ae                	mv	s1,a1
    8000289e:	89b2                	mv	s3,a2
    800028a0:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028a2:	fffff097          	auipc	ra,0xfffff
    800028a6:	422080e7          	jalr	1058(ra) # 80001cc4 <myproc>
    if (user_src)
    800028aa:	c08d                	beqz	s1,800028cc <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800028ac:	86d2                	mv	a3,s4
    800028ae:	864e                	mv	a2,s3
    800028b0:	85ca                	mv	a1,s2
    800028b2:	6928                	ld	a0,80(a0)
    800028b4:	fffff097          	auipc	ra,0xfffff
    800028b8:	068080e7          	jalr	104(ra) # 8000191c <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800028bc:	70a2                	ld	ra,40(sp)
    800028be:	7402                	ld	s0,32(sp)
    800028c0:	64e2                	ld	s1,24(sp)
    800028c2:	6942                	ld	s2,16(sp)
    800028c4:	69a2                	ld	s3,8(sp)
    800028c6:	6a02                	ld	s4,0(sp)
    800028c8:	6145                	addi	sp,sp,48
    800028ca:	8082                	ret
        memmove(dst, (char *)src, len);
    800028cc:	000a061b          	sext.w	a2,s4
    800028d0:	85ce                	mv	a1,s3
    800028d2:	854a                	mv	a0,s2
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	5c8080e7          	jalr	1480(ra) # 80000e9c <memmove>
        return 0;
    800028dc:	8526                	mv	a0,s1
    800028de:	bff9                	j	800028bc <either_copyin+0x32>

00000000800028e0 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800028e0:	715d                	addi	sp,sp,-80
    800028e2:	e486                	sd	ra,72(sp)
    800028e4:	e0a2                	sd	s0,64(sp)
    800028e6:	fc26                	sd	s1,56(sp)
    800028e8:	f84a                	sd	s2,48(sp)
    800028ea:	f44e                	sd	s3,40(sp)
    800028ec:	f052                	sd	s4,32(sp)
    800028ee:	ec56                	sd	s5,24(sp)
    800028f0:	e85a                	sd	s6,16(sp)
    800028f2:	e45e                	sd	s7,8(sp)
    800028f4:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800028f6:	00005517          	auipc	a0,0x5
    800028fa:	79250513          	addi	a0,a0,1938 # 80008088 <digits+0x38>
    800028fe:	ffffe097          	auipc	ra,0xffffe
    80002902:	c9a080e7          	jalr	-870(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002906:	0022f497          	auipc	s1,0x22f
    8000290a:	93248493          	addi	s1,s1,-1742 # 80231238 <proc+0x158>
    8000290e:	00234917          	auipc	s2,0x234
    80002912:	32a90913          	addi	s2,s2,810 # 80236c38 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002916:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002918:	00006997          	auipc	s3,0x6
    8000291c:	9a898993          	addi	s3,s3,-1624 # 800082c0 <digits+0x270>
        printf("%d <%s %s", p->pid, state, p->name);
    80002920:	00006a97          	auipc	s5,0x6
    80002924:	9a8a8a93          	addi	s5,s5,-1624 # 800082c8 <digits+0x278>
        printf("\n");
    80002928:	00005a17          	auipc	s4,0x5
    8000292c:	760a0a13          	addi	s4,s4,1888 # 80008088 <digits+0x38>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002930:	00006b97          	auipc	s7,0x6
    80002934:	aa8b8b93          	addi	s7,s7,-1368 # 800083d8 <states.0>
    80002938:	a00d                	j	8000295a <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    8000293a:	ed86a583          	lw	a1,-296(a3)
    8000293e:	8556                	mv	a0,s5
    80002940:	ffffe097          	auipc	ra,0xffffe
    80002944:	c58080e7          	jalr	-936(ra) # 80000598 <printf>
        printf("\n");
    80002948:	8552                	mv	a0,s4
    8000294a:	ffffe097          	auipc	ra,0xffffe
    8000294e:	c4e080e7          	jalr	-946(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002952:	16848493          	addi	s1,s1,360
    80002956:	03248263          	beq	s1,s2,8000297a <procdump+0x9a>
        if (p->state == UNUSED)
    8000295a:	86a6                	mv	a3,s1
    8000295c:	ec04a783          	lw	a5,-320(s1)
    80002960:	dbed                	beqz	a5,80002952 <procdump+0x72>
            state = "???";
    80002962:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002964:	fcfb6be3          	bltu	s6,a5,8000293a <procdump+0x5a>
    80002968:	02079713          	slli	a4,a5,0x20
    8000296c:	01d75793          	srli	a5,a4,0x1d
    80002970:	97de                	add	a5,a5,s7
    80002972:	6390                	ld	a2,0(a5)
    80002974:	f279                	bnez	a2,8000293a <procdump+0x5a>
            state = "???";
    80002976:	864e                	mv	a2,s3
    80002978:	b7c9                	j	8000293a <procdump+0x5a>
    }
}
    8000297a:	60a6                	ld	ra,72(sp)
    8000297c:	6406                	ld	s0,64(sp)
    8000297e:	74e2                	ld	s1,56(sp)
    80002980:	7942                	ld	s2,48(sp)
    80002982:	79a2                	ld	s3,40(sp)
    80002984:	7a02                	ld	s4,32(sp)
    80002986:	6ae2                	ld	s5,24(sp)
    80002988:	6b42                	ld	s6,16(sp)
    8000298a:	6ba2                	ld	s7,8(sp)
    8000298c:	6161                	addi	sp,sp,80
    8000298e:	8082                	ret

0000000080002990 <schedls>:

void schedls()
{
    80002990:	1141                	addi	sp,sp,-16
    80002992:	e406                	sd	ra,8(sp)
    80002994:	e022                	sd	s0,0(sp)
    80002996:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002998:	00006517          	auipc	a0,0x6
    8000299c:	94050513          	addi	a0,a0,-1728 # 800082d8 <digits+0x288>
    800029a0:	ffffe097          	auipc	ra,0xffffe
    800029a4:	bf8080e7          	jalr	-1032(ra) # 80000598 <printf>
    printf("====================================\n");
    800029a8:	00006517          	auipc	a0,0x6
    800029ac:	95850513          	addi	a0,a0,-1704 # 80008300 <digits+0x2b0>
    800029b0:	ffffe097          	auipc	ra,0xffffe
    800029b4:	be8080e7          	jalr	-1048(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800029b8:	00006717          	auipc	a4,0x6
    800029bc:	03073703          	ld	a4,48(a4) # 800089e8 <available_schedulers+0x10>
    800029c0:	00006797          	auipc	a5,0x6
    800029c4:	fc87b783          	ld	a5,-56(a5) # 80008988 <sched_pointer>
    800029c8:	04f70663          	beq	a4,a5,80002a14 <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    800029cc:	00006517          	auipc	a0,0x6
    800029d0:	96450513          	addi	a0,a0,-1692 # 80008330 <digits+0x2e0>
    800029d4:	ffffe097          	auipc	ra,0xffffe
    800029d8:	bc4080e7          	jalr	-1084(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    800029dc:	00006617          	auipc	a2,0x6
    800029e0:	01462603          	lw	a2,20(a2) # 800089f0 <available_schedulers+0x18>
    800029e4:	00006597          	auipc	a1,0x6
    800029e8:	ff458593          	addi	a1,a1,-12 # 800089d8 <available_schedulers>
    800029ec:	00006517          	auipc	a0,0x6
    800029f0:	94c50513          	addi	a0,a0,-1716 # 80008338 <digits+0x2e8>
    800029f4:	ffffe097          	auipc	ra,0xffffe
    800029f8:	ba4080e7          	jalr	-1116(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    800029fc:	00006517          	auipc	a0,0x6
    80002a00:	94450513          	addi	a0,a0,-1724 # 80008340 <digits+0x2f0>
    80002a04:	ffffe097          	auipc	ra,0xffffe
    80002a08:	b94080e7          	jalr	-1132(ra) # 80000598 <printf>
}
    80002a0c:	60a2                	ld	ra,8(sp)
    80002a0e:	6402                	ld	s0,0(sp)
    80002a10:	0141                	addi	sp,sp,16
    80002a12:	8082                	ret
            printf("[*]\t");
    80002a14:	00006517          	auipc	a0,0x6
    80002a18:	91450513          	addi	a0,a0,-1772 # 80008328 <digits+0x2d8>
    80002a1c:	ffffe097          	auipc	ra,0xffffe
    80002a20:	b7c080e7          	jalr	-1156(ra) # 80000598 <printf>
    80002a24:	bf65                	j	800029dc <schedls+0x4c>

0000000080002a26 <schedset>:

void schedset(int id)
{
    80002a26:	1141                	addi	sp,sp,-16
    80002a28:	e406                	sd	ra,8(sp)
    80002a2a:	e022                	sd	s0,0(sp)
    80002a2c:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002a2e:	e90d                	bnez	a0,80002a60 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002a30:	00006797          	auipc	a5,0x6
    80002a34:	fb87b783          	ld	a5,-72(a5) # 800089e8 <available_schedulers+0x10>
    80002a38:	00006717          	auipc	a4,0x6
    80002a3c:	f4f73823          	sd	a5,-176(a4) # 80008988 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002a40:	00006597          	auipc	a1,0x6
    80002a44:	f9858593          	addi	a1,a1,-104 # 800089d8 <available_schedulers>
    80002a48:	00006517          	auipc	a0,0x6
    80002a4c:	93850513          	addi	a0,a0,-1736 # 80008380 <digits+0x330>
    80002a50:	ffffe097          	auipc	ra,0xffffe
    80002a54:	b48080e7          	jalr	-1208(ra) # 80000598 <printf>
    80002a58:	60a2                	ld	ra,8(sp)
    80002a5a:	6402                	ld	s0,0(sp)
    80002a5c:	0141                	addi	sp,sp,16
    80002a5e:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002a60:	00006517          	auipc	a0,0x6
    80002a64:	8f850513          	addi	a0,a0,-1800 # 80008358 <digits+0x308>
    80002a68:	ffffe097          	auipc	ra,0xffffe
    80002a6c:	b30080e7          	jalr	-1232(ra) # 80000598 <printf>
        return;
    80002a70:	b7e5                	j	80002a58 <schedset+0x32>

0000000080002a72 <swtch>:
    80002a72:	00153023          	sd	ra,0(a0)
    80002a76:	00253423          	sd	sp,8(a0)
    80002a7a:	e900                	sd	s0,16(a0)
    80002a7c:	ed04                	sd	s1,24(a0)
    80002a7e:	03253023          	sd	s2,32(a0)
    80002a82:	03353423          	sd	s3,40(a0)
    80002a86:	03453823          	sd	s4,48(a0)
    80002a8a:	03553c23          	sd	s5,56(a0)
    80002a8e:	05653023          	sd	s6,64(a0)
    80002a92:	05753423          	sd	s7,72(a0)
    80002a96:	05853823          	sd	s8,80(a0)
    80002a9a:	05953c23          	sd	s9,88(a0)
    80002a9e:	07a53023          	sd	s10,96(a0)
    80002aa2:	07b53423          	sd	s11,104(a0)
    80002aa6:	0005b083          	ld	ra,0(a1)
    80002aaa:	0085b103          	ld	sp,8(a1)
    80002aae:	6980                	ld	s0,16(a1)
    80002ab0:	6d84                	ld	s1,24(a1)
    80002ab2:	0205b903          	ld	s2,32(a1)
    80002ab6:	0285b983          	ld	s3,40(a1)
    80002aba:	0305ba03          	ld	s4,48(a1)
    80002abe:	0385ba83          	ld	s5,56(a1)
    80002ac2:	0405bb03          	ld	s6,64(a1)
    80002ac6:	0485bb83          	ld	s7,72(a1)
    80002aca:	0505bc03          	ld	s8,80(a1)
    80002ace:	0585bc83          	ld	s9,88(a1)
    80002ad2:	0605bd03          	ld	s10,96(a1)
    80002ad6:	0685bd83          	ld	s11,104(a1)
    80002ada:	8082                	ret

0000000080002adc <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002adc:	1141                	addi	sp,sp,-16
    80002ade:	e406                	sd	ra,8(sp)
    80002ae0:	e022                	sd	s0,0(sp)
    80002ae2:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002ae4:	00006597          	auipc	a1,0x6
    80002ae8:	92458593          	addi	a1,a1,-1756 # 80008408 <states.0+0x30>
    80002aec:	00234517          	auipc	a0,0x234
    80002af0:	ff450513          	addi	a0,a0,-12 # 80236ae0 <tickslock>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	1c0080e7          	jalr	448(ra) # 80000cb4 <initlock>
}
    80002afc:	60a2                	ld	ra,8(sp)
    80002afe:	6402                	ld	s0,0(sp)
    80002b00:	0141                	addi	sp,sp,16
    80002b02:	8082                	ret

0000000080002b04 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002b04:	1141                	addi	sp,sp,-16
    80002b06:	e422                	sd	s0,8(sp)
    80002b08:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b0a:	00003797          	auipc	a5,0x3
    80002b0e:	62678793          	addi	a5,a5,1574 # 80006130 <kernelvec>
    80002b12:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b16:	6422                	ld	s0,8(sp)
    80002b18:	0141                	addi	sp,sp,16
    80002b1a:	8082                	ret

0000000080002b1c <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002b1c:	1141                	addi	sp,sp,-16
    80002b1e:	e406                	sd	ra,8(sp)
    80002b20:	e022                	sd	s0,0(sp)
    80002b22:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	1a0080e7          	jalr	416(ra) # 80001cc4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b2c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b30:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b32:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b36:	00004697          	auipc	a3,0x4
    80002b3a:	4ca68693          	addi	a3,a3,1226 # 80007000 <_trampoline>
    80002b3e:	00004717          	auipc	a4,0x4
    80002b42:	4c270713          	addi	a4,a4,1218 # 80007000 <_trampoline>
    80002b46:	8f15                	sub	a4,a4,a3
    80002b48:	040007b7          	lui	a5,0x4000
    80002b4c:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002b4e:	07b2                	slli	a5,a5,0xc
    80002b50:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b52:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002b56:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002b58:	18002673          	csrr	a2,satp
    80002b5c:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002b5e:	6d30                	ld	a2,88(a0)
    80002b60:	6138                	ld	a4,64(a0)
    80002b62:	6585                	lui	a1,0x1
    80002b64:	972e                	add	a4,a4,a1
    80002b66:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002b68:	6d38                	ld	a4,88(a0)
    80002b6a:	00000617          	auipc	a2,0x0
    80002b6e:	13460613          	addi	a2,a2,308 # 80002c9e <usertrap>
    80002b72:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002b74:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b76:	8612                	mv	a2,tp
    80002b78:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b7a:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002b7e:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002b82:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b86:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002b8a:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b8c:	6f18                	ld	a4,24(a4)
    80002b8e:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002b92:	6928                	ld	a0,80(a0)
    80002b94:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002b96:	00004717          	auipc	a4,0x4
    80002b9a:	50670713          	addi	a4,a4,1286 # 8000709c <userret>
    80002b9e:	8f15                	sub	a4,a4,a3
    80002ba0:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002ba2:	577d                	li	a4,-1
    80002ba4:	177e                	slli	a4,a4,0x3f
    80002ba6:	8d59                	or	a0,a0,a4
    80002ba8:	9782                	jalr	a5
}
    80002baa:	60a2                	ld	ra,8(sp)
    80002bac:	6402                	ld	s0,0(sp)
    80002bae:	0141                	addi	sp,sp,16
    80002bb0:	8082                	ret

0000000080002bb2 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002bbc:	00234497          	auipc	s1,0x234
    80002bc0:	f2448493          	addi	s1,s1,-220 # 80236ae0 <tickslock>
    80002bc4:	8526                	mv	a0,s1
    80002bc6:	ffffe097          	auipc	ra,0xffffe
    80002bca:	17e080e7          	jalr	382(ra) # 80000d44 <acquire>
  ticks++;
    80002bce:	00006517          	auipc	a0,0x6
    80002bd2:	e7250513          	addi	a0,a0,-398 # 80008a40 <ticks>
    80002bd6:	411c                	lw	a5,0(a0)
    80002bd8:	2785                	addiw	a5,a5,1
    80002bda:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002bdc:	00000097          	auipc	ra,0x0
    80002be0:	8b4080e7          	jalr	-1868(ra) # 80002490 <wakeup>
  release(&tickslock);
    80002be4:	8526                	mv	a0,s1
    80002be6:	ffffe097          	auipc	ra,0xffffe
    80002bea:	212080e7          	jalr	530(ra) # 80000df8 <release>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6105                	addi	sp,sp,32
    80002bf6:	8082                	ret

0000000080002bf8 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bf8:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002bfc:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002bfe:	0807df63          	bgez	a5,80002c9c <devintr+0xa4>
{
    80002c02:	1101                	addi	sp,sp,-32
    80002c04:	ec06                	sd	ra,24(sp)
    80002c06:	e822                	sd	s0,16(sp)
    80002c08:	e426                	sd	s1,8(sp)
    80002c0a:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002c0c:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002c10:	46a5                	li	a3,9
    80002c12:	00d70d63          	beq	a4,a3,80002c2c <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002c16:	577d                	li	a4,-1
    80002c18:	177e                	slli	a4,a4,0x3f
    80002c1a:	0705                	addi	a4,a4,1
    return 0;
    80002c1c:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002c1e:	04e78e63          	beq	a5,a4,80002c7a <devintr+0x82>
  }
}
    80002c22:	60e2                	ld	ra,24(sp)
    80002c24:	6442                	ld	s0,16(sp)
    80002c26:	64a2                	ld	s1,8(sp)
    80002c28:	6105                	addi	sp,sp,32
    80002c2a:	8082                	ret
    int irq = plic_claim();
    80002c2c:	00003097          	auipc	ra,0x3
    80002c30:	60c080e7          	jalr	1548(ra) # 80006238 <plic_claim>
    80002c34:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002c36:	47a9                	li	a5,10
    80002c38:	02f50763          	beq	a0,a5,80002c66 <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002c3c:	4785                	li	a5,1
    80002c3e:	02f50963          	beq	a0,a5,80002c70 <devintr+0x78>
    return 1;
    80002c42:	4505                	li	a0,1
    } else if(irq){
    80002c44:	dcf9                	beqz	s1,80002c22 <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002c46:	85a6                	mv	a1,s1
    80002c48:	00005517          	auipc	a0,0x5
    80002c4c:	7c850513          	addi	a0,a0,1992 # 80008410 <states.0+0x38>
    80002c50:	ffffe097          	auipc	ra,0xffffe
    80002c54:	948080e7          	jalr	-1720(ra) # 80000598 <printf>
      plic_complete(irq);
    80002c58:	8526                	mv	a0,s1
    80002c5a:	00003097          	auipc	ra,0x3
    80002c5e:	602080e7          	jalr	1538(ra) # 8000625c <plic_complete>
    return 1;
    80002c62:	4505                	li	a0,1
    80002c64:	bf7d                	j	80002c22 <devintr+0x2a>
      uartintr();
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	d40080e7          	jalr	-704(ra) # 800009a6 <uartintr>
    if(irq)
    80002c6e:	b7ed                	j	80002c58 <devintr+0x60>
      virtio_disk_intr();
    80002c70:	00004097          	auipc	ra,0x4
    80002c74:	ab2080e7          	jalr	-1358(ra) # 80006722 <virtio_disk_intr>
    if(irq)
    80002c78:	b7c5                	j	80002c58 <devintr+0x60>
    if(cpuid() == 0){
    80002c7a:	fffff097          	auipc	ra,0xfffff
    80002c7e:	01e080e7          	jalr	30(ra) # 80001c98 <cpuid>
    80002c82:	c901                	beqz	a0,80002c92 <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002c84:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002c88:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002c8a:	14479073          	csrw	sip,a5
    return 2;
    80002c8e:	4509                	li	a0,2
    80002c90:	bf49                	j	80002c22 <devintr+0x2a>
      clockintr();
    80002c92:	00000097          	auipc	ra,0x0
    80002c96:	f20080e7          	jalr	-224(ra) # 80002bb2 <clockintr>
    80002c9a:	b7ed                	j	80002c84 <devintr+0x8c>
}
    80002c9c:	8082                	ret

0000000080002c9e <usertrap>:
{
    80002c9e:	7179                	addi	sp,sp,-48
    80002ca0:	f406                	sd	ra,40(sp)
    80002ca2:	f022                	sd	s0,32(sp)
    80002ca4:	ec26                	sd	s1,24(sp)
    80002ca6:	e84a                	sd	s2,16(sp)
    80002ca8:	e44e                	sd	s3,8(sp)
    80002caa:	e052                	sd	s4,0(sp)
    80002cac:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cae:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002cb2:	1007f793          	andi	a5,a5,256
    80002cb6:	e7b9                	bnez	a5,80002d04 <usertrap+0x66>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002cb8:	00003797          	auipc	a5,0x3
    80002cbc:	47878793          	addi	a5,a5,1144 # 80006130 <kernelvec>
    80002cc0:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002cc4:	fffff097          	auipc	ra,0xfffff
    80002cc8:	000080e7          	jalr	ra # 80001cc4 <myproc>
    80002ccc:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002cce:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd0:	14102773          	csrr	a4,sepc
    80002cd4:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cd6:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002cda:	47a1                	li	a5,8
    80002cdc:	02f70c63          	beq	a4,a5,80002d14 <usertrap+0x76>
    80002ce0:	14202773          	csrr	a4,scause
  } else if (r_scause() == 15) {
    80002ce4:	47bd                	li	a5,15
    80002ce6:	06f70163          	beq	a4,a5,80002d48 <usertrap+0xaa>
  } else if((which_dev = devintr()) != 0){
    80002cea:	00000097          	auipc	ra,0x0
    80002cee:	f0e080e7          	jalr	-242(ra) # 80002bf8 <devintr>
    80002cf2:	892a                	mv	s2,a0
    80002cf4:	c169                	beqz	a0,80002db6 <usertrap+0x118>
  if(killed(p)) 
    80002cf6:	8526                	mv	a0,s1
    80002cf8:	00000097          	auipc	ra,0x0
    80002cfc:	9dc080e7          	jalr	-1572(ra) # 800026d4 <killed>
    80002d00:	cd75                	beqz	a0,80002dfc <usertrap+0x15e>
    80002d02:	a8c5                	j	80002df2 <usertrap+0x154>
    panic("usertrap: not from user mode");
    80002d04:	00005517          	auipc	a0,0x5
    80002d08:	72c50513          	addi	a0,a0,1836 # 80008430 <states.0+0x58>
    80002d0c:	ffffe097          	auipc	ra,0xffffe
    80002d10:	830080e7          	jalr	-2000(ra) # 8000053c <panic>
    if(killed(p))
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	9c0080e7          	jalr	-1600(ra) # 800026d4 <killed>
    80002d1c:	e105                	bnez	a0,80002d3c <usertrap+0x9e>
    p->trapframe->epc += 4;
    80002d1e:	6cb8                	ld	a4,88(s1)
    80002d20:	6f1c                	ld	a5,24(a4)
    80002d22:	0791                	addi	a5,a5,4
    80002d24:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d26:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002d2a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d2e:	10079073          	csrw	sstatus,a5
    syscall();
    80002d32:	00000097          	auipc	ra,0x0
    80002d36:	324080e7          	jalr	804(ra) # 80003056 <syscall>
    80002d3a:	a8a1                	j	80002d92 <usertrap+0xf4>
      exit(-1);
    80002d3c:	557d                	li	a0,-1
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	822080e7          	jalr	-2014(ra) # 80002560 <exit>
    80002d46:	bfe1                	j	80002d1e <usertrap+0x80>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d48:	143025f3          	csrr	a1,stval
    pte_t* pte = walk(p->pagetable, va, 0);
    80002d4c:	4601                	li	a2,0
    80002d4e:	6928                	ld	a0,80(a0)
    80002d50:	ffffe097          	auipc	ra,0xffffe
    80002d54:	3d2080e7          	jalr	978(ra) # 80001122 <walk>
    80002d58:	8a2a                	mv	s4,a0
    uint64 new_page = (uint64) kalloc();
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	eae080e7          	jalr	-338(ra) # 80000c08 <kalloc>
    80002d62:	892a                	mv	s2,a0
    uint64 old_page = (uint64) PTE2PA(*pte);
    80002d64:	000a3983          	ld	s3,0(s4)
    80002d68:	00a9d993          	srli	s3,s3,0xa
    80002d6c:	09b2                	slli	s3,s3,0xc
    memmove((void*) new_page, (void*) old_page, PGSIZE);
    80002d6e:	6605                	lui	a2,0x1
    80002d70:	85ce                	mv	a1,s3
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	12a080e7          	jalr	298(ra) # 80000e9c <memmove>
    *pte = PA2PTE(new_page) | PTE_V | PTE_U | PTE_W;
    80002d7a:	00c95913          	srli	s2,s2,0xc
    80002d7e:	092a                	slli	s2,s2,0xa
    80002d80:	01596913          	ori	s2,s2,21
    80002d84:	012a3023          	sd	s2,0(s4)
    kfree((void*) old_page);
    80002d88:	854e                	mv	a0,s3
    80002d8a:	ffffe097          	auipc	ra,0xffffe
    80002d8e:	d06080e7          	jalr	-762(ra) # 80000a90 <kfree>
  if(killed(p)) 
    80002d92:	8526                	mv	a0,s1
    80002d94:	00000097          	auipc	ra,0x0
    80002d98:	940080e7          	jalr	-1728(ra) # 800026d4 <killed>
    80002d9c:	e931                	bnez	a0,80002df0 <usertrap+0x152>
  usertrapret();
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	d7e080e7          	jalr	-642(ra) # 80002b1c <usertrapret>
}
    80002da6:	70a2                	ld	ra,40(sp)
    80002da8:	7402                	ld	s0,32(sp)
    80002daa:	64e2                	ld	s1,24(sp)
    80002dac:	6942                	ld	s2,16(sp)
    80002dae:	69a2                	ld	s3,8(sp)
    80002db0:	6a02                	ld	s4,0(sp)
    80002db2:	6145                	addi	sp,sp,48
    80002db4:	8082                	ret
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002db6:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002dba:	5890                	lw	a2,48(s1)
    80002dbc:	00005517          	auipc	a0,0x5
    80002dc0:	69450513          	addi	a0,a0,1684 # 80008450 <states.0+0x78>
    80002dc4:	ffffd097          	auipc	ra,0xffffd
    80002dc8:	7d4080e7          	jalr	2004(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dcc:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dd0:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dd4:	00005517          	auipc	a0,0x5
    80002dd8:	6ac50513          	addi	a0,a0,1708 # 80008480 <states.0+0xa8>
    80002ddc:	ffffd097          	auipc	ra,0xffffd
    80002de0:	7bc080e7          	jalr	1980(ra) # 80000598 <printf>
    setkilled(p);
    80002de4:	8526                	mv	a0,s1
    80002de6:	00000097          	auipc	ra,0x0
    80002dea:	8c2080e7          	jalr	-1854(ra) # 800026a8 <setkilled>
    80002dee:	b755                	j	80002d92 <usertrap+0xf4>
  if(killed(p)) 
    80002df0:	4901                	li	s2,0
    exit(-1);
    80002df2:	557d                	li	a0,-1
    80002df4:	fffff097          	auipc	ra,0xfffff
    80002df8:	76c080e7          	jalr	1900(ra) # 80002560 <exit>
  if(which_dev == 2)
    80002dfc:	4789                	li	a5,2
    80002dfe:	faf910e3          	bne	s2,a5,80002d9e <usertrap+0x100>
    yield();
    80002e02:	fffff097          	auipc	ra,0xfffff
    80002e06:	5ee080e7          	jalr	1518(ra) # 800023f0 <yield>
    80002e0a:	bf51                	j	80002d9e <usertrap+0x100>

0000000080002e0c <kerneltrap>:
{
    80002e0c:	7179                	addi	sp,sp,-48
    80002e0e:	f406                	sd	ra,40(sp)
    80002e10:	f022                	sd	s0,32(sp)
    80002e12:	ec26                	sd	s1,24(sp)
    80002e14:	e84a                	sd	s2,16(sp)
    80002e16:	e44e                	sd	s3,8(sp)
    80002e18:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e1a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e1e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e22:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e26:	1004f793          	andi	a5,s1,256
    80002e2a:	cb85                	beqz	a5,80002e5a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e2c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e30:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e32:	ef85                	bnez	a5,80002e6a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	dc4080e7          	jalr	-572(ra) # 80002bf8 <devintr>
    80002e3c:	cd1d                	beqz	a0,80002e7a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e3e:	4789                	li	a5,2
    80002e40:	06f50a63          	beq	a0,a5,80002eb4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e44:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e48:	10049073          	csrw	sstatus,s1
}
    80002e4c:	70a2                	ld	ra,40(sp)
    80002e4e:	7402                	ld	s0,32(sp)
    80002e50:	64e2                	ld	s1,24(sp)
    80002e52:	6942                	ld	s2,16(sp)
    80002e54:	69a2                	ld	s3,8(sp)
    80002e56:	6145                	addi	sp,sp,48
    80002e58:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e5a:	00005517          	auipc	a0,0x5
    80002e5e:	64650513          	addi	a0,a0,1606 # 800084a0 <states.0+0xc8>
    80002e62:	ffffd097          	auipc	ra,0xffffd
    80002e66:	6da080e7          	jalr	1754(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002e6a:	00005517          	auipc	a0,0x5
    80002e6e:	65e50513          	addi	a0,a0,1630 # 800084c8 <states.0+0xf0>
    80002e72:	ffffd097          	auipc	ra,0xffffd
    80002e76:	6ca080e7          	jalr	1738(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002e7a:	85ce                	mv	a1,s3
    80002e7c:	00005517          	auipc	a0,0x5
    80002e80:	66c50513          	addi	a0,a0,1644 # 800084e8 <states.0+0x110>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	714080e7          	jalr	1812(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e8c:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e90:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e94:	00005517          	auipc	a0,0x5
    80002e98:	66450513          	addi	a0,a0,1636 # 800084f8 <states.0+0x120>
    80002e9c:	ffffd097          	auipc	ra,0xffffd
    80002ea0:	6fc080e7          	jalr	1788(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002ea4:	00005517          	auipc	a0,0x5
    80002ea8:	66c50513          	addi	a0,a0,1644 # 80008510 <states.0+0x138>
    80002eac:	ffffd097          	auipc	ra,0xffffd
    80002eb0:	690080e7          	jalr	1680(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	e10080e7          	jalr	-496(ra) # 80001cc4 <myproc>
    80002ebc:	d541                	beqz	a0,80002e44 <kerneltrap+0x38>
    80002ebe:	fffff097          	auipc	ra,0xfffff
    80002ec2:	e06080e7          	jalr	-506(ra) # 80001cc4 <myproc>
    80002ec6:	4d18                	lw	a4,24(a0)
    80002ec8:	4791                	li	a5,4
    80002eca:	f6f71de3          	bne	a4,a5,80002e44 <kerneltrap+0x38>
    yield();
    80002ece:	fffff097          	auipc	ra,0xfffff
    80002ed2:	522080e7          	jalr	1314(ra) # 800023f0 <yield>
    80002ed6:	b7bd                	j	80002e44 <kerneltrap+0x38>

0000000080002ed8 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002ed8:	1101                	addi	sp,sp,-32
    80002eda:	ec06                	sd	ra,24(sp)
    80002edc:	e822                	sd	s0,16(sp)
    80002ede:	e426                	sd	s1,8(sp)
    80002ee0:	1000                	addi	s0,sp,32
    80002ee2:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002ee4:	fffff097          	auipc	ra,0xfffff
    80002ee8:	de0080e7          	jalr	-544(ra) # 80001cc4 <myproc>
    switch (n)
    80002eec:	4795                	li	a5,5
    80002eee:	0497e163          	bltu	a5,s1,80002f30 <argraw+0x58>
    80002ef2:	048a                	slli	s1,s1,0x2
    80002ef4:	00005717          	auipc	a4,0x5
    80002ef8:	65470713          	addi	a4,a4,1620 # 80008548 <states.0+0x170>
    80002efc:	94ba                	add	s1,s1,a4
    80002efe:	409c                	lw	a5,0(s1)
    80002f00:	97ba                	add	a5,a5,a4
    80002f02:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f04:	6d3c                	ld	a5,88(a0)
    80002f06:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6105                	addi	sp,sp,32
    80002f10:	8082                	ret
        return p->trapframe->a1;
    80002f12:	6d3c                	ld	a5,88(a0)
    80002f14:	7fa8                	ld	a0,120(a5)
    80002f16:	bfcd                	j	80002f08 <argraw+0x30>
        return p->trapframe->a2;
    80002f18:	6d3c                	ld	a5,88(a0)
    80002f1a:	63c8                	ld	a0,128(a5)
    80002f1c:	b7f5                	j	80002f08 <argraw+0x30>
        return p->trapframe->a3;
    80002f1e:	6d3c                	ld	a5,88(a0)
    80002f20:	67c8                	ld	a0,136(a5)
    80002f22:	b7dd                	j	80002f08 <argraw+0x30>
        return p->trapframe->a4;
    80002f24:	6d3c                	ld	a5,88(a0)
    80002f26:	6bc8                	ld	a0,144(a5)
    80002f28:	b7c5                	j	80002f08 <argraw+0x30>
        return p->trapframe->a5;
    80002f2a:	6d3c                	ld	a5,88(a0)
    80002f2c:	6fc8                	ld	a0,152(a5)
    80002f2e:	bfe9                	j	80002f08 <argraw+0x30>
    panic("argraw");
    80002f30:	00005517          	auipc	a0,0x5
    80002f34:	5f050513          	addi	a0,a0,1520 # 80008520 <states.0+0x148>
    80002f38:	ffffd097          	auipc	ra,0xffffd
    80002f3c:	604080e7          	jalr	1540(ra) # 8000053c <panic>

0000000080002f40 <fetchaddr>:
{
    80002f40:	1101                	addi	sp,sp,-32
    80002f42:	ec06                	sd	ra,24(sp)
    80002f44:	e822                	sd	s0,16(sp)
    80002f46:	e426                	sd	s1,8(sp)
    80002f48:	e04a                	sd	s2,0(sp)
    80002f4a:	1000                	addi	s0,sp,32
    80002f4c:	84aa                	mv	s1,a0
    80002f4e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	d74080e7          	jalr	-652(ra) # 80001cc4 <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f58:	653c                	ld	a5,72(a0)
    80002f5a:	02f4f863          	bgeu	s1,a5,80002f8a <fetchaddr+0x4a>
    80002f5e:	00848713          	addi	a4,s1,8
    80002f62:	02e7e663          	bltu	a5,a4,80002f8e <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002f66:	46a1                	li	a3,8
    80002f68:	8626                	mv	a2,s1
    80002f6a:	85ca                	mv	a1,s2
    80002f6c:	6928                	ld	a0,80(a0)
    80002f6e:	fffff097          	auipc	ra,0xfffff
    80002f72:	9ae080e7          	jalr	-1618(ra) # 8000191c <copyin>
    80002f76:	00a03533          	snez	a0,a0
    80002f7a:	40a00533          	neg	a0,a0
}
    80002f7e:	60e2                	ld	ra,24(sp)
    80002f80:	6442                	ld	s0,16(sp)
    80002f82:	64a2                	ld	s1,8(sp)
    80002f84:	6902                	ld	s2,0(sp)
    80002f86:	6105                	addi	sp,sp,32
    80002f88:	8082                	ret
        return -1;
    80002f8a:	557d                	li	a0,-1
    80002f8c:	bfcd                	j	80002f7e <fetchaddr+0x3e>
    80002f8e:	557d                	li	a0,-1
    80002f90:	b7fd                	j	80002f7e <fetchaddr+0x3e>

0000000080002f92 <fetchstr>:
{
    80002f92:	7179                	addi	sp,sp,-48
    80002f94:	f406                	sd	ra,40(sp)
    80002f96:	f022                	sd	s0,32(sp)
    80002f98:	ec26                	sd	s1,24(sp)
    80002f9a:	e84a                	sd	s2,16(sp)
    80002f9c:	e44e                	sd	s3,8(sp)
    80002f9e:	1800                	addi	s0,sp,48
    80002fa0:	892a                	mv	s2,a0
    80002fa2:	84ae                	mv	s1,a1
    80002fa4:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	d1e080e7          	jalr	-738(ra) # 80001cc4 <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002fae:	86ce                	mv	a3,s3
    80002fb0:	864a                	mv	a2,s2
    80002fb2:	85a6                	mv	a1,s1
    80002fb4:	6928                	ld	a0,80(a0)
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	9f4080e7          	jalr	-1548(ra) # 800019aa <copyinstr>
    80002fbe:	00054e63          	bltz	a0,80002fda <fetchstr+0x48>
    return strlen(buf);
    80002fc2:	8526                	mv	a0,s1
    80002fc4:	ffffe097          	auipc	ra,0xffffe
    80002fc8:	ff6080e7          	jalr	-10(ra) # 80000fba <strlen>
}
    80002fcc:	70a2                	ld	ra,40(sp)
    80002fce:	7402                	ld	s0,32(sp)
    80002fd0:	64e2                	ld	s1,24(sp)
    80002fd2:	6942                	ld	s2,16(sp)
    80002fd4:	69a2                	ld	s3,8(sp)
    80002fd6:	6145                	addi	sp,sp,48
    80002fd8:	8082                	ret
        return -1;
    80002fda:	557d                	li	a0,-1
    80002fdc:	bfc5                	j	80002fcc <fetchstr+0x3a>

0000000080002fde <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80002fde:	1101                	addi	sp,sp,-32
    80002fe0:	ec06                	sd	ra,24(sp)
    80002fe2:	e822                	sd	s0,16(sp)
    80002fe4:	e426                	sd	s1,8(sp)
    80002fe6:	1000                	addi	s0,sp,32
    80002fe8:	84ae                	mv	s1,a1
    *ip = argraw(n);
    80002fea:	00000097          	auipc	ra,0x0
    80002fee:	eee080e7          	jalr	-274(ra) # 80002ed8 <argraw>
    80002ff2:	c088                	sw	a0,0(s1)
}
    80002ff4:	60e2                	ld	ra,24(sp)
    80002ff6:	6442                	ld	s0,16(sp)
    80002ff8:	64a2                	ld	s1,8(sp)
    80002ffa:	6105                	addi	sp,sp,32
    80002ffc:	8082                	ret

0000000080002ffe <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80002ffe:	1101                	addi	sp,sp,-32
    80003000:	ec06                	sd	ra,24(sp)
    80003002:	e822                	sd	s0,16(sp)
    80003004:	e426                	sd	s1,8(sp)
    80003006:	1000                	addi	s0,sp,32
    80003008:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	ece080e7          	jalr	-306(ra) # 80002ed8 <argraw>
    80003012:	e088                	sd	a0,0(s1)
}
    80003014:	60e2                	ld	ra,24(sp)
    80003016:	6442                	ld	s0,16(sp)
    80003018:	64a2                	ld	s1,8(sp)
    8000301a:	6105                	addi	sp,sp,32
    8000301c:	8082                	ret

000000008000301e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000301e:	7179                	addi	sp,sp,-48
    80003020:	f406                	sd	ra,40(sp)
    80003022:	f022                	sd	s0,32(sp)
    80003024:	ec26                	sd	s1,24(sp)
    80003026:	e84a                	sd	s2,16(sp)
    80003028:	1800                	addi	s0,sp,48
    8000302a:	84ae                	mv	s1,a1
    8000302c:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000302e:	fd840593          	addi	a1,s0,-40
    80003032:	00000097          	auipc	ra,0x0
    80003036:	fcc080e7          	jalr	-52(ra) # 80002ffe <argaddr>
    return fetchstr(addr, buf, max);
    8000303a:	864a                	mv	a2,s2
    8000303c:	85a6                	mv	a1,s1
    8000303e:	fd843503          	ld	a0,-40(s0)
    80003042:	00000097          	auipc	ra,0x0
    80003046:	f50080e7          	jalr	-176(ra) # 80002f92 <fetchstr>
}
    8000304a:	70a2                	ld	ra,40(sp)
    8000304c:	7402                	ld	s0,32(sp)
    8000304e:	64e2                	ld	s1,24(sp)
    80003050:	6942                	ld	s2,16(sp)
    80003052:	6145                	addi	sp,sp,48
    80003054:	8082                	ret

0000000080003056 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003056:	1101                	addi	sp,sp,-32
    80003058:	ec06                	sd	ra,24(sp)
    8000305a:	e822                	sd	s0,16(sp)
    8000305c:	e426                	sd	s1,8(sp)
    8000305e:	e04a                	sd	s2,0(sp)
    80003060:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80003062:	fffff097          	auipc	ra,0xfffff
    80003066:	c62080e7          	jalr	-926(ra) # 80001cc4 <myproc>
    8000306a:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    8000306c:	05853903          	ld	s2,88(a0)
    80003070:	0a893783          	ld	a5,168(s2)
    80003074:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    80003078:	37fd                	addiw	a5,a5,-1
    8000307a:	4765                	li	a4,25
    8000307c:	00f76f63          	bltu	a4,a5,8000309a <syscall+0x44>
    80003080:	00369713          	slli	a4,a3,0x3
    80003084:	00005797          	auipc	a5,0x5
    80003088:	4dc78793          	addi	a5,a5,1244 # 80008560 <syscalls>
    8000308c:	97ba                	add	a5,a5,a4
    8000308e:	639c                	ld	a5,0(a5)
    80003090:	c789                	beqz	a5,8000309a <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    80003092:	9782                	jalr	a5
    80003094:	06a93823          	sd	a0,112(s2)
    80003098:	a839                	j	800030b6 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    8000309a:	15848613          	addi	a2,s1,344
    8000309e:	588c                	lw	a1,48(s1)
    800030a0:	00005517          	auipc	a0,0x5
    800030a4:	48850513          	addi	a0,a0,1160 # 80008528 <states.0+0x150>
    800030a8:	ffffd097          	auipc	ra,0xffffd
    800030ac:	4f0080e7          	jalr	1264(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030b0:	6cbc                	ld	a5,88(s1)
    800030b2:	577d                	li	a4,-1
    800030b4:	fbb8                	sd	a4,112(a5)
    }
}
    800030b6:	60e2                	ld	ra,24(sp)
    800030b8:	6442                	ld	s0,16(sp)
    800030ba:	64a2                	ld	s1,8(sp)
    800030bc:	6902                	ld	s2,0(sp)
    800030be:	6105                	addi	sp,sp,32
    800030c0:	8082                	ret

00000000800030c2 <sys_exit>:
extern uint64 FREE_PAGES; // kalloc.c keeps track of those
extern struct proc proc[];

uint64
sys_exit(void)
{
    800030c2:	1101                	addi	sp,sp,-32
    800030c4:	ec06                	sd	ra,24(sp)
    800030c6:	e822                	sd	s0,16(sp)
    800030c8:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800030ca:	fec40593          	addi	a1,s0,-20
    800030ce:	4501                	li	a0,0
    800030d0:	00000097          	auipc	ra,0x0
    800030d4:	f0e080e7          	jalr	-242(ra) # 80002fde <argint>
    exit(n);
    800030d8:	fec42503          	lw	a0,-20(s0)
    800030dc:	fffff097          	auipc	ra,0xfffff
    800030e0:	484080e7          	jalr	1156(ra) # 80002560 <exit>
    return 0; // not reached
}
    800030e4:	4501                	li	a0,0
    800030e6:	60e2                	ld	ra,24(sp)
    800030e8:	6442                	ld	s0,16(sp)
    800030ea:	6105                	addi	sp,sp,32
    800030ec:	8082                	ret

00000000800030ee <sys_getpid>:

uint64
sys_getpid(void)
{
    800030ee:	1141                	addi	sp,sp,-16
    800030f0:	e406                	sd	ra,8(sp)
    800030f2:	e022                	sd	s0,0(sp)
    800030f4:	0800                	addi	s0,sp,16
    return myproc()->pid;
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	bce080e7          	jalr	-1074(ra) # 80001cc4 <myproc>
}
    800030fe:	5908                	lw	a0,48(a0)
    80003100:	60a2                	ld	ra,8(sp)
    80003102:	6402                	ld	s0,0(sp)
    80003104:	0141                	addi	sp,sp,16
    80003106:	8082                	ret

0000000080003108 <sys_fork>:

uint64
sys_fork(void)
{
    80003108:	1141                	addi	sp,sp,-16
    8000310a:	e406                	sd	ra,8(sp)
    8000310c:	e022                	sd	s0,0(sp)
    8000310e:	0800                	addi	s0,sp,16
    return fork();
    80003110:	fffff097          	auipc	ra,0xfffff
    80003114:	0ba080e7          	jalr	186(ra) # 800021ca <fork>
}
    80003118:	60a2                	ld	ra,8(sp)
    8000311a:	6402                	ld	s0,0(sp)
    8000311c:	0141                	addi	sp,sp,16
    8000311e:	8082                	ret

0000000080003120 <sys_wait>:

uint64
sys_wait(void)
{
    80003120:	1101                	addi	sp,sp,-32
    80003122:	ec06                	sd	ra,24(sp)
    80003124:	e822                	sd	s0,16(sp)
    80003126:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003128:	fe840593          	addi	a1,s0,-24
    8000312c:	4501                	li	a0,0
    8000312e:	00000097          	auipc	ra,0x0
    80003132:	ed0080e7          	jalr	-304(ra) # 80002ffe <argaddr>
    return wait(p);
    80003136:	fe843503          	ld	a0,-24(s0)
    8000313a:	fffff097          	auipc	ra,0xfffff
    8000313e:	5cc080e7          	jalr	1484(ra) # 80002706 <wait>
}
    80003142:	60e2                	ld	ra,24(sp)
    80003144:	6442                	ld	s0,16(sp)
    80003146:	6105                	addi	sp,sp,32
    80003148:	8082                	ret

000000008000314a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000314a:	7179                	addi	sp,sp,-48
    8000314c:	f406                	sd	ra,40(sp)
    8000314e:	f022                	sd	s0,32(sp)
    80003150:	ec26                	sd	s1,24(sp)
    80003152:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003154:	fdc40593          	addi	a1,s0,-36
    80003158:	4501                	li	a0,0
    8000315a:	00000097          	auipc	ra,0x0
    8000315e:	e84080e7          	jalr	-380(ra) # 80002fde <argint>
    addr = myproc()->sz;
    80003162:	fffff097          	auipc	ra,0xfffff
    80003166:	b62080e7          	jalr	-1182(ra) # 80001cc4 <myproc>
    8000316a:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    8000316c:	fdc42503          	lw	a0,-36(s0)
    80003170:	fffff097          	auipc	ra,0xfffff
    80003174:	eae080e7          	jalr	-338(ra) # 8000201e <growproc>
    80003178:	00054863          	bltz	a0,80003188 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    8000317c:	8526                	mv	a0,s1
    8000317e:	70a2                	ld	ra,40(sp)
    80003180:	7402                	ld	s0,32(sp)
    80003182:	64e2                	ld	s1,24(sp)
    80003184:	6145                	addi	sp,sp,48
    80003186:	8082                	ret
        return -1;
    80003188:	54fd                	li	s1,-1
    8000318a:	bfcd                	j	8000317c <sys_sbrk+0x32>

000000008000318c <sys_sleep>:

uint64
sys_sleep(void)
{
    8000318c:	7139                	addi	sp,sp,-64
    8000318e:	fc06                	sd	ra,56(sp)
    80003190:	f822                	sd	s0,48(sp)
    80003192:	f426                	sd	s1,40(sp)
    80003194:	f04a                	sd	s2,32(sp)
    80003196:	ec4e                	sd	s3,24(sp)
    80003198:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    8000319a:	fcc40593          	addi	a1,s0,-52
    8000319e:	4501                	li	a0,0
    800031a0:	00000097          	auipc	ra,0x0
    800031a4:	e3e080e7          	jalr	-450(ra) # 80002fde <argint>
    acquire(&tickslock);
    800031a8:	00234517          	auipc	a0,0x234
    800031ac:	93850513          	addi	a0,a0,-1736 # 80236ae0 <tickslock>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	b94080e7          	jalr	-1132(ra) # 80000d44 <acquire>
    ticks0 = ticks;
    800031b8:	00006917          	auipc	s2,0x6
    800031bc:	88892903          	lw	s2,-1912(s2) # 80008a40 <ticks>
    while (ticks - ticks0 < n)
    800031c0:	fcc42783          	lw	a5,-52(s0)
    800031c4:	cf9d                	beqz	a5,80003202 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800031c6:	00234997          	auipc	s3,0x234
    800031ca:	91a98993          	addi	s3,s3,-1766 # 80236ae0 <tickslock>
    800031ce:	00006497          	auipc	s1,0x6
    800031d2:	87248493          	addi	s1,s1,-1934 # 80008a40 <ticks>
        if (killed(myproc()))
    800031d6:	fffff097          	auipc	ra,0xfffff
    800031da:	aee080e7          	jalr	-1298(ra) # 80001cc4 <myproc>
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	4f6080e7          	jalr	1270(ra) # 800026d4 <killed>
    800031e6:	ed15                	bnez	a0,80003222 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800031e8:	85ce                	mv	a1,s3
    800031ea:	8526                	mv	a0,s1
    800031ec:	fffff097          	auipc	ra,0xfffff
    800031f0:	240080e7          	jalr	576(ra) # 8000242c <sleep>
    while (ticks - ticks0 < n)
    800031f4:	409c                	lw	a5,0(s1)
    800031f6:	412787bb          	subw	a5,a5,s2
    800031fa:	fcc42703          	lw	a4,-52(s0)
    800031fe:	fce7ece3          	bltu	a5,a4,800031d6 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003202:	00234517          	auipc	a0,0x234
    80003206:	8de50513          	addi	a0,a0,-1826 # 80236ae0 <tickslock>
    8000320a:	ffffe097          	auipc	ra,0xffffe
    8000320e:	bee080e7          	jalr	-1042(ra) # 80000df8 <release>
    return 0;
    80003212:	4501                	li	a0,0
}
    80003214:	70e2                	ld	ra,56(sp)
    80003216:	7442                	ld	s0,48(sp)
    80003218:	74a2                	ld	s1,40(sp)
    8000321a:	7902                	ld	s2,32(sp)
    8000321c:	69e2                	ld	s3,24(sp)
    8000321e:	6121                	addi	sp,sp,64
    80003220:	8082                	ret
            release(&tickslock);
    80003222:	00234517          	auipc	a0,0x234
    80003226:	8be50513          	addi	a0,a0,-1858 # 80236ae0 <tickslock>
    8000322a:	ffffe097          	auipc	ra,0xffffe
    8000322e:	bce080e7          	jalr	-1074(ra) # 80000df8 <release>
            return -1;
    80003232:	557d                	li	a0,-1
    80003234:	b7c5                	j	80003214 <sys_sleep+0x88>

0000000080003236 <sys_kill>:

uint64
sys_kill(void)
{
    80003236:	1101                	addi	sp,sp,-32
    80003238:	ec06                	sd	ra,24(sp)
    8000323a:	e822                	sd	s0,16(sp)
    8000323c:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000323e:	fec40593          	addi	a1,s0,-20
    80003242:	4501                	li	a0,0
    80003244:	00000097          	auipc	ra,0x0
    80003248:	d9a080e7          	jalr	-614(ra) # 80002fde <argint>
    return kill(pid);
    8000324c:	fec42503          	lw	a0,-20(s0)
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	3e6080e7          	jalr	998(ra) # 80002636 <kill>
}
    80003258:	60e2                	ld	ra,24(sp)
    8000325a:	6442                	ld	s0,16(sp)
    8000325c:	6105                	addi	sp,sp,32
    8000325e:	8082                	ret

0000000080003260 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	e426                	sd	s1,8(sp)
    80003268:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    8000326a:	00234517          	auipc	a0,0x234
    8000326e:	87650513          	addi	a0,a0,-1930 # 80236ae0 <tickslock>
    80003272:	ffffe097          	auipc	ra,0xffffe
    80003276:	ad2080e7          	jalr	-1326(ra) # 80000d44 <acquire>
    xticks = ticks;
    8000327a:	00005497          	auipc	s1,0x5
    8000327e:	7c64a483          	lw	s1,1990(s1) # 80008a40 <ticks>
    release(&tickslock);
    80003282:	00234517          	auipc	a0,0x234
    80003286:	85e50513          	addi	a0,a0,-1954 # 80236ae0 <tickslock>
    8000328a:	ffffe097          	auipc	ra,0xffffe
    8000328e:	b6e080e7          	jalr	-1170(ra) # 80000df8 <release>
    return xticks;
}
    80003292:	02049513          	slli	a0,s1,0x20
    80003296:	9101                	srli	a0,a0,0x20
    80003298:	60e2                	ld	ra,24(sp)
    8000329a:	6442                	ld	s0,16(sp)
    8000329c:	64a2                	ld	s1,8(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <sys_ps>:

void *
sys_ps(void)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032aa:	fe042623          	sw	zero,-20(s0)
    800032ae:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032b2:	fec40593          	addi	a1,s0,-20
    800032b6:	4501                	li	a0,0
    800032b8:	00000097          	auipc	ra,0x0
    800032bc:	d26080e7          	jalr	-730(ra) # 80002fde <argint>
    argint(1, &count);
    800032c0:	fe840593          	addi	a1,s0,-24
    800032c4:	4505                	li	a0,1
    800032c6:	00000097          	auipc	ra,0x0
    800032ca:	d18080e7          	jalr	-744(ra) # 80002fde <argint>
    return ps((uint8)start, (uint8)count);
    800032ce:	fe844583          	lbu	a1,-24(s0)
    800032d2:	fec44503          	lbu	a0,-20(s0)
    800032d6:	fffff097          	auipc	ra,0xfffff
    800032da:	da4080e7          	jalr	-604(ra) # 8000207a <ps>
}
    800032de:	60e2                	ld	ra,24(sp)
    800032e0:	6442                	ld	s0,16(sp)
    800032e2:	6105                	addi	sp,sp,32
    800032e4:	8082                	ret

00000000800032e6 <sys_schedls>:

uint64 sys_schedls(void)
{
    800032e6:	1141                	addi	sp,sp,-16
    800032e8:	e406                	sd	ra,8(sp)
    800032ea:	e022                	sd	s0,0(sp)
    800032ec:	0800                	addi	s0,sp,16
    schedls();
    800032ee:	fffff097          	auipc	ra,0xfffff
    800032f2:	6a2080e7          	jalr	1698(ra) # 80002990 <schedls>
    return 0;
}
    800032f6:	4501                	li	a0,0
    800032f8:	60a2                	ld	ra,8(sp)
    800032fa:	6402                	ld	s0,0(sp)
    800032fc:	0141                	addi	sp,sp,16
    800032fe:	8082                	ret

0000000080003300 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003300:	1101                	addi	sp,sp,-32
    80003302:	ec06                	sd	ra,24(sp)
    80003304:	e822                	sd	s0,16(sp)
    80003306:	1000                	addi	s0,sp,32
    int id = 0;
    80003308:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000330c:	fec40593          	addi	a1,s0,-20
    80003310:	4501                	li	a0,0
    80003312:	00000097          	auipc	ra,0x0
    80003316:	ccc080e7          	jalr	-820(ra) # 80002fde <argint>
    schedset(id - 1);
    8000331a:	fec42503          	lw	a0,-20(s0)
    8000331e:	357d                	addiw	a0,a0,-1
    80003320:	fffff097          	auipc	ra,0xfffff
    80003324:	706080e7          	jalr	1798(ra) # 80002a26 <schedset>
    return 0;
}
    80003328:	4501                	li	a0,0
    8000332a:	60e2                	ld	ra,24(sp)
    8000332c:	6442                	ld	s0,16(sp)
    8000332e:	6105                	addi	sp,sp,32
    80003330:	8082                	ret

0000000080003332 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003332:	7179                	addi	sp,sp,-48
    80003334:	f406                	sd	ra,40(sp)
    80003336:	f022                	sd	s0,32(sp)
    80003338:	ec26                	sd	s1,24(sp)
    8000333a:	e84a                	sd	s2,16(sp)
    8000333c:	1800                	addi	s0,sp,48
    int pid = 0;
    8000333e:	fc042e23          	sw	zero,-36(s0)
    uint64 va = 0;
    80003342:	fc043823          	sd	zero,-48(s0)
    
    argint(1, &pid);
    80003346:	fdc40593          	addi	a1,s0,-36
    8000334a:	4505                	li	a0,1
    8000334c:	00000097          	auipc	ra,0x0
    80003350:	c92080e7          	jalr	-878(ra) # 80002fde <argint>
    argaddr(0, &va);
    80003354:	fd040593          	addi	a1,s0,-48
    80003358:	4501                	li	a0,0
    8000335a:	00000097          	auipc	ra,0x0
    8000335e:	ca4080e7          	jalr	-860(ra) # 80002ffe <argaddr>

    struct proc *p;
    int pidExists = 0;

    // Check if we supplied a PID
    if (pid != 0) {
    80003362:	fdc42783          	lw	a5,-36(s0)
    80003366:	c3a5                	beqz	a5,800033c6 <sys_va2pa+0x94>
        for (p = proc; p < &proc[NPROC]; p++) {
    80003368:	0022e497          	auipc	s1,0x22e
    8000336c:	d7848493          	addi	s1,s1,-648 # 802310e0 <proc>
    80003370:	00233917          	auipc	s2,0x233
    80003374:	77090913          	addi	s2,s2,1904 # 80236ae0 <tickslock>
            acquire(&p->lock);
    80003378:	8526                	mv	a0,s1
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	9ca080e7          	jalr	-1590(ra) # 80000d44 <acquire>
            if (p->pid == pid) {
    80003382:	5898                	lw	a4,48(s1)
    80003384:	fdc42783          	lw	a5,-36(s0)
    80003388:	00f70d63          	beq	a4,a5,800033a2 <sys_va2pa+0x70>
                release(&p->lock);
                pidExists = 1;
                break;
            }
            release(&p->lock);
    8000338c:	8526                	mv	a0,s1
    8000338e:	ffffe097          	auipc	ra,0xffffe
    80003392:	a6a080e7          	jalr	-1430(ra) # 80000df8 <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    80003396:	16848493          	addi	s1,s1,360
    8000339a:	fd249fe3          	bne	s1,s2,80003378 <sys_va2pa+0x46>
        }
        if (pidExists == 0) {
            return 0;
    8000339e:	4501                	li	a0,0
    800033a0:	a829                	j	800033ba <sys_va2pa+0x88>
                release(&p->lock);
    800033a2:	8526                	mv	a0,s1
    800033a4:	ffffe097          	auipc	ra,0xffffe
    800033a8:	a54080e7          	jalr	-1452(ra) # 80000df8 <release>
        p = myproc();
    }

    // Find the VA
    pagetable_t pagetable = p->pagetable;
    uint64 pa = walkaddr(pagetable, va);
    800033ac:	fd043583          	ld	a1,-48(s0)
    800033b0:	68a8                	ld	a0,80(s1)
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	e16080e7          	jalr	-490(ra) # 800011c8 <walkaddr>
        return 0;
    } else {
        return pa;
    }
    return 0;
}
    800033ba:	70a2                	ld	ra,40(sp)
    800033bc:	7402                	ld	s0,32(sp)
    800033be:	64e2                	ld	s1,24(sp)
    800033c0:	6942                	ld	s2,16(sp)
    800033c2:	6145                	addi	sp,sp,48
    800033c4:	8082                	ret
        p = myproc();
    800033c6:	fffff097          	auipc	ra,0xfffff
    800033ca:	8fe080e7          	jalr	-1794(ra) # 80001cc4 <myproc>
    800033ce:	84aa                	mv	s1,a0
    800033d0:	bff1                	j	800033ac <sys_va2pa+0x7a>

00000000800033d2 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    800033d2:	1141                	addi	sp,sp,-16
    800033d4:	e406                	sd	ra,8(sp)
    800033d6:	e022                	sd	s0,0(sp)
    800033d8:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    800033da:	00005597          	auipc	a1,0x5
    800033de:	63e5b583          	ld	a1,1598(a1) # 80008a18 <FREE_PAGES>
    800033e2:	00005517          	auipc	a0,0x5
    800033e6:	15e50513          	addi	a0,a0,350 # 80008540 <states.0+0x168>
    800033ea:	ffffd097          	auipc	ra,0xffffd
    800033ee:	1ae080e7          	jalr	430(ra) # 80000598 <printf>
    return 0;
    800033f2:	4501                	li	a0,0
    800033f4:	60a2                	ld	ra,8(sp)
    800033f6:	6402                	ld	s0,0(sp)
    800033f8:	0141                	addi	sp,sp,16
    800033fa:	8082                	ret

00000000800033fc <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    800033fc:	7179                	addi	sp,sp,-48
    800033fe:	f406                	sd	ra,40(sp)
    80003400:	f022                	sd	s0,32(sp)
    80003402:	ec26                	sd	s1,24(sp)
    80003404:	e84a                	sd	s2,16(sp)
    80003406:	e44e                	sd	s3,8(sp)
    80003408:	e052                	sd	s4,0(sp)
    8000340a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000340c:	00005597          	auipc	a1,0x5
    80003410:	22c58593          	addi	a1,a1,556 # 80008638 <syscalls+0xd8>
    80003414:	00233517          	auipc	a0,0x233
    80003418:	6e450513          	addi	a0,a0,1764 # 80236af8 <bcache>
    8000341c:	ffffe097          	auipc	ra,0xffffe
    80003420:	898080e7          	jalr	-1896(ra) # 80000cb4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003424:	0023b797          	auipc	a5,0x23b
    80003428:	6d478793          	addi	a5,a5,1748 # 8023eaf8 <bcache+0x8000>
    8000342c:	0023c717          	auipc	a4,0x23c
    80003430:	93470713          	addi	a4,a4,-1740 # 8023ed60 <bcache+0x8268>
    80003434:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003438:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000343c:	00233497          	auipc	s1,0x233
    80003440:	6d448493          	addi	s1,s1,1748 # 80236b10 <bcache+0x18>
    b->next = bcache.head.next;
    80003444:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003446:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003448:	00005a17          	auipc	s4,0x5
    8000344c:	1f8a0a13          	addi	s4,s4,504 # 80008640 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003450:	2b893783          	ld	a5,696(s2)
    80003454:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003456:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000345a:	85d2                	mv	a1,s4
    8000345c:	01048513          	addi	a0,s1,16
    80003460:	00001097          	auipc	ra,0x1
    80003464:	496080e7          	jalr	1174(ra) # 800048f6 <initsleeplock>
    bcache.head.next->prev = b;
    80003468:	2b893783          	ld	a5,696(s2)
    8000346c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000346e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003472:	45848493          	addi	s1,s1,1112
    80003476:	fd349de3          	bne	s1,s3,80003450 <binit+0x54>
  }
}
    8000347a:	70a2                	ld	ra,40(sp)
    8000347c:	7402                	ld	s0,32(sp)
    8000347e:	64e2                	ld	s1,24(sp)
    80003480:	6942                	ld	s2,16(sp)
    80003482:	69a2                	ld	s3,8(sp)
    80003484:	6a02                	ld	s4,0(sp)
    80003486:	6145                	addi	sp,sp,48
    80003488:	8082                	ret

000000008000348a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	1800                	addi	s0,sp,48
    80003498:	892a                	mv	s2,a0
    8000349a:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    8000349c:	00233517          	auipc	a0,0x233
    800034a0:	65c50513          	addi	a0,a0,1628 # 80236af8 <bcache>
    800034a4:	ffffe097          	auipc	ra,0xffffe
    800034a8:	8a0080e7          	jalr	-1888(ra) # 80000d44 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800034ac:	0023c497          	auipc	s1,0x23c
    800034b0:	9044b483          	ld	s1,-1788(s1) # 8023edb0 <bcache+0x82b8>
    800034b4:	0023c797          	auipc	a5,0x23c
    800034b8:	8ac78793          	addi	a5,a5,-1876 # 8023ed60 <bcache+0x8268>
    800034bc:	02f48f63          	beq	s1,a5,800034fa <bread+0x70>
    800034c0:	873e                	mv	a4,a5
    800034c2:	a021                	j	800034ca <bread+0x40>
    800034c4:	68a4                	ld	s1,80(s1)
    800034c6:	02e48a63          	beq	s1,a4,800034fa <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800034ca:	449c                	lw	a5,8(s1)
    800034cc:	ff279ce3          	bne	a5,s2,800034c4 <bread+0x3a>
    800034d0:	44dc                	lw	a5,12(s1)
    800034d2:	ff3799e3          	bne	a5,s3,800034c4 <bread+0x3a>
      b->refcnt++;
    800034d6:	40bc                	lw	a5,64(s1)
    800034d8:	2785                	addiw	a5,a5,1
    800034da:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034dc:	00233517          	auipc	a0,0x233
    800034e0:	61c50513          	addi	a0,a0,1564 # 80236af8 <bcache>
    800034e4:	ffffe097          	auipc	ra,0xffffe
    800034e8:	914080e7          	jalr	-1772(ra) # 80000df8 <release>
      acquiresleep(&b->lock);
    800034ec:	01048513          	addi	a0,s1,16
    800034f0:	00001097          	auipc	ra,0x1
    800034f4:	440080e7          	jalr	1088(ra) # 80004930 <acquiresleep>
      return b;
    800034f8:	a8b9                	j	80003556 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800034fa:	0023c497          	auipc	s1,0x23c
    800034fe:	8ae4b483          	ld	s1,-1874(s1) # 8023eda8 <bcache+0x82b0>
    80003502:	0023c797          	auipc	a5,0x23c
    80003506:	85e78793          	addi	a5,a5,-1954 # 8023ed60 <bcache+0x8268>
    8000350a:	00f48863          	beq	s1,a5,8000351a <bread+0x90>
    8000350e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003510:	40bc                	lw	a5,64(s1)
    80003512:	cf81                	beqz	a5,8000352a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003514:	64a4                	ld	s1,72(s1)
    80003516:	fee49de3          	bne	s1,a4,80003510 <bread+0x86>
  panic("bget: no buffers");
    8000351a:	00005517          	auipc	a0,0x5
    8000351e:	12e50513          	addi	a0,a0,302 # 80008648 <syscalls+0xe8>
    80003522:	ffffd097          	auipc	ra,0xffffd
    80003526:	01a080e7          	jalr	26(ra) # 8000053c <panic>
      b->dev = dev;
    8000352a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000352e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003532:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003536:	4785                	li	a5,1
    80003538:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000353a:	00233517          	auipc	a0,0x233
    8000353e:	5be50513          	addi	a0,a0,1470 # 80236af8 <bcache>
    80003542:	ffffe097          	auipc	ra,0xffffe
    80003546:	8b6080e7          	jalr	-1866(ra) # 80000df8 <release>
      acquiresleep(&b->lock);
    8000354a:	01048513          	addi	a0,s1,16
    8000354e:	00001097          	auipc	ra,0x1
    80003552:	3e2080e7          	jalr	994(ra) # 80004930 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003556:	409c                	lw	a5,0(s1)
    80003558:	cb89                	beqz	a5,8000356a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000355a:	8526                	mv	a0,s1
    8000355c:	70a2                	ld	ra,40(sp)
    8000355e:	7402                	ld	s0,32(sp)
    80003560:	64e2                	ld	s1,24(sp)
    80003562:	6942                	ld	s2,16(sp)
    80003564:	69a2                	ld	s3,8(sp)
    80003566:	6145                	addi	sp,sp,48
    80003568:	8082                	ret
    virtio_disk_rw(b, 0);
    8000356a:	4581                	li	a1,0
    8000356c:	8526                	mv	a0,s1
    8000356e:	00003097          	auipc	ra,0x3
    80003572:	f84080e7          	jalr	-124(ra) # 800064f2 <virtio_disk_rw>
    b->valid = 1;
    80003576:	4785                	li	a5,1
    80003578:	c09c                	sw	a5,0(s1)
  return b;
    8000357a:	b7c5                	j	8000355a <bread+0xd0>

000000008000357c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000357c:	1101                	addi	sp,sp,-32
    8000357e:	ec06                	sd	ra,24(sp)
    80003580:	e822                	sd	s0,16(sp)
    80003582:	e426                	sd	s1,8(sp)
    80003584:	1000                	addi	s0,sp,32
    80003586:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003588:	0541                	addi	a0,a0,16
    8000358a:	00001097          	auipc	ra,0x1
    8000358e:	440080e7          	jalr	1088(ra) # 800049ca <holdingsleep>
    80003592:	cd01                	beqz	a0,800035aa <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003594:	4585                	li	a1,1
    80003596:	8526                	mv	a0,s1
    80003598:	00003097          	auipc	ra,0x3
    8000359c:	f5a080e7          	jalr	-166(ra) # 800064f2 <virtio_disk_rw>
}
    800035a0:	60e2                	ld	ra,24(sp)
    800035a2:	6442                	ld	s0,16(sp)
    800035a4:	64a2                	ld	s1,8(sp)
    800035a6:	6105                	addi	sp,sp,32
    800035a8:	8082                	ret
    panic("bwrite");
    800035aa:	00005517          	auipc	a0,0x5
    800035ae:	0b650513          	addi	a0,a0,182 # 80008660 <syscalls+0x100>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	f8a080e7          	jalr	-118(ra) # 8000053c <panic>

00000000800035ba <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800035ba:	1101                	addi	sp,sp,-32
    800035bc:	ec06                	sd	ra,24(sp)
    800035be:	e822                	sd	s0,16(sp)
    800035c0:	e426                	sd	s1,8(sp)
    800035c2:	e04a                	sd	s2,0(sp)
    800035c4:	1000                	addi	s0,sp,32
    800035c6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800035c8:	01050913          	addi	s2,a0,16
    800035cc:	854a                	mv	a0,s2
    800035ce:	00001097          	auipc	ra,0x1
    800035d2:	3fc080e7          	jalr	1020(ra) # 800049ca <holdingsleep>
    800035d6:	c925                	beqz	a0,80003646 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800035d8:	854a                	mv	a0,s2
    800035da:	00001097          	auipc	ra,0x1
    800035de:	3ac080e7          	jalr	940(ra) # 80004986 <releasesleep>

  acquire(&bcache.lock);
    800035e2:	00233517          	auipc	a0,0x233
    800035e6:	51650513          	addi	a0,a0,1302 # 80236af8 <bcache>
    800035ea:	ffffd097          	auipc	ra,0xffffd
    800035ee:	75a080e7          	jalr	1882(ra) # 80000d44 <acquire>
  b->refcnt--;
    800035f2:	40bc                	lw	a5,64(s1)
    800035f4:	37fd                	addiw	a5,a5,-1
    800035f6:	0007871b          	sext.w	a4,a5
    800035fa:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800035fc:	e71d                	bnez	a4,8000362a <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800035fe:	68b8                	ld	a4,80(s1)
    80003600:	64bc                	ld	a5,72(s1)
    80003602:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003604:	68b8                	ld	a4,80(s1)
    80003606:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003608:	0023b797          	auipc	a5,0x23b
    8000360c:	4f078793          	addi	a5,a5,1264 # 8023eaf8 <bcache+0x8000>
    80003610:	2b87b703          	ld	a4,696(a5)
    80003614:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003616:	0023b717          	auipc	a4,0x23b
    8000361a:	74a70713          	addi	a4,a4,1866 # 8023ed60 <bcache+0x8268>
    8000361e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003620:	2b87b703          	ld	a4,696(a5)
    80003624:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003626:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000362a:	00233517          	auipc	a0,0x233
    8000362e:	4ce50513          	addi	a0,a0,1230 # 80236af8 <bcache>
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	7c6080e7          	jalr	1990(ra) # 80000df8 <release>
}
    8000363a:	60e2                	ld	ra,24(sp)
    8000363c:	6442                	ld	s0,16(sp)
    8000363e:	64a2                	ld	s1,8(sp)
    80003640:	6902                	ld	s2,0(sp)
    80003642:	6105                	addi	sp,sp,32
    80003644:	8082                	ret
    panic("brelse");
    80003646:	00005517          	auipc	a0,0x5
    8000364a:	02250513          	addi	a0,a0,34 # 80008668 <syscalls+0x108>
    8000364e:	ffffd097          	auipc	ra,0xffffd
    80003652:	eee080e7          	jalr	-274(ra) # 8000053c <panic>

0000000080003656 <bpin>:

void
bpin(struct buf *b) {
    80003656:	1101                	addi	sp,sp,-32
    80003658:	ec06                	sd	ra,24(sp)
    8000365a:	e822                	sd	s0,16(sp)
    8000365c:	e426                	sd	s1,8(sp)
    8000365e:	1000                	addi	s0,sp,32
    80003660:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003662:	00233517          	auipc	a0,0x233
    80003666:	49650513          	addi	a0,a0,1174 # 80236af8 <bcache>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	6da080e7          	jalr	1754(ra) # 80000d44 <acquire>
  b->refcnt++;
    80003672:	40bc                	lw	a5,64(s1)
    80003674:	2785                	addiw	a5,a5,1
    80003676:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003678:	00233517          	auipc	a0,0x233
    8000367c:	48050513          	addi	a0,a0,1152 # 80236af8 <bcache>
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	778080e7          	jalr	1912(ra) # 80000df8 <release>
}
    80003688:	60e2                	ld	ra,24(sp)
    8000368a:	6442                	ld	s0,16(sp)
    8000368c:	64a2                	ld	s1,8(sp)
    8000368e:	6105                	addi	sp,sp,32
    80003690:	8082                	ret

0000000080003692 <bunpin>:

void
bunpin(struct buf *b) {
    80003692:	1101                	addi	sp,sp,-32
    80003694:	ec06                	sd	ra,24(sp)
    80003696:	e822                	sd	s0,16(sp)
    80003698:	e426                	sd	s1,8(sp)
    8000369a:	1000                	addi	s0,sp,32
    8000369c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000369e:	00233517          	auipc	a0,0x233
    800036a2:	45a50513          	addi	a0,a0,1114 # 80236af8 <bcache>
    800036a6:	ffffd097          	auipc	ra,0xffffd
    800036aa:	69e080e7          	jalr	1694(ra) # 80000d44 <acquire>
  b->refcnt--;
    800036ae:	40bc                	lw	a5,64(s1)
    800036b0:	37fd                	addiw	a5,a5,-1
    800036b2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800036b4:	00233517          	auipc	a0,0x233
    800036b8:	44450513          	addi	a0,a0,1092 # 80236af8 <bcache>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	73c080e7          	jalr	1852(ra) # 80000df8 <release>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret

00000000800036ce <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800036ce:	1101                	addi	sp,sp,-32
    800036d0:	ec06                	sd	ra,24(sp)
    800036d2:	e822                	sd	s0,16(sp)
    800036d4:	e426                	sd	s1,8(sp)
    800036d6:	e04a                	sd	s2,0(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800036dc:	00d5d59b          	srliw	a1,a1,0xd
    800036e0:	0023c797          	auipc	a5,0x23c
    800036e4:	af47a783          	lw	a5,-1292(a5) # 8023f1d4 <sb+0x1c>
    800036e8:	9dbd                	addw	a1,a1,a5
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	da0080e7          	jalr	-608(ra) # 8000348a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800036f2:	0074f713          	andi	a4,s1,7
    800036f6:	4785                	li	a5,1
    800036f8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800036fc:	14ce                	slli	s1,s1,0x33
    800036fe:	90d9                	srli	s1,s1,0x36
    80003700:	00950733          	add	a4,a0,s1
    80003704:	05874703          	lbu	a4,88(a4)
    80003708:	00e7f6b3          	and	a3,a5,a4
    8000370c:	c69d                	beqz	a3,8000373a <bfree+0x6c>
    8000370e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003710:	94aa                	add	s1,s1,a0
    80003712:	fff7c793          	not	a5,a5
    80003716:	8f7d                	and	a4,a4,a5
    80003718:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000371c:	00001097          	auipc	ra,0x1
    80003720:	0f6080e7          	jalr	246(ra) # 80004812 <log_write>
  brelse(bp);
    80003724:	854a                	mv	a0,s2
    80003726:	00000097          	auipc	ra,0x0
    8000372a:	e94080e7          	jalr	-364(ra) # 800035ba <brelse>
}
    8000372e:	60e2                	ld	ra,24(sp)
    80003730:	6442                	ld	s0,16(sp)
    80003732:	64a2                	ld	s1,8(sp)
    80003734:	6902                	ld	s2,0(sp)
    80003736:	6105                	addi	sp,sp,32
    80003738:	8082                	ret
    panic("freeing free block");
    8000373a:	00005517          	auipc	a0,0x5
    8000373e:	f3650513          	addi	a0,a0,-202 # 80008670 <syscalls+0x110>
    80003742:	ffffd097          	auipc	ra,0xffffd
    80003746:	dfa080e7          	jalr	-518(ra) # 8000053c <panic>

000000008000374a <balloc>:
{
    8000374a:	711d                	addi	sp,sp,-96
    8000374c:	ec86                	sd	ra,88(sp)
    8000374e:	e8a2                	sd	s0,80(sp)
    80003750:	e4a6                	sd	s1,72(sp)
    80003752:	e0ca                	sd	s2,64(sp)
    80003754:	fc4e                	sd	s3,56(sp)
    80003756:	f852                	sd	s4,48(sp)
    80003758:	f456                	sd	s5,40(sp)
    8000375a:	f05a                	sd	s6,32(sp)
    8000375c:	ec5e                	sd	s7,24(sp)
    8000375e:	e862                	sd	s8,16(sp)
    80003760:	e466                	sd	s9,8(sp)
    80003762:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003764:	0023c797          	auipc	a5,0x23c
    80003768:	a587a783          	lw	a5,-1448(a5) # 8023f1bc <sb+0x4>
    8000376c:	cff5                	beqz	a5,80003868 <balloc+0x11e>
    8000376e:	8baa                	mv	s7,a0
    80003770:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003772:	0023cb17          	auipc	s6,0x23c
    80003776:	a46b0b13          	addi	s6,s6,-1466 # 8023f1b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000377c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000377e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003780:	6c89                	lui	s9,0x2
    80003782:	a061                	j	8000380a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003784:	97ca                	add	a5,a5,s2
    80003786:	8e55                	or	a2,a2,a3
    80003788:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000378c:	854a                	mv	a0,s2
    8000378e:	00001097          	auipc	ra,0x1
    80003792:	084080e7          	jalr	132(ra) # 80004812 <log_write>
        brelse(bp);
    80003796:	854a                	mv	a0,s2
    80003798:	00000097          	auipc	ra,0x0
    8000379c:	e22080e7          	jalr	-478(ra) # 800035ba <brelse>
  bp = bread(dev, bno);
    800037a0:	85a6                	mv	a1,s1
    800037a2:	855e                	mv	a0,s7
    800037a4:	00000097          	auipc	ra,0x0
    800037a8:	ce6080e7          	jalr	-794(ra) # 8000348a <bread>
    800037ac:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800037ae:	40000613          	li	a2,1024
    800037b2:	4581                	li	a1,0
    800037b4:	05850513          	addi	a0,a0,88
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	688080e7          	jalr	1672(ra) # 80000e40 <memset>
  log_write(bp);
    800037c0:	854a                	mv	a0,s2
    800037c2:	00001097          	auipc	ra,0x1
    800037c6:	050080e7          	jalr	80(ra) # 80004812 <log_write>
  brelse(bp);
    800037ca:	854a                	mv	a0,s2
    800037cc:	00000097          	auipc	ra,0x0
    800037d0:	dee080e7          	jalr	-530(ra) # 800035ba <brelse>
}
    800037d4:	8526                	mv	a0,s1
    800037d6:	60e6                	ld	ra,88(sp)
    800037d8:	6446                	ld	s0,80(sp)
    800037da:	64a6                	ld	s1,72(sp)
    800037dc:	6906                	ld	s2,64(sp)
    800037de:	79e2                	ld	s3,56(sp)
    800037e0:	7a42                	ld	s4,48(sp)
    800037e2:	7aa2                	ld	s5,40(sp)
    800037e4:	7b02                	ld	s6,32(sp)
    800037e6:	6be2                	ld	s7,24(sp)
    800037e8:	6c42                	ld	s8,16(sp)
    800037ea:	6ca2                	ld	s9,8(sp)
    800037ec:	6125                	addi	sp,sp,96
    800037ee:	8082                	ret
    brelse(bp);
    800037f0:	854a                	mv	a0,s2
    800037f2:	00000097          	auipc	ra,0x0
    800037f6:	dc8080e7          	jalr	-568(ra) # 800035ba <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800037fa:	015c87bb          	addw	a5,s9,s5
    800037fe:	00078a9b          	sext.w	s5,a5
    80003802:	004b2703          	lw	a4,4(s6)
    80003806:	06eaf163          	bgeu	s5,a4,80003868 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000380a:	41fad79b          	sraiw	a5,s5,0x1f
    8000380e:	0137d79b          	srliw	a5,a5,0x13
    80003812:	015787bb          	addw	a5,a5,s5
    80003816:	40d7d79b          	sraiw	a5,a5,0xd
    8000381a:	01cb2583          	lw	a1,28(s6)
    8000381e:	9dbd                	addw	a1,a1,a5
    80003820:	855e                	mv	a0,s7
    80003822:	00000097          	auipc	ra,0x0
    80003826:	c68080e7          	jalr	-920(ra) # 8000348a <bread>
    8000382a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000382c:	004b2503          	lw	a0,4(s6)
    80003830:	000a849b          	sext.w	s1,s5
    80003834:	8762                	mv	a4,s8
    80003836:	faa4fde3          	bgeu	s1,a0,800037f0 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000383a:	00777693          	andi	a3,a4,7
    8000383e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003842:	41f7579b          	sraiw	a5,a4,0x1f
    80003846:	01d7d79b          	srliw	a5,a5,0x1d
    8000384a:	9fb9                	addw	a5,a5,a4
    8000384c:	4037d79b          	sraiw	a5,a5,0x3
    80003850:	00f90633          	add	a2,s2,a5
    80003854:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    80003858:	00c6f5b3          	and	a1,a3,a2
    8000385c:	d585                	beqz	a1,80003784 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000385e:	2705                	addiw	a4,a4,1
    80003860:	2485                	addiw	s1,s1,1
    80003862:	fd471ae3          	bne	a4,s4,80003836 <balloc+0xec>
    80003866:	b769                	j	800037f0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003868:	00005517          	auipc	a0,0x5
    8000386c:	e2050513          	addi	a0,a0,-480 # 80008688 <syscalls+0x128>
    80003870:	ffffd097          	auipc	ra,0xffffd
    80003874:	d28080e7          	jalr	-728(ra) # 80000598 <printf>
  return 0;
    80003878:	4481                	li	s1,0
    8000387a:	bfa9                	j	800037d4 <balloc+0x8a>

000000008000387c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000387c:	7179                	addi	sp,sp,-48
    8000387e:	f406                	sd	ra,40(sp)
    80003880:	f022                	sd	s0,32(sp)
    80003882:	ec26                	sd	s1,24(sp)
    80003884:	e84a                	sd	s2,16(sp)
    80003886:	e44e                	sd	s3,8(sp)
    80003888:	e052                	sd	s4,0(sp)
    8000388a:	1800                	addi	s0,sp,48
    8000388c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000388e:	47ad                	li	a5,11
    80003890:	02b7e863          	bltu	a5,a1,800038c0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003894:	02059793          	slli	a5,a1,0x20
    80003898:	01e7d593          	srli	a1,a5,0x1e
    8000389c:	00b504b3          	add	s1,a0,a1
    800038a0:	0504a903          	lw	s2,80(s1)
    800038a4:	06091e63          	bnez	s2,80003920 <bmap+0xa4>
      addr = balloc(ip->dev);
    800038a8:	4108                	lw	a0,0(a0)
    800038aa:	00000097          	auipc	ra,0x0
    800038ae:	ea0080e7          	jalr	-352(ra) # 8000374a <balloc>
    800038b2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038b6:	06090563          	beqz	s2,80003920 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800038ba:	0524a823          	sw	s2,80(s1)
    800038be:	a08d                	j	80003920 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800038c0:	ff45849b          	addiw	s1,a1,-12
    800038c4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800038c8:	0ff00793          	li	a5,255
    800038cc:	08e7e563          	bltu	a5,a4,80003956 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800038d0:	08052903          	lw	s2,128(a0)
    800038d4:	00091d63          	bnez	s2,800038ee <bmap+0x72>
      addr = balloc(ip->dev);
    800038d8:	4108                	lw	a0,0(a0)
    800038da:	00000097          	auipc	ra,0x0
    800038de:	e70080e7          	jalr	-400(ra) # 8000374a <balloc>
    800038e2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800038e6:	02090d63          	beqz	s2,80003920 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800038ea:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800038ee:	85ca                	mv	a1,s2
    800038f0:	0009a503          	lw	a0,0(s3)
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	b96080e7          	jalr	-1130(ra) # 8000348a <bread>
    800038fc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800038fe:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003902:	02049713          	slli	a4,s1,0x20
    80003906:	01e75593          	srli	a1,a4,0x1e
    8000390a:	00b784b3          	add	s1,a5,a1
    8000390e:	0004a903          	lw	s2,0(s1)
    80003912:	02090063          	beqz	s2,80003932 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003916:	8552                	mv	a0,s4
    80003918:	00000097          	auipc	ra,0x0
    8000391c:	ca2080e7          	jalr	-862(ra) # 800035ba <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003920:	854a                	mv	a0,s2
    80003922:	70a2                	ld	ra,40(sp)
    80003924:	7402                	ld	s0,32(sp)
    80003926:	64e2                	ld	s1,24(sp)
    80003928:	6942                	ld	s2,16(sp)
    8000392a:	69a2                	ld	s3,8(sp)
    8000392c:	6a02                	ld	s4,0(sp)
    8000392e:	6145                	addi	sp,sp,48
    80003930:	8082                	ret
      addr = balloc(ip->dev);
    80003932:	0009a503          	lw	a0,0(s3)
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	e14080e7          	jalr	-492(ra) # 8000374a <balloc>
    8000393e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003942:	fc090ae3          	beqz	s2,80003916 <bmap+0x9a>
        a[bn] = addr;
    80003946:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000394a:	8552                	mv	a0,s4
    8000394c:	00001097          	auipc	ra,0x1
    80003950:	ec6080e7          	jalr	-314(ra) # 80004812 <log_write>
    80003954:	b7c9                	j	80003916 <bmap+0x9a>
  panic("bmap: out of range");
    80003956:	00005517          	auipc	a0,0x5
    8000395a:	d4a50513          	addi	a0,a0,-694 # 800086a0 <syscalls+0x140>
    8000395e:	ffffd097          	auipc	ra,0xffffd
    80003962:	bde080e7          	jalr	-1058(ra) # 8000053c <panic>

0000000080003966 <iget>:
{
    80003966:	7179                	addi	sp,sp,-48
    80003968:	f406                	sd	ra,40(sp)
    8000396a:	f022                	sd	s0,32(sp)
    8000396c:	ec26                	sd	s1,24(sp)
    8000396e:	e84a                	sd	s2,16(sp)
    80003970:	e44e                	sd	s3,8(sp)
    80003972:	e052                	sd	s4,0(sp)
    80003974:	1800                	addi	s0,sp,48
    80003976:	89aa                	mv	s3,a0
    80003978:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000397a:	0023c517          	auipc	a0,0x23c
    8000397e:	85e50513          	addi	a0,a0,-1954 # 8023f1d8 <itable>
    80003982:	ffffd097          	auipc	ra,0xffffd
    80003986:	3c2080e7          	jalr	962(ra) # 80000d44 <acquire>
  empty = 0;
    8000398a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000398c:	0023c497          	auipc	s1,0x23c
    80003990:	86448493          	addi	s1,s1,-1948 # 8023f1f0 <itable+0x18>
    80003994:	0023d697          	auipc	a3,0x23d
    80003998:	2ec68693          	addi	a3,a3,748 # 80240c80 <log>
    8000399c:	a039                	j	800039aa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000399e:	02090b63          	beqz	s2,800039d4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800039a2:	08848493          	addi	s1,s1,136
    800039a6:	02d48a63          	beq	s1,a3,800039da <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800039aa:	449c                	lw	a5,8(s1)
    800039ac:	fef059e3          	blez	a5,8000399e <iget+0x38>
    800039b0:	4098                	lw	a4,0(s1)
    800039b2:	ff3716e3          	bne	a4,s3,8000399e <iget+0x38>
    800039b6:	40d8                	lw	a4,4(s1)
    800039b8:	ff4713e3          	bne	a4,s4,8000399e <iget+0x38>
      ip->ref++;
    800039bc:	2785                	addiw	a5,a5,1
    800039be:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800039c0:	0023c517          	auipc	a0,0x23c
    800039c4:	81850513          	addi	a0,a0,-2024 # 8023f1d8 <itable>
    800039c8:	ffffd097          	auipc	ra,0xffffd
    800039cc:	430080e7          	jalr	1072(ra) # 80000df8 <release>
      return ip;
    800039d0:	8926                	mv	s2,s1
    800039d2:	a03d                	j	80003a00 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800039d4:	f7f9                	bnez	a5,800039a2 <iget+0x3c>
    800039d6:	8926                	mv	s2,s1
    800039d8:	b7e9                	j	800039a2 <iget+0x3c>
  if(empty == 0)
    800039da:	02090c63          	beqz	s2,80003a12 <iget+0xac>
  ip->dev = dev;
    800039de:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800039e2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800039e6:	4785                	li	a5,1
    800039e8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800039ec:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800039f0:	0023b517          	auipc	a0,0x23b
    800039f4:	7e850513          	addi	a0,a0,2024 # 8023f1d8 <itable>
    800039f8:	ffffd097          	auipc	ra,0xffffd
    800039fc:	400080e7          	jalr	1024(ra) # 80000df8 <release>
}
    80003a00:	854a                	mv	a0,s2
    80003a02:	70a2                	ld	ra,40(sp)
    80003a04:	7402                	ld	s0,32(sp)
    80003a06:	64e2                	ld	s1,24(sp)
    80003a08:	6942                	ld	s2,16(sp)
    80003a0a:	69a2                	ld	s3,8(sp)
    80003a0c:	6a02                	ld	s4,0(sp)
    80003a0e:	6145                	addi	sp,sp,48
    80003a10:	8082                	ret
    panic("iget: no inodes");
    80003a12:	00005517          	auipc	a0,0x5
    80003a16:	ca650513          	addi	a0,a0,-858 # 800086b8 <syscalls+0x158>
    80003a1a:	ffffd097          	auipc	ra,0xffffd
    80003a1e:	b22080e7          	jalr	-1246(ra) # 8000053c <panic>

0000000080003a22 <fsinit>:
fsinit(int dev) {
    80003a22:	7179                	addi	sp,sp,-48
    80003a24:	f406                	sd	ra,40(sp)
    80003a26:	f022                	sd	s0,32(sp)
    80003a28:	ec26                	sd	s1,24(sp)
    80003a2a:	e84a                	sd	s2,16(sp)
    80003a2c:	e44e                	sd	s3,8(sp)
    80003a2e:	1800                	addi	s0,sp,48
    80003a30:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003a32:	4585                	li	a1,1
    80003a34:	00000097          	auipc	ra,0x0
    80003a38:	a56080e7          	jalr	-1450(ra) # 8000348a <bread>
    80003a3c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003a3e:	0023b997          	auipc	s3,0x23b
    80003a42:	77a98993          	addi	s3,s3,1914 # 8023f1b8 <sb>
    80003a46:	02000613          	li	a2,32
    80003a4a:	05850593          	addi	a1,a0,88
    80003a4e:	854e                	mv	a0,s3
    80003a50:	ffffd097          	auipc	ra,0xffffd
    80003a54:	44c080e7          	jalr	1100(ra) # 80000e9c <memmove>
  brelse(bp);
    80003a58:	8526                	mv	a0,s1
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	b60080e7          	jalr	-1184(ra) # 800035ba <brelse>
  if(sb.magic != FSMAGIC)
    80003a62:	0009a703          	lw	a4,0(s3)
    80003a66:	102037b7          	lui	a5,0x10203
    80003a6a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003a6e:	02f71263          	bne	a4,a5,80003a92 <fsinit+0x70>
  initlog(dev, &sb);
    80003a72:	0023b597          	auipc	a1,0x23b
    80003a76:	74658593          	addi	a1,a1,1862 # 8023f1b8 <sb>
    80003a7a:	854a                	mv	a0,s2
    80003a7c:	00001097          	auipc	ra,0x1
    80003a80:	b2c080e7          	jalr	-1236(ra) # 800045a8 <initlog>
}
    80003a84:	70a2                	ld	ra,40(sp)
    80003a86:	7402                	ld	s0,32(sp)
    80003a88:	64e2                	ld	s1,24(sp)
    80003a8a:	6942                	ld	s2,16(sp)
    80003a8c:	69a2                	ld	s3,8(sp)
    80003a8e:	6145                	addi	sp,sp,48
    80003a90:	8082                	ret
    panic("invalid file system");
    80003a92:	00005517          	auipc	a0,0x5
    80003a96:	c3650513          	addi	a0,a0,-970 # 800086c8 <syscalls+0x168>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	aa2080e7          	jalr	-1374(ra) # 8000053c <panic>

0000000080003aa2 <iinit>:
{
    80003aa2:	7179                	addi	sp,sp,-48
    80003aa4:	f406                	sd	ra,40(sp)
    80003aa6:	f022                	sd	s0,32(sp)
    80003aa8:	ec26                	sd	s1,24(sp)
    80003aaa:	e84a                	sd	s2,16(sp)
    80003aac:	e44e                	sd	s3,8(sp)
    80003aae:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003ab0:	00005597          	auipc	a1,0x5
    80003ab4:	c3058593          	addi	a1,a1,-976 # 800086e0 <syscalls+0x180>
    80003ab8:	0023b517          	auipc	a0,0x23b
    80003abc:	72050513          	addi	a0,a0,1824 # 8023f1d8 <itable>
    80003ac0:	ffffd097          	auipc	ra,0xffffd
    80003ac4:	1f4080e7          	jalr	500(ra) # 80000cb4 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003ac8:	0023b497          	auipc	s1,0x23b
    80003acc:	73848493          	addi	s1,s1,1848 # 8023f200 <itable+0x28>
    80003ad0:	0023d997          	auipc	s3,0x23d
    80003ad4:	1c098993          	addi	s3,s3,448 # 80240c90 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003ad8:	00005917          	auipc	s2,0x5
    80003adc:	c1090913          	addi	s2,s2,-1008 # 800086e8 <syscalls+0x188>
    80003ae0:	85ca                	mv	a1,s2
    80003ae2:	8526                	mv	a0,s1
    80003ae4:	00001097          	auipc	ra,0x1
    80003ae8:	e12080e7          	jalr	-494(ra) # 800048f6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003aec:	08848493          	addi	s1,s1,136
    80003af0:	ff3498e3          	bne	s1,s3,80003ae0 <iinit+0x3e>
}
    80003af4:	70a2                	ld	ra,40(sp)
    80003af6:	7402                	ld	s0,32(sp)
    80003af8:	64e2                	ld	s1,24(sp)
    80003afa:	6942                	ld	s2,16(sp)
    80003afc:	69a2                	ld	s3,8(sp)
    80003afe:	6145                	addi	sp,sp,48
    80003b00:	8082                	ret

0000000080003b02 <ialloc>:
{
    80003b02:	7139                	addi	sp,sp,-64
    80003b04:	fc06                	sd	ra,56(sp)
    80003b06:	f822                	sd	s0,48(sp)
    80003b08:	f426                	sd	s1,40(sp)
    80003b0a:	f04a                	sd	s2,32(sp)
    80003b0c:	ec4e                	sd	s3,24(sp)
    80003b0e:	e852                	sd	s4,16(sp)
    80003b10:	e456                	sd	s5,8(sp)
    80003b12:	e05a                	sd	s6,0(sp)
    80003b14:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b16:	0023b717          	auipc	a4,0x23b
    80003b1a:	6ae72703          	lw	a4,1710(a4) # 8023f1c4 <sb+0xc>
    80003b1e:	4785                	li	a5,1
    80003b20:	04e7f863          	bgeu	a5,a4,80003b70 <ialloc+0x6e>
    80003b24:	8aaa                	mv	s5,a0
    80003b26:	8b2e                	mv	s6,a1
    80003b28:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003b2a:	0023ba17          	auipc	s4,0x23b
    80003b2e:	68ea0a13          	addi	s4,s4,1678 # 8023f1b8 <sb>
    80003b32:	00495593          	srli	a1,s2,0x4
    80003b36:	018a2783          	lw	a5,24(s4)
    80003b3a:	9dbd                	addw	a1,a1,a5
    80003b3c:	8556                	mv	a0,s5
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	94c080e7          	jalr	-1716(ra) # 8000348a <bread>
    80003b46:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003b48:	05850993          	addi	s3,a0,88
    80003b4c:	00f97793          	andi	a5,s2,15
    80003b50:	079a                	slli	a5,a5,0x6
    80003b52:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003b54:	00099783          	lh	a5,0(s3)
    80003b58:	cf9d                	beqz	a5,80003b96 <ialloc+0x94>
    brelse(bp);
    80003b5a:	00000097          	auipc	ra,0x0
    80003b5e:	a60080e7          	jalr	-1440(ra) # 800035ba <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003b62:	0905                	addi	s2,s2,1
    80003b64:	00ca2703          	lw	a4,12(s4)
    80003b68:	0009079b          	sext.w	a5,s2
    80003b6c:	fce7e3e3          	bltu	a5,a4,80003b32 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003b70:	00005517          	auipc	a0,0x5
    80003b74:	b8050513          	addi	a0,a0,-1152 # 800086f0 <syscalls+0x190>
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	a20080e7          	jalr	-1504(ra) # 80000598 <printf>
  return 0;
    80003b80:	4501                	li	a0,0
}
    80003b82:	70e2                	ld	ra,56(sp)
    80003b84:	7442                	ld	s0,48(sp)
    80003b86:	74a2                	ld	s1,40(sp)
    80003b88:	7902                	ld	s2,32(sp)
    80003b8a:	69e2                	ld	s3,24(sp)
    80003b8c:	6a42                	ld	s4,16(sp)
    80003b8e:	6aa2                	ld	s5,8(sp)
    80003b90:	6b02                	ld	s6,0(sp)
    80003b92:	6121                	addi	sp,sp,64
    80003b94:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b96:	04000613          	li	a2,64
    80003b9a:	4581                	li	a1,0
    80003b9c:	854e                	mv	a0,s3
    80003b9e:	ffffd097          	auipc	ra,0xffffd
    80003ba2:	2a2080e7          	jalr	674(ra) # 80000e40 <memset>
      dip->type = type;
    80003ba6:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003baa:	8526                	mv	a0,s1
    80003bac:	00001097          	auipc	ra,0x1
    80003bb0:	c66080e7          	jalr	-922(ra) # 80004812 <log_write>
      brelse(bp);
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	00000097          	auipc	ra,0x0
    80003bba:	a04080e7          	jalr	-1532(ra) # 800035ba <brelse>
      return iget(dev, inum);
    80003bbe:	0009059b          	sext.w	a1,s2
    80003bc2:	8556                	mv	a0,s5
    80003bc4:	00000097          	auipc	ra,0x0
    80003bc8:	da2080e7          	jalr	-606(ra) # 80003966 <iget>
    80003bcc:	bf5d                	j	80003b82 <ialloc+0x80>

0000000080003bce <iupdate>:
{
    80003bce:	1101                	addi	sp,sp,-32
    80003bd0:	ec06                	sd	ra,24(sp)
    80003bd2:	e822                	sd	s0,16(sp)
    80003bd4:	e426                	sd	s1,8(sp)
    80003bd6:	e04a                	sd	s2,0(sp)
    80003bd8:	1000                	addi	s0,sp,32
    80003bda:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bdc:	415c                	lw	a5,4(a0)
    80003bde:	0047d79b          	srliw	a5,a5,0x4
    80003be2:	0023b597          	auipc	a1,0x23b
    80003be6:	5ee5a583          	lw	a1,1518(a1) # 8023f1d0 <sb+0x18>
    80003bea:	9dbd                	addw	a1,a1,a5
    80003bec:	4108                	lw	a0,0(a0)
    80003bee:	00000097          	auipc	ra,0x0
    80003bf2:	89c080e7          	jalr	-1892(ra) # 8000348a <bread>
    80003bf6:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bf8:	05850793          	addi	a5,a0,88
    80003bfc:	40d8                	lw	a4,4(s1)
    80003bfe:	8b3d                	andi	a4,a4,15
    80003c00:	071a                	slli	a4,a4,0x6
    80003c02:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003c04:	04449703          	lh	a4,68(s1)
    80003c08:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003c0c:	04649703          	lh	a4,70(s1)
    80003c10:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003c14:	04849703          	lh	a4,72(s1)
    80003c18:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003c1c:	04a49703          	lh	a4,74(s1)
    80003c20:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003c24:	44f8                	lw	a4,76(s1)
    80003c26:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003c28:	03400613          	li	a2,52
    80003c2c:	05048593          	addi	a1,s1,80
    80003c30:	00c78513          	addi	a0,a5,12
    80003c34:	ffffd097          	auipc	ra,0xffffd
    80003c38:	268080e7          	jalr	616(ra) # 80000e9c <memmove>
  log_write(bp);
    80003c3c:	854a                	mv	a0,s2
    80003c3e:	00001097          	auipc	ra,0x1
    80003c42:	bd4080e7          	jalr	-1068(ra) # 80004812 <log_write>
  brelse(bp);
    80003c46:	854a                	mv	a0,s2
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	972080e7          	jalr	-1678(ra) # 800035ba <brelse>
}
    80003c50:	60e2                	ld	ra,24(sp)
    80003c52:	6442                	ld	s0,16(sp)
    80003c54:	64a2                	ld	s1,8(sp)
    80003c56:	6902                	ld	s2,0(sp)
    80003c58:	6105                	addi	sp,sp,32
    80003c5a:	8082                	ret

0000000080003c5c <idup>:
{
    80003c5c:	1101                	addi	sp,sp,-32
    80003c5e:	ec06                	sd	ra,24(sp)
    80003c60:	e822                	sd	s0,16(sp)
    80003c62:	e426                	sd	s1,8(sp)
    80003c64:	1000                	addi	s0,sp,32
    80003c66:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003c68:	0023b517          	auipc	a0,0x23b
    80003c6c:	57050513          	addi	a0,a0,1392 # 8023f1d8 <itable>
    80003c70:	ffffd097          	auipc	ra,0xffffd
    80003c74:	0d4080e7          	jalr	212(ra) # 80000d44 <acquire>
  ip->ref++;
    80003c78:	449c                	lw	a5,8(s1)
    80003c7a:	2785                	addiw	a5,a5,1
    80003c7c:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003c7e:	0023b517          	auipc	a0,0x23b
    80003c82:	55a50513          	addi	a0,a0,1370 # 8023f1d8 <itable>
    80003c86:	ffffd097          	auipc	ra,0xffffd
    80003c8a:	172080e7          	jalr	370(ra) # 80000df8 <release>
}
    80003c8e:	8526                	mv	a0,s1
    80003c90:	60e2                	ld	ra,24(sp)
    80003c92:	6442                	ld	s0,16(sp)
    80003c94:	64a2                	ld	s1,8(sp)
    80003c96:	6105                	addi	sp,sp,32
    80003c98:	8082                	ret

0000000080003c9a <ilock>:
{
    80003c9a:	1101                	addi	sp,sp,-32
    80003c9c:	ec06                	sd	ra,24(sp)
    80003c9e:	e822                	sd	s0,16(sp)
    80003ca0:	e426                	sd	s1,8(sp)
    80003ca2:	e04a                	sd	s2,0(sp)
    80003ca4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003ca6:	c115                	beqz	a0,80003cca <ilock+0x30>
    80003ca8:	84aa                	mv	s1,a0
    80003caa:	451c                	lw	a5,8(a0)
    80003cac:	00f05f63          	blez	a5,80003cca <ilock+0x30>
  acquiresleep(&ip->lock);
    80003cb0:	0541                	addi	a0,a0,16
    80003cb2:	00001097          	auipc	ra,0x1
    80003cb6:	c7e080e7          	jalr	-898(ra) # 80004930 <acquiresleep>
  if(ip->valid == 0){
    80003cba:	40bc                	lw	a5,64(s1)
    80003cbc:	cf99                	beqz	a5,80003cda <ilock+0x40>
}
    80003cbe:	60e2                	ld	ra,24(sp)
    80003cc0:	6442                	ld	s0,16(sp)
    80003cc2:	64a2                	ld	s1,8(sp)
    80003cc4:	6902                	ld	s2,0(sp)
    80003cc6:	6105                	addi	sp,sp,32
    80003cc8:	8082                	ret
    panic("ilock");
    80003cca:	00005517          	auipc	a0,0x5
    80003cce:	a3e50513          	addi	a0,a0,-1474 # 80008708 <syscalls+0x1a8>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	86a080e7          	jalr	-1942(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cda:	40dc                	lw	a5,4(s1)
    80003cdc:	0047d79b          	srliw	a5,a5,0x4
    80003ce0:	0023b597          	auipc	a1,0x23b
    80003ce4:	4f05a583          	lw	a1,1264(a1) # 8023f1d0 <sb+0x18>
    80003ce8:	9dbd                	addw	a1,a1,a5
    80003cea:	4088                	lw	a0,0(s1)
    80003cec:	fffff097          	auipc	ra,0xfffff
    80003cf0:	79e080e7          	jalr	1950(ra) # 8000348a <bread>
    80003cf4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003cf6:	05850593          	addi	a1,a0,88
    80003cfa:	40dc                	lw	a5,4(s1)
    80003cfc:	8bbd                	andi	a5,a5,15
    80003cfe:	079a                	slli	a5,a5,0x6
    80003d00:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003d02:	00059783          	lh	a5,0(a1)
    80003d06:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003d0a:	00259783          	lh	a5,2(a1)
    80003d0e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003d12:	00459783          	lh	a5,4(a1)
    80003d16:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003d1a:	00659783          	lh	a5,6(a1)
    80003d1e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003d22:	459c                	lw	a5,8(a1)
    80003d24:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003d26:	03400613          	li	a2,52
    80003d2a:	05b1                	addi	a1,a1,12
    80003d2c:	05048513          	addi	a0,s1,80
    80003d30:	ffffd097          	auipc	ra,0xffffd
    80003d34:	16c080e7          	jalr	364(ra) # 80000e9c <memmove>
    brelse(bp);
    80003d38:	854a                	mv	a0,s2
    80003d3a:	00000097          	auipc	ra,0x0
    80003d3e:	880080e7          	jalr	-1920(ra) # 800035ba <brelse>
    ip->valid = 1;
    80003d42:	4785                	li	a5,1
    80003d44:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003d46:	04449783          	lh	a5,68(s1)
    80003d4a:	fbb5                	bnez	a5,80003cbe <ilock+0x24>
      panic("ilock: no type");
    80003d4c:	00005517          	auipc	a0,0x5
    80003d50:	9c450513          	addi	a0,a0,-1596 # 80008710 <syscalls+0x1b0>
    80003d54:	ffffc097          	auipc	ra,0xffffc
    80003d58:	7e8080e7          	jalr	2024(ra) # 8000053c <panic>

0000000080003d5c <iunlock>:
{
    80003d5c:	1101                	addi	sp,sp,-32
    80003d5e:	ec06                	sd	ra,24(sp)
    80003d60:	e822                	sd	s0,16(sp)
    80003d62:	e426                	sd	s1,8(sp)
    80003d64:	e04a                	sd	s2,0(sp)
    80003d66:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003d68:	c905                	beqz	a0,80003d98 <iunlock+0x3c>
    80003d6a:	84aa                	mv	s1,a0
    80003d6c:	01050913          	addi	s2,a0,16
    80003d70:	854a                	mv	a0,s2
    80003d72:	00001097          	auipc	ra,0x1
    80003d76:	c58080e7          	jalr	-936(ra) # 800049ca <holdingsleep>
    80003d7a:	cd19                	beqz	a0,80003d98 <iunlock+0x3c>
    80003d7c:	449c                	lw	a5,8(s1)
    80003d7e:	00f05d63          	blez	a5,80003d98 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d82:	854a                	mv	a0,s2
    80003d84:	00001097          	auipc	ra,0x1
    80003d88:	c02080e7          	jalr	-1022(ra) # 80004986 <releasesleep>
}
    80003d8c:	60e2                	ld	ra,24(sp)
    80003d8e:	6442                	ld	s0,16(sp)
    80003d90:	64a2                	ld	s1,8(sp)
    80003d92:	6902                	ld	s2,0(sp)
    80003d94:	6105                	addi	sp,sp,32
    80003d96:	8082                	ret
    panic("iunlock");
    80003d98:	00005517          	auipc	a0,0x5
    80003d9c:	98850513          	addi	a0,a0,-1656 # 80008720 <syscalls+0x1c0>
    80003da0:	ffffc097          	auipc	ra,0xffffc
    80003da4:	79c080e7          	jalr	1948(ra) # 8000053c <panic>

0000000080003da8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003da8:	7179                	addi	sp,sp,-48
    80003daa:	f406                	sd	ra,40(sp)
    80003dac:	f022                	sd	s0,32(sp)
    80003dae:	ec26                	sd	s1,24(sp)
    80003db0:	e84a                	sd	s2,16(sp)
    80003db2:	e44e                	sd	s3,8(sp)
    80003db4:	e052                	sd	s4,0(sp)
    80003db6:	1800                	addi	s0,sp,48
    80003db8:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003dba:	05050493          	addi	s1,a0,80
    80003dbe:	08050913          	addi	s2,a0,128
    80003dc2:	a021                	j	80003dca <itrunc+0x22>
    80003dc4:	0491                	addi	s1,s1,4
    80003dc6:	01248d63          	beq	s1,s2,80003de0 <itrunc+0x38>
    if(ip->addrs[i]){
    80003dca:	408c                	lw	a1,0(s1)
    80003dcc:	dde5                	beqz	a1,80003dc4 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003dce:	0009a503          	lw	a0,0(s3)
    80003dd2:	00000097          	auipc	ra,0x0
    80003dd6:	8fc080e7          	jalr	-1796(ra) # 800036ce <bfree>
      ip->addrs[i] = 0;
    80003dda:	0004a023          	sw	zero,0(s1)
    80003dde:	b7dd                	j	80003dc4 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003de0:	0809a583          	lw	a1,128(s3)
    80003de4:	e185                	bnez	a1,80003e04 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003de6:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003dea:	854e                	mv	a0,s3
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	de2080e7          	jalr	-542(ra) # 80003bce <iupdate>
}
    80003df4:	70a2                	ld	ra,40(sp)
    80003df6:	7402                	ld	s0,32(sp)
    80003df8:	64e2                	ld	s1,24(sp)
    80003dfa:	6942                	ld	s2,16(sp)
    80003dfc:	69a2                	ld	s3,8(sp)
    80003dfe:	6a02                	ld	s4,0(sp)
    80003e00:	6145                	addi	sp,sp,48
    80003e02:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003e04:	0009a503          	lw	a0,0(s3)
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	682080e7          	jalr	1666(ra) # 8000348a <bread>
    80003e10:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003e12:	05850493          	addi	s1,a0,88
    80003e16:	45850913          	addi	s2,a0,1112
    80003e1a:	a021                	j	80003e22 <itrunc+0x7a>
    80003e1c:	0491                	addi	s1,s1,4
    80003e1e:	01248b63          	beq	s1,s2,80003e34 <itrunc+0x8c>
      if(a[j])
    80003e22:	408c                	lw	a1,0(s1)
    80003e24:	dde5                	beqz	a1,80003e1c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003e26:	0009a503          	lw	a0,0(s3)
    80003e2a:	00000097          	auipc	ra,0x0
    80003e2e:	8a4080e7          	jalr	-1884(ra) # 800036ce <bfree>
    80003e32:	b7ed                	j	80003e1c <itrunc+0x74>
    brelse(bp);
    80003e34:	8552                	mv	a0,s4
    80003e36:	fffff097          	auipc	ra,0xfffff
    80003e3a:	784080e7          	jalr	1924(ra) # 800035ba <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003e3e:	0809a583          	lw	a1,128(s3)
    80003e42:	0009a503          	lw	a0,0(s3)
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	888080e7          	jalr	-1912(ra) # 800036ce <bfree>
    ip->addrs[NDIRECT] = 0;
    80003e4e:	0809a023          	sw	zero,128(s3)
    80003e52:	bf51                	j	80003de6 <itrunc+0x3e>

0000000080003e54 <iput>:
{
    80003e54:	1101                	addi	sp,sp,-32
    80003e56:	ec06                	sd	ra,24(sp)
    80003e58:	e822                	sd	s0,16(sp)
    80003e5a:	e426                	sd	s1,8(sp)
    80003e5c:	e04a                	sd	s2,0(sp)
    80003e5e:	1000                	addi	s0,sp,32
    80003e60:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003e62:	0023b517          	auipc	a0,0x23b
    80003e66:	37650513          	addi	a0,a0,886 # 8023f1d8 <itable>
    80003e6a:	ffffd097          	auipc	ra,0xffffd
    80003e6e:	eda080e7          	jalr	-294(ra) # 80000d44 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e72:	4498                	lw	a4,8(s1)
    80003e74:	4785                	li	a5,1
    80003e76:	02f70363          	beq	a4,a5,80003e9c <iput+0x48>
  ip->ref--;
    80003e7a:	449c                	lw	a5,8(s1)
    80003e7c:	37fd                	addiw	a5,a5,-1
    80003e7e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e80:	0023b517          	auipc	a0,0x23b
    80003e84:	35850513          	addi	a0,a0,856 # 8023f1d8 <itable>
    80003e88:	ffffd097          	auipc	ra,0xffffd
    80003e8c:	f70080e7          	jalr	-144(ra) # 80000df8 <release>
}
    80003e90:	60e2                	ld	ra,24(sp)
    80003e92:	6442                	ld	s0,16(sp)
    80003e94:	64a2                	ld	s1,8(sp)
    80003e96:	6902                	ld	s2,0(sp)
    80003e98:	6105                	addi	sp,sp,32
    80003e9a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e9c:	40bc                	lw	a5,64(s1)
    80003e9e:	dff1                	beqz	a5,80003e7a <iput+0x26>
    80003ea0:	04a49783          	lh	a5,74(s1)
    80003ea4:	fbf9                	bnez	a5,80003e7a <iput+0x26>
    acquiresleep(&ip->lock);
    80003ea6:	01048913          	addi	s2,s1,16
    80003eaa:	854a                	mv	a0,s2
    80003eac:	00001097          	auipc	ra,0x1
    80003eb0:	a84080e7          	jalr	-1404(ra) # 80004930 <acquiresleep>
    release(&itable.lock);
    80003eb4:	0023b517          	auipc	a0,0x23b
    80003eb8:	32450513          	addi	a0,a0,804 # 8023f1d8 <itable>
    80003ebc:	ffffd097          	auipc	ra,0xffffd
    80003ec0:	f3c080e7          	jalr	-196(ra) # 80000df8 <release>
    itrunc(ip);
    80003ec4:	8526                	mv	a0,s1
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	ee2080e7          	jalr	-286(ra) # 80003da8 <itrunc>
    ip->type = 0;
    80003ece:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ed2:	8526                	mv	a0,s1
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	cfa080e7          	jalr	-774(ra) # 80003bce <iupdate>
    ip->valid = 0;
    80003edc:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	00001097          	auipc	ra,0x1
    80003ee6:	aa4080e7          	jalr	-1372(ra) # 80004986 <releasesleep>
    acquire(&itable.lock);
    80003eea:	0023b517          	auipc	a0,0x23b
    80003eee:	2ee50513          	addi	a0,a0,750 # 8023f1d8 <itable>
    80003ef2:	ffffd097          	auipc	ra,0xffffd
    80003ef6:	e52080e7          	jalr	-430(ra) # 80000d44 <acquire>
    80003efa:	b741                	j	80003e7a <iput+0x26>

0000000080003efc <iunlockput>:
{
    80003efc:	1101                	addi	sp,sp,-32
    80003efe:	ec06                	sd	ra,24(sp)
    80003f00:	e822                	sd	s0,16(sp)
    80003f02:	e426                	sd	s1,8(sp)
    80003f04:	1000                	addi	s0,sp,32
    80003f06:	84aa                	mv	s1,a0
  iunlock(ip);
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	e54080e7          	jalr	-428(ra) # 80003d5c <iunlock>
  iput(ip);
    80003f10:	8526                	mv	a0,s1
    80003f12:	00000097          	auipc	ra,0x0
    80003f16:	f42080e7          	jalr	-190(ra) # 80003e54 <iput>
}
    80003f1a:	60e2                	ld	ra,24(sp)
    80003f1c:	6442                	ld	s0,16(sp)
    80003f1e:	64a2                	ld	s1,8(sp)
    80003f20:	6105                	addi	sp,sp,32
    80003f22:	8082                	ret

0000000080003f24 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003f24:	1141                	addi	sp,sp,-16
    80003f26:	e422                	sd	s0,8(sp)
    80003f28:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003f2a:	411c                	lw	a5,0(a0)
    80003f2c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003f2e:	415c                	lw	a5,4(a0)
    80003f30:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003f32:	04451783          	lh	a5,68(a0)
    80003f36:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003f3a:	04a51783          	lh	a5,74(a0)
    80003f3e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003f42:	04c56783          	lwu	a5,76(a0)
    80003f46:	e99c                	sd	a5,16(a1)
}
    80003f48:	6422                	ld	s0,8(sp)
    80003f4a:	0141                	addi	sp,sp,16
    80003f4c:	8082                	ret

0000000080003f4e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f4e:	457c                	lw	a5,76(a0)
    80003f50:	0ed7e963          	bltu	a5,a3,80004042 <readi+0xf4>
{
    80003f54:	7159                	addi	sp,sp,-112
    80003f56:	f486                	sd	ra,104(sp)
    80003f58:	f0a2                	sd	s0,96(sp)
    80003f5a:	eca6                	sd	s1,88(sp)
    80003f5c:	e8ca                	sd	s2,80(sp)
    80003f5e:	e4ce                	sd	s3,72(sp)
    80003f60:	e0d2                	sd	s4,64(sp)
    80003f62:	fc56                	sd	s5,56(sp)
    80003f64:	f85a                	sd	s6,48(sp)
    80003f66:	f45e                	sd	s7,40(sp)
    80003f68:	f062                	sd	s8,32(sp)
    80003f6a:	ec66                	sd	s9,24(sp)
    80003f6c:	e86a                	sd	s10,16(sp)
    80003f6e:	e46e                	sd	s11,8(sp)
    80003f70:	1880                	addi	s0,sp,112
    80003f72:	8b2a                	mv	s6,a0
    80003f74:	8bae                	mv	s7,a1
    80003f76:	8a32                	mv	s4,a2
    80003f78:	84b6                	mv	s1,a3
    80003f7a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003f7c:	9f35                	addw	a4,a4,a3
    return 0;
    80003f7e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f80:	0ad76063          	bltu	a4,a3,80004020 <readi+0xd2>
  if(off + n > ip->size)
    80003f84:	00e7f463          	bgeu	a5,a4,80003f8c <readi+0x3e>
    n = ip->size - off;
    80003f88:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f8c:	0a0a8963          	beqz	s5,8000403e <readi+0xf0>
    80003f90:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f92:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f96:	5c7d                	li	s8,-1
    80003f98:	a82d                	j	80003fd2 <readi+0x84>
    80003f9a:	020d1d93          	slli	s11,s10,0x20
    80003f9e:	020ddd93          	srli	s11,s11,0x20
    80003fa2:	05890613          	addi	a2,s2,88
    80003fa6:	86ee                	mv	a3,s11
    80003fa8:	963a                	add	a2,a2,a4
    80003faa:	85d2                	mv	a1,s4
    80003fac:	855e                	mv	a0,s7
    80003fae:	fffff097          	auipc	ra,0xfffff
    80003fb2:	886080e7          	jalr	-1914(ra) # 80002834 <either_copyout>
    80003fb6:	05850d63          	beq	a0,s8,80004010 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003fba:	854a                	mv	a0,s2
    80003fbc:	fffff097          	auipc	ra,0xfffff
    80003fc0:	5fe080e7          	jalr	1534(ra) # 800035ba <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fc4:	013d09bb          	addw	s3,s10,s3
    80003fc8:	009d04bb          	addw	s1,s10,s1
    80003fcc:	9a6e                	add	s4,s4,s11
    80003fce:	0559f763          	bgeu	s3,s5,8000401c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003fd2:	00a4d59b          	srliw	a1,s1,0xa
    80003fd6:	855a                	mv	a0,s6
    80003fd8:	00000097          	auipc	ra,0x0
    80003fdc:	8a4080e7          	jalr	-1884(ra) # 8000387c <bmap>
    80003fe0:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003fe4:	cd85                	beqz	a1,8000401c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003fe6:	000b2503          	lw	a0,0(s6)
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	4a0080e7          	jalr	1184(ra) # 8000348a <bread>
    80003ff2:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ff4:	3ff4f713          	andi	a4,s1,1023
    80003ff8:	40ec87bb          	subw	a5,s9,a4
    80003ffc:	413a86bb          	subw	a3,s5,s3
    80004000:	8d3e                	mv	s10,a5
    80004002:	2781                	sext.w	a5,a5
    80004004:	0006861b          	sext.w	a2,a3
    80004008:	f8f679e3          	bgeu	a2,a5,80003f9a <readi+0x4c>
    8000400c:	8d36                	mv	s10,a3
    8000400e:	b771                	j	80003f9a <readi+0x4c>
      brelse(bp);
    80004010:	854a                	mv	a0,s2
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	5a8080e7          	jalr	1448(ra) # 800035ba <brelse>
      tot = -1;
    8000401a:	59fd                	li	s3,-1
  }
  return tot;
    8000401c:	0009851b          	sext.w	a0,s3
}
    80004020:	70a6                	ld	ra,104(sp)
    80004022:	7406                	ld	s0,96(sp)
    80004024:	64e6                	ld	s1,88(sp)
    80004026:	6946                	ld	s2,80(sp)
    80004028:	69a6                	ld	s3,72(sp)
    8000402a:	6a06                	ld	s4,64(sp)
    8000402c:	7ae2                	ld	s5,56(sp)
    8000402e:	7b42                	ld	s6,48(sp)
    80004030:	7ba2                	ld	s7,40(sp)
    80004032:	7c02                	ld	s8,32(sp)
    80004034:	6ce2                	ld	s9,24(sp)
    80004036:	6d42                	ld	s10,16(sp)
    80004038:	6da2                	ld	s11,8(sp)
    8000403a:	6165                	addi	sp,sp,112
    8000403c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000403e:	89d6                	mv	s3,s5
    80004040:	bff1                	j	8000401c <readi+0xce>
    return 0;
    80004042:	4501                	li	a0,0
}
    80004044:	8082                	ret

0000000080004046 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004046:	457c                	lw	a5,76(a0)
    80004048:	10d7e863          	bltu	a5,a3,80004158 <writei+0x112>
{
    8000404c:	7159                	addi	sp,sp,-112
    8000404e:	f486                	sd	ra,104(sp)
    80004050:	f0a2                	sd	s0,96(sp)
    80004052:	eca6                	sd	s1,88(sp)
    80004054:	e8ca                	sd	s2,80(sp)
    80004056:	e4ce                	sd	s3,72(sp)
    80004058:	e0d2                	sd	s4,64(sp)
    8000405a:	fc56                	sd	s5,56(sp)
    8000405c:	f85a                	sd	s6,48(sp)
    8000405e:	f45e                	sd	s7,40(sp)
    80004060:	f062                	sd	s8,32(sp)
    80004062:	ec66                	sd	s9,24(sp)
    80004064:	e86a                	sd	s10,16(sp)
    80004066:	e46e                	sd	s11,8(sp)
    80004068:	1880                	addi	s0,sp,112
    8000406a:	8aaa                	mv	s5,a0
    8000406c:	8bae                	mv	s7,a1
    8000406e:	8a32                	mv	s4,a2
    80004070:	8936                	mv	s2,a3
    80004072:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004074:	00e687bb          	addw	a5,a3,a4
    80004078:	0ed7e263          	bltu	a5,a3,8000415c <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    8000407c:	00043737          	lui	a4,0x43
    80004080:	0ef76063          	bltu	a4,a5,80004160 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004084:	0c0b0863          	beqz	s6,80004154 <writei+0x10e>
    80004088:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000408a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000408e:	5c7d                	li	s8,-1
    80004090:	a091                	j	800040d4 <writei+0x8e>
    80004092:	020d1d93          	slli	s11,s10,0x20
    80004096:	020ddd93          	srli	s11,s11,0x20
    8000409a:	05848513          	addi	a0,s1,88
    8000409e:	86ee                	mv	a3,s11
    800040a0:	8652                	mv	a2,s4
    800040a2:	85de                	mv	a1,s7
    800040a4:	953a                	add	a0,a0,a4
    800040a6:	ffffe097          	auipc	ra,0xffffe
    800040aa:	7e4080e7          	jalr	2020(ra) # 8000288a <either_copyin>
    800040ae:	07850263          	beq	a0,s8,80004112 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800040b2:	8526                	mv	a0,s1
    800040b4:	00000097          	auipc	ra,0x0
    800040b8:	75e080e7          	jalr	1886(ra) # 80004812 <log_write>
    brelse(bp);
    800040bc:	8526                	mv	a0,s1
    800040be:	fffff097          	auipc	ra,0xfffff
    800040c2:	4fc080e7          	jalr	1276(ra) # 800035ba <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040c6:	013d09bb          	addw	s3,s10,s3
    800040ca:	012d093b          	addw	s2,s10,s2
    800040ce:	9a6e                	add	s4,s4,s11
    800040d0:	0569f663          	bgeu	s3,s6,8000411c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800040d4:	00a9559b          	srliw	a1,s2,0xa
    800040d8:	8556                	mv	a0,s5
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	7a2080e7          	jalr	1954(ra) # 8000387c <bmap>
    800040e2:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040e6:	c99d                	beqz	a1,8000411c <writei+0xd6>
    bp = bread(ip->dev, addr);
    800040e8:	000aa503          	lw	a0,0(s5)
    800040ec:	fffff097          	auipc	ra,0xfffff
    800040f0:	39e080e7          	jalr	926(ra) # 8000348a <bread>
    800040f4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    800040f6:	3ff97713          	andi	a4,s2,1023
    800040fa:	40ec87bb          	subw	a5,s9,a4
    800040fe:	413b06bb          	subw	a3,s6,s3
    80004102:	8d3e                	mv	s10,a5
    80004104:	2781                	sext.w	a5,a5
    80004106:	0006861b          	sext.w	a2,a3
    8000410a:	f8f674e3          	bgeu	a2,a5,80004092 <writei+0x4c>
    8000410e:	8d36                	mv	s10,a3
    80004110:	b749                	j	80004092 <writei+0x4c>
      brelse(bp);
    80004112:	8526                	mv	a0,s1
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	4a6080e7          	jalr	1190(ra) # 800035ba <brelse>
  }

  if(off > ip->size)
    8000411c:	04caa783          	lw	a5,76(s5)
    80004120:	0127f463          	bgeu	a5,s2,80004128 <writei+0xe2>
    ip->size = off;
    80004124:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004128:	8556                	mv	a0,s5
    8000412a:	00000097          	auipc	ra,0x0
    8000412e:	aa4080e7          	jalr	-1372(ra) # 80003bce <iupdate>

  return tot;
    80004132:	0009851b          	sext.w	a0,s3
}
    80004136:	70a6                	ld	ra,104(sp)
    80004138:	7406                	ld	s0,96(sp)
    8000413a:	64e6                	ld	s1,88(sp)
    8000413c:	6946                	ld	s2,80(sp)
    8000413e:	69a6                	ld	s3,72(sp)
    80004140:	6a06                	ld	s4,64(sp)
    80004142:	7ae2                	ld	s5,56(sp)
    80004144:	7b42                	ld	s6,48(sp)
    80004146:	7ba2                	ld	s7,40(sp)
    80004148:	7c02                	ld	s8,32(sp)
    8000414a:	6ce2                	ld	s9,24(sp)
    8000414c:	6d42                	ld	s10,16(sp)
    8000414e:	6da2                	ld	s11,8(sp)
    80004150:	6165                	addi	sp,sp,112
    80004152:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004154:	89da                	mv	s3,s6
    80004156:	bfc9                	j	80004128 <writei+0xe2>
    return -1;
    80004158:	557d                	li	a0,-1
}
    8000415a:	8082                	ret
    return -1;
    8000415c:	557d                	li	a0,-1
    8000415e:	bfe1                	j	80004136 <writei+0xf0>
    return -1;
    80004160:	557d                	li	a0,-1
    80004162:	bfd1                	j	80004136 <writei+0xf0>

0000000080004164 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004164:	1141                	addi	sp,sp,-16
    80004166:	e406                	sd	ra,8(sp)
    80004168:	e022                	sd	s0,0(sp)
    8000416a:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    8000416c:	4639                	li	a2,14
    8000416e:	ffffd097          	auipc	ra,0xffffd
    80004172:	da2080e7          	jalr	-606(ra) # 80000f10 <strncmp>
}
    80004176:	60a2                	ld	ra,8(sp)
    80004178:	6402                	ld	s0,0(sp)
    8000417a:	0141                	addi	sp,sp,16
    8000417c:	8082                	ret

000000008000417e <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000417e:	7139                	addi	sp,sp,-64
    80004180:	fc06                	sd	ra,56(sp)
    80004182:	f822                	sd	s0,48(sp)
    80004184:	f426                	sd	s1,40(sp)
    80004186:	f04a                	sd	s2,32(sp)
    80004188:	ec4e                	sd	s3,24(sp)
    8000418a:	e852                	sd	s4,16(sp)
    8000418c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000418e:	04451703          	lh	a4,68(a0)
    80004192:	4785                	li	a5,1
    80004194:	00f71a63          	bne	a4,a5,800041a8 <dirlookup+0x2a>
    80004198:	892a                	mv	s2,a0
    8000419a:	89ae                	mv	s3,a1
    8000419c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000419e:	457c                	lw	a5,76(a0)
    800041a0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800041a2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041a4:	e79d                	bnez	a5,800041d2 <dirlookup+0x54>
    800041a6:	a8a5                	j	8000421e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800041a8:	00004517          	auipc	a0,0x4
    800041ac:	58050513          	addi	a0,a0,1408 # 80008728 <syscalls+0x1c8>
    800041b0:	ffffc097          	auipc	ra,0xffffc
    800041b4:	38c080e7          	jalr	908(ra) # 8000053c <panic>
      panic("dirlookup read");
    800041b8:	00004517          	auipc	a0,0x4
    800041bc:	58850513          	addi	a0,a0,1416 # 80008740 <syscalls+0x1e0>
    800041c0:	ffffc097          	auipc	ra,0xffffc
    800041c4:	37c080e7          	jalr	892(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800041c8:	24c1                	addiw	s1,s1,16
    800041ca:	04c92783          	lw	a5,76(s2)
    800041ce:	04f4f763          	bgeu	s1,a5,8000421c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800041d2:	4741                	li	a4,16
    800041d4:	86a6                	mv	a3,s1
    800041d6:	fc040613          	addi	a2,s0,-64
    800041da:	4581                	li	a1,0
    800041dc:	854a                	mv	a0,s2
    800041de:	00000097          	auipc	ra,0x0
    800041e2:	d70080e7          	jalr	-656(ra) # 80003f4e <readi>
    800041e6:	47c1                	li	a5,16
    800041e8:	fcf518e3          	bne	a0,a5,800041b8 <dirlookup+0x3a>
    if(de.inum == 0)
    800041ec:	fc045783          	lhu	a5,-64(s0)
    800041f0:	dfe1                	beqz	a5,800041c8 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800041f2:	fc240593          	addi	a1,s0,-62
    800041f6:	854e                	mv	a0,s3
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	f6c080e7          	jalr	-148(ra) # 80004164 <namecmp>
    80004200:	f561                	bnez	a0,800041c8 <dirlookup+0x4a>
      if(poff)
    80004202:	000a0463          	beqz	s4,8000420a <dirlookup+0x8c>
        *poff = off;
    80004206:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000420a:	fc045583          	lhu	a1,-64(s0)
    8000420e:	00092503          	lw	a0,0(s2)
    80004212:	fffff097          	auipc	ra,0xfffff
    80004216:	754080e7          	jalr	1876(ra) # 80003966 <iget>
    8000421a:	a011                	j	8000421e <dirlookup+0xa0>
  return 0;
    8000421c:	4501                	li	a0,0
}
    8000421e:	70e2                	ld	ra,56(sp)
    80004220:	7442                	ld	s0,48(sp)
    80004222:	74a2                	ld	s1,40(sp)
    80004224:	7902                	ld	s2,32(sp)
    80004226:	69e2                	ld	s3,24(sp)
    80004228:	6a42                	ld	s4,16(sp)
    8000422a:	6121                	addi	sp,sp,64
    8000422c:	8082                	ret

000000008000422e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000422e:	711d                	addi	sp,sp,-96
    80004230:	ec86                	sd	ra,88(sp)
    80004232:	e8a2                	sd	s0,80(sp)
    80004234:	e4a6                	sd	s1,72(sp)
    80004236:	e0ca                	sd	s2,64(sp)
    80004238:	fc4e                	sd	s3,56(sp)
    8000423a:	f852                	sd	s4,48(sp)
    8000423c:	f456                	sd	s5,40(sp)
    8000423e:	f05a                	sd	s6,32(sp)
    80004240:	ec5e                	sd	s7,24(sp)
    80004242:	e862                	sd	s8,16(sp)
    80004244:	e466                	sd	s9,8(sp)
    80004246:	1080                	addi	s0,sp,96
    80004248:	84aa                	mv	s1,a0
    8000424a:	8b2e                	mv	s6,a1
    8000424c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000424e:	00054703          	lbu	a4,0(a0)
    80004252:	02f00793          	li	a5,47
    80004256:	02f70263          	beq	a4,a5,8000427a <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000425a:	ffffe097          	auipc	ra,0xffffe
    8000425e:	a6a080e7          	jalr	-1430(ra) # 80001cc4 <myproc>
    80004262:	15053503          	ld	a0,336(a0)
    80004266:	00000097          	auipc	ra,0x0
    8000426a:	9f6080e7          	jalr	-1546(ra) # 80003c5c <idup>
    8000426e:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004270:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004274:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004276:	4b85                	li	s7,1
    80004278:	a875                	j	80004334 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000427a:	4585                	li	a1,1
    8000427c:	4505                	li	a0,1
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	6e8080e7          	jalr	1768(ra) # 80003966 <iget>
    80004286:	8a2a                	mv	s4,a0
    80004288:	b7e5                	j	80004270 <namex+0x42>
      iunlockput(ip);
    8000428a:	8552                	mv	a0,s4
    8000428c:	00000097          	auipc	ra,0x0
    80004290:	c70080e7          	jalr	-912(ra) # 80003efc <iunlockput>
      return 0;
    80004294:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004296:	8552                	mv	a0,s4
    80004298:	60e6                	ld	ra,88(sp)
    8000429a:	6446                	ld	s0,80(sp)
    8000429c:	64a6                	ld	s1,72(sp)
    8000429e:	6906                	ld	s2,64(sp)
    800042a0:	79e2                	ld	s3,56(sp)
    800042a2:	7a42                	ld	s4,48(sp)
    800042a4:	7aa2                	ld	s5,40(sp)
    800042a6:	7b02                	ld	s6,32(sp)
    800042a8:	6be2                	ld	s7,24(sp)
    800042aa:	6c42                	ld	s8,16(sp)
    800042ac:	6ca2                	ld	s9,8(sp)
    800042ae:	6125                	addi	sp,sp,96
    800042b0:	8082                	ret
      iunlock(ip);
    800042b2:	8552                	mv	a0,s4
    800042b4:	00000097          	auipc	ra,0x0
    800042b8:	aa8080e7          	jalr	-1368(ra) # 80003d5c <iunlock>
      return ip;
    800042bc:	bfe9                	j	80004296 <namex+0x68>
      iunlockput(ip);
    800042be:	8552                	mv	a0,s4
    800042c0:	00000097          	auipc	ra,0x0
    800042c4:	c3c080e7          	jalr	-964(ra) # 80003efc <iunlockput>
      return 0;
    800042c8:	8a4e                	mv	s4,s3
    800042ca:	b7f1                	j	80004296 <namex+0x68>
  len = path - s;
    800042cc:	40998633          	sub	a2,s3,s1
    800042d0:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800042d4:	099c5863          	bge	s8,s9,80004364 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800042d8:	4639                	li	a2,14
    800042da:	85a6                	mv	a1,s1
    800042dc:	8556                	mv	a0,s5
    800042de:	ffffd097          	auipc	ra,0xffffd
    800042e2:	bbe080e7          	jalr	-1090(ra) # 80000e9c <memmove>
    800042e6:	84ce                	mv	s1,s3
  while(*path == '/')
    800042e8:	0004c783          	lbu	a5,0(s1)
    800042ec:	01279763          	bne	a5,s2,800042fa <namex+0xcc>
    path++;
    800042f0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042f2:	0004c783          	lbu	a5,0(s1)
    800042f6:	ff278de3          	beq	a5,s2,800042f0 <namex+0xc2>
    ilock(ip);
    800042fa:	8552                	mv	a0,s4
    800042fc:	00000097          	auipc	ra,0x0
    80004300:	99e080e7          	jalr	-1634(ra) # 80003c9a <ilock>
    if(ip->type != T_DIR){
    80004304:	044a1783          	lh	a5,68(s4)
    80004308:	f97791e3          	bne	a5,s7,8000428a <namex+0x5c>
    if(nameiparent && *path == '\0'){
    8000430c:	000b0563          	beqz	s6,80004316 <namex+0xe8>
    80004310:	0004c783          	lbu	a5,0(s1)
    80004314:	dfd9                	beqz	a5,800042b2 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004316:	4601                	li	a2,0
    80004318:	85d6                	mv	a1,s5
    8000431a:	8552                	mv	a0,s4
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	e62080e7          	jalr	-414(ra) # 8000417e <dirlookup>
    80004324:	89aa                	mv	s3,a0
    80004326:	dd41                	beqz	a0,800042be <namex+0x90>
    iunlockput(ip);
    80004328:	8552                	mv	a0,s4
    8000432a:	00000097          	auipc	ra,0x0
    8000432e:	bd2080e7          	jalr	-1070(ra) # 80003efc <iunlockput>
    ip = next;
    80004332:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004334:	0004c783          	lbu	a5,0(s1)
    80004338:	01279763          	bne	a5,s2,80004346 <namex+0x118>
    path++;
    8000433c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000433e:	0004c783          	lbu	a5,0(s1)
    80004342:	ff278de3          	beq	a5,s2,8000433c <namex+0x10e>
  if(*path == 0)
    80004346:	cb9d                	beqz	a5,8000437c <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004348:	0004c783          	lbu	a5,0(s1)
    8000434c:	89a6                	mv	s3,s1
  len = path - s;
    8000434e:	4c81                	li	s9,0
    80004350:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004352:	01278963          	beq	a5,s2,80004364 <namex+0x136>
    80004356:	dbbd                	beqz	a5,800042cc <namex+0x9e>
    path++;
    80004358:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000435a:	0009c783          	lbu	a5,0(s3)
    8000435e:	ff279ce3          	bne	a5,s2,80004356 <namex+0x128>
    80004362:	b7ad                	j	800042cc <namex+0x9e>
    memmove(name, s, len);
    80004364:	2601                	sext.w	a2,a2
    80004366:	85a6                	mv	a1,s1
    80004368:	8556                	mv	a0,s5
    8000436a:	ffffd097          	auipc	ra,0xffffd
    8000436e:	b32080e7          	jalr	-1230(ra) # 80000e9c <memmove>
    name[len] = 0;
    80004372:	9cd6                	add	s9,s9,s5
    80004374:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    80004378:	84ce                	mv	s1,s3
    8000437a:	b7bd                	j	800042e8 <namex+0xba>
  if(nameiparent){
    8000437c:	f00b0de3          	beqz	s6,80004296 <namex+0x68>
    iput(ip);
    80004380:	8552                	mv	a0,s4
    80004382:	00000097          	auipc	ra,0x0
    80004386:	ad2080e7          	jalr	-1326(ra) # 80003e54 <iput>
    return 0;
    8000438a:	4a01                	li	s4,0
    8000438c:	b729                	j	80004296 <namex+0x68>

000000008000438e <dirlink>:
{
    8000438e:	7139                	addi	sp,sp,-64
    80004390:	fc06                	sd	ra,56(sp)
    80004392:	f822                	sd	s0,48(sp)
    80004394:	f426                	sd	s1,40(sp)
    80004396:	f04a                	sd	s2,32(sp)
    80004398:	ec4e                	sd	s3,24(sp)
    8000439a:	e852                	sd	s4,16(sp)
    8000439c:	0080                	addi	s0,sp,64
    8000439e:	892a                	mv	s2,a0
    800043a0:	8a2e                	mv	s4,a1
    800043a2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800043a4:	4601                	li	a2,0
    800043a6:	00000097          	auipc	ra,0x0
    800043aa:	dd8080e7          	jalr	-552(ra) # 8000417e <dirlookup>
    800043ae:	e93d                	bnez	a0,80004424 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043b0:	04c92483          	lw	s1,76(s2)
    800043b4:	c49d                	beqz	s1,800043e2 <dirlink+0x54>
    800043b6:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043b8:	4741                	li	a4,16
    800043ba:	86a6                	mv	a3,s1
    800043bc:	fc040613          	addi	a2,s0,-64
    800043c0:	4581                	li	a1,0
    800043c2:	854a                	mv	a0,s2
    800043c4:	00000097          	auipc	ra,0x0
    800043c8:	b8a080e7          	jalr	-1142(ra) # 80003f4e <readi>
    800043cc:	47c1                	li	a5,16
    800043ce:	06f51163          	bne	a0,a5,80004430 <dirlink+0xa2>
    if(de.inum == 0)
    800043d2:	fc045783          	lhu	a5,-64(s0)
    800043d6:	c791                	beqz	a5,800043e2 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800043d8:	24c1                	addiw	s1,s1,16
    800043da:	04c92783          	lw	a5,76(s2)
    800043de:	fcf4ede3          	bltu	s1,a5,800043b8 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800043e2:	4639                	li	a2,14
    800043e4:	85d2                	mv	a1,s4
    800043e6:	fc240513          	addi	a0,s0,-62
    800043ea:	ffffd097          	auipc	ra,0xffffd
    800043ee:	b62080e7          	jalr	-1182(ra) # 80000f4c <strncpy>
  de.inum = inum;
    800043f2:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800043f6:	4741                	li	a4,16
    800043f8:	86a6                	mv	a3,s1
    800043fa:	fc040613          	addi	a2,s0,-64
    800043fe:	4581                	li	a1,0
    80004400:	854a                	mv	a0,s2
    80004402:	00000097          	auipc	ra,0x0
    80004406:	c44080e7          	jalr	-956(ra) # 80004046 <writei>
    8000440a:	1541                	addi	a0,a0,-16
    8000440c:	00a03533          	snez	a0,a0
    80004410:	40a00533          	neg	a0,a0
}
    80004414:	70e2                	ld	ra,56(sp)
    80004416:	7442                	ld	s0,48(sp)
    80004418:	74a2                	ld	s1,40(sp)
    8000441a:	7902                	ld	s2,32(sp)
    8000441c:	69e2                	ld	s3,24(sp)
    8000441e:	6a42                	ld	s4,16(sp)
    80004420:	6121                	addi	sp,sp,64
    80004422:	8082                	ret
    iput(ip);
    80004424:	00000097          	auipc	ra,0x0
    80004428:	a30080e7          	jalr	-1488(ra) # 80003e54 <iput>
    return -1;
    8000442c:	557d                	li	a0,-1
    8000442e:	b7dd                	j	80004414 <dirlink+0x86>
      panic("dirlink read");
    80004430:	00004517          	auipc	a0,0x4
    80004434:	32050513          	addi	a0,a0,800 # 80008750 <syscalls+0x1f0>
    80004438:	ffffc097          	auipc	ra,0xffffc
    8000443c:	104080e7          	jalr	260(ra) # 8000053c <panic>

0000000080004440 <namei>:

struct inode*
namei(char *path)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004448:	fe040613          	addi	a2,s0,-32
    8000444c:	4581                	li	a1,0
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	de0080e7          	jalr	-544(ra) # 8000422e <namex>
}
    80004456:	60e2                	ld	ra,24(sp)
    80004458:	6442                	ld	s0,16(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000445e:	1141                	addi	sp,sp,-16
    80004460:	e406                	sd	ra,8(sp)
    80004462:	e022                	sd	s0,0(sp)
    80004464:	0800                	addi	s0,sp,16
    80004466:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004468:	4585                	li	a1,1
    8000446a:	00000097          	auipc	ra,0x0
    8000446e:	dc4080e7          	jalr	-572(ra) # 8000422e <namex>
}
    80004472:	60a2                	ld	ra,8(sp)
    80004474:	6402                	ld	s0,0(sp)
    80004476:	0141                	addi	sp,sp,16
    80004478:	8082                	ret

000000008000447a <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000447a:	1101                	addi	sp,sp,-32
    8000447c:	ec06                	sd	ra,24(sp)
    8000447e:	e822                	sd	s0,16(sp)
    80004480:	e426                	sd	s1,8(sp)
    80004482:	e04a                	sd	s2,0(sp)
    80004484:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004486:	0023c917          	auipc	s2,0x23c
    8000448a:	7fa90913          	addi	s2,s2,2042 # 80240c80 <log>
    8000448e:	01892583          	lw	a1,24(s2)
    80004492:	02892503          	lw	a0,40(s2)
    80004496:	fffff097          	auipc	ra,0xfffff
    8000449a:	ff4080e7          	jalr	-12(ra) # 8000348a <bread>
    8000449e:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800044a0:	02c92603          	lw	a2,44(s2)
    800044a4:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800044a6:	00c05f63          	blez	a2,800044c4 <write_head+0x4a>
    800044aa:	0023d717          	auipc	a4,0x23d
    800044ae:	80670713          	addi	a4,a4,-2042 # 80240cb0 <log+0x30>
    800044b2:	87aa                	mv	a5,a0
    800044b4:	060a                	slli	a2,a2,0x2
    800044b6:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800044b8:	4314                	lw	a3,0(a4)
    800044ba:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800044bc:	0711                	addi	a4,a4,4
    800044be:	0791                	addi	a5,a5,4
    800044c0:	fec79ce3          	bne	a5,a2,800044b8 <write_head+0x3e>
  }
  bwrite(buf);
    800044c4:	8526                	mv	a0,s1
    800044c6:	fffff097          	auipc	ra,0xfffff
    800044ca:	0b6080e7          	jalr	182(ra) # 8000357c <bwrite>
  brelse(buf);
    800044ce:	8526                	mv	a0,s1
    800044d0:	fffff097          	auipc	ra,0xfffff
    800044d4:	0ea080e7          	jalr	234(ra) # 800035ba <brelse>
}
    800044d8:	60e2                	ld	ra,24(sp)
    800044da:	6442                	ld	s0,16(sp)
    800044dc:	64a2                	ld	s1,8(sp)
    800044de:	6902                	ld	s2,0(sp)
    800044e0:	6105                	addi	sp,sp,32
    800044e2:	8082                	ret

00000000800044e4 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800044e4:	0023c797          	auipc	a5,0x23c
    800044e8:	7c87a783          	lw	a5,1992(a5) # 80240cac <log+0x2c>
    800044ec:	0af05d63          	blez	a5,800045a6 <install_trans+0xc2>
{
    800044f0:	7139                	addi	sp,sp,-64
    800044f2:	fc06                	sd	ra,56(sp)
    800044f4:	f822                	sd	s0,48(sp)
    800044f6:	f426                	sd	s1,40(sp)
    800044f8:	f04a                	sd	s2,32(sp)
    800044fa:	ec4e                	sd	s3,24(sp)
    800044fc:	e852                	sd	s4,16(sp)
    800044fe:	e456                	sd	s5,8(sp)
    80004500:	e05a                	sd	s6,0(sp)
    80004502:	0080                	addi	s0,sp,64
    80004504:	8b2a                	mv	s6,a0
    80004506:	0023ca97          	auipc	s5,0x23c
    8000450a:	7aaa8a93          	addi	s5,s5,1962 # 80240cb0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000450e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004510:	0023c997          	auipc	s3,0x23c
    80004514:	77098993          	addi	s3,s3,1904 # 80240c80 <log>
    80004518:	a00d                	j	8000453a <install_trans+0x56>
    brelse(lbuf);
    8000451a:	854a                	mv	a0,s2
    8000451c:	fffff097          	auipc	ra,0xfffff
    80004520:	09e080e7          	jalr	158(ra) # 800035ba <brelse>
    brelse(dbuf);
    80004524:	8526                	mv	a0,s1
    80004526:	fffff097          	auipc	ra,0xfffff
    8000452a:	094080e7          	jalr	148(ra) # 800035ba <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000452e:	2a05                	addiw	s4,s4,1
    80004530:	0a91                	addi	s5,s5,4
    80004532:	02c9a783          	lw	a5,44(s3)
    80004536:	04fa5e63          	bge	s4,a5,80004592 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000453a:	0189a583          	lw	a1,24(s3)
    8000453e:	014585bb          	addw	a1,a1,s4
    80004542:	2585                	addiw	a1,a1,1
    80004544:	0289a503          	lw	a0,40(s3)
    80004548:	fffff097          	auipc	ra,0xfffff
    8000454c:	f42080e7          	jalr	-190(ra) # 8000348a <bread>
    80004550:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004552:	000aa583          	lw	a1,0(s5)
    80004556:	0289a503          	lw	a0,40(s3)
    8000455a:	fffff097          	auipc	ra,0xfffff
    8000455e:	f30080e7          	jalr	-208(ra) # 8000348a <bread>
    80004562:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004564:	40000613          	li	a2,1024
    80004568:	05890593          	addi	a1,s2,88
    8000456c:	05850513          	addi	a0,a0,88
    80004570:	ffffd097          	auipc	ra,0xffffd
    80004574:	92c080e7          	jalr	-1748(ra) # 80000e9c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004578:	8526                	mv	a0,s1
    8000457a:	fffff097          	auipc	ra,0xfffff
    8000457e:	002080e7          	jalr	2(ra) # 8000357c <bwrite>
    if(recovering == 0)
    80004582:	f80b1ce3          	bnez	s6,8000451a <install_trans+0x36>
      bunpin(dbuf);
    80004586:	8526                	mv	a0,s1
    80004588:	fffff097          	auipc	ra,0xfffff
    8000458c:	10a080e7          	jalr	266(ra) # 80003692 <bunpin>
    80004590:	b769                	j	8000451a <install_trans+0x36>
}
    80004592:	70e2                	ld	ra,56(sp)
    80004594:	7442                	ld	s0,48(sp)
    80004596:	74a2                	ld	s1,40(sp)
    80004598:	7902                	ld	s2,32(sp)
    8000459a:	69e2                	ld	s3,24(sp)
    8000459c:	6a42                	ld	s4,16(sp)
    8000459e:	6aa2                	ld	s5,8(sp)
    800045a0:	6b02                	ld	s6,0(sp)
    800045a2:	6121                	addi	sp,sp,64
    800045a4:	8082                	ret
    800045a6:	8082                	ret

00000000800045a8 <initlog>:
{
    800045a8:	7179                	addi	sp,sp,-48
    800045aa:	f406                	sd	ra,40(sp)
    800045ac:	f022                	sd	s0,32(sp)
    800045ae:	ec26                	sd	s1,24(sp)
    800045b0:	e84a                	sd	s2,16(sp)
    800045b2:	e44e                	sd	s3,8(sp)
    800045b4:	1800                	addi	s0,sp,48
    800045b6:	892a                	mv	s2,a0
    800045b8:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800045ba:	0023c497          	auipc	s1,0x23c
    800045be:	6c648493          	addi	s1,s1,1734 # 80240c80 <log>
    800045c2:	00004597          	auipc	a1,0x4
    800045c6:	19e58593          	addi	a1,a1,414 # 80008760 <syscalls+0x200>
    800045ca:	8526                	mv	a0,s1
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6e8080e7          	jalr	1768(ra) # 80000cb4 <initlock>
  log.start = sb->logstart;
    800045d4:	0149a583          	lw	a1,20(s3)
    800045d8:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800045da:	0109a783          	lw	a5,16(s3)
    800045de:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800045e0:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800045e4:	854a                	mv	a0,s2
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	ea4080e7          	jalr	-348(ra) # 8000348a <bread>
  log.lh.n = lh->n;
    800045ee:	4d30                	lw	a2,88(a0)
    800045f0:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800045f2:	00c05f63          	blez	a2,80004610 <initlog+0x68>
    800045f6:	87aa                	mv	a5,a0
    800045f8:	0023c717          	auipc	a4,0x23c
    800045fc:	6b870713          	addi	a4,a4,1720 # 80240cb0 <log+0x30>
    80004600:	060a                	slli	a2,a2,0x2
    80004602:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004604:	4ff4                	lw	a3,92(a5)
    80004606:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004608:	0791                	addi	a5,a5,4
    8000460a:	0711                	addi	a4,a4,4
    8000460c:	fec79ce3          	bne	a5,a2,80004604 <initlog+0x5c>
  brelse(buf);
    80004610:	fffff097          	auipc	ra,0xfffff
    80004614:	faa080e7          	jalr	-86(ra) # 800035ba <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004618:	4505                	li	a0,1
    8000461a:	00000097          	auipc	ra,0x0
    8000461e:	eca080e7          	jalr	-310(ra) # 800044e4 <install_trans>
  log.lh.n = 0;
    80004622:	0023c797          	auipc	a5,0x23c
    80004626:	6807a523          	sw	zero,1674(a5) # 80240cac <log+0x2c>
  write_head(); // clear the log
    8000462a:	00000097          	auipc	ra,0x0
    8000462e:	e50080e7          	jalr	-432(ra) # 8000447a <write_head>
}
    80004632:	70a2                	ld	ra,40(sp)
    80004634:	7402                	ld	s0,32(sp)
    80004636:	64e2                	ld	s1,24(sp)
    80004638:	6942                	ld	s2,16(sp)
    8000463a:	69a2                	ld	s3,8(sp)
    8000463c:	6145                	addi	sp,sp,48
    8000463e:	8082                	ret

0000000080004640 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004640:	1101                	addi	sp,sp,-32
    80004642:	ec06                	sd	ra,24(sp)
    80004644:	e822                	sd	s0,16(sp)
    80004646:	e426                	sd	s1,8(sp)
    80004648:	e04a                	sd	s2,0(sp)
    8000464a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000464c:	0023c517          	auipc	a0,0x23c
    80004650:	63450513          	addi	a0,a0,1588 # 80240c80 <log>
    80004654:	ffffc097          	auipc	ra,0xffffc
    80004658:	6f0080e7          	jalr	1776(ra) # 80000d44 <acquire>
  while(1){
    if(log.committing){
    8000465c:	0023c497          	auipc	s1,0x23c
    80004660:	62448493          	addi	s1,s1,1572 # 80240c80 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004664:	4979                	li	s2,30
    80004666:	a039                	j	80004674 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004668:	85a6                	mv	a1,s1
    8000466a:	8526                	mv	a0,s1
    8000466c:	ffffe097          	auipc	ra,0xffffe
    80004670:	dc0080e7          	jalr	-576(ra) # 8000242c <sleep>
    if(log.committing){
    80004674:	50dc                	lw	a5,36(s1)
    80004676:	fbed                	bnez	a5,80004668 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004678:	5098                	lw	a4,32(s1)
    8000467a:	2705                	addiw	a4,a4,1
    8000467c:	0027179b          	slliw	a5,a4,0x2
    80004680:	9fb9                	addw	a5,a5,a4
    80004682:	0017979b          	slliw	a5,a5,0x1
    80004686:	54d4                	lw	a3,44(s1)
    80004688:	9fb5                	addw	a5,a5,a3
    8000468a:	00f95963          	bge	s2,a5,8000469c <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000468e:	85a6                	mv	a1,s1
    80004690:	8526                	mv	a0,s1
    80004692:	ffffe097          	auipc	ra,0xffffe
    80004696:	d9a080e7          	jalr	-614(ra) # 8000242c <sleep>
    8000469a:	bfe9                	j	80004674 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000469c:	0023c517          	auipc	a0,0x23c
    800046a0:	5e450513          	addi	a0,a0,1508 # 80240c80 <log>
    800046a4:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	752080e7          	jalr	1874(ra) # 80000df8 <release>
      break;
    }
  }
}
    800046ae:	60e2                	ld	ra,24(sp)
    800046b0:	6442                	ld	s0,16(sp)
    800046b2:	64a2                	ld	s1,8(sp)
    800046b4:	6902                	ld	s2,0(sp)
    800046b6:	6105                	addi	sp,sp,32
    800046b8:	8082                	ret

00000000800046ba <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800046ba:	7139                	addi	sp,sp,-64
    800046bc:	fc06                	sd	ra,56(sp)
    800046be:	f822                	sd	s0,48(sp)
    800046c0:	f426                	sd	s1,40(sp)
    800046c2:	f04a                	sd	s2,32(sp)
    800046c4:	ec4e                	sd	s3,24(sp)
    800046c6:	e852                	sd	s4,16(sp)
    800046c8:	e456                	sd	s5,8(sp)
    800046ca:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800046cc:	0023c497          	auipc	s1,0x23c
    800046d0:	5b448493          	addi	s1,s1,1460 # 80240c80 <log>
    800046d4:	8526                	mv	a0,s1
    800046d6:	ffffc097          	auipc	ra,0xffffc
    800046da:	66e080e7          	jalr	1646(ra) # 80000d44 <acquire>
  log.outstanding -= 1;
    800046de:	509c                	lw	a5,32(s1)
    800046e0:	37fd                	addiw	a5,a5,-1
    800046e2:	0007891b          	sext.w	s2,a5
    800046e6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800046e8:	50dc                	lw	a5,36(s1)
    800046ea:	e7b9                	bnez	a5,80004738 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800046ec:	04091e63          	bnez	s2,80004748 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800046f0:	0023c497          	auipc	s1,0x23c
    800046f4:	59048493          	addi	s1,s1,1424 # 80240c80 <log>
    800046f8:	4785                	li	a5,1
    800046fa:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046fc:	8526                	mv	a0,s1
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	6fa080e7          	jalr	1786(ra) # 80000df8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004706:	54dc                	lw	a5,44(s1)
    80004708:	06f04763          	bgtz	a5,80004776 <end_op+0xbc>
    acquire(&log.lock);
    8000470c:	0023c497          	auipc	s1,0x23c
    80004710:	57448493          	addi	s1,s1,1396 # 80240c80 <log>
    80004714:	8526                	mv	a0,s1
    80004716:	ffffc097          	auipc	ra,0xffffc
    8000471a:	62e080e7          	jalr	1582(ra) # 80000d44 <acquire>
    log.committing = 0;
    8000471e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004722:	8526                	mv	a0,s1
    80004724:	ffffe097          	auipc	ra,0xffffe
    80004728:	d6c080e7          	jalr	-660(ra) # 80002490 <wakeup>
    release(&log.lock);
    8000472c:	8526                	mv	a0,s1
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	6ca080e7          	jalr	1738(ra) # 80000df8 <release>
}
    80004736:	a03d                	j	80004764 <end_op+0xaa>
    panic("log.committing");
    80004738:	00004517          	auipc	a0,0x4
    8000473c:	03050513          	addi	a0,a0,48 # 80008768 <syscalls+0x208>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	dfc080e7          	jalr	-516(ra) # 8000053c <panic>
    wakeup(&log);
    80004748:	0023c497          	auipc	s1,0x23c
    8000474c:	53848493          	addi	s1,s1,1336 # 80240c80 <log>
    80004750:	8526                	mv	a0,s1
    80004752:	ffffe097          	auipc	ra,0xffffe
    80004756:	d3e080e7          	jalr	-706(ra) # 80002490 <wakeup>
  release(&log.lock);
    8000475a:	8526                	mv	a0,s1
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	69c080e7          	jalr	1692(ra) # 80000df8 <release>
}
    80004764:	70e2                	ld	ra,56(sp)
    80004766:	7442                	ld	s0,48(sp)
    80004768:	74a2                	ld	s1,40(sp)
    8000476a:	7902                	ld	s2,32(sp)
    8000476c:	69e2                	ld	s3,24(sp)
    8000476e:	6a42                	ld	s4,16(sp)
    80004770:	6aa2                	ld	s5,8(sp)
    80004772:	6121                	addi	sp,sp,64
    80004774:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004776:	0023ca97          	auipc	s5,0x23c
    8000477a:	53aa8a93          	addi	s5,s5,1338 # 80240cb0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000477e:	0023ca17          	auipc	s4,0x23c
    80004782:	502a0a13          	addi	s4,s4,1282 # 80240c80 <log>
    80004786:	018a2583          	lw	a1,24(s4)
    8000478a:	012585bb          	addw	a1,a1,s2
    8000478e:	2585                	addiw	a1,a1,1
    80004790:	028a2503          	lw	a0,40(s4)
    80004794:	fffff097          	auipc	ra,0xfffff
    80004798:	cf6080e7          	jalr	-778(ra) # 8000348a <bread>
    8000479c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000479e:	000aa583          	lw	a1,0(s5)
    800047a2:	028a2503          	lw	a0,40(s4)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	ce4080e7          	jalr	-796(ra) # 8000348a <bread>
    800047ae:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800047b0:	40000613          	li	a2,1024
    800047b4:	05850593          	addi	a1,a0,88
    800047b8:	05848513          	addi	a0,s1,88
    800047bc:	ffffc097          	auipc	ra,0xffffc
    800047c0:	6e0080e7          	jalr	1760(ra) # 80000e9c <memmove>
    bwrite(to);  // write the log
    800047c4:	8526                	mv	a0,s1
    800047c6:	fffff097          	auipc	ra,0xfffff
    800047ca:	db6080e7          	jalr	-586(ra) # 8000357c <bwrite>
    brelse(from);
    800047ce:	854e                	mv	a0,s3
    800047d0:	fffff097          	auipc	ra,0xfffff
    800047d4:	dea080e7          	jalr	-534(ra) # 800035ba <brelse>
    brelse(to);
    800047d8:	8526                	mv	a0,s1
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	de0080e7          	jalr	-544(ra) # 800035ba <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800047e2:	2905                	addiw	s2,s2,1
    800047e4:	0a91                	addi	s5,s5,4
    800047e6:	02ca2783          	lw	a5,44(s4)
    800047ea:	f8f94ee3          	blt	s2,a5,80004786 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800047ee:	00000097          	auipc	ra,0x0
    800047f2:	c8c080e7          	jalr	-884(ra) # 8000447a <write_head>
    install_trans(0); // Now install writes to home locations
    800047f6:	4501                	li	a0,0
    800047f8:	00000097          	auipc	ra,0x0
    800047fc:	cec080e7          	jalr	-788(ra) # 800044e4 <install_trans>
    log.lh.n = 0;
    80004800:	0023c797          	auipc	a5,0x23c
    80004804:	4a07a623          	sw	zero,1196(a5) # 80240cac <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004808:	00000097          	auipc	ra,0x0
    8000480c:	c72080e7          	jalr	-910(ra) # 8000447a <write_head>
    80004810:	bdf5                	j	8000470c <end_op+0x52>

0000000080004812 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004812:	1101                	addi	sp,sp,-32
    80004814:	ec06                	sd	ra,24(sp)
    80004816:	e822                	sd	s0,16(sp)
    80004818:	e426                	sd	s1,8(sp)
    8000481a:	e04a                	sd	s2,0(sp)
    8000481c:	1000                	addi	s0,sp,32
    8000481e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004820:	0023c917          	auipc	s2,0x23c
    80004824:	46090913          	addi	s2,s2,1120 # 80240c80 <log>
    80004828:	854a                	mv	a0,s2
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	51a080e7          	jalr	1306(ra) # 80000d44 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004832:	02c92603          	lw	a2,44(s2)
    80004836:	47f5                	li	a5,29
    80004838:	06c7c563          	blt	a5,a2,800048a2 <log_write+0x90>
    8000483c:	0023c797          	auipc	a5,0x23c
    80004840:	4607a783          	lw	a5,1120(a5) # 80240c9c <log+0x1c>
    80004844:	37fd                	addiw	a5,a5,-1
    80004846:	04f65e63          	bge	a2,a5,800048a2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000484a:	0023c797          	auipc	a5,0x23c
    8000484e:	4567a783          	lw	a5,1110(a5) # 80240ca0 <log+0x20>
    80004852:	06f05063          	blez	a5,800048b2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004856:	4781                	li	a5,0
    80004858:	06c05563          	blez	a2,800048c2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000485c:	44cc                	lw	a1,12(s1)
    8000485e:	0023c717          	auipc	a4,0x23c
    80004862:	45270713          	addi	a4,a4,1106 # 80240cb0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004866:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004868:	4314                	lw	a3,0(a4)
    8000486a:	04b68c63          	beq	a3,a1,800048c2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000486e:	2785                	addiw	a5,a5,1
    80004870:	0711                	addi	a4,a4,4
    80004872:	fef61be3          	bne	a2,a5,80004868 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004876:	0621                	addi	a2,a2,8
    80004878:	060a                	slli	a2,a2,0x2
    8000487a:	0023c797          	auipc	a5,0x23c
    8000487e:	40678793          	addi	a5,a5,1030 # 80240c80 <log>
    80004882:	97b2                	add	a5,a5,a2
    80004884:	44d8                	lw	a4,12(s1)
    80004886:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004888:	8526                	mv	a0,s1
    8000488a:	fffff097          	auipc	ra,0xfffff
    8000488e:	dcc080e7          	jalr	-564(ra) # 80003656 <bpin>
    log.lh.n++;
    80004892:	0023c717          	auipc	a4,0x23c
    80004896:	3ee70713          	addi	a4,a4,1006 # 80240c80 <log>
    8000489a:	575c                	lw	a5,44(a4)
    8000489c:	2785                	addiw	a5,a5,1
    8000489e:	d75c                	sw	a5,44(a4)
    800048a0:	a82d                	j	800048da <log_write+0xc8>
    panic("too big a transaction");
    800048a2:	00004517          	auipc	a0,0x4
    800048a6:	ed650513          	addi	a0,a0,-298 # 80008778 <syscalls+0x218>
    800048aa:	ffffc097          	auipc	ra,0xffffc
    800048ae:	c92080e7          	jalr	-878(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800048b2:	00004517          	auipc	a0,0x4
    800048b6:	ede50513          	addi	a0,a0,-290 # 80008790 <syscalls+0x230>
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	c82080e7          	jalr	-894(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800048c2:	00878693          	addi	a3,a5,8
    800048c6:	068a                	slli	a3,a3,0x2
    800048c8:	0023c717          	auipc	a4,0x23c
    800048cc:	3b870713          	addi	a4,a4,952 # 80240c80 <log>
    800048d0:	9736                	add	a4,a4,a3
    800048d2:	44d4                	lw	a3,12(s1)
    800048d4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800048d6:	faf609e3          	beq	a2,a5,80004888 <log_write+0x76>
  }
  release(&log.lock);
    800048da:	0023c517          	auipc	a0,0x23c
    800048de:	3a650513          	addi	a0,a0,934 # 80240c80 <log>
    800048e2:	ffffc097          	auipc	ra,0xffffc
    800048e6:	516080e7          	jalr	1302(ra) # 80000df8 <release>
}
    800048ea:	60e2                	ld	ra,24(sp)
    800048ec:	6442                	ld	s0,16(sp)
    800048ee:	64a2                	ld	s1,8(sp)
    800048f0:	6902                	ld	s2,0(sp)
    800048f2:	6105                	addi	sp,sp,32
    800048f4:	8082                	ret

00000000800048f6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048f6:	1101                	addi	sp,sp,-32
    800048f8:	ec06                	sd	ra,24(sp)
    800048fa:	e822                	sd	s0,16(sp)
    800048fc:	e426                	sd	s1,8(sp)
    800048fe:	e04a                	sd	s2,0(sp)
    80004900:	1000                	addi	s0,sp,32
    80004902:	84aa                	mv	s1,a0
    80004904:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004906:	00004597          	auipc	a1,0x4
    8000490a:	eaa58593          	addi	a1,a1,-342 # 800087b0 <syscalls+0x250>
    8000490e:	0521                	addi	a0,a0,8
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	3a4080e7          	jalr	932(ra) # 80000cb4 <initlock>
  lk->name = name;
    80004918:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000491c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004920:	0204a423          	sw	zero,40(s1)
}
    80004924:	60e2                	ld	ra,24(sp)
    80004926:	6442                	ld	s0,16(sp)
    80004928:	64a2                	ld	s1,8(sp)
    8000492a:	6902                	ld	s2,0(sp)
    8000492c:	6105                	addi	sp,sp,32
    8000492e:	8082                	ret

0000000080004930 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004930:	1101                	addi	sp,sp,-32
    80004932:	ec06                	sd	ra,24(sp)
    80004934:	e822                	sd	s0,16(sp)
    80004936:	e426                	sd	s1,8(sp)
    80004938:	e04a                	sd	s2,0(sp)
    8000493a:	1000                	addi	s0,sp,32
    8000493c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000493e:	00850913          	addi	s2,a0,8
    80004942:	854a                	mv	a0,s2
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	400080e7          	jalr	1024(ra) # 80000d44 <acquire>
  while (lk->locked) {
    8000494c:	409c                	lw	a5,0(s1)
    8000494e:	cb89                	beqz	a5,80004960 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004950:	85ca                	mv	a1,s2
    80004952:	8526                	mv	a0,s1
    80004954:	ffffe097          	auipc	ra,0xffffe
    80004958:	ad8080e7          	jalr	-1320(ra) # 8000242c <sleep>
  while (lk->locked) {
    8000495c:	409c                	lw	a5,0(s1)
    8000495e:	fbed                	bnez	a5,80004950 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004960:	4785                	li	a5,1
    80004962:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004964:	ffffd097          	auipc	ra,0xffffd
    80004968:	360080e7          	jalr	864(ra) # 80001cc4 <myproc>
    8000496c:	591c                	lw	a5,48(a0)
    8000496e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004970:	854a                	mv	a0,s2
    80004972:	ffffc097          	auipc	ra,0xffffc
    80004976:	486080e7          	jalr	1158(ra) # 80000df8 <release>
}
    8000497a:	60e2                	ld	ra,24(sp)
    8000497c:	6442                	ld	s0,16(sp)
    8000497e:	64a2                	ld	s1,8(sp)
    80004980:	6902                	ld	s2,0(sp)
    80004982:	6105                	addi	sp,sp,32
    80004984:	8082                	ret

0000000080004986 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004986:	1101                	addi	sp,sp,-32
    80004988:	ec06                	sd	ra,24(sp)
    8000498a:	e822                	sd	s0,16(sp)
    8000498c:	e426                	sd	s1,8(sp)
    8000498e:	e04a                	sd	s2,0(sp)
    80004990:	1000                	addi	s0,sp,32
    80004992:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004994:	00850913          	addi	s2,a0,8
    80004998:	854a                	mv	a0,s2
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	3aa080e7          	jalr	938(ra) # 80000d44 <acquire>
  lk->locked = 0;
    800049a2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800049a6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800049aa:	8526                	mv	a0,s1
    800049ac:	ffffe097          	auipc	ra,0xffffe
    800049b0:	ae4080e7          	jalr	-1308(ra) # 80002490 <wakeup>
  release(&lk->lk);
    800049b4:	854a                	mv	a0,s2
    800049b6:	ffffc097          	auipc	ra,0xffffc
    800049ba:	442080e7          	jalr	1090(ra) # 80000df8 <release>
}
    800049be:	60e2                	ld	ra,24(sp)
    800049c0:	6442                	ld	s0,16(sp)
    800049c2:	64a2                	ld	s1,8(sp)
    800049c4:	6902                	ld	s2,0(sp)
    800049c6:	6105                	addi	sp,sp,32
    800049c8:	8082                	ret

00000000800049ca <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800049ca:	7179                	addi	sp,sp,-48
    800049cc:	f406                	sd	ra,40(sp)
    800049ce:	f022                	sd	s0,32(sp)
    800049d0:	ec26                	sd	s1,24(sp)
    800049d2:	e84a                	sd	s2,16(sp)
    800049d4:	e44e                	sd	s3,8(sp)
    800049d6:	1800                	addi	s0,sp,48
    800049d8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800049da:	00850913          	addi	s2,a0,8
    800049de:	854a                	mv	a0,s2
    800049e0:	ffffc097          	auipc	ra,0xffffc
    800049e4:	364080e7          	jalr	868(ra) # 80000d44 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800049e8:	409c                	lw	a5,0(s1)
    800049ea:	ef99                	bnez	a5,80004a08 <holdingsleep+0x3e>
    800049ec:	4481                	li	s1,0
  release(&lk->lk);
    800049ee:	854a                	mv	a0,s2
    800049f0:	ffffc097          	auipc	ra,0xffffc
    800049f4:	408080e7          	jalr	1032(ra) # 80000df8 <release>
  return r;
}
    800049f8:	8526                	mv	a0,s1
    800049fa:	70a2                	ld	ra,40(sp)
    800049fc:	7402                	ld	s0,32(sp)
    800049fe:	64e2                	ld	s1,24(sp)
    80004a00:	6942                	ld	s2,16(sp)
    80004a02:	69a2                	ld	s3,8(sp)
    80004a04:	6145                	addi	sp,sp,48
    80004a06:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004a08:	0284a983          	lw	s3,40(s1)
    80004a0c:	ffffd097          	auipc	ra,0xffffd
    80004a10:	2b8080e7          	jalr	696(ra) # 80001cc4 <myproc>
    80004a14:	5904                	lw	s1,48(a0)
    80004a16:	413484b3          	sub	s1,s1,s3
    80004a1a:	0014b493          	seqz	s1,s1
    80004a1e:	bfc1                	j	800049ee <holdingsleep+0x24>

0000000080004a20 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004a20:	1141                	addi	sp,sp,-16
    80004a22:	e406                	sd	ra,8(sp)
    80004a24:	e022                	sd	s0,0(sp)
    80004a26:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004a28:	00004597          	auipc	a1,0x4
    80004a2c:	d9858593          	addi	a1,a1,-616 # 800087c0 <syscalls+0x260>
    80004a30:	0023c517          	auipc	a0,0x23c
    80004a34:	39850513          	addi	a0,a0,920 # 80240dc8 <ftable>
    80004a38:	ffffc097          	auipc	ra,0xffffc
    80004a3c:	27c080e7          	jalr	636(ra) # 80000cb4 <initlock>
}
    80004a40:	60a2                	ld	ra,8(sp)
    80004a42:	6402                	ld	s0,0(sp)
    80004a44:	0141                	addi	sp,sp,16
    80004a46:	8082                	ret

0000000080004a48 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004a48:	1101                	addi	sp,sp,-32
    80004a4a:	ec06                	sd	ra,24(sp)
    80004a4c:	e822                	sd	s0,16(sp)
    80004a4e:	e426                	sd	s1,8(sp)
    80004a50:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004a52:	0023c517          	auipc	a0,0x23c
    80004a56:	37650513          	addi	a0,a0,886 # 80240dc8 <ftable>
    80004a5a:	ffffc097          	auipc	ra,0xffffc
    80004a5e:	2ea080e7          	jalr	746(ra) # 80000d44 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a62:	0023c497          	auipc	s1,0x23c
    80004a66:	37e48493          	addi	s1,s1,894 # 80240de0 <ftable+0x18>
    80004a6a:	0023d717          	auipc	a4,0x23d
    80004a6e:	31670713          	addi	a4,a4,790 # 80241d80 <disk>
    if(f->ref == 0){
    80004a72:	40dc                	lw	a5,4(s1)
    80004a74:	cf99                	beqz	a5,80004a92 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a76:	02848493          	addi	s1,s1,40
    80004a7a:	fee49ce3          	bne	s1,a4,80004a72 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a7e:	0023c517          	auipc	a0,0x23c
    80004a82:	34a50513          	addi	a0,a0,842 # 80240dc8 <ftable>
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	372080e7          	jalr	882(ra) # 80000df8 <release>
  return 0;
    80004a8e:	4481                	li	s1,0
    80004a90:	a819                	j	80004aa6 <filealloc+0x5e>
      f->ref = 1;
    80004a92:	4785                	li	a5,1
    80004a94:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a96:	0023c517          	auipc	a0,0x23c
    80004a9a:	33250513          	addi	a0,a0,818 # 80240dc8 <ftable>
    80004a9e:	ffffc097          	auipc	ra,0xffffc
    80004aa2:	35a080e7          	jalr	858(ra) # 80000df8 <release>
}
    80004aa6:	8526                	mv	a0,s1
    80004aa8:	60e2                	ld	ra,24(sp)
    80004aaa:	6442                	ld	s0,16(sp)
    80004aac:	64a2                	ld	s1,8(sp)
    80004aae:	6105                	addi	sp,sp,32
    80004ab0:	8082                	ret

0000000080004ab2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004ab2:	1101                	addi	sp,sp,-32
    80004ab4:	ec06                	sd	ra,24(sp)
    80004ab6:	e822                	sd	s0,16(sp)
    80004ab8:	e426                	sd	s1,8(sp)
    80004aba:	1000                	addi	s0,sp,32
    80004abc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004abe:	0023c517          	auipc	a0,0x23c
    80004ac2:	30a50513          	addi	a0,a0,778 # 80240dc8 <ftable>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	27e080e7          	jalr	638(ra) # 80000d44 <acquire>
  if(f->ref < 1)
    80004ace:	40dc                	lw	a5,4(s1)
    80004ad0:	02f05263          	blez	a5,80004af4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004ad4:	2785                	addiw	a5,a5,1
    80004ad6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004ad8:	0023c517          	auipc	a0,0x23c
    80004adc:	2f050513          	addi	a0,a0,752 # 80240dc8 <ftable>
    80004ae0:	ffffc097          	auipc	ra,0xffffc
    80004ae4:	318080e7          	jalr	792(ra) # 80000df8 <release>
  return f;
}
    80004ae8:	8526                	mv	a0,s1
    80004aea:	60e2                	ld	ra,24(sp)
    80004aec:	6442                	ld	s0,16(sp)
    80004aee:	64a2                	ld	s1,8(sp)
    80004af0:	6105                	addi	sp,sp,32
    80004af2:	8082                	ret
    panic("filedup");
    80004af4:	00004517          	auipc	a0,0x4
    80004af8:	cd450513          	addi	a0,a0,-812 # 800087c8 <syscalls+0x268>
    80004afc:	ffffc097          	auipc	ra,0xffffc
    80004b00:	a40080e7          	jalr	-1472(ra) # 8000053c <panic>

0000000080004b04 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004b04:	7139                	addi	sp,sp,-64
    80004b06:	fc06                	sd	ra,56(sp)
    80004b08:	f822                	sd	s0,48(sp)
    80004b0a:	f426                	sd	s1,40(sp)
    80004b0c:	f04a                	sd	s2,32(sp)
    80004b0e:	ec4e                	sd	s3,24(sp)
    80004b10:	e852                	sd	s4,16(sp)
    80004b12:	e456                	sd	s5,8(sp)
    80004b14:	0080                	addi	s0,sp,64
    80004b16:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004b18:	0023c517          	auipc	a0,0x23c
    80004b1c:	2b050513          	addi	a0,a0,688 # 80240dc8 <ftable>
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	224080e7          	jalr	548(ra) # 80000d44 <acquire>
  if(f->ref < 1)
    80004b28:	40dc                	lw	a5,4(s1)
    80004b2a:	06f05163          	blez	a5,80004b8c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004b2e:	37fd                	addiw	a5,a5,-1
    80004b30:	0007871b          	sext.w	a4,a5
    80004b34:	c0dc                	sw	a5,4(s1)
    80004b36:	06e04363          	bgtz	a4,80004b9c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004b3a:	0004a903          	lw	s2,0(s1)
    80004b3e:	0094ca83          	lbu	s5,9(s1)
    80004b42:	0104ba03          	ld	s4,16(s1)
    80004b46:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004b4a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004b4e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004b52:	0023c517          	auipc	a0,0x23c
    80004b56:	27650513          	addi	a0,a0,630 # 80240dc8 <ftable>
    80004b5a:	ffffc097          	auipc	ra,0xffffc
    80004b5e:	29e080e7          	jalr	670(ra) # 80000df8 <release>

  if(ff.type == FD_PIPE){
    80004b62:	4785                	li	a5,1
    80004b64:	04f90d63          	beq	s2,a5,80004bbe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b68:	3979                	addiw	s2,s2,-2
    80004b6a:	4785                	li	a5,1
    80004b6c:	0527e063          	bltu	a5,s2,80004bac <fileclose+0xa8>
    begin_op();
    80004b70:	00000097          	auipc	ra,0x0
    80004b74:	ad0080e7          	jalr	-1328(ra) # 80004640 <begin_op>
    iput(ff.ip);
    80004b78:	854e                	mv	a0,s3
    80004b7a:	fffff097          	auipc	ra,0xfffff
    80004b7e:	2da080e7          	jalr	730(ra) # 80003e54 <iput>
    end_op();
    80004b82:	00000097          	auipc	ra,0x0
    80004b86:	b38080e7          	jalr	-1224(ra) # 800046ba <end_op>
    80004b8a:	a00d                	j	80004bac <fileclose+0xa8>
    panic("fileclose");
    80004b8c:	00004517          	auipc	a0,0x4
    80004b90:	c4450513          	addi	a0,a0,-956 # 800087d0 <syscalls+0x270>
    80004b94:	ffffc097          	auipc	ra,0xffffc
    80004b98:	9a8080e7          	jalr	-1624(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004b9c:	0023c517          	auipc	a0,0x23c
    80004ba0:	22c50513          	addi	a0,a0,556 # 80240dc8 <ftable>
    80004ba4:	ffffc097          	auipc	ra,0xffffc
    80004ba8:	254080e7          	jalr	596(ra) # 80000df8 <release>
  }
}
    80004bac:	70e2                	ld	ra,56(sp)
    80004bae:	7442                	ld	s0,48(sp)
    80004bb0:	74a2                	ld	s1,40(sp)
    80004bb2:	7902                	ld	s2,32(sp)
    80004bb4:	69e2                	ld	s3,24(sp)
    80004bb6:	6a42                	ld	s4,16(sp)
    80004bb8:	6aa2                	ld	s5,8(sp)
    80004bba:	6121                	addi	sp,sp,64
    80004bbc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004bbe:	85d6                	mv	a1,s5
    80004bc0:	8552                	mv	a0,s4
    80004bc2:	00000097          	auipc	ra,0x0
    80004bc6:	348080e7          	jalr	840(ra) # 80004f0a <pipeclose>
    80004bca:	b7cd                	j	80004bac <fileclose+0xa8>

0000000080004bcc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004bcc:	715d                	addi	sp,sp,-80
    80004bce:	e486                	sd	ra,72(sp)
    80004bd0:	e0a2                	sd	s0,64(sp)
    80004bd2:	fc26                	sd	s1,56(sp)
    80004bd4:	f84a                	sd	s2,48(sp)
    80004bd6:	f44e                	sd	s3,40(sp)
    80004bd8:	0880                	addi	s0,sp,80
    80004bda:	84aa                	mv	s1,a0
    80004bdc:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004bde:	ffffd097          	auipc	ra,0xffffd
    80004be2:	0e6080e7          	jalr	230(ra) # 80001cc4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004be6:	409c                	lw	a5,0(s1)
    80004be8:	37f9                	addiw	a5,a5,-2
    80004bea:	4705                	li	a4,1
    80004bec:	04f76763          	bltu	a4,a5,80004c3a <filestat+0x6e>
    80004bf0:	892a                	mv	s2,a0
    ilock(f->ip);
    80004bf2:	6c88                	ld	a0,24(s1)
    80004bf4:	fffff097          	auipc	ra,0xfffff
    80004bf8:	0a6080e7          	jalr	166(ra) # 80003c9a <ilock>
    stati(f->ip, &st);
    80004bfc:	fb840593          	addi	a1,s0,-72
    80004c00:	6c88                	ld	a0,24(s1)
    80004c02:	fffff097          	auipc	ra,0xfffff
    80004c06:	322080e7          	jalr	802(ra) # 80003f24 <stati>
    iunlock(f->ip);
    80004c0a:	6c88                	ld	a0,24(s1)
    80004c0c:	fffff097          	auipc	ra,0xfffff
    80004c10:	150080e7          	jalr	336(ra) # 80003d5c <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004c14:	46e1                	li	a3,24
    80004c16:	fb840613          	addi	a2,s0,-72
    80004c1a:	85ce                	mv	a1,s3
    80004c1c:	05093503          	ld	a0,80(s2)
    80004c20:	ffffd097          	auipc	ra,0xffffd
    80004c24:	c70080e7          	jalr	-912(ra) # 80001890 <copyout>
    80004c28:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004c2c:	60a6                	ld	ra,72(sp)
    80004c2e:	6406                	ld	s0,64(sp)
    80004c30:	74e2                	ld	s1,56(sp)
    80004c32:	7942                	ld	s2,48(sp)
    80004c34:	79a2                	ld	s3,40(sp)
    80004c36:	6161                	addi	sp,sp,80
    80004c38:	8082                	ret
  return -1;
    80004c3a:	557d                	li	a0,-1
    80004c3c:	bfc5                	j	80004c2c <filestat+0x60>

0000000080004c3e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004c3e:	7179                	addi	sp,sp,-48
    80004c40:	f406                	sd	ra,40(sp)
    80004c42:	f022                	sd	s0,32(sp)
    80004c44:	ec26                	sd	s1,24(sp)
    80004c46:	e84a                	sd	s2,16(sp)
    80004c48:	e44e                	sd	s3,8(sp)
    80004c4a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004c4c:	00854783          	lbu	a5,8(a0)
    80004c50:	c3d5                	beqz	a5,80004cf4 <fileread+0xb6>
    80004c52:	84aa                	mv	s1,a0
    80004c54:	89ae                	mv	s3,a1
    80004c56:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c58:	411c                	lw	a5,0(a0)
    80004c5a:	4705                	li	a4,1
    80004c5c:	04e78963          	beq	a5,a4,80004cae <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c60:	470d                	li	a4,3
    80004c62:	04e78d63          	beq	a5,a4,80004cbc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c66:	4709                	li	a4,2
    80004c68:	06e79e63          	bne	a5,a4,80004ce4 <fileread+0xa6>
    ilock(f->ip);
    80004c6c:	6d08                	ld	a0,24(a0)
    80004c6e:	fffff097          	auipc	ra,0xfffff
    80004c72:	02c080e7          	jalr	44(ra) # 80003c9a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c76:	874a                	mv	a4,s2
    80004c78:	5094                	lw	a3,32(s1)
    80004c7a:	864e                	mv	a2,s3
    80004c7c:	4585                	li	a1,1
    80004c7e:	6c88                	ld	a0,24(s1)
    80004c80:	fffff097          	auipc	ra,0xfffff
    80004c84:	2ce080e7          	jalr	718(ra) # 80003f4e <readi>
    80004c88:	892a                	mv	s2,a0
    80004c8a:	00a05563          	blez	a0,80004c94 <fileread+0x56>
      f->off += r;
    80004c8e:	509c                	lw	a5,32(s1)
    80004c90:	9fa9                	addw	a5,a5,a0
    80004c92:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c94:	6c88                	ld	a0,24(s1)
    80004c96:	fffff097          	auipc	ra,0xfffff
    80004c9a:	0c6080e7          	jalr	198(ra) # 80003d5c <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c9e:	854a                	mv	a0,s2
    80004ca0:	70a2                	ld	ra,40(sp)
    80004ca2:	7402                	ld	s0,32(sp)
    80004ca4:	64e2                	ld	s1,24(sp)
    80004ca6:	6942                	ld	s2,16(sp)
    80004ca8:	69a2                	ld	s3,8(sp)
    80004caa:	6145                	addi	sp,sp,48
    80004cac:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004cae:	6908                	ld	a0,16(a0)
    80004cb0:	00000097          	auipc	ra,0x0
    80004cb4:	3c2080e7          	jalr	962(ra) # 80005072 <piperead>
    80004cb8:	892a                	mv	s2,a0
    80004cba:	b7d5                	j	80004c9e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004cbc:	02451783          	lh	a5,36(a0)
    80004cc0:	03079693          	slli	a3,a5,0x30
    80004cc4:	92c1                	srli	a3,a3,0x30
    80004cc6:	4725                	li	a4,9
    80004cc8:	02d76863          	bltu	a4,a3,80004cf8 <fileread+0xba>
    80004ccc:	0792                	slli	a5,a5,0x4
    80004cce:	0023c717          	auipc	a4,0x23c
    80004cd2:	05a70713          	addi	a4,a4,90 # 80240d28 <devsw>
    80004cd6:	97ba                	add	a5,a5,a4
    80004cd8:	639c                	ld	a5,0(a5)
    80004cda:	c38d                	beqz	a5,80004cfc <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004cdc:	4505                	li	a0,1
    80004cde:	9782                	jalr	a5
    80004ce0:	892a                	mv	s2,a0
    80004ce2:	bf75                	j	80004c9e <fileread+0x60>
    panic("fileread");
    80004ce4:	00004517          	auipc	a0,0x4
    80004ce8:	afc50513          	addi	a0,a0,-1284 # 800087e0 <syscalls+0x280>
    80004cec:	ffffc097          	auipc	ra,0xffffc
    80004cf0:	850080e7          	jalr	-1968(ra) # 8000053c <panic>
    return -1;
    80004cf4:	597d                	li	s2,-1
    80004cf6:	b765                	j	80004c9e <fileread+0x60>
      return -1;
    80004cf8:	597d                	li	s2,-1
    80004cfa:	b755                	j	80004c9e <fileread+0x60>
    80004cfc:	597d                	li	s2,-1
    80004cfe:	b745                	j	80004c9e <fileread+0x60>

0000000080004d00 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004d00:	00954783          	lbu	a5,9(a0)
    80004d04:	10078e63          	beqz	a5,80004e20 <filewrite+0x120>
{
    80004d08:	715d                	addi	sp,sp,-80
    80004d0a:	e486                	sd	ra,72(sp)
    80004d0c:	e0a2                	sd	s0,64(sp)
    80004d0e:	fc26                	sd	s1,56(sp)
    80004d10:	f84a                	sd	s2,48(sp)
    80004d12:	f44e                	sd	s3,40(sp)
    80004d14:	f052                	sd	s4,32(sp)
    80004d16:	ec56                	sd	s5,24(sp)
    80004d18:	e85a                	sd	s6,16(sp)
    80004d1a:	e45e                	sd	s7,8(sp)
    80004d1c:	e062                	sd	s8,0(sp)
    80004d1e:	0880                	addi	s0,sp,80
    80004d20:	892a                	mv	s2,a0
    80004d22:	8b2e                	mv	s6,a1
    80004d24:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d26:	411c                	lw	a5,0(a0)
    80004d28:	4705                	li	a4,1
    80004d2a:	02e78263          	beq	a5,a4,80004d4e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d2e:	470d                	li	a4,3
    80004d30:	02e78563          	beq	a5,a4,80004d5a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d34:	4709                	li	a4,2
    80004d36:	0ce79d63          	bne	a5,a4,80004e10 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004d3a:	0ac05b63          	blez	a2,80004df0 <filewrite+0xf0>
    int i = 0;
    80004d3e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004d40:	6b85                	lui	s7,0x1
    80004d42:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004d46:	6c05                	lui	s8,0x1
    80004d48:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004d4c:	a851                	j	80004de0 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004d4e:	6908                	ld	a0,16(a0)
    80004d50:	00000097          	auipc	ra,0x0
    80004d54:	22a080e7          	jalr	554(ra) # 80004f7a <pipewrite>
    80004d58:	a045                	j	80004df8 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d5a:	02451783          	lh	a5,36(a0)
    80004d5e:	03079693          	slli	a3,a5,0x30
    80004d62:	92c1                	srli	a3,a3,0x30
    80004d64:	4725                	li	a4,9
    80004d66:	0ad76f63          	bltu	a4,a3,80004e24 <filewrite+0x124>
    80004d6a:	0792                	slli	a5,a5,0x4
    80004d6c:	0023c717          	auipc	a4,0x23c
    80004d70:	fbc70713          	addi	a4,a4,-68 # 80240d28 <devsw>
    80004d74:	97ba                	add	a5,a5,a4
    80004d76:	679c                	ld	a5,8(a5)
    80004d78:	cbc5                	beqz	a5,80004e28 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004d7a:	4505                	li	a0,1
    80004d7c:	9782                	jalr	a5
    80004d7e:	a8ad                	j	80004df8 <filewrite+0xf8>
      if(n1 > max)
    80004d80:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004d84:	00000097          	auipc	ra,0x0
    80004d88:	8bc080e7          	jalr	-1860(ra) # 80004640 <begin_op>
      ilock(f->ip);
    80004d8c:	01893503          	ld	a0,24(s2)
    80004d90:	fffff097          	auipc	ra,0xfffff
    80004d94:	f0a080e7          	jalr	-246(ra) # 80003c9a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d98:	8756                	mv	a4,s5
    80004d9a:	02092683          	lw	a3,32(s2)
    80004d9e:	01698633          	add	a2,s3,s6
    80004da2:	4585                	li	a1,1
    80004da4:	01893503          	ld	a0,24(s2)
    80004da8:	fffff097          	auipc	ra,0xfffff
    80004dac:	29e080e7          	jalr	670(ra) # 80004046 <writei>
    80004db0:	84aa                	mv	s1,a0
    80004db2:	00a05763          	blez	a0,80004dc0 <filewrite+0xc0>
        f->off += r;
    80004db6:	02092783          	lw	a5,32(s2)
    80004dba:	9fa9                	addw	a5,a5,a0
    80004dbc:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004dc0:	01893503          	ld	a0,24(s2)
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	f98080e7          	jalr	-104(ra) # 80003d5c <iunlock>
      end_op();
    80004dcc:	00000097          	auipc	ra,0x0
    80004dd0:	8ee080e7          	jalr	-1810(ra) # 800046ba <end_op>

      if(r != n1){
    80004dd4:	009a9f63          	bne	s5,s1,80004df2 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004dd8:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ddc:	0149db63          	bge	s3,s4,80004df2 <filewrite+0xf2>
      int n1 = n - i;
    80004de0:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004de4:	0004879b          	sext.w	a5,s1
    80004de8:	f8fbdce3          	bge	s7,a5,80004d80 <filewrite+0x80>
    80004dec:	84e2                	mv	s1,s8
    80004dee:	bf49                	j	80004d80 <filewrite+0x80>
    int i = 0;
    80004df0:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004df2:	033a1d63          	bne	s4,s3,80004e2c <filewrite+0x12c>
    80004df6:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004df8:	60a6                	ld	ra,72(sp)
    80004dfa:	6406                	ld	s0,64(sp)
    80004dfc:	74e2                	ld	s1,56(sp)
    80004dfe:	7942                	ld	s2,48(sp)
    80004e00:	79a2                	ld	s3,40(sp)
    80004e02:	7a02                	ld	s4,32(sp)
    80004e04:	6ae2                	ld	s5,24(sp)
    80004e06:	6b42                	ld	s6,16(sp)
    80004e08:	6ba2                	ld	s7,8(sp)
    80004e0a:	6c02                	ld	s8,0(sp)
    80004e0c:	6161                	addi	sp,sp,80
    80004e0e:	8082                	ret
    panic("filewrite");
    80004e10:	00004517          	auipc	a0,0x4
    80004e14:	9e050513          	addi	a0,a0,-1568 # 800087f0 <syscalls+0x290>
    80004e18:	ffffb097          	auipc	ra,0xffffb
    80004e1c:	724080e7          	jalr	1828(ra) # 8000053c <panic>
    return -1;
    80004e20:	557d                	li	a0,-1
}
    80004e22:	8082                	ret
      return -1;
    80004e24:	557d                	li	a0,-1
    80004e26:	bfc9                	j	80004df8 <filewrite+0xf8>
    80004e28:	557d                	li	a0,-1
    80004e2a:	b7f9                	j	80004df8 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004e2c:	557d                	li	a0,-1
    80004e2e:	b7e9                	j	80004df8 <filewrite+0xf8>

0000000080004e30 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004e30:	7179                	addi	sp,sp,-48
    80004e32:	f406                	sd	ra,40(sp)
    80004e34:	f022                	sd	s0,32(sp)
    80004e36:	ec26                	sd	s1,24(sp)
    80004e38:	e84a                	sd	s2,16(sp)
    80004e3a:	e44e                	sd	s3,8(sp)
    80004e3c:	e052                	sd	s4,0(sp)
    80004e3e:	1800                	addi	s0,sp,48
    80004e40:	84aa                	mv	s1,a0
    80004e42:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004e44:	0005b023          	sd	zero,0(a1)
    80004e48:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004e4c:	00000097          	auipc	ra,0x0
    80004e50:	bfc080e7          	jalr	-1028(ra) # 80004a48 <filealloc>
    80004e54:	e088                	sd	a0,0(s1)
    80004e56:	c551                	beqz	a0,80004ee2 <pipealloc+0xb2>
    80004e58:	00000097          	auipc	ra,0x0
    80004e5c:	bf0080e7          	jalr	-1040(ra) # 80004a48 <filealloc>
    80004e60:	00aa3023          	sd	a0,0(s4)
    80004e64:	c92d                	beqz	a0,80004ed6 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e66:	ffffc097          	auipc	ra,0xffffc
    80004e6a:	da2080e7          	jalr	-606(ra) # 80000c08 <kalloc>
    80004e6e:	892a                	mv	s2,a0
    80004e70:	c125                	beqz	a0,80004ed0 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e72:	4985                	li	s3,1
    80004e74:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e78:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e7c:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e80:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e84:	00004597          	auipc	a1,0x4
    80004e88:	97c58593          	addi	a1,a1,-1668 # 80008800 <syscalls+0x2a0>
    80004e8c:	ffffc097          	auipc	ra,0xffffc
    80004e90:	e28080e7          	jalr	-472(ra) # 80000cb4 <initlock>
  (*f0)->type = FD_PIPE;
    80004e94:	609c                	ld	a5,0(s1)
    80004e96:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e9a:	609c                	ld	a5,0(s1)
    80004e9c:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ea0:	609c                	ld	a5,0(s1)
    80004ea2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ea6:	609c                	ld	a5,0(s1)
    80004ea8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004eac:	000a3783          	ld	a5,0(s4)
    80004eb0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004eb4:	000a3783          	ld	a5,0(s4)
    80004eb8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004ebc:	000a3783          	ld	a5,0(s4)
    80004ec0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004ec4:	000a3783          	ld	a5,0(s4)
    80004ec8:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ecc:	4501                	li	a0,0
    80004ece:	a025                	j	80004ef6 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ed0:	6088                	ld	a0,0(s1)
    80004ed2:	e501                	bnez	a0,80004eda <pipealloc+0xaa>
    80004ed4:	a039                	j	80004ee2 <pipealloc+0xb2>
    80004ed6:	6088                	ld	a0,0(s1)
    80004ed8:	c51d                	beqz	a0,80004f06 <pipealloc+0xd6>
    fileclose(*f0);
    80004eda:	00000097          	auipc	ra,0x0
    80004ede:	c2a080e7          	jalr	-982(ra) # 80004b04 <fileclose>
  if(*f1)
    80004ee2:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ee6:	557d                	li	a0,-1
  if(*f1)
    80004ee8:	c799                	beqz	a5,80004ef6 <pipealloc+0xc6>
    fileclose(*f1);
    80004eea:	853e                	mv	a0,a5
    80004eec:	00000097          	auipc	ra,0x0
    80004ef0:	c18080e7          	jalr	-1000(ra) # 80004b04 <fileclose>
  return -1;
    80004ef4:	557d                	li	a0,-1
}
    80004ef6:	70a2                	ld	ra,40(sp)
    80004ef8:	7402                	ld	s0,32(sp)
    80004efa:	64e2                	ld	s1,24(sp)
    80004efc:	6942                	ld	s2,16(sp)
    80004efe:	69a2                	ld	s3,8(sp)
    80004f00:	6a02                	ld	s4,0(sp)
    80004f02:	6145                	addi	sp,sp,48
    80004f04:	8082                	ret
  return -1;
    80004f06:	557d                	li	a0,-1
    80004f08:	b7fd                	j	80004ef6 <pipealloc+0xc6>

0000000080004f0a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004f0a:	1101                	addi	sp,sp,-32
    80004f0c:	ec06                	sd	ra,24(sp)
    80004f0e:	e822                	sd	s0,16(sp)
    80004f10:	e426                	sd	s1,8(sp)
    80004f12:	e04a                	sd	s2,0(sp)
    80004f14:	1000                	addi	s0,sp,32
    80004f16:	84aa                	mv	s1,a0
    80004f18:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	e2a080e7          	jalr	-470(ra) # 80000d44 <acquire>
  if(writable){
    80004f22:	02090d63          	beqz	s2,80004f5c <pipeclose+0x52>
    pi->writeopen = 0;
    80004f26:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004f2a:	21848513          	addi	a0,s1,536
    80004f2e:	ffffd097          	auipc	ra,0xffffd
    80004f32:	562080e7          	jalr	1378(ra) # 80002490 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004f36:	2204b783          	ld	a5,544(s1)
    80004f3a:	eb95                	bnez	a5,80004f6e <pipeclose+0x64>
    release(&pi->lock);
    80004f3c:	8526                	mv	a0,s1
    80004f3e:	ffffc097          	auipc	ra,0xffffc
    80004f42:	eba080e7          	jalr	-326(ra) # 80000df8 <release>
    kfree((char*)pi);
    80004f46:	8526                	mv	a0,s1
    80004f48:	ffffc097          	auipc	ra,0xffffc
    80004f4c:	b48080e7          	jalr	-1208(ra) # 80000a90 <kfree>
  } else
    release(&pi->lock);
}
    80004f50:	60e2                	ld	ra,24(sp)
    80004f52:	6442                	ld	s0,16(sp)
    80004f54:	64a2                	ld	s1,8(sp)
    80004f56:	6902                	ld	s2,0(sp)
    80004f58:	6105                	addi	sp,sp,32
    80004f5a:	8082                	ret
    pi->readopen = 0;
    80004f5c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f60:	21c48513          	addi	a0,s1,540
    80004f64:	ffffd097          	auipc	ra,0xffffd
    80004f68:	52c080e7          	jalr	1324(ra) # 80002490 <wakeup>
    80004f6c:	b7e9                	j	80004f36 <pipeclose+0x2c>
    release(&pi->lock);
    80004f6e:	8526                	mv	a0,s1
    80004f70:	ffffc097          	auipc	ra,0xffffc
    80004f74:	e88080e7          	jalr	-376(ra) # 80000df8 <release>
}
    80004f78:	bfe1                	j	80004f50 <pipeclose+0x46>

0000000080004f7a <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f7a:	711d                	addi	sp,sp,-96
    80004f7c:	ec86                	sd	ra,88(sp)
    80004f7e:	e8a2                	sd	s0,80(sp)
    80004f80:	e4a6                	sd	s1,72(sp)
    80004f82:	e0ca                	sd	s2,64(sp)
    80004f84:	fc4e                	sd	s3,56(sp)
    80004f86:	f852                	sd	s4,48(sp)
    80004f88:	f456                	sd	s5,40(sp)
    80004f8a:	f05a                	sd	s6,32(sp)
    80004f8c:	ec5e                	sd	s7,24(sp)
    80004f8e:	e862                	sd	s8,16(sp)
    80004f90:	1080                	addi	s0,sp,96
    80004f92:	84aa                	mv	s1,a0
    80004f94:	8aae                	mv	s5,a1
    80004f96:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f98:	ffffd097          	auipc	ra,0xffffd
    80004f9c:	d2c080e7          	jalr	-724(ra) # 80001cc4 <myproc>
    80004fa0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	ffffc097          	auipc	ra,0xffffc
    80004fa8:	da0080e7          	jalr	-608(ra) # 80000d44 <acquire>
  while(i < n){
    80004fac:	0b405663          	blez	s4,80005058 <pipewrite+0xde>
  int i = 0;
    80004fb0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fb2:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004fb4:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004fb8:	21c48b93          	addi	s7,s1,540
    80004fbc:	a089                	j	80004ffe <pipewrite+0x84>
      release(&pi->lock);
    80004fbe:	8526                	mv	a0,s1
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	e38080e7          	jalr	-456(ra) # 80000df8 <release>
      return -1;
    80004fc8:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004fca:	854a                	mv	a0,s2
    80004fcc:	60e6                	ld	ra,88(sp)
    80004fce:	6446                	ld	s0,80(sp)
    80004fd0:	64a6                	ld	s1,72(sp)
    80004fd2:	6906                	ld	s2,64(sp)
    80004fd4:	79e2                	ld	s3,56(sp)
    80004fd6:	7a42                	ld	s4,48(sp)
    80004fd8:	7aa2                	ld	s5,40(sp)
    80004fda:	7b02                	ld	s6,32(sp)
    80004fdc:	6be2                	ld	s7,24(sp)
    80004fde:	6c42                	ld	s8,16(sp)
    80004fe0:	6125                	addi	sp,sp,96
    80004fe2:	8082                	ret
      wakeup(&pi->nread);
    80004fe4:	8562                	mv	a0,s8
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	4aa080e7          	jalr	1194(ra) # 80002490 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004fee:	85a6                	mv	a1,s1
    80004ff0:	855e                	mv	a0,s7
    80004ff2:	ffffd097          	auipc	ra,0xffffd
    80004ff6:	43a080e7          	jalr	1082(ra) # 8000242c <sleep>
  while(i < n){
    80004ffa:	07495063          	bge	s2,s4,8000505a <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004ffe:	2204a783          	lw	a5,544(s1)
    80005002:	dfd5                	beqz	a5,80004fbe <pipewrite+0x44>
    80005004:	854e                	mv	a0,s3
    80005006:	ffffd097          	auipc	ra,0xffffd
    8000500a:	6ce080e7          	jalr	1742(ra) # 800026d4 <killed>
    8000500e:	f945                	bnez	a0,80004fbe <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005010:	2184a783          	lw	a5,536(s1)
    80005014:	21c4a703          	lw	a4,540(s1)
    80005018:	2007879b          	addiw	a5,a5,512
    8000501c:	fcf704e3          	beq	a4,a5,80004fe4 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005020:	4685                	li	a3,1
    80005022:	01590633          	add	a2,s2,s5
    80005026:	faf40593          	addi	a1,s0,-81
    8000502a:	0509b503          	ld	a0,80(s3)
    8000502e:	ffffd097          	auipc	ra,0xffffd
    80005032:	8ee080e7          	jalr	-1810(ra) # 8000191c <copyin>
    80005036:	03650263          	beq	a0,s6,8000505a <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000503a:	21c4a783          	lw	a5,540(s1)
    8000503e:	0017871b          	addiw	a4,a5,1
    80005042:	20e4ae23          	sw	a4,540(s1)
    80005046:	1ff7f793          	andi	a5,a5,511
    8000504a:	97a6                	add	a5,a5,s1
    8000504c:	faf44703          	lbu	a4,-81(s0)
    80005050:	00e78c23          	sb	a4,24(a5)
      i++;
    80005054:	2905                	addiw	s2,s2,1
    80005056:	b755                	j	80004ffa <pipewrite+0x80>
  int i = 0;
    80005058:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000505a:	21848513          	addi	a0,s1,536
    8000505e:	ffffd097          	auipc	ra,0xffffd
    80005062:	432080e7          	jalr	1074(ra) # 80002490 <wakeup>
  release(&pi->lock);
    80005066:	8526                	mv	a0,s1
    80005068:	ffffc097          	auipc	ra,0xffffc
    8000506c:	d90080e7          	jalr	-624(ra) # 80000df8 <release>
  return i;
    80005070:	bfa9                	j	80004fca <pipewrite+0x50>

0000000080005072 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005072:	715d                	addi	sp,sp,-80
    80005074:	e486                	sd	ra,72(sp)
    80005076:	e0a2                	sd	s0,64(sp)
    80005078:	fc26                	sd	s1,56(sp)
    8000507a:	f84a                	sd	s2,48(sp)
    8000507c:	f44e                	sd	s3,40(sp)
    8000507e:	f052                	sd	s4,32(sp)
    80005080:	ec56                	sd	s5,24(sp)
    80005082:	e85a                	sd	s6,16(sp)
    80005084:	0880                	addi	s0,sp,80
    80005086:	84aa                	mv	s1,a0
    80005088:	892e                	mv	s2,a1
    8000508a:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000508c:	ffffd097          	auipc	ra,0xffffd
    80005090:	c38080e7          	jalr	-968(ra) # 80001cc4 <myproc>
    80005094:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	cac080e7          	jalr	-852(ra) # 80000d44 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050a0:	2184a703          	lw	a4,536(s1)
    800050a4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050a8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ac:	02f71763          	bne	a4,a5,800050da <piperead+0x68>
    800050b0:	2244a783          	lw	a5,548(s1)
    800050b4:	c39d                	beqz	a5,800050da <piperead+0x68>
    if(killed(pr)){
    800050b6:	8552                	mv	a0,s4
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	61c080e7          	jalr	1564(ra) # 800026d4 <killed>
    800050c0:	e949                	bnez	a0,80005152 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800050c2:	85a6                	mv	a1,s1
    800050c4:	854e                	mv	a0,s3
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	366080e7          	jalr	870(ra) # 8000242c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800050ce:	2184a703          	lw	a4,536(s1)
    800050d2:	21c4a783          	lw	a5,540(s1)
    800050d6:	fcf70de3          	beq	a4,a5,800050b0 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050da:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050dc:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050de:	05505463          	blez	s5,80005126 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800050e2:	2184a783          	lw	a5,536(s1)
    800050e6:	21c4a703          	lw	a4,540(s1)
    800050ea:	02f70e63          	beq	a4,a5,80005126 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800050ee:	0017871b          	addiw	a4,a5,1
    800050f2:	20e4ac23          	sw	a4,536(s1)
    800050f6:	1ff7f793          	andi	a5,a5,511
    800050fa:	97a6                	add	a5,a5,s1
    800050fc:	0187c783          	lbu	a5,24(a5)
    80005100:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005104:	4685                	li	a3,1
    80005106:	fbf40613          	addi	a2,s0,-65
    8000510a:	85ca                	mv	a1,s2
    8000510c:	050a3503          	ld	a0,80(s4)
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	780080e7          	jalr	1920(ra) # 80001890 <copyout>
    80005118:	01650763          	beq	a0,s6,80005126 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000511c:	2985                	addiw	s3,s3,1
    8000511e:	0905                	addi	s2,s2,1
    80005120:	fd3a91e3          	bne	s5,s3,800050e2 <piperead+0x70>
    80005124:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005126:	21c48513          	addi	a0,s1,540
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	366080e7          	jalr	870(ra) # 80002490 <wakeup>
  release(&pi->lock);
    80005132:	8526                	mv	a0,s1
    80005134:	ffffc097          	auipc	ra,0xffffc
    80005138:	cc4080e7          	jalr	-828(ra) # 80000df8 <release>
  return i;
}
    8000513c:	854e                	mv	a0,s3
    8000513e:	60a6                	ld	ra,72(sp)
    80005140:	6406                	ld	s0,64(sp)
    80005142:	74e2                	ld	s1,56(sp)
    80005144:	7942                	ld	s2,48(sp)
    80005146:	79a2                	ld	s3,40(sp)
    80005148:	7a02                	ld	s4,32(sp)
    8000514a:	6ae2                	ld	s5,24(sp)
    8000514c:	6b42                	ld	s6,16(sp)
    8000514e:	6161                	addi	sp,sp,80
    80005150:	8082                	ret
      release(&pi->lock);
    80005152:	8526                	mv	a0,s1
    80005154:	ffffc097          	auipc	ra,0xffffc
    80005158:	ca4080e7          	jalr	-860(ra) # 80000df8 <release>
      return -1;
    8000515c:	59fd                	li	s3,-1
    8000515e:	bff9                	j	8000513c <piperead+0xca>

0000000080005160 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005160:	1141                	addi	sp,sp,-16
    80005162:	e422                	sd	s0,8(sp)
    80005164:	0800                	addi	s0,sp,16
    80005166:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005168:	8905                	andi	a0,a0,1
    8000516a:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000516c:	8b89                	andi	a5,a5,2
    8000516e:	c399                	beqz	a5,80005174 <flags2perm+0x14>
      perm |= PTE_W;
    80005170:	00456513          	ori	a0,a0,4
    return perm;
}
    80005174:	6422                	ld	s0,8(sp)
    80005176:	0141                	addi	sp,sp,16
    80005178:	8082                	ret

000000008000517a <exec>:

int
exec(char *path, char **argv)
{
    8000517a:	df010113          	addi	sp,sp,-528
    8000517e:	20113423          	sd	ra,520(sp)
    80005182:	20813023          	sd	s0,512(sp)
    80005186:	ffa6                	sd	s1,504(sp)
    80005188:	fbca                	sd	s2,496(sp)
    8000518a:	f7ce                	sd	s3,488(sp)
    8000518c:	f3d2                	sd	s4,480(sp)
    8000518e:	efd6                	sd	s5,472(sp)
    80005190:	ebda                	sd	s6,464(sp)
    80005192:	e7de                	sd	s7,456(sp)
    80005194:	e3e2                	sd	s8,448(sp)
    80005196:	ff66                	sd	s9,440(sp)
    80005198:	fb6a                	sd	s10,432(sp)
    8000519a:	f76e                	sd	s11,424(sp)
    8000519c:	0c00                	addi	s0,sp,528
    8000519e:	892a                	mv	s2,a0
    800051a0:	dea43c23          	sd	a0,-520(s0)
    800051a4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800051a8:	ffffd097          	auipc	ra,0xffffd
    800051ac:	b1c080e7          	jalr	-1252(ra) # 80001cc4 <myproc>
    800051b0:	84aa                	mv	s1,a0

  begin_op();
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	48e080e7          	jalr	1166(ra) # 80004640 <begin_op>

  if((ip = namei(path)) == 0){
    800051ba:	854a                	mv	a0,s2
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	284080e7          	jalr	644(ra) # 80004440 <namei>
    800051c4:	c92d                	beqz	a0,80005236 <exec+0xbc>
    800051c6:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800051c8:	fffff097          	auipc	ra,0xfffff
    800051cc:	ad2080e7          	jalr	-1326(ra) # 80003c9a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800051d0:	04000713          	li	a4,64
    800051d4:	4681                	li	a3,0
    800051d6:	e5040613          	addi	a2,s0,-432
    800051da:	4581                	li	a1,0
    800051dc:	8552                	mv	a0,s4
    800051de:	fffff097          	auipc	ra,0xfffff
    800051e2:	d70080e7          	jalr	-656(ra) # 80003f4e <readi>
    800051e6:	04000793          	li	a5,64
    800051ea:	00f51a63          	bne	a0,a5,800051fe <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051ee:	e5042703          	lw	a4,-432(s0)
    800051f2:	464c47b7          	lui	a5,0x464c4
    800051f6:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051fa:	04f70463          	beq	a4,a5,80005242 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051fe:	8552                	mv	a0,s4
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	cfc080e7          	jalr	-772(ra) # 80003efc <iunlockput>
    end_op();
    80005208:	fffff097          	auipc	ra,0xfffff
    8000520c:	4b2080e7          	jalr	1202(ra) # 800046ba <end_op>
  }
  return -1;
    80005210:	557d                	li	a0,-1
}
    80005212:	20813083          	ld	ra,520(sp)
    80005216:	20013403          	ld	s0,512(sp)
    8000521a:	74fe                	ld	s1,504(sp)
    8000521c:	795e                	ld	s2,496(sp)
    8000521e:	79be                	ld	s3,488(sp)
    80005220:	7a1e                	ld	s4,480(sp)
    80005222:	6afe                	ld	s5,472(sp)
    80005224:	6b5e                	ld	s6,464(sp)
    80005226:	6bbe                	ld	s7,456(sp)
    80005228:	6c1e                	ld	s8,448(sp)
    8000522a:	7cfa                	ld	s9,440(sp)
    8000522c:	7d5a                	ld	s10,432(sp)
    8000522e:	7dba                	ld	s11,424(sp)
    80005230:	21010113          	addi	sp,sp,528
    80005234:	8082                	ret
    end_op();
    80005236:	fffff097          	auipc	ra,0xfffff
    8000523a:	484080e7          	jalr	1156(ra) # 800046ba <end_op>
    return -1;
    8000523e:	557d                	li	a0,-1
    80005240:	bfc9                	j	80005212 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005242:	8526                	mv	a0,s1
    80005244:	ffffd097          	auipc	ra,0xffffd
    80005248:	b44080e7          	jalr	-1212(ra) # 80001d88 <proc_pagetable>
    8000524c:	8b2a                	mv	s6,a0
    8000524e:	d945                	beqz	a0,800051fe <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005250:	e7042d03          	lw	s10,-400(s0)
    80005254:	e8845783          	lhu	a5,-376(s0)
    80005258:	10078463          	beqz	a5,80005360 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000525c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000525e:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005260:	6c85                	lui	s9,0x1
    80005262:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005266:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000526a:	6a85                	lui	s5,0x1
    8000526c:	a0b5                	j	800052d8 <exec+0x15e>
      panic("loadseg: address should exist");
    8000526e:	00003517          	auipc	a0,0x3
    80005272:	59a50513          	addi	a0,a0,1434 # 80008808 <syscalls+0x2a8>
    80005276:	ffffb097          	auipc	ra,0xffffb
    8000527a:	2c6080e7          	jalr	710(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    8000527e:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005280:	8726                	mv	a4,s1
    80005282:	012c06bb          	addw	a3,s8,s2
    80005286:	4581                	li	a1,0
    80005288:	8552                	mv	a0,s4
    8000528a:	fffff097          	auipc	ra,0xfffff
    8000528e:	cc4080e7          	jalr	-828(ra) # 80003f4e <readi>
    80005292:	2501                	sext.w	a0,a0
    80005294:	24a49863          	bne	s1,a0,800054e4 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    80005298:	012a893b          	addw	s2,s5,s2
    8000529c:	03397563          	bgeu	s2,s3,800052c6 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800052a0:	02091593          	slli	a1,s2,0x20
    800052a4:	9181                	srli	a1,a1,0x20
    800052a6:	95de                	add	a1,a1,s7
    800052a8:	855a                	mv	a0,s6
    800052aa:	ffffc097          	auipc	ra,0xffffc
    800052ae:	f1e080e7          	jalr	-226(ra) # 800011c8 <walkaddr>
    800052b2:	862a                	mv	a2,a0
    if(pa == 0)
    800052b4:	dd4d                	beqz	a0,8000526e <exec+0xf4>
    if(sz - i < PGSIZE)
    800052b6:	412984bb          	subw	s1,s3,s2
    800052ba:	0004879b          	sext.w	a5,s1
    800052be:	fcfcf0e3          	bgeu	s9,a5,8000527e <exec+0x104>
    800052c2:	84d6                	mv	s1,s5
    800052c4:	bf6d                	j	8000527e <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800052c6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800052ca:	2d85                	addiw	s11,s11,1
    800052cc:	038d0d1b          	addiw	s10,s10,56
    800052d0:	e8845783          	lhu	a5,-376(s0)
    800052d4:	08fdd763          	bge	s11,a5,80005362 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800052d8:	2d01                	sext.w	s10,s10
    800052da:	03800713          	li	a4,56
    800052de:	86ea                	mv	a3,s10
    800052e0:	e1840613          	addi	a2,s0,-488
    800052e4:	4581                	li	a1,0
    800052e6:	8552                	mv	a0,s4
    800052e8:	fffff097          	auipc	ra,0xfffff
    800052ec:	c66080e7          	jalr	-922(ra) # 80003f4e <readi>
    800052f0:	03800793          	li	a5,56
    800052f4:	1ef51663          	bne	a0,a5,800054e0 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    800052f8:	e1842783          	lw	a5,-488(s0)
    800052fc:	4705                	li	a4,1
    800052fe:	fce796e3          	bne	a5,a4,800052ca <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005302:	e4043483          	ld	s1,-448(s0)
    80005306:	e3843783          	ld	a5,-456(s0)
    8000530a:	1ef4e863          	bltu	s1,a5,800054fa <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000530e:	e2843783          	ld	a5,-472(s0)
    80005312:	94be                	add	s1,s1,a5
    80005314:	1ef4e663          	bltu	s1,a5,80005500 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005318:	df043703          	ld	a4,-528(s0)
    8000531c:	8ff9                	and	a5,a5,a4
    8000531e:	1e079463          	bnez	a5,80005506 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005322:	e1c42503          	lw	a0,-484(s0)
    80005326:	00000097          	auipc	ra,0x0
    8000532a:	e3a080e7          	jalr	-454(ra) # 80005160 <flags2perm>
    8000532e:	86aa                	mv	a3,a0
    80005330:	8626                	mv	a2,s1
    80005332:	85ca                	mv	a1,s2
    80005334:	855a                	mv	a0,s6
    80005336:	ffffc097          	auipc	ra,0xffffc
    8000533a:	246080e7          	jalr	582(ra) # 8000157c <uvmalloc>
    8000533e:	e0a43423          	sd	a0,-504(s0)
    80005342:	1c050563          	beqz	a0,8000550c <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005346:	e2843b83          	ld	s7,-472(s0)
    8000534a:	e2042c03          	lw	s8,-480(s0)
    8000534e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005352:	00098463          	beqz	s3,8000535a <exec+0x1e0>
    80005356:	4901                	li	s2,0
    80005358:	b7a1                	j	800052a0 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000535a:	e0843903          	ld	s2,-504(s0)
    8000535e:	b7b5                	j	800052ca <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005360:	4901                	li	s2,0
  iunlockput(ip);
    80005362:	8552                	mv	a0,s4
    80005364:	fffff097          	auipc	ra,0xfffff
    80005368:	b98080e7          	jalr	-1128(ra) # 80003efc <iunlockput>
  end_op();
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	34e080e7          	jalr	846(ra) # 800046ba <end_op>
  p = myproc();
    80005374:	ffffd097          	auipc	ra,0xffffd
    80005378:	950080e7          	jalr	-1712(ra) # 80001cc4 <myproc>
    8000537c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000537e:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005382:	6985                	lui	s3,0x1
    80005384:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80005386:	99ca                	add	s3,s3,s2
    80005388:	77fd                	lui	a5,0xfffff
    8000538a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000538e:	4691                	li	a3,4
    80005390:	6609                	lui	a2,0x2
    80005392:	964e                	add	a2,a2,s3
    80005394:	85ce                	mv	a1,s3
    80005396:	855a                	mv	a0,s6
    80005398:	ffffc097          	auipc	ra,0xffffc
    8000539c:	1e4080e7          	jalr	484(ra) # 8000157c <uvmalloc>
    800053a0:	892a                	mv	s2,a0
    800053a2:	e0a43423          	sd	a0,-504(s0)
    800053a6:	e509                	bnez	a0,800053b0 <exec+0x236>
  if(pagetable)
    800053a8:	e1343423          	sd	s3,-504(s0)
    800053ac:	4a01                	li	s4,0
    800053ae:	aa1d                	j	800054e4 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800053b0:	75f9                	lui	a1,0xffffe
    800053b2:	95aa                	add	a1,a1,a0
    800053b4:	855a                	mv	a0,s6
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	4a8080e7          	jalr	1192(ra) # 8000185e <uvmclear>
  stackbase = sp - PGSIZE;
    800053be:	7bfd                	lui	s7,0xfffff
    800053c0:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800053c2:	e0043783          	ld	a5,-512(s0)
    800053c6:	6388                	ld	a0,0(a5)
    800053c8:	c52d                	beqz	a0,80005432 <exec+0x2b8>
    800053ca:	e9040993          	addi	s3,s0,-368
    800053ce:	f9040c13          	addi	s8,s0,-112
    800053d2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800053d4:	ffffc097          	auipc	ra,0xffffc
    800053d8:	be6080e7          	jalr	-1050(ra) # 80000fba <strlen>
    800053dc:	0015079b          	addiw	a5,a0,1
    800053e0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800053e4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800053e8:	13796563          	bltu	s2,s7,80005512 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800053ec:	e0043d03          	ld	s10,-512(s0)
    800053f0:	000d3a03          	ld	s4,0(s10)
    800053f4:	8552                	mv	a0,s4
    800053f6:	ffffc097          	auipc	ra,0xffffc
    800053fa:	bc4080e7          	jalr	-1084(ra) # 80000fba <strlen>
    800053fe:	0015069b          	addiw	a3,a0,1
    80005402:	8652                	mv	a2,s4
    80005404:	85ca                	mv	a1,s2
    80005406:	855a                	mv	a0,s6
    80005408:	ffffc097          	auipc	ra,0xffffc
    8000540c:	488080e7          	jalr	1160(ra) # 80001890 <copyout>
    80005410:	10054363          	bltz	a0,80005516 <exec+0x39c>
    ustack[argc] = sp;
    80005414:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005418:	0485                	addi	s1,s1,1
    8000541a:	008d0793          	addi	a5,s10,8
    8000541e:	e0f43023          	sd	a5,-512(s0)
    80005422:	008d3503          	ld	a0,8(s10)
    80005426:	c909                	beqz	a0,80005438 <exec+0x2be>
    if(argc >= MAXARG)
    80005428:	09a1                	addi	s3,s3,8
    8000542a:	fb8995e3          	bne	s3,s8,800053d4 <exec+0x25a>
  ip = 0;
    8000542e:	4a01                	li	s4,0
    80005430:	a855                	j	800054e4 <exec+0x36a>
  sp = sz;
    80005432:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005436:	4481                	li	s1,0
  ustack[argc] = 0;
    80005438:	00349793          	slli	a5,s1,0x3
    8000543c:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbd0d0>
    80005440:	97a2                	add	a5,a5,s0
    80005442:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005446:	00148693          	addi	a3,s1,1
    8000544a:	068e                	slli	a3,a3,0x3
    8000544c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005450:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005454:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    80005458:	f57968e3          	bltu	s2,s7,800053a8 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000545c:	e9040613          	addi	a2,s0,-368
    80005460:	85ca                	mv	a1,s2
    80005462:	855a                	mv	a0,s6
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	42c080e7          	jalr	1068(ra) # 80001890 <copyout>
    8000546c:	0a054763          	bltz	a0,8000551a <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005470:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005474:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005478:	df843783          	ld	a5,-520(s0)
    8000547c:	0007c703          	lbu	a4,0(a5)
    80005480:	cf11                	beqz	a4,8000549c <exec+0x322>
    80005482:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005484:	02f00693          	li	a3,47
    80005488:	a039                	j	80005496 <exec+0x31c>
      last = s+1;
    8000548a:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    8000548e:	0785                	addi	a5,a5,1
    80005490:	fff7c703          	lbu	a4,-1(a5)
    80005494:	c701                	beqz	a4,8000549c <exec+0x322>
    if(*s == '/')
    80005496:	fed71ce3          	bne	a4,a3,8000548e <exec+0x314>
    8000549a:	bfc5                	j	8000548a <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    8000549c:	4641                	li	a2,16
    8000549e:	df843583          	ld	a1,-520(s0)
    800054a2:	158a8513          	addi	a0,s5,344
    800054a6:	ffffc097          	auipc	ra,0xffffc
    800054aa:	ae2080e7          	jalr	-1310(ra) # 80000f88 <safestrcpy>
  oldpagetable = p->pagetable;
    800054ae:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800054b2:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800054b6:	e0843783          	ld	a5,-504(s0)
    800054ba:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800054be:	058ab783          	ld	a5,88(s5)
    800054c2:	e6843703          	ld	a4,-408(s0)
    800054c6:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800054c8:	058ab783          	ld	a5,88(s5)
    800054cc:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800054d0:	85e6                	mv	a1,s9
    800054d2:	ffffd097          	auipc	ra,0xffffd
    800054d6:	952080e7          	jalr	-1710(ra) # 80001e24 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800054da:	0004851b          	sext.w	a0,s1
    800054de:	bb15                	j	80005212 <exec+0x98>
    800054e0:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800054e4:	e0843583          	ld	a1,-504(s0)
    800054e8:	855a                	mv	a0,s6
    800054ea:	ffffd097          	auipc	ra,0xffffd
    800054ee:	93a080e7          	jalr	-1734(ra) # 80001e24 <proc_freepagetable>
  return -1;
    800054f2:	557d                	li	a0,-1
  if(ip){
    800054f4:	d00a0fe3          	beqz	s4,80005212 <exec+0x98>
    800054f8:	b319                	j	800051fe <exec+0x84>
    800054fa:	e1243423          	sd	s2,-504(s0)
    800054fe:	b7dd                	j	800054e4 <exec+0x36a>
    80005500:	e1243423          	sd	s2,-504(s0)
    80005504:	b7c5                	j	800054e4 <exec+0x36a>
    80005506:	e1243423          	sd	s2,-504(s0)
    8000550a:	bfe9                	j	800054e4 <exec+0x36a>
    8000550c:	e1243423          	sd	s2,-504(s0)
    80005510:	bfd1                	j	800054e4 <exec+0x36a>
  ip = 0;
    80005512:	4a01                	li	s4,0
    80005514:	bfc1                	j	800054e4 <exec+0x36a>
    80005516:	4a01                	li	s4,0
  if(pagetable)
    80005518:	b7f1                	j	800054e4 <exec+0x36a>
  sz = sz1;
    8000551a:	e0843983          	ld	s3,-504(s0)
    8000551e:	b569                	j	800053a8 <exec+0x22e>

0000000080005520 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005520:	7179                	addi	sp,sp,-48
    80005522:	f406                	sd	ra,40(sp)
    80005524:	f022                	sd	s0,32(sp)
    80005526:	ec26                	sd	s1,24(sp)
    80005528:	e84a                	sd	s2,16(sp)
    8000552a:	1800                	addi	s0,sp,48
    8000552c:	892e                	mv	s2,a1
    8000552e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005530:	fdc40593          	addi	a1,s0,-36
    80005534:	ffffe097          	auipc	ra,0xffffe
    80005538:	aaa080e7          	jalr	-1366(ra) # 80002fde <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000553c:	fdc42703          	lw	a4,-36(s0)
    80005540:	47bd                	li	a5,15
    80005542:	02e7eb63          	bltu	a5,a4,80005578 <argfd+0x58>
    80005546:	ffffc097          	auipc	ra,0xffffc
    8000554a:	77e080e7          	jalr	1918(ra) # 80001cc4 <myproc>
    8000554e:	fdc42703          	lw	a4,-36(s0)
    80005552:	01a70793          	addi	a5,a4,26
    80005556:	078e                	slli	a5,a5,0x3
    80005558:	953e                	add	a0,a0,a5
    8000555a:	611c                	ld	a5,0(a0)
    8000555c:	c385                	beqz	a5,8000557c <argfd+0x5c>
    return -1;
  if(pfd)
    8000555e:	00090463          	beqz	s2,80005566 <argfd+0x46>
    *pfd = fd;
    80005562:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005566:	4501                	li	a0,0
  if(pf)
    80005568:	c091                	beqz	s1,8000556c <argfd+0x4c>
    *pf = f;
    8000556a:	e09c                	sd	a5,0(s1)
}
    8000556c:	70a2                	ld	ra,40(sp)
    8000556e:	7402                	ld	s0,32(sp)
    80005570:	64e2                	ld	s1,24(sp)
    80005572:	6942                	ld	s2,16(sp)
    80005574:	6145                	addi	sp,sp,48
    80005576:	8082                	ret
    return -1;
    80005578:	557d                	li	a0,-1
    8000557a:	bfcd                	j	8000556c <argfd+0x4c>
    8000557c:	557d                	li	a0,-1
    8000557e:	b7fd                	j	8000556c <argfd+0x4c>

0000000080005580 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005580:	1101                	addi	sp,sp,-32
    80005582:	ec06                	sd	ra,24(sp)
    80005584:	e822                	sd	s0,16(sp)
    80005586:	e426                	sd	s1,8(sp)
    80005588:	1000                	addi	s0,sp,32
    8000558a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000558c:	ffffc097          	auipc	ra,0xffffc
    80005590:	738080e7          	jalr	1848(ra) # 80001cc4 <myproc>
    80005594:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005596:	0d050793          	addi	a5,a0,208
    8000559a:	4501                	li	a0,0
    8000559c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000559e:	6398                	ld	a4,0(a5)
    800055a0:	cb19                	beqz	a4,800055b6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800055a2:	2505                	addiw	a0,a0,1
    800055a4:	07a1                	addi	a5,a5,8
    800055a6:	fed51ce3          	bne	a0,a3,8000559e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800055aa:	557d                	li	a0,-1
}
    800055ac:	60e2                	ld	ra,24(sp)
    800055ae:	6442                	ld	s0,16(sp)
    800055b0:	64a2                	ld	s1,8(sp)
    800055b2:	6105                	addi	sp,sp,32
    800055b4:	8082                	ret
      p->ofile[fd] = f;
    800055b6:	01a50793          	addi	a5,a0,26
    800055ba:	078e                	slli	a5,a5,0x3
    800055bc:	963e                	add	a2,a2,a5
    800055be:	e204                	sd	s1,0(a2)
      return fd;
    800055c0:	b7f5                	j	800055ac <fdalloc+0x2c>

00000000800055c2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800055c2:	715d                	addi	sp,sp,-80
    800055c4:	e486                	sd	ra,72(sp)
    800055c6:	e0a2                	sd	s0,64(sp)
    800055c8:	fc26                	sd	s1,56(sp)
    800055ca:	f84a                	sd	s2,48(sp)
    800055cc:	f44e                	sd	s3,40(sp)
    800055ce:	f052                	sd	s4,32(sp)
    800055d0:	ec56                	sd	s5,24(sp)
    800055d2:	e85a                	sd	s6,16(sp)
    800055d4:	0880                	addi	s0,sp,80
    800055d6:	8b2e                	mv	s6,a1
    800055d8:	89b2                	mv	s3,a2
    800055da:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055dc:	fb040593          	addi	a1,s0,-80
    800055e0:	fffff097          	auipc	ra,0xfffff
    800055e4:	e7e080e7          	jalr	-386(ra) # 8000445e <nameiparent>
    800055e8:	84aa                	mv	s1,a0
    800055ea:	14050b63          	beqz	a0,80005740 <create+0x17e>
    return 0;

  ilock(dp);
    800055ee:	ffffe097          	auipc	ra,0xffffe
    800055f2:	6ac080e7          	jalr	1708(ra) # 80003c9a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055f6:	4601                	li	a2,0
    800055f8:	fb040593          	addi	a1,s0,-80
    800055fc:	8526                	mv	a0,s1
    800055fe:	fffff097          	auipc	ra,0xfffff
    80005602:	b80080e7          	jalr	-1152(ra) # 8000417e <dirlookup>
    80005606:	8aaa                	mv	s5,a0
    80005608:	c921                	beqz	a0,80005658 <create+0x96>
    iunlockput(dp);
    8000560a:	8526                	mv	a0,s1
    8000560c:	fffff097          	auipc	ra,0xfffff
    80005610:	8f0080e7          	jalr	-1808(ra) # 80003efc <iunlockput>
    ilock(ip);
    80005614:	8556                	mv	a0,s5
    80005616:	ffffe097          	auipc	ra,0xffffe
    8000561a:	684080e7          	jalr	1668(ra) # 80003c9a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000561e:	4789                	li	a5,2
    80005620:	02fb1563          	bne	s6,a5,8000564a <create+0x88>
    80005624:	044ad783          	lhu	a5,68(s5)
    80005628:	37f9                	addiw	a5,a5,-2
    8000562a:	17c2                	slli	a5,a5,0x30
    8000562c:	93c1                	srli	a5,a5,0x30
    8000562e:	4705                	li	a4,1
    80005630:	00f76d63          	bltu	a4,a5,8000564a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005634:	8556                	mv	a0,s5
    80005636:	60a6                	ld	ra,72(sp)
    80005638:	6406                	ld	s0,64(sp)
    8000563a:	74e2                	ld	s1,56(sp)
    8000563c:	7942                	ld	s2,48(sp)
    8000563e:	79a2                	ld	s3,40(sp)
    80005640:	7a02                	ld	s4,32(sp)
    80005642:	6ae2                	ld	s5,24(sp)
    80005644:	6b42                	ld	s6,16(sp)
    80005646:	6161                	addi	sp,sp,80
    80005648:	8082                	ret
    iunlockput(ip);
    8000564a:	8556                	mv	a0,s5
    8000564c:	fffff097          	auipc	ra,0xfffff
    80005650:	8b0080e7          	jalr	-1872(ra) # 80003efc <iunlockput>
    return 0;
    80005654:	4a81                	li	s5,0
    80005656:	bff9                	j	80005634 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005658:	85da                	mv	a1,s6
    8000565a:	4088                	lw	a0,0(s1)
    8000565c:	ffffe097          	auipc	ra,0xffffe
    80005660:	4a6080e7          	jalr	1190(ra) # 80003b02 <ialloc>
    80005664:	8a2a                	mv	s4,a0
    80005666:	c529                	beqz	a0,800056b0 <create+0xee>
  ilock(ip);
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	632080e7          	jalr	1586(ra) # 80003c9a <ilock>
  ip->major = major;
    80005670:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005674:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005678:	4905                	li	s2,1
    8000567a:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    8000567e:	8552                	mv	a0,s4
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	54e080e7          	jalr	1358(ra) # 80003bce <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005688:	032b0b63          	beq	s6,s2,800056be <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    8000568c:	004a2603          	lw	a2,4(s4)
    80005690:	fb040593          	addi	a1,s0,-80
    80005694:	8526                	mv	a0,s1
    80005696:	fffff097          	auipc	ra,0xfffff
    8000569a:	cf8080e7          	jalr	-776(ra) # 8000438e <dirlink>
    8000569e:	06054f63          	bltz	a0,8000571c <create+0x15a>
  iunlockput(dp);
    800056a2:	8526                	mv	a0,s1
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	858080e7          	jalr	-1960(ra) # 80003efc <iunlockput>
  return ip;
    800056ac:	8ad2                	mv	s5,s4
    800056ae:	b759                	j	80005634 <create+0x72>
    iunlockput(dp);
    800056b0:	8526                	mv	a0,s1
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	84a080e7          	jalr	-1974(ra) # 80003efc <iunlockput>
    return 0;
    800056ba:	8ad2                	mv	s5,s4
    800056bc:	bfa5                	j	80005634 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800056be:	004a2603          	lw	a2,4(s4)
    800056c2:	00003597          	auipc	a1,0x3
    800056c6:	16658593          	addi	a1,a1,358 # 80008828 <syscalls+0x2c8>
    800056ca:	8552                	mv	a0,s4
    800056cc:	fffff097          	auipc	ra,0xfffff
    800056d0:	cc2080e7          	jalr	-830(ra) # 8000438e <dirlink>
    800056d4:	04054463          	bltz	a0,8000571c <create+0x15a>
    800056d8:	40d0                	lw	a2,4(s1)
    800056da:	00003597          	auipc	a1,0x3
    800056de:	15658593          	addi	a1,a1,342 # 80008830 <syscalls+0x2d0>
    800056e2:	8552                	mv	a0,s4
    800056e4:	fffff097          	auipc	ra,0xfffff
    800056e8:	caa080e7          	jalr	-854(ra) # 8000438e <dirlink>
    800056ec:	02054863          	bltz	a0,8000571c <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    800056f0:	004a2603          	lw	a2,4(s4)
    800056f4:	fb040593          	addi	a1,s0,-80
    800056f8:	8526                	mv	a0,s1
    800056fa:	fffff097          	auipc	ra,0xfffff
    800056fe:	c94080e7          	jalr	-876(ra) # 8000438e <dirlink>
    80005702:	00054d63          	bltz	a0,8000571c <create+0x15a>
    dp->nlink++;  // for ".."
    80005706:	04a4d783          	lhu	a5,74(s1)
    8000570a:	2785                	addiw	a5,a5,1
    8000570c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005710:	8526                	mv	a0,s1
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	4bc080e7          	jalr	1212(ra) # 80003bce <iupdate>
    8000571a:	b761                	j	800056a2 <create+0xe0>
  ip->nlink = 0;
    8000571c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005720:	8552                	mv	a0,s4
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	4ac080e7          	jalr	1196(ra) # 80003bce <iupdate>
  iunlockput(ip);
    8000572a:	8552                	mv	a0,s4
    8000572c:	ffffe097          	auipc	ra,0xffffe
    80005730:	7d0080e7          	jalr	2000(ra) # 80003efc <iunlockput>
  iunlockput(dp);
    80005734:	8526                	mv	a0,s1
    80005736:	ffffe097          	auipc	ra,0xffffe
    8000573a:	7c6080e7          	jalr	1990(ra) # 80003efc <iunlockput>
  return 0;
    8000573e:	bddd                	j	80005634 <create+0x72>
    return 0;
    80005740:	8aaa                	mv	s5,a0
    80005742:	bdcd                	j	80005634 <create+0x72>

0000000080005744 <sys_dup>:
{
    80005744:	7179                	addi	sp,sp,-48
    80005746:	f406                	sd	ra,40(sp)
    80005748:	f022                	sd	s0,32(sp)
    8000574a:	ec26                	sd	s1,24(sp)
    8000574c:	e84a                	sd	s2,16(sp)
    8000574e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005750:	fd840613          	addi	a2,s0,-40
    80005754:	4581                	li	a1,0
    80005756:	4501                	li	a0,0
    80005758:	00000097          	auipc	ra,0x0
    8000575c:	dc8080e7          	jalr	-568(ra) # 80005520 <argfd>
    return -1;
    80005760:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005762:	02054363          	bltz	a0,80005788 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005766:	fd843903          	ld	s2,-40(s0)
    8000576a:	854a                	mv	a0,s2
    8000576c:	00000097          	auipc	ra,0x0
    80005770:	e14080e7          	jalr	-492(ra) # 80005580 <fdalloc>
    80005774:	84aa                	mv	s1,a0
    return -1;
    80005776:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005778:	00054863          	bltz	a0,80005788 <sys_dup+0x44>
  filedup(f);
    8000577c:	854a                	mv	a0,s2
    8000577e:	fffff097          	auipc	ra,0xfffff
    80005782:	334080e7          	jalr	820(ra) # 80004ab2 <filedup>
  return fd;
    80005786:	87a6                	mv	a5,s1
}
    80005788:	853e                	mv	a0,a5
    8000578a:	70a2                	ld	ra,40(sp)
    8000578c:	7402                	ld	s0,32(sp)
    8000578e:	64e2                	ld	s1,24(sp)
    80005790:	6942                	ld	s2,16(sp)
    80005792:	6145                	addi	sp,sp,48
    80005794:	8082                	ret

0000000080005796 <sys_read>:
{
    80005796:	7179                	addi	sp,sp,-48
    80005798:	f406                	sd	ra,40(sp)
    8000579a:	f022                	sd	s0,32(sp)
    8000579c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000579e:	fd840593          	addi	a1,s0,-40
    800057a2:	4505                	li	a0,1
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	85a080e7          	jalr	-1958(ra) # 80002ffe <argaddr>
  argint(2, &n);
    800057ac:	fe440593          	addi	a1,s0,-28
    800057b0:	4509                	li	a0,2
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	82c080e7          	jalr	-2004(ra) # 80002fde <argint>
  if(argfd(0, 0, &f) < 0)
    800057ba:	fe840613          	addi	a2,s0,-24
    800057be:	4581                	li	a1,0
    800057c0:	4501                	li	a0,0
    800057c2:	00000097          	auipc	ra,0x0
    800057c6:	d5e080e7          	jalr	-674(ra) # 80005520 <argfd>
    800057ca:	87aa                	mv	a5,a0
    return -1;
    800057cc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057ce:	0007cc63          	bltz	a5,800057e6 <sys_read+0x50>
  return fileread(f, p, n);
    800057d2:	fe442603          	lw	a2,-28(s0)
    800057d6:	fd843583          	ld	a1,-40(s0)
    800057da:	fe843503          	ld	a0,-24(s0)
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	460080e7          	jalr	1120(ra) # 80004c3e <fileread>
}
    800057e6:	70a2                	ld	ra,40(sp)
    800057e8:	7402                	ld	s0,32(sp)
    800057ea:	6145                	addi	sp,sp,48
    800057ec:	8082                	ret

00000000800057ee <sys_write>:
{
    800057ee:	7179                	addi	sp,sp,-48
    800057f0:	f406                	sd	ra,40(sp)
    800057f2:	f022                	sd	s0,32(sp)
    800057f4:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057f6:	fd840593          	addi	a1,s0,-40
    800057fa:	4505                	li	a0,1
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	802080e7          	jalr	-2046(ra) # 80002ffe <argaddr>
  argint(2, &n);
    80005804:	fe440593          	addi	a1,s0,-28
    80005808:	4509                	li	a0,2
    8000580a:	ffffd097          	auipc	ra,0xffffd
    8000580e:	7d4080e7          	jalr	2004(ra) # 80002fde <argint>
  if(argfd(0, 0, &f) < 0)
    80005812:	fe840613          	addi	a2,s0,-24
    80005816:	4581                	li	a1,0
    80005818:	4501                	li	a0,0
    8000581a:	00000097          	auipc	ra,0x0
    8000581e:	d06080e7          	jalr	-762(ra) # 80005520 <argfd>
    80005822:	87aa                	mv	a5,a0
    return -1;
    80005824:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005826:	0007cc63          	bltz	a5,8000583e <sys_write+0x50>
  return filewrite(f, p, n);
    8000582a:	fe442603          	lw	a2,-28(s0)
    8000582e:	fd843583          	ld	a1,-40(s0)
    80005832:	fe843503          	ld	a0,-24(s0)
    80005836:	fffff097          	auipc	ra,0xfffff
    8000583a:	4ca080e7          	jalr	1226(ra) # 80004d00 <filewrite>
}
    8000583e:	70a2                	ld	ra,40(sp)
    80005840:	7402                	ld	s0,32(sp)
    80005842:	6145                	addi	sp,sp,48
    80005844:	8082                	ret

0000000080005846 <sys_close>:
{
    80005846:	1101                	addi	sp,sp,-32
    80005848:	ec06                	sd	ra,24(sp)
    8000584a:	e822                	sd	s0,16(sp)
    8000584c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000584e:	fe040613          	addi	a2,s0,-32
    80005852:	fec40593          	addi	a1,s0,-20
    80005856:	4501                	li	a0,0
    80005858:	00000097          	auipc	ra,0x0
    8000585c:	cc8080e7          	jalr	-824(ra) # 80005520 <argfd>
    return -1;
    80005860:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005862:	02054463          	bltz	a0,8000588a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005866:	ffffc097          	auipc	ra,0xffffc
    8000586a:	45e080e7          	jalr	1118(ra) # 80001cc4 <myproc>
    8000586e:	fec42783          	lw	a5,-20(s0)
    80005872:	07e9                	addi	a5,a5,26
    80005874:	078e                	slli	a5,a5,0x3
    80005876:	953e                	add	a0,a0,a5
    80005878:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000587c:	fe043503          	ld	a0,-32(s0)
    80005880:	fffff097          	auipc	ra,0xfffff
    80005884:	284080e7          	jalr	644(ra) # 80004b04 <fileclose>
  return 0;
    80005888:	4781                	li	a5,0
}
    8000588a:	853e                	mv	a0,a5
    8000588c:	60e2                	ld	ra,24(sp)
    8000588e:	6442                	ld	s0,16(sp)
    80005890:	6105                	addi	sp,sp,32
    80005892:	8082                	ret

0000000080005894 <sys_fstat>:
{
    80005894:	1101                	addi	sp,sp,-32
    80005896:	ec06                	sd	ra,24(sp)
    80005898:	e822                	sd	s0,16(sp)
    8000589a:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000589c:	fe040593          	addi	a1,s0,-32
    800058a0:	4505                	li	a0,1
    800058a2:	ffffd097          	auipc	ra,0xffffd
    800058a6:	75c080e7          	jalr	1884(ra) # 80002ffe <argaddr>
  if(argfd(0, 0, &f) < 0)
    800058aa:	fe840613          	addi	a2,s0,-24
    800058ae:	4581                	li	a1,0
    800058b0:	4501                	li	a0,0
    800058b2:	00000097          	auipc	ra,0x0
    800058b6:	c6e080e7          	jalr	-914(ra) # 80005520 <argfd>
    800058ba:	87aa                	mv	a5,a0
    return -1;
    800058bc:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058be:	0007ca63          	bltz	a5,800058d2 <sys_fstat+0x3e>
  return filestat(f, st);
    800058c2:	fe043583          	ld	a1,-32(s0)
    800058c6:	fe843503          	ld	a0,-24(s0)
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	302080e7          	jalr	770(ra) # 80004bcc <filestat>
}
    800058d2:	60e2                	ld	ra,24(sp)
    800058d4:	6442                	ld	s0,16(sp)
    800058d6:	6105                	addi	sp,sp,32
    800058d8:	8082                	ret

00000000800058da <sys_link>:
{
    800058da:	7169                	addi	sp,sp,-304
    800058dc:	f606                	sd	ra,296(sp)
    800058de:	f222                	sd	s0,288(sp)
    800058e0:	ee26                	sd	s1,280(sp)
    800058e2:	ea4a                	sd	s2,272(sp)
    800058e4:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e6:	08000613          	li	a2,128
    800058ea:	ed040593          	addi	a1,s0,-304
    800058ee:	4501                	li	a0,0
    800058f0:	ffffd097          	auipc	ra,0xffffd
    800058f4:	72e080e7          	jalr	1838(ra) # 8000301e <argstr>
    return -1;
    800058f8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058fa:	10054e63          	bltz	a0,80005a16 <sys_link+0x13c>
    800058fe:	08000613          	li	a2,128
    80005902:	f5040593          	addi	a1,s0,-176
    80005906:	4505                	li	a0,1
    80005908:	ffffd097          	auipc	ra,0xffffd
    8000590c:	716080e7          	jalr	1814(ra) # 8000301e <argstr>
    return -1;
    80005910:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005912:	10054263          	bltz	a0,80005a16 <sys_link+0x13c>
  begin_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	d2a080e7          	jalr	-726(ra) # 80004640 <begin_op>
  if((ip = namei(old)) == 0){
    8000591e:	ed040513          	addi	a0,s0,-304
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	b1e080e7          	jalr	-1250(ra) # 80004440 <namei>
    8000592a:	84aa                	mv	s1,a0
    8000592c:	c551                	beqz	a0,800059b8 <sys_link+0xde>
  ilock(ip);
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	36c080e7          	jalr	876(ra) # 80003c9a <ilock>
  if(ip->type == T_DIR){
    80005936:	04449703          	lh	a4,68(s1)
    8000593a:	4785                	li	a5,1
    8000593c:	08f70463          	beq	a4,a5,800059c4 <sys_link+0xea>
  ip->nlink++;
    80005940:	04a4d783          	lhu	a5,74(s1)
    80005944:	2785                	addiw	a5,a5,1
    80005946:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000594a:	8526                	mv	a0,s1
    8000594c:	ffffe097          	auipc	ra,0xffffe
    80005950:	282080e7          	jalr	642(ra) # 80003bce <iupdate>
  iunlock(ip);
    80005954:	8526                	mv	a0,s1
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	406080e7          	jalr	1030(ra) # 80003d5c <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000595e:	fd040593          	addi	a1,s0,-48
    80005962:	f5040513          	addi	a0,s0,-176
    80005966:	fffff097          	auipc	ra,0xfffff
    8000596a:	af8080e7          	jalr	-1288(ra) # 8000445e <nameiparent>
    8000596e:	892a                	mv	s2,a0
    80005970:	c935                	beqz	a0,800059e4 <sys_link+0x10a>
  ilock(dp);
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	328080e7          	jalr	808(ra) # 80003c9a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000597a:	00092703          	lw	a4,0(s2)
    8000597e:	409c                	lw	a5,0(s1)
    80005980:	04f71d63          	bne	a4,a5,800059da <sys_link+0x100>
    80005984:	40d0                	lw	a2,4(s1)
    80005986:	fd040593          	addi	a1,s0,-48
    8000598a:	854a                	mv	a0,s2
    8000598c:	fffff097          	auipc	ra,0xfffff
    80005990:	a02080e7          	jalr	-1534(ra) # 8000438e <dirlink>
    80005994:	04054363          	bltz	a0,800059da <sys_link+0x100>
  iunlockput(dp);
    80005998:	854a                	mv	a0,s2
    8000599a:	ffffe097          	auipc	ra,0xffffe
    8000599e:	562080e7          	jalr	1378(ra) # 80003efc <iunlockput>
  iput(ip);
    800059a2:	8526                	mv	a0,s1
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	4b0080e7          	jalr	1200(ra) # 80003e54 <iput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	d0e080e7          	jalr	-754(ra) # 800046ba <end_op>
  return 0;
    800059b4:	4781                	li	a5,0
    800059b6:	a085                	j	80005a16 <sys_link+0x13c>
    end_op();
    800059b8:	fffff097          	auipc	ra,0xfffff
    800059bc:	d02080e7          	jalr	-766(ra) # 800046ba <end_op>
    return -1;
    800059c0:	57fd                	li	a5,-1
    800059c2:	a891                	j	80005a16 <sys_link+0x13c>
    iunlockput(ip);
    800059c4:	8526                	mv	a0,s1
    800059c6:	ffffe097          	auipc	ra,0xffffe
    800059ca:	536080e7          	jalr	1334(ra) # 80003efc <iunlockput>
    end_op();
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	cec080e7          	jalr	-788(ra) # 800046ba <end_op>
    return -1;
    800059d6:	57fd                	li	a5,-1
    800059d8:	a83d                	j	80005a16 <sys_link+0x13c>
    iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	ffffe097          	auipc	ra,0xffffe
    800059e0:	520080e7          	jalr	1312(ra) # 80003efc <iunlockput>
  ilock(ip);
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	2b4080e7          	jalr	692(ra) # 80003c9a <ilock>
  ip->nlink--;
    800059ee:	04a4d783          	lhu	a5,74(s1)
    800059f2:	37fd                	addiw	a5,a5,-1
    800059f4:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	1d4080e7          	jalr	468(ra) # 80003bce <iupdate>
  iunlockput(ip);
    80005a02:	8526                	mv	a0,s1
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	4f8080e7          	jalr	1272(ra) # 80003efc <iunlockput>
  end_op();
    80005a0c:	fffff097          	auipc	ra,0xfffff
    80005a10:	cae080e7          	jalr	-850(ra) # 800046ba <end_op>
  return -1;
    80005a14:	57fd                	li	a5,-1
}
    80005a16:	853e                	mv	a0,a5
    80005a18:	70b2                	ld	ra,296(sp)
    80005a1a:	7412                	ld	s0,288(sp)
    80005a1c:	64f2                	ld	s1,280(sp)
    80005a1e:	6952                	ld	s2,272(sp)
    80005a20:	6155                	addi	sp,sp,304
    80005a22:	8082                	ret

0000000080005a24 <sys_unlink>:
{
    80005a24:	7151                	addi	sp,sp,-240
    80005a26:	f586                	sd	ra,232(sp)
    80005a28:	f1a2                	sd	s0,224(sp)
    80005a2a:	eda6                	sd	s1,216(sp)
    80005a2c:	e9ca                	sd	s2,208(sp)
    80005a2e:	e5ce                	sd	s3,200(sp)
    80005a30:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a32:	08000613          	li	a2,128
    80005a36:	f3040593          	addi	a1,s0,-208
    80005a3a:	4501                	li	a0,0
    80005a3c:	ffffd097          	auipc	ra,0xffffd
    80005a40:	5e2080e7          	jalr	1506(ra) # 8000301e <argstr>
    80005a44:	18054163          	bltz	a0,80005bc6 <sys_unlink+0x1a2>
  begin_op();
    80005a48:	fffff097          	auipc	ra,0xfffff
    80005a4c:	bf8080e7          	jalr	-1032(ra) # 80004640 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a50:	fb040593          	addi	a1,s0,-80
    80005a54:	f3040513          	addi	a0,s0,-208
    80005a58:	fffff097          	auipc	ra,0xfffff
    80005a5c:	a06080e7          	jalr	-1530(ra) # 8000445e <nameiparent>
    80005a60:	84aa                	mv	s1,a0
    80005a62:	c979                	beqz	a0,80005b38 <sys_unlink+0x114>
  ilock(dp);
    80005a64:	ffffe097          	auipc	ra,0xffffe
    80005a68:	236080e7          	jalr	566(ra) # 80003c9a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a6c:	00003597          	auipc	a1,0x3
    80005a70:	dbc58593          	addi	a1,a1,-580 # 80008828 <syscalls+0x2c8>
    80005a74:	fb040513          	addi	a0,s0,-80
    80005a78:	ffffe097          	auipc	ra,0xffffe
    80005a7c:	6ec080e7          	jalr	1772(ra) # 80004164 <namecmp>
    80005a80:	14050a63          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
    80005a84:	00003597          	auipc	a1,0x3
    80005a88:	dac58593          	addi	a1,a1,-596 # 80008830 <syscalls+0x2d0>
    80005a8c:	fb040513          	addi	a0,s0,-80
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	6d4080e7          	jalr	1748(ra) # 80004164 <namecmp>
    80005a98:	12050e63          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a9c:	f2c40613          	addi	a2,s0,-212
    80005aa0:	fb040593          	addi	a1,s0,-80
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	6d8080e7          	jalr	1752(ra) # 8000417e <dirlookup>
    80005aae:	892a                	mv	s2,a0
    80005ab0:	12050263          	beqz	a0,80005bd4 <sys_unlink+0x1b0>
  ilock(ip);
    80005ab4:	ffffe097          	auipc	ra,0xffffe
    80005ab8:	1e6080e7          	jalr	486(ra) # 80003c9a <ilock>
  if(ip->nlink < 1)
    80005abc:	04a91783          	lh	a5,74(s2)
    80005ac0:	08f05263          	blez	a5,80005b44 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005ac4:	04491703          	lh	a4,68(s2)
    80005ac8:	4785                	li	a5,1
    80005aca:	08f70563          	beq	a4,a5,80005b54 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005ace:	4641                	li	a2,16
    80005ad0:	4581                	li	a1,0
    80005ad2:	fc040513          	addi	a0,s0,-64
    80005ad6:	ffffb097          	auipc	ra,0xffffb
    80005ada:	36a080e7          	jalr	874(ra) # 80000e40 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ade:	4741                	li	a4,16
    80005ae0:	f2c42683          	lw	a3,-212(s0)
    80005ae4:	fc040613          	addi	a2,s0,-64
    80005ae8:	4581                	li	a1,0
    80005aea:	8526                	mv	a0,s1
    80005aec:	ffffe097          	auipc	ra,0xffffe
    80005af0:	55a080e7          	jalr	1370(ra) # 80004046 <writei>
    80005af4:	47c1                	li	a5,16
    80005af6:	0af51563          	bne	a0,a5,80005ba0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005afa:	04491703          	lh	a4,68(s2)
    80005afe:	4785                	li	a5,1
    80005b00:	0af70863          	beq	a4,a5,80005bb0 <sys_unlink+0x18c>
  iunlockput(dp);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	3f6080e7          	jalr	1014(ra) # 80003efc <iunlockput>
  ip->nlink--;
    80005b0e:	04a95783          	lhu	a5,74(s2)
    80005b12:	37fd                	addiw	a5,a5,-1
    80005b14:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005b18:	854a                	mv	a0,s2
    80005b1a:	ffffe097          	auipc	ra,0xffffe
    80005b1e:	0b4080e7          	jalr	180(ra) # 80003bce <iupdate>
  iunlockput(ip);
    80005b22:	854a                	mv	a0,s2
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	3d8080e7          	jalr	984(ra) # 80003efc <iunlockput>
  end_op();
    80005b2c:	fffff097          	auipc	ra,0xfffff
    80005b30:	b8e080e7          	jalr	-1138(ra) # 800046ba <end_op>
  return 0;
    80005b34:	4501                	li	a0,0
    80005b36:	a84d                	j	80005be8 <sys_unlink+0x1c4>
    end_op();
    80005b38:	fffff097          	auipc	ra,0xfffff
    80005b3c:	b82080e7          	jalr	-1150(ra) # 800046ba <end_op>
    return -1;
    80005b40:	557d                	li	a0,-1
    80005b42:	a05d                	j	80005be8 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b44:	00003517          	auipc	a0,0x3
    80005b48:	cf450513          	addi	a0,a0,-780 # 80008838 <syscalls+0x2d8>
    80005b4c:	ffffb097          	auipc	ra,0xffffb
    80005b50:	9f0080e7          	jalr	-1552(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b54:	04c92703          	lw	a4,76(s2)
    80005b58:	02000793          	li	a5,32
    80005b5c:	f6e7f9e3          	bgeu	a5,a4,80005ace <sys_unlink+0xaa>
    80005b60:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b64:	4741                	li	a4,16
    80005b66:	86ce                	mv	a3,s3
    80005b68:	f1840613          	addi	a2,s0,-232
    80005b6c:	4581                	li	a1,0
    80005b6e:	854a                	mv	a0,s2
    80005b70:	ffffe097          	auipc	ra,0xffffe
    80005b74:	3de080e7          	jalr	990(ra) # 80003f4e <readi>
    80005b78:	47c1                	li	a5,16
    80005b7a:	00f51b63          	bne	a0,a5,80005b90 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b7e:	f1845783          	lhu	a5,-232(s0)
    80005b82:	e7a1                	bnez	a5,80005bca <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b84:	29c1                	addiw	s3,s3,16
    80005b86:	04c92783          	lw	a5,76(s2)
    80005b8a:	fcf9ede3          	bltu	s3,a5,80005b64 <sys_unlink+0x140>
    80005b8e:	b781                	j	80005ace <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b90:	00003517          	auipc	a0,0x3
    80005b94:	cc050513          	addi	a0,a0,-832 # 80008850 <syscalls+0x2f0>
    80005b98:	ffffb097          	auipc	ra,0xffffb
    80005b9c:	9a4080e7          	jalr	-1628(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005ba0:	00003517          	auipc	a0,0x3
    80005ba4:	cc850513          	addi	a0,a0,-824 # 80008868 <syscalls+0x308>
    80005ba8:	ffffb097          	auipc	ra,0xffffb
    80005bac:	994080e7          	jalr	-1644(ra) # 8000053c <panic>
    dp->nlink--;
    80005bb0:	04a4d783          	lhu	a5,74(s1)
    80005bb4:	37fd                	addiw	a5,a5,-1
    80005bb6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005bba:	8526                	mv	a0,s1
    80005bbc:	ffffe097          	auipc	ra,0xffffe
    80005bc0:	012080e7          	jalr	18(ra) # 80003bce <iupdate>
    80005bc4:	b781                	j	80005b04 <sys_unlink+0xe0>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	a005                	j	80005be8 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005bca:	854a                	mv	a0,s2
    80005bcc:	ffffe097          	auipc	ra,0xffffe
    80005bd0:	330080e7          	jalr	816(ra) # 80003efc <iunlockput>
  iunlockput(dp);
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	ffffe097          	auipc	ra,0xffffe
    80005bda:	326080e7          	jalr	806(ra) # 80003efc <iunlockput>
  end_op();
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	adc080e7          	jalr	-1316(ra) # 800046ba <end_op>
  return -1;
    80005be6:	557d                	li	a0,-1
}
    80005be8:	70ae                	ld	ra,232(sp)
    80005bea:	740e                	ld	s0,224(sp)
    80005bec:	64ee                	ld	s1,216(sp)
    80005bee:	694e                	ld	s2,208(sp)
    80005bf0:	69ae                	ld	s3,200(sp)
    80005bf2:	616d                	addi	sp,sp,240
    80005bf4:	8082                	ret

0000000080005bf6 <sys_open>:

uint64
sys_open(void)
{
    80005bf6:	7131                	addi	sp,sp,-192
    80005bf8:	fd06                	sd	ra,184(sp)
    80005bfa:	f922                	sd	s0,176(sp)
    80005bfc:	f526                	sd	s1,168(sp)
    80005bfe:	f14a                	sd	s2,160(sp)
    80005c00:	ed4e                	sd	s3,152(sp)
    80005c02:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005c04:	f4c40593          	addi	a1,s0,-180
    80005c08:	4505                	li	a0,1
    80005c0a:	ffffd097          	auipc	ra,0xffffd
    80005c0e:	3d4080e7          	jalr	980(ra) # 80002fde <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c12:	08000613          	li	a2,128
    80005c16:	f5040593          	addi	a1,s0,-176
    80005c1a:	4501                	li	a0,0
    80005c1c:	ffffd097          	auipc	ra,0xffffd
    80005c20:	402080e7          	jalr	1026(ra) # 8000301e <argstr>
    80005c24:	87aa                	mv	a5,a0
    return -1;
    80005c26:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005c28:	0a07c863          	bltz	a5,80005cd8 <sys_open+0xe2>

  begin_op();
    80005c2c:	fffff097          	auipc	ra,0xfffff
    80005c30:	a14080e7          	jalr	-1516(ra) # 80004640 <begin_op>

  if(omode & O_CREATE){
    80005c34:	f4c42783          	lw	a5,-180(s0)
    80005c38:	2007f793          	andi	a5,a5,512
    80005c3c:	cbdd                	beqz	a5,80005cf2 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005c3e:	4681                	li	a3,0
    80005c40:	4601                	li	a2,0
    80005c42:	4589                	li	a1,2
    80005c44:	f5040513          	addi	a0,s0,-176
    80005c48:	00000097          	auipc	ra,0x0
    80005c4c:	97a080e7          	jalr	-1670(ra) # 800055c2 <create>
    80005c50:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c52:	c951                	beqz	a0,80005ce6 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c54:	04449703          	lh	a4,68(s1)
    80005c58:	478d                	li	a5,3
    80005c5a:	00f71763          	bne	a4,a5,80005c68 <sys_open+0x72>
    80005c5e:	0464d703          	lhu	a4,70(s1)
    80005c62:	47a5                	li	a5,9
    80005c64:	0ce7ec63          	bltu	a5,a4,80005d3c <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c68:	fffff097          	auipc	ra,0xfffff
    80005c6c:	de0080e7          	jalr	-544(ra) # 80004a48 <filealloc>
    80005c70:	892a                	mv	s2,a0
    80005c72:	c56d                	beqz	a0,80005d5c <sys_open+0x166>
    80005c74:	00000097          	auipc	ra,0x0
    80005c78:	90c080e7          	jalr	-1780(ra) # 80005580 <fdalloc>
    80005c7c:	89aa                	mv	s3,a0
    80005c7e:	0c054a63          	bltz	a0,80005d52 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c82:	04449703          	lh	a4,68(s1)
    80005c86:	478d                	li	a5,3
    80005c88:	0ef70563          	beq	a4,a5,80005d72 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c8c:	4789                	li	a5,2
    80005c8e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005c92:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005c96:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005c9a:	f4c42783          	lw	a5,-180(s0)
    80005c9e:	0017c713          	xori	a4,a5,1
    80005ca2:	8b05                	andi	a4,a4,1
    80005ca4:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ca8:	0037f713          	andi	a4,a5,3
    80005cac:	00e03733          	snez	a4,a4
    80005cb0:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005cb4:	4007f793          	andi	a5,a5,1024
    80005cb8:	c791                	beqz	a5,80005cc4 <sys_open+0xce>
    80005cba:	04449703          	lh	a4,68(s1)
    80005cbe:	4789                	li	a5,2
    80005cc0:	0cf70063          	beq	a4,a5,80005d80 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005cc4:	8526                	mv	a0,s1
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	096080e7          	jalr	150(ra) # 80003d5c <iunlock>
  end_op();
    80005cce:	fffff097          	auipc	ra,0xfffff
    80005cd2:	9ec080e7          	jalr	-1556(ra) # 800046ba <end_op>

  return fd;
    80005cd6:	854e                	mv	a0,s3
}
    80005cd8:	70ea                	ld	ra,184(sp)
    80005cda:	744a                	ld	s0,176(sp)
    80005cdc:	74aa                	ld	s1,168(sp)
    80005cde:	790a                	ld	s2,160(sp)
    80005ce0:	69ea                	ld	s3,152(sp)
    80005ce2:	6129                	addi	sp,sp,192
    80005ce4:	8082                	ret
      end_op();
    80005ce6:	fffff097          	auipc	ra,0xfffff
    80005cea:	9d4080e7          	jalr	-1580(ra) # 800046ba <end_op>
      return -1;
    80005cee:	557d                	li	a0,-1
    80005cf0:	b7e5                	j	80005cd8 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005cf2:	f5040513          	addi	a0,s0,-176
    80005cf6:	ffffe097          	auipc	ra,0xffffe
    80005cfa:	74a080e7          	jalr	1866(ra) # 80004440 <namei>
    80005cfe:	84aa                	mv	s1,a0
    80005d00:	c905                	beqz	a0,80005d30 <sys_open+0x13a>
    ilock(ip);
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	f98080e7          	jalr	-104(ra) # 80003c9a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005d0a:	04449703          	lh	a4,68(s1)
    80005d0e:	4785                	li	a5,1
    80005d10:	f4f712e3          	bne	a4,a5,80005c54 <sys_open+0x5e>
    80005d14:	f4c42783          	lw	a5,-180(s0)
    80005d18:	dba1                	beqz	a5,80005c68 <sys_open+0x72>
      iunlockput(ip);
    80005d1a:	8526                	mv	a0,s1
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	1e0080e7          	jalr	480(ra) # 80003efc <iunlockput>
      end_op();
    80005d24:	fffff097          	auipc	ra,0xfffff
    80005d28:	996080e7          	jalr	-1642(ra) # 800046ba <end_op>
      return -1;
    80005d2c:	557d                	li	a0,-1
    80005d2e:	b76d                	j	80005cd8 <sys_open+0xe2>
      end_op();
    80005d30:	fffff097          	auipc	ra,0xfffff
    80005d34:	98a080e7          	jalr	-1654(ra) # 800046ba <end_op>
      return -1;
    80005d38:	557d                	li	a0,-1
    80005d3a:	bf79                	j	80005cd8 <sys_open+0xe2>
    iunlockput(ip);
    80005d3c:	8526                	mv	a0,s1
    80005d3e:	ffffe097          	auipc	ra,0xffffe
    80005d42:	1be080e7          	jalr	446(ra) # 80003efc <iunlockput>
    end_op();
    80005d46:	fffff097          	auipc	ra,0xfffff
    80005d4a:	974080e7          	jalr	-1676(ra) # 800046ba <end_op>
    return -1;
    80005d4e:	557d                	li	a0,-1
    80005d50:	b761                	j	80005cd8 <sys_open+0xe2>
      fileclose(f);
    80005d52:	854a                	mv	a0,s2
    80005d54:	fffff097          	auipc	ra,0xfffff
    80005d58:	db0080e7          	jalr	-592(ra) # 80004b04 <fileclose>
    iunlockput(ip);
    80005d5c:	8526                	mv	a0,s1
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	19e080e7          	jalr	414(ra) # 80003efc <iunlockput>
    end_op();
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	954080e7          	jalr	-1708(ra) # 800046ba <end_op>
    return -1;
    80005d6e:	557d                	li	a0,-1
    80005d70:	b7a5                	j	80005cd8 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005d72:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005d76:	04649783          	lh	a5,70(s1)
    80005d7a:	02f91223          	sh	a5,36(s2)
    80005d7e:	bf21                	j	80005c96 <sys_open+0xa0>
    itrunc(ip);
    80005d80:	8526                	mv	a0,s1
    80005d82:	ffffe097          	auipc	ra,0xffffe
    80005d86:	026080e7          	jalr	38(ra) # 80003da8 <itrunc>
    80005d8a:	bf2d                	j	80005cc4 <sys_open+0xce>

0000000080005d8c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d8c:	7175                	addi	sp,sp,-144
    80005d8e:	e506                	sd	ra,136(sp)
    80005d90:	e122                	sd	s0,128(sp)
    80005d92:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	8ac080e7          	jalr	-1876(ra) # 80004640 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d9c:	08000613          	li	a2,128
    80005da0:	f7040593          	addi	a1,s0,-144
    80005da4:	4501                	li	a0,0
    80005da6:	ffffd097          	auipc	ra,0xffffd
    80005daa:	278080e7          	jalr	632(ra) # 8000301e <argstr>
    80005dae:	02054963          	bltz	a0,80005de0 <sys_mkdir+0x54>
    80005db2:	4681                	li	a3,0
    80005db4:	4601                	li	a2,0
    80005db6:	4585                	li	a1,1
    80005db8:	f7040513          	addi	a0,s0,-144
    80005dbc:	00000097          	auipc	ra,0x0
    80005dc0:	806080e7          	jalr	-2042(ra) # 800055c2 <create>
    80005dc4:	cd11                	beqz	a0,80005de0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005dc6:	ffffe097          	auipc	ra,0xffffe
    80005dca:	136080e7          	jalr	310(ra) # 80003efc <iunlockput>
  end_op();
    80005dce:	fffff097          	auipc	ra,0xfffff
    80005dd2:	8ec080e7          	jalr	-1812(ra) # 800046ba <end_op>
  return 0;
    80005dd6:	4501                	li	a0,0
}
    80005dd8:	60aa                	ld	ra,136(sp)
    80005dda:	640a                	ld	s0,128(sp)
    80005ddc:	6149                	addi	sp,sp,144
    80005dde:	8082                	ret
    end_op();
    80005de0:	fffff097          	auipc	ra,0xfffff
    80005de4:	8da080e7          	jalr	-1830(ra) # 800046ba <end_op>
    return -1;
    80005de8:	557d                	li	a0,-1
    80005dea:	b7fd                	j	80005dd8 <sys_mkdir+0x4c>

0000000080005dec <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dec:	7135                	addi	sp,sp,-160
    80005dee:	ed06                	sd	ra,152(sp)
    80005df0:	e922                	sd	s0,144(sp)
    80005df2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005df4:	fffff097          	auipc	ra,0xfffff
    80005df8:	84c080e7          	jalr	-1972(ra) # 80004640 <begin_op>
  argint(1, &major);
    80005dfc:	f6c40593          	addi	a1,s0,-148
    80005e00:	4505                	li	a0,1
    80005e02:	ffffd097          	auipc	ra,0xffffd
    80005e06:	1dc080e7          	jalr	476(ra) # 80002fde <argint>
  argint(2, &minor);
    80005e0a:	f6840593          	addi	a1,s0,-152
    80005e0e:	4509                	li	a0,2
    80005e10:	ffffd097          	auipc	ra,0xffffd
    80005e14:	1ce080e7          	jalr	462(ra) # 80002fde <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e18:	08000613          	li	a2,128
    80005e1c:	f7040593          	addi	a1,s0,-144
    80005e20:	4501                	li	a0,0
    80005e22:	ffffd097          	auipc	ra,0xffffd
    80005e26:	1fc080e7          	jalr	508(ra) # 8000301e <argstr>
    80005e2a:	02054b63          	bltz	a0,80005e60 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005e2e:	f6841683          	lh	a3,-152(s0)
    80005e32:	f6c41603          	lh	a2,-148(s0)
    80005e36:	458d                	li	a1,3
    80005e38:	f7040513          	addi	a0,s0,-144
    80005e3c:	fffff097          	auipc	ra,0xfffff
    80005e40:	786080e7          	jalr	1926(ra) # 800055c2 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e44:	cd11                	beqz	a0,80005e60 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	0b6080e7          	jalr	182(ra) # 80003efc <iunlockput>
  end_op();
    80005e4e:	fffff097          	auipc	ra,0xfffff
    80005e52:	86c080e7          	jalr	-1940(ra) # 800046ba <end_op>
  return 0;
    80005e56:	4501                	li	a0,0
}
    80005e58:	60ea                	ld	ra,152(sp)
    80005e5a:	644a                	ld	s0,144(sp)
    80005e5c:	610d                	addi	sp,sp,160
    80005e5e:	8082                	ret
    end_op();
    80005e60:	fffff097          	auipc	ra,0xfffff
    80005e64:	85a080e7          	jalr	-1958(ra) # 800046ba <end_op>
    return -1;
    80005e68:	557d                	li	a0,-1
    80005e6a:	b7fd                	j	80005e58 <sys_mknod+0x6c>

0000000080005e6c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e6c:	7135                	addi	sp,sp,-160
    80005e6e:	ed06                	sd	ra,152(sp)
    80005e70:	e922                	sd	s0,144(sp)
    80005e72:	e526                	sd	s1,136(sp)
    80005e74:	e14a                	sd	s2,128(sp)
    80005e76:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e78:	ffffc097          	auipc	ra,0xffffc
    80005e7c:	e4c080e7          	jalr	-436(ra) # 80001cc4 <myproc>
    80005e80:	892a                	mv	s2,a0
  
  begin_op();
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	7be080e7          	jalr	1982(ra) # 80004640 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e8a:	08000613          	li	a2,128
    80005e8e:	f6040593          	addi	a1,s0,-160
    80005e92:	4501                	li	a0,0
    80005e94:	ffffd097          	auipc	ra,0xffffd
    80005e98:	18a080e7          	jalr	394(ra) # 8000301e <argstr>
    80005e9c:	04054b63          	bltz	a0,80005ef2 <sys_chdir+0x86>
    80005ea0:	f6040513          	addi	a0,s0,-160
    80005ea4:	ffffe097          	auipc	ra,0xffffe
    80005ea8:	59c080e7          	jalr	1436(ra) # 80004440 <namei>
    80005eac:	84aa                	mv	s1,a0
    80005eae:	c131                	beqz	a0,80005ef2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005eb0:	ffffe097          	auipc	ra,0xffffe
    80005eb4:	dea080e7          	jalr	-534(ra) # 80003c9a <ilock>
  if(ip->type != T_DIR){
    80005eb8:	04449703          	lh	a4,68(s1)
    80005ebc:	4785                	li	a5,1
    80005ebe:	04f71063          	bne	a4,a5,80005efe <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005ec2:	8526                	mv	a0,s1
    80005ec4:	ffffe097          	auipc	ra,0xffffe
    80005ec8:	e98080e7          	jalr	-360(ra) # 80003d5c <iunlock>
  iput(p->cwd);
    80005ecc:	15093503          	ld	a0,336(s2)
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	f84080e7          	jalr	-124(ra) # 80003e54 <iput>
  end_op();
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	7e2080e7          	jalr	2018(ra) # 800046ba <end_op>
  p->cwd = ip;
    80005ee0:	14993823          	sd	s1,336(s2)
  return 0;
    80005ee4:	4501                	li	a0,0
}
    80005ee6:	60ea                	ld	ra,152(sp)
    80005ee8:	644a                	ld	s0,144(sp)
    80005eea:	64aa                	ld	s1,136(sp)
    80005eec:	690a                	ld	s2,128(sp)
    80005eee:	610d                	addi	sp,sp,160
    80005ef0:	8082                	ret
    end_op();
    80005ef2:	ffffe097          	auipc	ra,0xffffe
    80005ef6:	7c8080e7          	jalr	1992(ra) # 800046ba <end_op>
    return -1;
    80005efa:	557d                	li	a0,-1
    80005efc:	b7ed                	j	80005ee6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005efe:	8526                	mv	a0,s1
    80005f00:	ffffe097          	auipc	ra,0xffffe
    80005f04:	ffc080e7          	jalr	-4(ra) # 80003efc <iunlockput>
    end_op();
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	7b2080e7          	jalr	1970(ra) # 800046ba <end_op>
    return -1;
    80005f10:	557d                	li	a0,-1
    80005f12:	bfd1                	j	80005ee6 <sys_chdir+0x7a>

0000000080005f14 <sys_exec>:

uint64
sys_exec(void)
{
    80005f14:	7121                	addi	sp,sp,-448
    80005f16:	ff06                	sd	ra,440(sp)
    80005f18:	fb22                	sd	s0,432(sp)
    80005f1a:	f726                	sd	s1,424(sp)
    80005f1c:	f34a                	sd	s2,416(sp)
    80005f1e:	ef4e                	sd	s3,408(sp)
    80005f20:	eb52                	sd	s4,400(sp)
    80005f22:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005f24:	e4840593          	addi	a1,s0,-440
    80005f28:	4505                	li	a0,1
    80005f2a:	ffffd097          	auipc	ra,0xffffd
    80005f2e:	0d4080e7          	jalr	212(ra) # 80002ffe <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f32:	08000613          	li	a2,128
    80005f36:	f5040593          	addi	a1,s0,-176
    80005f3a:	4501                	li	a0,0
    80005f3c:	ffffd097          	auipc	ra,0xffffd
    80005f40:	0e2080e7          	jalr	226(ra) # 8000301e <argstr>
    80005f44:	87aa                	mv	a5,a0
    return -1;
    80005f46:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f48:	0c07c263          	bltz	a5,8000600c <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80005f4c:	10000613          	li	a2,256
    80005f50:	4581                	li	a1,0
    80005f52:	e5040513          	addi	a0,s0,-432
    80005f56:	ffffb097          	auipc	ra,0xffffb
    80005f5a:	eea080e7          	jalr	-278(ra) # 80000e40 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f5e:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80005f62:	89a6                	mv	s3,s1
    80005f64:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f66:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f6a:	00391513          	slli	a0,s2,0x3
    80005f6e:	e4040593          	addi	a1,s0,-448
    80005f72:	e4843783          	ld	a5,-440(s0)
    80005f76:	953e                	add	a0,a0,a5
    80005f78:	ffffd097          	auipc	ra,0xffffd
    80005f7c:	fc8080e7          	jalr	-56(ra) # 80002f40 <fetchaddr>
    80005f80:	02054a63          	bltz	a0,80005fb4 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80005f84:	e4043783          	ld	a5,-448(s0)
    80005f88:	c3b9                	beqz	a5,80005fce <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f8a:	ffffb097          	auipc	ra,0xffffb
    80005f8e:	c7e080e7          	jalr	-898(ra) # 80000c08 <kalloc>
    80005f92:	85aa                	mv	a1,a0
    80005f94:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f98:	cd11                	beqz	a0,80005fb4 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f9a:	6605                	lui	a2,0x1
    80005f9c:	e4043503          	ld	a0,-448(s0)
    80005fa0:	ffffd097          	auipc	ra,0xffffd
    80005fa4:	ff2080e7          	jalr	-14(ra) # 80002f92 <fetchstr>
    80005fa8:	00054663          	bltz	a0,80005fb4 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    80005fac:	0905                	addi	s2,s2,1
    80005fae:	09a1                	addi	s3,s3,8
    80005fb0:	fb491de3          	bne	s2,s4,80005f6a <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fb4:	f5040913          	addi	s2,s0,-176
    80005fb8:	6088                	ld	a0,0(s1)
    80005fba:	c921                	beqz	a0,8000600a <sys_exec+0xf6>
    kfree(argv[i]);
    80005fbc:	ffffb097          	auipc	ra,0xffffb
    80005fc0:	ad4080e7          	jalr	-1324(ra) # 80000a90 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc4:	04a1                	addi	s1,s1,8
    80005fc6:	ff2499e3          	bne	s1,s2,80005fb8 <sys_exec+0xa4>
  return -1;
    80005fca:	557d                	li	a0,-1
    80005fcc:	a081                	j	8000600c <sys_exec+0xf8>
      argv[i] = 0;
    80005fce:	0009079b          	sext.w	a5,s2
    80005fd2:	078e                	slli	a5,a5,0x3
    80005fd4:	fd078793          	addi	a5,a5,-48
    80005fd8:	97a2                	add	a5,a5,s0
    80005fda:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80005fde:	e5040593          	addi	a1,s0,-432
    80005fe2:	f5040513          	addi	a0,s0,-176
    80005fe6:	fffff097          	auipc	ra,0xfffff
    80005fea:	194080e7          	jalr	404(ra) # 8000517a <exec>
    80005fee:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ff0:	f5040993          	addi	s3,s0,-176
    80005ff4:	6088                	ld	a0,0(s1)
    80005ff6:	c901                	beqz	a0,80006006 <sys_exec+0xf2>
    kfree(argv[i]);
    80005ff8:	ffffb097          	auipc	ra,0xffffb
    80005ffc:	a98080e7          	jalr	-1384(ra) # 80000a90 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006000:	04a1                	addi	s1,s1,8
    80006002:	ff3499e3          	bne	s1,s3,80005ff4 <sys_exec+0xe0>
  return ret;
    80006006:	854a                	mv	a0,s2
    80006008:	a011                	j	8000600c <sys_exec+0xf8>
  return -1;
    8000600a:	557d                	li	a0,-1
}
    8000600c:	70fa                	ld	ra,440(sp)
    8000600e:	745a                	ld	s0,432(sp)
    80006010:	74ba                	ld	s1,424(sp)
    80006012:	791a                	ld	s2,416(sp)
    80006014:	69fa                	ld	s3,408(sp)
    80006016:	6a5a                	ld	s4,400(sp)
    80006018:	6139                	addi	sp,sp,448
    8000601a:	8082                	ret

000000008000601c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000601c:	7139                	addi	sp,sp,-64
    8000601e:	fc06                	sd	ra,56(sp)
    80006020:	f822                	sd	s0,48(sp)
    80006022:	f426                	sd	s1,40(sp)
    80006024:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006026:	ffffc097          	auipc	ra,0xffffc
    8000602a:	c9e080e7          	jalr	-866(ra) # 80001cc4 <myproc>
    8000602e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006030:	fd840593          	addi	a1,s0,-40
    80006034:	4501                	li	a0,0
    80006036:	ffffd097          	auipc	ra,0xffffd
    8000603a:	fc8080e7          	jalr	-56(ra) # 80002ffe <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000603e:	fc840593          	addi	a1,s0,-56
    80006042:	fd040513          	addi	a0,s0,-48
    80006046:	fffff097          	auipc	ra,0xfffff
    8000604a:	dea080e7          	jalr	-534(ra) # 80004e30 <pipealloc>
    return -1;
    8000604e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006050:	0c054463          	bltz	a0,80006118 <sys_pipe+0xfc>
  fd0 = -1;
    80006054:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006058:	fd043503          	ld	a0,-48(s0)
    8000605c:	fffff097          	auipc	ra,0xfffff
    80006060:	524080e7          	jalr	1316(ra) # 80005580 <fdalloc>
    80006064:	fca42223          	sw	a0,-60(s0)
    80006068:	08054b63          	bltz	a0,800060fe <sys_pipe+0xe2>
    8000606c:	fc843503          	ld	a0,-56(s0)
    80006070:	fffff097          	auipc	ra,0xfffff
    80006074:	510080e7          	jalr	1296(ra) # 80005580 <fdalloc>
    80006078:	fca42023          	sw	a0,-64(s0)
    8000607c:	06054863          	bltz	a0,800060ec <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006080:	4691                	li	a3,4
    80006082:	fc440613          	addi	a2,s0,-60
    80006086:	fd843583          	ld	a1,-40(s0)
    8000608a:	68a8                	ld	a0,80(s1)
    8000608c:	ffffc097          	auipc	ra,0xffffc
    80006090:	804080e7          	jalr	-2044(ra) # 80001890 <copyout>
    80006094:	02054063          	bltz	a0,800060b4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006098:	4691                	li	a3,4
    8000609a:	fc040613          	addi	a2,s0,-64
    8000609e:	fd843583          	ld	a1,-40(s0)
    800060a2:	0591                	addi	a1,a1,4
    800060a4:	68a8                	ld	a0,80(s1)
    800060a6:	ffffb097          	auipc	ra,0xffffb
    800060aa:	7ea080e7          	jalr	2026(ra) # 80001890 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800060ae:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800060b0:	06055463          	bgez	a0,80006118 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800060b4:	fc442783          	lw	a5,-60(s0)
    800060b8:	07e9                	addi	a5,a5,26
    800060ba:	078e                	slli	a5,a5,0x3
    800060bc:	97a6                	add	a5,a5,s1
    800060be:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800060c2:	fc042783          	lw	a5,-64(s0)
    800060c6:	07e9                	addi	a5,a5,26
    800060c8:	078e                	slli	a5,a5,0x3
    800060ca:	94be                	add	s1,s1,a5
    800060cc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060d0:	fd043503          	ld	a0,-48(s0)
    800060d4:	fffff097          	auipc	ra,0xfffff
    800060d8:	a30080e7          	jalr	-1488(ra) # 80004b04 <fileclose>
    fileclose(wf);
    800060dc:	fc843503          	ld	a0,-56(s0)
    800060e0:	fffff097          	auipc	ra,0xfffff
    800060e4:	a24080e7          	jalr	-1500(ra) # 80004b04 <fileclose>
    return -1;
    800060e8:	57fd                	li	a5,-1
    800060ea:	a03d                	j	80006118 <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060ec:	fc442783          	lw	a5,-60(s0)
    800060f0:	0007c763          	bltz	a5,800060fe <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060f4:	07e9                	addi	a5,a5,26
    800060f6:	078e                	slli	a5,a5,0x3
    800060f8:	97a6                	add	a5,a5,s1
    800060fa:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800060fe:	fd043503          	ld	a0,-48(s0)
    80006102:	fffff097          	auipc	ra,0xfffff
    80006106:	a02080e7          	jalr	-1534(ra) # 80004b04 <fileclose>
    fileclose(wf);
    8000610a:	fc843503          	ld	a0,-56(s0)
    8000610e:	fffff097          	auipc	ra,0xfffff
    80006112:	9f6080e7          	jalr	-1546(ra) # 80004b04 <fileclose>
    return -1;
    80006116:	57fd                	li	a5,-1
}
    80006118:	853e                	mv	a0,a5
    8000611a:	70e2                	ld	ra,56(sp)
    8000611c:	7442                	ld	s0,48(sp)
    8000611e:	74a2                	ld	s1,40(sp)
    80006120:	6121                	addi	sp,sp,64
    80006122:	8082                	ret
	...

0000000080006130 <kernelvec>:
    80006130:	7111                	addi	sp,sp,-256
    80006132:	e006                	sd	ra,0(sp)
    80006134:	e40a                	sd	sp,8(sp)
    80006136:	e80e                	sd	gp,16(sp)
    80006138:	ec12                	sd	tp,24(sp)
    8000613a:	f016                	sd	t0,32(sp)
    8000613c:	f41a                	sd	t1,40(sp)
    8000613e:	f81e                	sd	t2,48(sp)
    80006140:	fc22                	sd	s0,56(sp)
    80006142:	e0a6                	sd	s1,64(sp)
    80006144:	e4aa                	sd	a0,72(sp)
    80006146:	e8ae                	sd	a1,80(sp)
    80006148:	ecb2                	sd	a2,88(sp)
    8000614a:	f0b6                	sd	a3,96(sp)
    8000614c:	f4ba                	sd	a4,104(sp)
    8000614e:	f8be                	sd	a5,112(sp)
    80006150:	fcc2                	sd	a6,120(sp)
    80006152:	e146                	sd	a7,128(sp)
    80006154:	e54a                	sd	s2,136(sp)
    80006156:	e94e                	sd	s3,144(sp)
    80006158:	ed52                	sd	s4,152(sp)
    8000615a:	f156                	sd	s5,160(sp)
    8000615c:	f55a                	sd	s6,168(sp)
    8000615e:	f95e                	sd	s7,176(sp)
    80006160:	fd62                	sd	s8,184(sp)
    80006162:	e1e6                	sd	s9,192(sp)
    80006164:	e5ea                	sd	s10,200(sp)
    80006166:	e9ee                	sd	s11,208(sp)
    80006168:	edf2                	sd	t3,216(sp)
    8000616a:	f1f6                	sd	t4,224(sp)
    8000616c:	f5fa                	sd	t5,232(sp)
    8000616e:	f9fe                	sd	t6,240(sp)
    80006170:	c9dfc0ef          	jal	ra,80002e0c <kerneltrap>
    80006174:	6082                	ld	ra,0(sp)
    80006176:	6122                	ld	sp,8(sp)
    80006178:	61c2                	ld	gp,16(sp)
    8000617a:	7282                	ld	t0,32(sp)
    8000617c:	7322                	ld	t1,40(sp)
    8000617e:	73c2                	ld	t2,48(sp)
    80006180:	7462                	ld	s0,56(sp)
    80006182:	6486                	ld	s1,64(sp)
    80006184:	6526                	ld	a0,72(sp)
    80006186:	65c6                	ld	a1,80(sp)
    80006188:	6666                	ld	a2,88(sp)
    8000618a:	7686                	ld	a3,96(sp)
    8000618c:	7726                	ld	a4,104(sp)
    8000618e:	77c6                	ld	a5,112(sp)
    80006190:	7866                	ld	a6,120(sp)
    80006192:	688a                	ld	a7,128(sp)
    80006194:	692a                	ld	s2,136(sp)
    80006196:	69ca                	ld	s3,144(sp)
    80006198:	6a6a                	ld	s4,152(sp)
    8000619a:	7a8a                	ld	s5,160(sp)
    8000619c:	7b2a                	ld	s6,168(sp)
    8000619e:	7bca                	ld	s7,176(sp)
    800061a0:	7c6a                	ld	s8,184(sp)
    800061a2:	6c8e                	ld	s9,192(sp)
    800061a4:	6d2e                	ld	s10,200(sp)
    800061a6:	6dce                	ld	s11,208(sp)
    800061a8:	6e6e                	ld	t3,216(sp)
    800061aa:	7e8e                	ld	t4,224(sp)
    800061ac:	7f2e                	ld	t5,232(sp)
    800061ae:	7fce                	ld	t6,240(sp)
    800061b0:	6111                	addi	sp,sp,256
    800061b2:	10200073          	sret
    800061b6:	00000013          	nop
    800061ba:	00000013          	nop
    800061be:	0001                	nop

00000000800061c0 <timervec>:
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	e10c                	sd	a1,0(a0)
    800061c6:	e510                	sd	a2,8(a0)
    800061c8:	e914                	sd	a3,16(a0)
    800061ca:	6d0c                	ld	a1,24(a0)
    800061cc:	7110                	ld	a2,32(a0)
    800061ce:	6194                	ld	a3,0(a1)
    800061d0:	96b2                	add	a3,a3,a2
    800061d2:	e194                	sd	a3,0(a1)
    800061d4:	4589                	li	a1,2
    800061d6:	14459073          	csrw	sip,a1
    800061da:	6914                	ld	a3,16(a0)
    800061dc:	6510                	ld	a2,8(a0)
    800061de:	610c                	ld	a1,0(a0)
    800061e0:	34051573          	csrrw	a0,mscratch,a0
    800061e4:	30200073          	mret
	...

00000000800061ea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ea:	1141                	addi	sp,sp,-16
    800061ec:	e422                	sd	s0,8(sp)
    800061ee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061f0:	0c0007b7          	lui	a5,0xc000
    800061f4:	4705                	li	a4,1
    800061f6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061f8:	c3d8                	sw	a4,4(a5)
}
    800061fa:	6422                	ld	s0,8(sp)
    800061fc:	0141                	addi	sp,sp,16
    800061fe:	8082                	ret

0000000080006200 <plicinithart>:

void
plicinithart(void)
{
    80006200:	1141                	addi	sp,sp,-16
    80006202:	e406                	sd	ra,8(sp)
    80006204:	e022                	sd	s0,0(sp)
    80006206:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006208:	ffffc097          	auipc	ra,0xffffc
    8000620c:	a90080e7          	jalr	-1392(ra) # 80001c98 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006210:	0085171b          	slliw	a4,a0,0x8
    80006214:	0c0027b7          	lui	a5,0xc002
    80006218:	97ba                	add	a5,a5,a4
    8000621a:	40200713          	li	a4,1026
    8000621e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006222:	00d5151b          	slliw	a0,a0,0xd
    80006226:	0c2017b7          	lui	a5,0xc201
    8000622a:	97aa                	add	a5,a5,a0
    8000622c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006230:	60a2                	ld	ra,8(sp)
    80006232:	6402                	ld	s0,0(sp)
    80006234:	0141                	addi	sp,sp,16
    80006236:	8082                	ret

0000000080006238 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006238:	1141                	addi	sp,sp,-16
    8000623a:	e406                	sd	ra,8(sp)
    8000623c:	e022                	sd	s0,0(sp)
    8000623e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006240:	ffffc097          	auipc	ra,0xffffc
    80006244:	a58080e7          	jalr	-1448(ra) # 80001c98 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006248:	00d5151b          	slliw	a0,a0,0xd
    8000624c:	0c2017b7          	lui	a5,0xc201
    80006250:	97aa                	add	a5,a5,a0
  return irq;
}
    80006252:	43c8                	lw	a0,4(a5)
    80006254:	60a2                	ld	ra,8(sp)
    80006256:	6402                	ld	s0,0(sp)
    80006258:	0141                	addi	sp,sp,16
    8000625a:	8082                	ret

000000008000625c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000625c:	1101                	addi	sp,sp,-32
    8000625e:	ec06                	sd	ra,24(sp)
    80006260:	e822                	sd	s0,16(sp)
    80006262:	e426                	sd	s1,8(sp)
    80006264:	1000                	addi	s0,sp,32
    80006266:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006268:	ffffc097          	auipc	ra,0xffffc
    8000626c:	a30080e7          	jalr	-1488(ra) # 80001c98 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006270:	00d5151b          	slliw	a0,a0,0xd
    80006274:	0c2017b7          	lui	a5,0xc201
    80006278:	97aa                	add	a5,a5,a0
    8000627a:	c3c4                	sw	s1,4(a5)
}
    8000627c:	60e2                	ld	ra,24(sp)
    8000627e:	6442                	ld	s0,16(sp)
    80006280:	64a2                	ld	s1,8(sp)
    80006282:	6105                	addi	sp,sp,32
    80006284:	8082                	ret

0000000080006286 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006286:	1141                	addi	sp,sp,-16
    80006288:	e406                	sd	ra,8(sp)
    8000628a:	e022                	sd	s0,0(sp)
    8000628c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000628e:	479d                	li	a5,7
    80006290:	04a7cc63          	blt	a5,a0,800062e8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006294:	0023c797          	auipc	a5,0x23c
    80006298:	aec78793          	addi	a5,a5,-1300 # 80241d80 <disk>
    8000629c:	97aa                	add	a5,a5,a0
    8000629e:	0187c783          	lbu	a5,24(a5)
    800062a2:	ebb9                	bnez	a5,800062f8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800062a4:	00451693          	slli	a3,a0,0x4
    800062a8:	0023c797          	auipc	a5,0x23c
    800062ac:	ad878793          	addi	a5,a5,-1320 # 80241d80 <disk>
    800062b0:	6398                	ld	a4,0(a5)
    800062b2:	9736                	add	a4,a4,a3
    800062b4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800062b8:	6398                	ld	a4,0(a5)
    800062ba:	9736                	add	a4,a4,a3
    800062bc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800062c0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800062c4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800062c8:	97aa                	add	a5,a5,a0
    800062ca:	4705                	li	a4,1
    800062cc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800062d0:	0023c517          	auipc	a0,0x23c
    800062d4:	ac850513          	addi	a0,a0,-1336 # 80241d98 <disk+0x18>
    800062d8:	ffffc097          	auipc	ra,0xffffc
    800062dc:	1b8080e7          	jalr	440(ra) # 80002490 <wakeup>
}
    800062e0:	60a2                	ld	ra,8(sp)
    800062e2:	6402                	ld	s0,0(sp)
    800062e4:	0141                	addi	sp,sp,16
    800062e6:	8082                	ret
    panic("free_desc 1");
    800062e8:	00002517          	auipc	a0,0x2
    800062ec:	59050513          	addi	a0,a0,1424 # 80008878 <syscalls+0x318>
    800062f0:	ffffa097          	auipc	ra,0xffffa
    800062f4:	24c080e7          	jalr	588(ra) # 8000053c <panic>
    panic("free_desc 2");
    800062f8:	00002517          	auipc	a0,0x2
    800062fc:	59050513          	addi	a0,a0,1424 # 80008888 <syscalls+0x328>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	23c080e7          	jalr	572(ra) # 8000053c <panic>

0000000080006308 <virtio_disk_init>:
{
    80006308:	1101                	addi	sp,sp,-32
    8000630a:	ec06                	sd	ra,24(sp)
    8000630c:	e822                	sd	s0,16(sp)
    8000630e:	e426                	sd	s1,8(sp)
    80006310:	e04a                	sd	s2,0(sp)
    80006312:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006314:	00002597          	auipc	a1,0x2
    80006318:	58458593          	addi	a1,a1,1412 # 80008898 <syscalls+0x338>
    8000631c:	0023c517          	auipc	a0,0x23c
    80006320:	b8c50513          	addi	a0,a0,-1140 # 80241ea8 <disk+0x128>
    80006324:	ffffb097          	auipc	ra,0xffffb
    80006328:	990080e7          	jalr	-1648(ra) # 80000cb4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000632c:	100017b7          	lui	a5,0x10001
    80006330:	4398                	lw	a4,0(a5)
    80006332:	2701                	sext.w	a4,a4
    80006334:	747277b7          	lui	a5,0x74727
    80006338:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000633c:	14f71b63          	bne	a4,a5,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006340:	100017b7          	lui	a5,0x10001
    80006344:	43dc                	lw	a5,4(a5)
    80006346:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006348:	4709                	li	a4,2
    8000634a:	14e79463          	bne	a5,a4,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000634e:	100017b7          	lui	a5,0x10001
    80006352:	479c                	lw	a5,8(a5)
    80006354:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006356:	12e79e63          	bne	a5,a4,80006492 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000635a:	100017b7          	lui	a5,0x10001
    8000635e:	47d8                	lw	a4,12(a5)
    80006360:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006362:	554d47b7          	lui	a5,0x554d4
    80006366:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000636a:	12f71463          	bne	a4,a5,80006492 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000636e:	100017b7          	lui	a5,0x10001
    80006372:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006376:	4705                	li	a4,1
    80006378:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000637a:	470d                	li	a4,3
    8000637c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000637e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006380:	c7ffe6b7          	lui	a3,0xc7ffe
    80006384:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc89f>
    80006388:	8f75                	and	a4,a4,a3
    8000638a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000638c:	472d                	li	a4,11
    8000638e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006390:	5bbc                	lw	a5,112(a5)
    80006392:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006396:	8ba1                	andi	a5,a5,8
    80006398:	10078563          	beqz	a5,800064a2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000639c:	100017b7          	lui	a5,0x10001
    800063a0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800063a4:	43fc                	lw	a5,68(a5)
    800063a6:	2781                	sext.w	a5,a5
    800063a8:	10079563          	bnez	a5,800064b2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800063ac:	100017b7          	lui	a5,0x10001
    800063b0:	5bdc                	lw	a5,52(a5)
    800063b2:	2781                	sext.w	a5,a5
  if(max == 0)
    800063b4:	10078763          	beqz	a5,800064c2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800063b8:	471d                	li	a4,7
    800063ba:	10f77c63          	bgeu	a4,a5,800064d2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800063be:	ffffb097          	auipc	ra,0xffffb
    800063c2:	84a080e7          	jalr	-1974(ra) # 80000c08 <kalloc>
    800063c6:	0023c497          	auipc	s1,0x23c
    800063ca:	9ba48493          	addi	s1,s1,-1606 # 80241d80 <disk>
    800063ce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063d0:	ffffb097          	auipc	ra,0xffffb
    800063d4:	838080e7          	jalr	-1992(ra) # 80000c08 <kalloc>
    800063d8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063da:	ffffb097          	auipc	ra,0xffffb
    800063de:	82e080e7          	jalr	-2002(ra) # 80000c08 <kalloc>
    800063e2:	87aa                	mv	a5,a0
    800063e4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063e6:	6088                	ld	a0,0(s1)
    800063e8:	cd6d                	beqz	a0,800064e2 <virtio_disk_init+0x1da>
    800063ea:	0023c717          	auipc	a4,0x23c
    800063ee:	99e73703          	ld	a4,-1634(a4) # 80241d88 <disk+0x8>
    800063f2:	cb65                	beqz	a4,800064e2 <virtio_disk_init+0x1da>
    800063f4:	c7fd                	beqz	a5,800064e2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800063f6:	6605                	lui	a2,0x1
    800063f8:	4581                	li	a1,0
    800063fa:	ffffb097          	auipc	ra,0xffffb
    800063fe:	a46080e7          	jalr	-1466(ra) # 80000e40 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006402:	0023c497          	auipc	s1,0x23c
    80006406:	97e48493          	addi	s1,s1,-1666 # 80241d80 <disk>
    8000640a:	6605                	lui	a2,0x1
    8000640c:	4581                	li	a1,0
    8000640e:	6488                	ld	a0,8(s1)
    80006410:	ffffb097          	auipc	ra,0xffffb
    80006414:	a30080e7          	jalr	-1488(ra) # 80000e40 <memset>
  memset(disk.used, 0, PGSIZE);
    80006418:	6605                	lui	a2,0x1
    8000641a:	4581                	li	a1,0
    8000641c:	6888                	ld	a0,16(s1)
    8000641e:	ffffb097          	auipc	ra,0xffffb
    80006422:	a22080e7          	jalr	-1502(ra) # 80000e40 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006426:	100017b7          	lui	a5,0x10001
    8000642a:	4721                	li	a4,8
    8000642c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000642e:	4098                	lw	a4,0(s1)
    80006430:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006434:	40d8                	lw	a4,4(s1)
    80006436:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000643a:	6498                	ld	a4,8(s1)
    8000643c:	0007069b          	sext.w	a3,a4
    80006440:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006444:	9701                	srai	a4,a4,0x20
    80006446:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000644a:	6898                	ld	a4,16(s1)
    8000644c:	0007069b          	sext.w	a3,a4
    80006450:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006454:	9701                	srai	a4,a4,0x20
    80006456:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000645a:	4705                	li	a4,1
    8000645c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000645e:	00e48c23          	sb	a4,24(s1)
    80006462:	00e48ca3          	sb	a4,25(s1)
    80006466:	00e48d23          	sb	a4,26(s1)
    8000646a:	00e48da3          	sb	a4,27(s1)
    8000646e:	00e48e23          	sb	a4,28(s1)
    80006472:	00e48ea3          	sb	a4,29(s1)
    80006476:	00e48f23          	sb	a4,30(s1)
    8000647a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000647e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006482:	0727a823          	sw	s2,112(a5)
}
    80006486:	60e2                	ld	ra,24(sp)
    80006488:	6442                	ld	s0,16(sp)
    8000648a:	64a2                	ld	s1,8(sp)
    8000648c:	6902                	ld	s2,0(sp)
    8000648e:	6105                	addi	sp,sp,32
    80006490:	8082                	ret
    panic("could not find virtio disk");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	41650513          	addi	a0,a0,1046 # 800088a8 <syscalls+0x348>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a2080e7          	jalr	162(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	42650513          	addi	a0,a0,1062 # 800088c8 <syscalls+0x368>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	092080e7          	jalr	146(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800064b2:	00002517          	auipc	a0,0x2
    800064b6:	43650513          	addi	a0,a0,1078 # 800088e8 <syscalls+0x388>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	082080e7          	jalr	130(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800064c2:	00002517          	auipc	a0,0x2
    800064c6:	44650513          	addi	a0,a0,1094 # 80008908 <syscalls+0x3a8>
    800064ca:	ffffa097          	auipc	ra,0xffffa
    800064ce:	072080e7          	jalr	114(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800064d2:	00002517          	auipc	a0,0x2
    800064d6:	45650513          	addi	a0,a0,1110 # 80008928 <syscalls+0x3c8>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	062080e7          	jalr	98(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800064e2:	00002517          	auipc	a0,0x2
    800064e6:	46650513          	addi	a0,a0,1126 # 80008948 <syscalls+0x3e8>
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	052080e7          	jalr	82(ra) # 8000053c <panic>

00000000800064f2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064f2:	7159                	addi	sp,sp,-112
    800064f4:	f486                	sd	ra,104(sp)
    800064f6:	f0a2                	sd	s0,96(sp)
    800064f8:	eca6                	sd	s1,88(sp)
    800064fa:	e8ca                	sd	s2,80(sp)
    800064fc:	e4ce                	sd	s3,72(sp)
    800064fe:	e0d2                	sd	s4,64(sp)
    80006500:	fc56                	sd	s5,56(sp)
    80006502:	f85a                	sd	s6,48(sp)
    80006504:	f45e                	sd	s7,40(sp)
    80006506:	f062                	sd	s8,32(sp)
    80006508:	ec66                	sd	s9,24(sp)
    8000650a:	e86a                	sd	s10,16(sp)
    8000650c:	1880                	addi	s0,sp,112
    8000650e:	8a2a                	mv	s4,a0
    80006510:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006512:	00c52c83          	lw	s9,12(a0)
    80006516:	001c9c9b          	slliw	s9,s9,0x1
    8000651a:	1c82                	slli	s9,s9,0x20
    8000651c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006520:	0023c517          	auipc	a0,0x23c
    80006524:	98850513          	addi	a0,a0,-1656 # 80241ea8 <disk+0x128>
    80006528:	ffffb097          	auipc	ra,0xffffb
    8000652c:	81c080e7          	jalr	-2020(ra) # 80000d44 <acquire>
  for(int i = 0; i < 3; i++){
    80006530:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006532:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006534:	0023cb17          	auipc	s6,0x23c
    80006538:	84cb0b13          	addi	s6,s6,-1972 # 80241d80 <disk>
  for(int i = 0; i < 3; i++){
    8000653c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000653e:	0023cc17          	auipc	s8,0x23c
    80006542:	96ac0c13          	addi	s8,s8,-1686 # 80241ea8 <disk+0x128>
    80006546:	a095                	j	800065aa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006548:	00fb0733          	add	a4,s6,a5
    8000654c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006550:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006552:	0207c563          	bltz	a5,8000657c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006556:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006558:	0591                	addi	a1,a1,4
    8000655a:	05560d63          	beq	a2,s5,800065b4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000655e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006560:	0023c717          	auipc	a4,0x23c
    80006564:	82070713          	addi	a4,a4,-2016 # 80241d80 <disk>
    80006568:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000656a:	01874683          	lbu	a3,24(a4)
    8000656e:	fee9                	bnez	a3,80006548 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006570:	2785                	addiw	a5,a5,1
    80006572:	0705                	addi	a4,a4,1
    80006574:	fe979be3          	bne	a5,s1,8000656a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006578:	57fd                	li	a5,-1
    8000657a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000657c:	00c05e63          	blez	a2,80006598 <virtio_disk_rw+0xa6>
    80006580:	060a                	slli	a2,a2,0x2
    80006582:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006586:	0009a503          	lw	a0,0(s3)
    8000658a:	00000097          	auipc	ra,0x0
    8000658e:	cfc080e7          	jalr	-772(ra) # 80006286 <free_desc>
      for(int j = 0; j < i; j++)
    80006592:	0991                	addi	s3,s3,4
    80006594:	ffa999e3          	bne	s3,s10,80006586 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006598:	85e2                	mv	a1,s8
    8000659a:	0023b517          	auipc	a0,0x23b
    8000659e:	7fe50513          	addi	a0,a0,2046 # 80241d98 <disk+0x18>
    800065a2:	ffffc097          	auipc	ra,0xffffc
    800065a6:	e8a080e7          	jalr	-374(ra) # 8000242c <sleep>
  for(int i = 0; i < 3; i++){
    800065aa:	f9040993          	addi	s3,s0,-112
{
    800065ae:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800065b0:	864a                	mv	a2,s2
    800065b2:	b775                	j	8000655e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065b4:	f9042503          	lw	a0,-112(s0)
    800065b8:	00a50713          	addi	a4,a0,10
    800065bc:	0712                	slli	a4,a4,0x4

  if(write)
    800065be:	0023b797          	auipc	a5,0x23b
    800065c2:	7c278793          	addi	a5,a5,1986 # 80241d80 <disk>
    800065c6:	00e786b3          	add	a3,a5,a4
    800065ca:	01703633          	snez	a2,s7
    800065ce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065d0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800065d4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065d8:	f6070613          	addi	a2,a4,-160
    800065dc:	6394                	ld	a3,0(a5)
    800065de:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065e0:	00870593          	addi	a1,a4,8
    800065e4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065e6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065e8:	0007b803          	ld	a6,0(a5)
    800065ec:	9642                	add	a2,a2,a6
    800065ee:	46c1                	li	a3,16
    800065f0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065f2:	4585                	li	a1,1
    800065f4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800065f8:	f9442683          	lw	a3,-108(s0)
    800065fc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006600:	0692                	slli	a3,a3,0x4
    80006602:	9836                	add	a6,a6,a3
    80006604:	058a0613          	addi	a2,s4,88
    80006608:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000660c:	0007b803          	ld	a6,0(a5)
    80006610:	96c2                	add	a3,a3,a6
    80006612:	40000613          	li	a2,1024
    80006616:	c690                	sw	a2,8(a3)
  if(write)
    80006618:	001bb613          	seqz	a2,s7
    8000661c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006620:	00166613          	ori	a2,a2,1
    80006624:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006628:	f9842603          	lw	a2,-104(s0)
    8000662c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006630:	00250693          	addi	a3,a0,2
    80006634:	0692                	slli	a3,a3,0x4
    80006636:	96be                	add	a3,a3,a5
    80006638:	58fd                	li	a7,-1
    8000663a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000663e:	0612                	slli	a2,a2,0x4
    80006640:	9832                	add	a6,a6,a2
    80006642:	f9070713          	addi	a4,a4,-112
    80006646:	973e                	add	a4,a4,a5
    80006648:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000664c:	6398                	ld	a4,0(a5)
    8000664e:	9732                	add	a4,a4,a2
    80006650:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006652:	4609                	li	a2,2
    80006654:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006658:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000665c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006660:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006664:	6794                	ld	a3,8(a5)
    80006666:	0026d703          	lhu	a4,2(a3)
    8000666a:	8b1d                	andi	a4,a4,7
    8000666c:	0706                	slli	a4,a4,0x1
    8000666e:	96ba                	add	a3,a3,a4
    80006670:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006674:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006678:	6798                	ld	a4,8(a5)
    8000667a:	00275783          	lhu	a5,2(a4)
    8000667e:	2785                	addiw	a5,a5,1
    80006680:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006684:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006688:	100017b7          	lui	a5,0x10001
    8000668c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006690:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    80006694:	0023c917          	auipc	s2,0x23c
    80006698:	81490913          	addi	s2,s2,-2028 # 80241ea8 <disk+0x128>
  while(b->disk == 1) {
    8000669c:	4485                	li	s1,1
    8000669e:	00b79c63          	bne	a5,a1,800066b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800066a2:	85ca                	mv	a1,s2
    800066a4:	8552                	mv	a0,s4
    800066a6:	ffffc097          	auipc	ra,0xffffc
    800066aa:	d86080e7          	jalr	-634(ra) # 8000242c <sleep>
  while(b->disk == 1) {
    800066ae:	004a2783          	lw	a5,4(s4)
    800066b2:	fe9788e3          	beq	a5,s1,800066a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800066b6:	f9042903          	lw	s2,-112(s0)
    800066ba:	00290713          	addi	a4,s2,2
    800066be:	0712                	slli	a4,a4,0x4
    800066c0:	0023b797          	auipc	a5,0x23b
    800066c4:	6c078793          	addi	a5,a5,1728 # 80241d80 <disk>
    800066c8:	97ba                	add	a5,a5,a4
    800066ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800066ce:	0023b997          	auipc	s3,0x23b
    800066d2:	6b298993          	addi	s3,s3,1714 # 80241d80 <disk>
    800066d6:	00491713          	slli	a4,s2,0x4
    800066da:	0009b783          	ld	a5,0(s3)
    800066de:	97ba                	add	a5,a5,a4
    800066e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066e4:	854a                	mv	a0,s2
    800066e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	b9c080e7          	jalr	-1124(ra) # 80006286 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066f2:	8885                	andi	s1,s1,1
    800066f4:	f0ed                	bnez	s1,800066d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066f6:	0023b517          	auipc	a0,0x23b
    800066fa:	7b250513          	addi	a0,a0,1970 # 80241ea8 <disk+0x128>
    800066fe:	ffffa097          	auipc	ra,0xffffa
    80006702:	6fa080e7          	jalr	1786(ra) # 80000df8 <release>
}
    80006706:	70a6                	ld	ra,104(sp)
    80006708:	7406                	ld	s0,96(sp)
    8000670a:	64e6                	ld	s1,88(sp)
    8000670c:	6946                	ld	s2,80(sp)
    8000670e:	69a6                	ld	s3,72(sp)
    80006710:	6a06                	ld	s4,64(sp)
    80006712:	7ae2                	ld	s5,56(sp)
    80006714:	7b42                	ld	s6,48(sp)
    80006716:	7ba2                	ld	s7,40(sp)
    80006718:	7c02                	ld	s8,32(sp)
    8000671a:	6ce2                	ld	s9,24(sp)
    8000671c:	6d42                	ld	s10,16(sp)
    8000671e:	6165                	addi	sp,sp,112
    80006720:	8082                	ret

0000000080006722 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006722:	1101                	addi	sp,sp,-32
    80006724:	ec06                	sd	ra,24(sp)
    80006726:	e822                	sd	s0,16(sp)
    80006728:	e426                	sd	s1,8(sp)
    8000672a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000672c:	0023b497          	auipc	s1,0x23b
    80006730:	65448493          	addi	s1,s1,1620 # 80241d80 <disk>
    80006734:	0023b517          	auipc	a0,0x23b
    80006738:	77450513          	addi	a0,a0,1908 # 80241ea8 <disk+0x128>
    8000673c:	ffffa097          	auipc	ra,0xffffa
    80006740:	608080e7          	jalr	1544(ra) # 80000d44 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006744:	10001737          	lui	a4,0x10001
    80006748:	533c                	lw	a5,96(a4)
    8000674a:	8b8d                	andi	a5,a5,3
    8000674c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000674e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006752:	689c                	ld	a5,16(s1)
    80006754:	0204d703          	lhu	a4,32(s1)
    80006758:	0027d783          	lhu	a5,2(a5)
    8000675c:	04f70863          	beq	a4,a5,800067ac <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006760:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006764:	6898                	ld	a4,16(s1)
    80006766:	0204d783          	lhu	a5,32(s1)
    8000676a:	8b9d                	andi	a5,a5,7
    8000676c:	078e                	slli	a5,a5,0x3
    8000676e:	97ba                	add	a5,a5,a4
    80006770:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006772:	00278713          	addi	a4,a5,2
    80006776:	0712                	slli	a4,a4,0x4
    80006778:	9726                	add	a4,a4,s1
    8000677a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000677e:	e721                	bnez	a4,800067c6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006780:	0789                	addi	a5,a5,2
    80006782:	0792                	slli	a5,a5,0x4
    80006784:	97a6                	add	a5,a5,s1
    80006786:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006788:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000678c:	ffffc097          	auipc	ra,0xffffc
    80006790:	d04080e7          	jalr	-764(ra) # 80002490 <wakeup>

    disk.used_idx += 1;
    80006794:	0204d783          	lhu	a5,32(s1)
    80006798:	2785                	addiw	a5,a5,1
    8000679a:	17c2                	slli	a5,a5,0x30
    8000679c:	93c1                	srli	a5,a5,0x30
    8000679e:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067a2:	6898                	ld	a4,16(s1)
    800067a4:	00275703          	lhu	a4,2(a4)
    800067a8:	faf71ce3          	bne	a4,a5,80006760 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800067ac:	0023b517          	auipc	a0,0x23b
    800067b0:	6fc50513          	addi	a0,a0,1788 # 80241ea8 <disk+0x128>
    800067b4:	ffffa097          	auipc	ra,0xffffa
    800067b8:	644080e7          	jalr	1604(ra) # 80000df8 <release>
}
    800067bc:	60e2                	ld	ra,24(sp)
    800067be:	6442                	ld	s0,16(sp)
    800067c0:	64a2                	ld	s1,8(sp)
    800067c2:	6105                	addi	sp,sp,32
    800067c4:	8082                	ret
      panic("virtio_disk_intr status");
    800067c6:	00002517          	auipc	a0,0x2
    800067ca:	19a50513          	addi	a0,a0,410 # 80008960 <syscalls+0x400>
    800067ce:	ffffa097          	auipc	ra,0xffffa
    800067d2:	d6e080e7          	jalr	-658(ra) # 8000053c <panic>
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
