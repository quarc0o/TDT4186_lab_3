
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c4010113          	addi	sp,sp,-960 # 80008c40 <stack0>
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
    80000054:	ab070713          	addi	a4,a4,-1360 # 80008b00 <timer_scratch>
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
    80000066:	26e78793          	addi	a5,a5,622 # 800062d0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc88f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	fcc78793          	addi	a5,a5,-52 # 80001078 <main>
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
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	808080e7          	jalr	-2040(ra) # 80002932 <either_copyin>
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
    80000188:	abc50513          	addi	a0,a0,-1348 # 80010c40 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	c4c080e7          	jalr	-948(ra) # 80000dd8 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	aac48493          	addi	s1,s1,-1364 # 80010c40 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	b3c90913          	addi	s2,s2,-1220 # 80010cd8 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	bb8080e7          	jalr	-1096(ra) # 80001d6c <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	5c0080e7          	jalr	1472(ra) # 8000277c <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	30a080e7          	jalr	778(ra) # 800024d4 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	a6270713          	addi	a4,a4,-1438 # 80010c40 <cons>
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
    80000214:	6cc080e7          	jalr	1740(ra) # 800028dc <either_copyout>
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
    8000022c:	a1850513          	addi	a0,a0,-1512 # 80010c40 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	c5c080e7          	jalr	-932(ra) # 80000e8c <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	a0250513          	addi	a0,a0,-1534 # 80010c40 <cons>
    80000246:	00001097          	auipc	ra,0x1
    8000024a:	c46080e7          	jalr	-954(ra) # 80000e8c <release>
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
    80000272:	a6f72523          	sw	a5,-1430(a4) # 80010cd8 <cons+0x98>
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
    800002cc:	97850513          	addi	a0,a0,-1672 # 80010c40 <cons>
    800002d0:	00001097          	auipc	ra,0x1
    800002d4:	b08080e7          	jalr	-1272(ra) # 80000dd8 <acquire>

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
    800002f2:	69a080e7          	jalr	1690(ra) # 80002988 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	94a50513          	addi	a0,a0,-1718 # 80010c40 <cons>
    800002fe:	00001097          	auipc	ra,0x1
    80000302:	b8e080e7          	jalr	-1138(ra) # 80000e8c <release>
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
    8000031e:	92670713          	addi	a4,a4,-1754 # 80010c40 <cons>
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
    80000348:	8fc78793          	addi	a5,a5,-1796 # 80010c40 <cons>
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
    80000376:	9667a783          	lw	a5,-1690(a5) # 80010cd8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	8ba70713          	addi	a4,a4,-1862 # 80010c40 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	8aa48493          	addi	s1,s1,-1878 # 80010c40 <cons>
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
    800003d2:	00011717          	auipc	a4,0x11
    800003d6:	86e70713          	addi	a4,a4,-1938 # 80010c40 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	8ef72c23          	sw	a5,-1800(a4) # 80010ce0 <cons+0xa0>
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
    8000040e:	00011797          	auipc	a5,0x11
    80000412:	83278793          	addi	a5,a5,-1998 # 80010c40 <cons>
    80000416:	0a07a703          	lw	a4,160(a5)
    8000041a:	0017069b          	addiw	a3,a4,1
    8000041e:	0006861b          	sext.w	a2,a3
    80000422:	0ad7a023          	sw	a3,160(a5)
    80000426:	07f77713          	andi	a4,a4,127
    8000042a:	97ba                	add	a5,a5,a4
    8000042c:	4729                	li	a4,10
    8000042e:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000432:	00011797          	auipc	a5,0x11
    80000436:	8ac7a523          	sw	a2,-1878(a5) # 80010cdc <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	89e50513          	addi	a0,a0,-1890 # 80010cd8 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	0f6080e7          	jalr	246(ra) # 80002538 <wakeup>
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
    80000460:	7e450513          	addi	a0,a0,2020 # 80010c40 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	8e4080e7          	jalr	-1820(ra) # 80000d48 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	96478793          	addi	a5,a5,-1692 # 80240dd8 <devsw>
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
    8000055e:	7a07a323          	sw	zero,1958(a5) # 80010d00 <pr+0x18>
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
    80000580:	b2450513          	addi	a0,a0,-1244 # 800080a0 <digits+0x50>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	52f72123          	sw	a5,1314(a4) # 80008ab0 <panicked>
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
    800005ce:	736dad83          	lw	s11,1846(s11) # 80010d00 <pr+0x18>
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
    8000060c:	6e050513          	addi	a0,a0,1760 # 80010ce8 <pr>
    80000610:	00000097          	auipc	ra,0x0
    80000614:	7c8080e7          	jalr	1992(ra) # 80000dd8 <acquire>
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
    8000076a:	58250513          	addi	a0,a0,1410 # 80010ce8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	71e080e7          	jalr	1822(ra) # 80000e8c <release>
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
    80000786:	56648493          	addi	s1,s1,1382 # 80010ce8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8be58593          	addi	a1,a1,-1858 # 80008048 <__func__.1+0x40>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	5b4080e7          	jalr	1460(ra) # 80000d48 <initlock>
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
    800007e6:	52650513          	addi	a0,a0,1318 # 80010d08 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	55e080e7          	jalr	1374(ra) # 80000d48 <initlock>
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
    8000080a:	586080e7          	jalr	1414(ra) # 80000d8c <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	2a27a783          	lw	a5,674(a5) # 80008ab0 <panicked>
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
    80000838:	5f8080e7          	jalr	1528(ra) # 80000e2c <pop_off>
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
    8000084a:	2727b783          	ld	a5,626(a5) # 80008ab8 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	27273703          	ld	a4,626(a4) # 80008ac0 <uart_tx_w>
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
    80000874:	498a0a13          	addi	s4,s4,1176 # 80010d08 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	24048493          	addi	s1,s1,576 # 80008ab8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	24098993          	addi	s3,s3,576 # 80008ac0 <uart_tx_w>
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
    800008a6:	c96080e7          	jalr	-874(ra) # 80002538 <wakeup>
    
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
    800008e2:	42a50513          	addi	a0,a0,1066 # 80010d08 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	4f2080e7          	jalr	1266(ra) # 80000dd8 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1c27a783          	lw	a5,450(a5) # 80008ab0 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	1c873703          	ld	a4,456(a4) # 80008ac0 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1b87b783          	ld	a5,440(a5) # 80008ab8 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	3fc98993          	addi	s3,s3,1020 # 80010d08 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	1a448493          	addi	s1,s1,420 # 80008ab8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	1a490913          	addi	s2,s2,420 # 80008ac0 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	ba8080e7          	jalr	-1112(ra) # 800024d4 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	3c648493          	addi	s1,s1,966 # 80010d08 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	16e7b523          	sd	a4,362(a5) # 80008ac0 <uart_tx_w>
  uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee8080e7          	jalr	-280(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	524080e7          	jalr	1316(ra) # 80000e8c <release>
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
    800009cc:	34048493          	addi	s1,s1,832 # 80010d08 <uart_tx_lock>
    800009d0:	8526                	mv	a0,s1
    800009d2:	00000097          	auipc	ra,0x0
    800009d6:	406080e7          	jalr	1030(ra) # 80000dd8 <acquire>
  uartstart();
    800009da:	00000097          	auipc	ra,0x0
    800009de:	e6c080e7          	jalr	-404(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009e2:	8526                	mv	a0,s1
    800009e4:	00000097          	auipc	ra,0x0
    800009e8:	4a8080e7          	jalr	1192(ra) # 80000e8c <release>
}
    800009ec:	60e2                	ld	ra,24(sp)
    800009ee:	6442                	ld	s0,16(sp)
    800009f0:	64a2                	ld	s1,8(sp)
    800009f2:	6105                	addi	sp,sp,32
    800009f4:	8082                	ret

00000000800009f6 <increment_refcount>:
        reference_count[(uint64) p / PGSIZE] = 1;
        kfree(p);
    }
}

void increment_refcount(uint64 pa) {
    800009f6:	1101                	addi	sp,sp,-32
    800009f8:	ec06                	sd	ra,24(sp)
    800009fa:	e822                	sd	s0,16(sp)
    800009fc:	e426                	sd	s1,8(sp)
    800009fe:	e04a                	sd	s2,0(sp)
    80000a00:	1000                	addi	s0,sp,32
    80000a02:	892a                	mv	s2,a0
    int pn = pa / PGSIZE;
    80000a04:	00c55493          	srli	s1,a0,0xc
    acquire(&kmem.lock);
    80000a08:	00010517          	auipc	a0,0x10
    80000a0c:	33850513          	addi	a0,a0,824 # 80010d40 <kmem>
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	3c8080e7          	jalr	968(ra) # 80000dd8 <acquire>
    if (pa >= PHYSTOP || reference_count[pn] < 1) {
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f97363          	bgeu	s2,a5,80000a62 <increment_refcount+0x6c>
    80000a20:	2481                	sext.w	s1,s1
    80000a22:	00249713          	slli	a4,s1,0x2
    80000a26:	00010797          	auipc	a5,0x10
    80000a2a:	33a78793          	addi	a5,a5,826 # 80010d60 <reference_count>
    80000a2e:	97ba                	add	a5,a5,a4
    80000a30:	439c                	lw	a5,0(a5)
    80000a32:	02f05863          	blez	a5,80000a62 <increment_refcount+0x6c>
        panic("increment_refcount");
    }
    reference_count[pn]++;
    80000a36:	048a                	slli	s1,s1,0x2
    80000a38:	00010717          	auipc	a4,0x10
    80000a3c:	32870713          	addi	a4,a4,808 # 80010d60 <reference_count>
    80000a40:	9726                	add	a4,a4,s1
    80000a42:	2785                	addiw	a5,a5,1
    80000a44:	c31c                	sw	a5,0(a4)
    release(&kmem.lock);
    80000a46:	00010517          	auipc	a0,0x10
    80000a4a:	2fa50513          	addi	a0,a0,762 # 80010d40 <kmem>
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	43e080e7          	jalr	1086(ra) # 80000e8c <release>
}
    80000a56:	60e2                	ld	ra,24(sp)
    80000a58:	6442                	ld	s0,16(sp)
    80000a5a:	64a2                	ld	s1,8(sp)
    80000a5c:	6902                	ld	s2,0(sp)
    80000a5e:	6105                	addi	sp,sp,32
    80000a60:	8082                	ret
        panic("increment_refcount");
    80000a62:	00007517          	auipc	a0,0x7
    80000a66:	60e50513          	addi	a0,a0,1550 # 80008070 <digits+0x20>
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	ad2080e7          	jalr	-1326(ra) # 8000053c <panic>

0000000080000a72 <kfree>:
// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
    80000a72:	1101                	addi	sp,sp,-32
    80000a74:	ec06                	sd	ra,24(sp)
    80000a76:	e822                	sd	s0,16(sp)
    80000a78:	e426                	sd	s1,8(sp)
    80000a7a:	e04a                	sd	s2,0(sp)
    80000a7c:	1000                	addi	s0,sp,32
    80000a7e:	84aa                	mv	s1,a0
    if (MAX_PAGES != 0)
    80000a80:	00008797          	auipc	a5,0x8
    80000a84:	0507b783          	ld	a5,80(a5) # 80008ad0 <MAX_PAGES>
    80000a88:	c799                	beqz	a5,80000a96 <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a8a:	00008717          	auipc	a4,0x8
    80000a8e:	03e73703          	ld	a4,62(a4) # 80008ac8 <FREE_PAGES>
    80000a92:	06f77e63          	bgeu	a4,a5,80000b0e <kfree+0x9c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) {
    80000a96:	03449793          	slli	a5,s1,0x34
    80000a9a:	e7c5                	bnez	a5,80000b42 <kfree+0xd0>
    80000a9c:	00241797          	auipc	a5,0x241
    80000aa0:	4d478793          	addi	a5,a5,1236 # 80241f70 <end>
    80000aa4:	08f4ef63          	bltu	s1,a5,80000b42 <kfree+0xd0>
    80000aa8:	47c5                	li	a5,17
    80000aaa:	07ee                	slli	a5,a5,0x1b
    80000aac:	08f4fb63          	bgeu	s1,a5,80000b42 <kfree+0xd0>
        panic("kfree");
    }

    acquire(&kmem.lock);
    80000ab0:	00010517          	auipc	a0,0x10
    80000ab4:	29050513          	addi	a0,a0,656 # 80010d40 <kmem>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	320080e7          	jalr	800(ra) # 80000dd8 <acquire>
    int pn = (uint64) pa / PGSIZE;
    80000ac0:	00c4d793          	srli	a5,s1,0xc
    80000ac4:	2781                	sext.w	a5,a5
    if (reference_count[pn] < 1) {
    80000ac6:	00279693          	slli	a3,a5,0x2
    80000aca:	00010717          	auipc	a4,0x10
    80000ace:	29670713          	addi	a4,a4,662 # 80010d60 <reference_count>
    80000ad2:	9736                	add	a4,a4,a3
    80000ad4:	4318                	lw	a4,0(a4)
    80000ad6:	06e05e63          	blez	a4,80000b52 <kfree+0xe0>
        panic("kfree");
    }
    reference_count[pn]--;
    80000ada:	377d                	addiw	a4,a4,-1
    80000adc:	0007091b          	sext.w	s2,a4
    80000ae0:	078a                	slli	a5,a5,0x2
    80000ae2:	00010697          	auipc	a3,0x10
    80000ae6:	27e68693          	addi	a3,a3,638 # 80010d60 <reference_count>
    80000aea:	97b6                	add	a5,a5,a3
    80000aec:	c398                	sw	a4,0(a5)
    int temp = reference_count[pn];
    release(&kmem.lock);
    80000aee:	00010517          	auipc	a0,0x10
    80000af2:	25250513          	addi	a0,a0,594 # 80010d40 <kmem>
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	396080e7          	jalr	918(ra) # 80000e8c <release>

    if (0 < temp) {
    80000afe:	07205263          	blez	s2,80000b62 <kfree+0xf0>
    acquire(&kmem.lock);
    r->next = kmem.freelist;
    kmem.freelist = r;
    FREE_PAGES++;
    release(&kmem.lock);
}
    80000b02:	60e2                	ld	ra,24(sp)
    80000b04:	6442                	ld	s0,16(sp)
    80000b06:	64a2                	ld	s1,8(sp)
    80000b08:	6902                	ld	s2,0(sp)
    80000b0a:	6105                	addi	sp,sp,32
    80000b0c:	8082                	ret
        assert(FREE_PAGES < MAX_PAGES);
    80000b0e:	04600693          	li	a3,70
    80000b12:	00007617          	auipc	a2,0x7
    80000b16:	4f660613          	addi	a2,a2,1270 # 80008008 <__func__.1>
    80000b1a:	00007597          	auipc	a1,0x7
    80000b1e:	56e58593          	addi	a1,a1,1390 # 80008088 <digits+0x38>
    80000b22:	00007517          	auipc	a0,0x7
    80000b26:	57650513          	addi	a0,a0,1398 # 80008098 <digits+0x48>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	a6e080e7          	jalr	-1426(ra) # 80000598 <printf>
    80000b32:	00007517          	auipc	a0,0x7
    80000b36:	57650513          	addi	a0,a0,1398 # 800080a8 <digits+0x58>
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	a02080e7          	jalr	-1534(ra) # 8000053c <panic>
        panic("kfree");
    80000b42:	00007517          	auipc	a0,0x7
    80000b46:	57650513          	addi	a0,a0,1398 # 800080b8 <digits+0x68>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	9f2080e7          	jalr	-1550(ra) # 8000053c <panic>
        panic("kfree");
    80000b52:	00007517          	auipc	a0,0x7
    80000b56:	56650513          	addi	a0,a0,1382 # 800080b8 <digits+0x68>
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	9e2080e7          	jalr	-1566(ra) # 8000053c <panic>
    memset(pa, 1, PGSIZE);
    80000b62:	6605                	lui	a2,0x1
    80000b64:	4585                	li	a1,1
    80000b66:	8526                	mv	a0,s1
    80000b68:	00000097          	auipc	ra,0x0
    80000b6c:	36c080e7          	jalr	876(ra) # 80000ed4 <memset>
    acquire(&kmem.lock);
    80000b70:	00010917          	auipc	s2,0x10
    80000b74:	1d090913          	addi	s2,s2,464 # 80010d40 <kmem>
    80000b78:	854a                	mv	a0,s2
    80000b7a:	00000097          	auipc	ra,0x0
    80000b7e:	25e080e7          	jalr	606(ra) # 80000dd8 <acquire>
    r->next = kmem.freelist;
    80000b82:	01893783          	ld	a5,24(s2)
    80000b86:	e09c                	sd	a5,0(s1)
    kmem.freelist = r;
    80000b88:	00993c23          	sd	s1,24(s2)
    FREE_PAGES++;
    80000b8c:	00008717          	auipc	a4,0x8
    80000b90:	f3c70713          	addi	a4,a4,-196 # 80008ac8 <FREE_PAGES>
    80000b94:	631c                	ld	a5,0(a4)
    80000b96:	0785                	addi	a5,a5,1
    80000b98:	e31c                	sd	a5,0(a4)
    release(&kmem.lock);
    80000b9a:	854a                	mv	a0,s2
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	2f0080e7          	jalr	752(ra) # 80000e8c <release>
    80000ba4:	bfb9                	j	80000b02 <kfree+0x90>

0000000080000ba6 <freerange>:
{
    80000ba6:	7139                	addi	sp,sp,-64
    80000ba8:	fc06                	sd	ra,56(sp)
    80000baa:	f822                	sd	s0,48(sp)
    80000bac:	f426                	sd	s1,40(sp)
    80000bae:	f04a                	sd	s2,32(sp)
    80000bb0:	ec4e                	sd	s3,24(sp)
    80000bb2:	e852                	sd	s4,16(sp)
    80000bb4:	e456                	sd	s5,8(sp)
    80000bb6:	e05a                	sd	s6,0(sp)
    80000bb8:	0080                	addi	s0,sp,64
    p = (char *)PGROUNDUP((uint64)pa_start);
    80000bba:	6785                	lui	a5,0x1
    80000bbc:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000bc0:	953a                	add	a0,a0,a4
    80000bc2:	777d                	lui	a4,0xfffff
    80000bc4:	00e574b3          	and	s1,a0,a4
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bc8:	97a6                	add	a5,a5,s1
    80000bca:	02f5ea63          	bltu	a1,a5,80000bfe <freerange+0x58>
    80000bce:	892e                	mv	s2,a1
        reference_count[(uint64) p / PGSIZE] = 1;
    80000bd0:	00010b17          	auipc	s6,0x10
    80000bd4:	190b0b13          	addi	s6,s6,400 # 80010d60 <reference_count>
    80000bd8:	4a85                	li	s5,1
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bda:	6a05                	lui	s4,0x1
    80000bdc:	6989                	lui	s3,0x2
        reference_count[(uint64) p / PGSIZE] = 1;
    80000bde:	00c4d793          	srli	a5,s1,0xc
    80000be2:	078a                	slli	a5,a5,0x2
    80000be4:	97da                	add	a5,a5,s6
    80000be6:	0157a023          	sw	s5,0(a5)
        kfree(p);
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	e86080e7          	jalr	-378(ra) # 80000a72 <kfree>
    for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
    80000bf4:	87a6                	mv	a5,s1
    80000bf6:	94d2                	add	s1,s1,s4
    80000bf8:	97ce                	add	a5,a5,s3
    80000bfa:	fef972e3          	bgeu	s2,a5,80000bde <freerange+0x38>
}
    80000bfe:	70e2                	ld	ra,56(sp)
    80000c00:	7442                	ld	s0,48(sp)
    80000c02:	74a2                	ld	s1,40(sp)
    80000c04:	7902                	ld	s2,32(sp)
    80000c06:	69e2                	ld	s3,24(sp)
    80000c08:	6a42                	ld	s4,16(sp)
    80000c0a:	6aa2                	ld	s5,8(sp)
    80000c0c:	6b02                	ld	s6,0(sp)
    80000c0e:	6121                	addi	sp,sp,64
    80000c10:	8082                	ret

0000000080000c12 <kinit>:
{
    80000c12:	1141                	addi	sp,sp,-16
    80000c14:	e406                	sd	ra,8(sp)
    80000c16:	e022                	sd	s0,0(sp)
    80000c18:	0800                	addi	s0,sp,16
    initlock(&kmem.lock, "kmem");
    80000c1a:	00007597          	auipc	a1,0x7
    80000c1e:	4a658593          	addi	a1,a1,1190 # 800080c0 <digits+0x70>
    80000c22:	00010517          	auipc	a0,0x10
    80000c26:	11e50513          	addi	a0,a0,286 # 80010d40 <kmem>
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	11e080e7          	jalr	286(ra) # 80000d48 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000c32:	45c5                	li	a1,17
    80000c34:	05ee                	slli	a1,a1,0x1b
    80000c36:	00241517          	auipc	a0,0x241
    80000c3a:	33a50513          	addi	a0,a0,826 # 80241f70 <end>
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	f68080e7          	jalr	-152(ra) # 80000ba6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000c46:	00008797          	auipc	a5,0x8
    80000c4a:	e827b783          	ld	a5,-382(a5) # 80008ac8 <FREE_PAGES>
    80000c4e:	00008717          	auipc	a4,0x8
    80000c52:	e8f73123          	sd	a5,-382(a4) # 80008ad0 <MAX_PAGES>
}
    80000c56:	60a2                	ld	ra,8(sp)
    80000c58:	6402                	ld	s0,0(sp)
    80000c5a:	0141                	addi	sp,sp,16
    80000c5c:	8082                	ret

0000000080000c5e <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c5e:	1101                	addi	sp,sp,-32
    80000c60:	ec06                	sd	ra,24(sp)
    80000c62:	e822                	sd	s0,16(sp)
    80000c64:	e426                	sd	s1,8(sp)
    80000c66:	1000                	addi	s0,sp,32
    assert(FREE_PAGES > 0);
    80000c68:	00008797          	auipc	a5,0x8
    80000c6c:	e607b783          	ld	a5,-416(a5) # 80008ac8 <FREE_PAGES>
    80000c70:	c3c9                	beqz	a5,80000cf2 <kalloc+0x94>
    struct run *r;

    acquire(&kmem.lock);
    80000c72:	00010497          	auipc	s1,0x10
    80000c76:	0ce48493          	addi	s1,s1,206 # 80010d40 <kmem>
    80000c7a:	8526                	mv	a0,s1
    80000c7c:	00000097          	auipc	ra,0x0
    80000c80:	15c080e7          	jalr	348(ra) # 80000dd8 <acquire>
    r = kmem.freelist;
    80000c84:	6c84                	ld	s1,24(s1)
    if (r) {
    80000c86:	c8c5                	beqz	s1,80000d36 <kalloc+0xd8>
        kmem.freelist = r->next;
    80000c88:	609c                	ld	a5,0(s1)
    80000c8a:	00010717          	auipc	a4,0x10
    80000c8e:	0cf73723          	sd	a5,206(a4) # 80010d58 <kmem+0x18>
        int pn = (uint64) r / PGSIZE;
    80000c92:	00c4d793          	srli	a5,s1,0xc
    80000c96:	2781                	sext.w	a5,a5
        // Check that refcount is not 0
        if (reference_count[pn] != 0) {
    80000c98:	00279693          	slli	a3,a5,0x2
    80000c9c:	00010717          	auipc	a4,0x10
    80000ca0:	0c470713          	addi	a4,a4,196 # 80010d60 <reference_count>
    80000ca4:	9736                	add	a4,a4,a3
    80000ca6:	4318                	lw	a4,0(a4)
    80000ca8:	ef3d                	bnez	a4,80000d26 <kalloc+0xc8>
            panic("kalloc");
        }
        reference_count[pn] = 1;
    80000caa:	078a                	slli	a5,a5,0x2
    80000cac:	00010717          	auipc	a4,0x10
    80000cb0:	0b470713          	addi	a4,a4,180 # 80010d60 <reference_count>
    80000cb4:	97ba                	add	a5,a5,a4
    80000cb6:	4705                	li	a4,1
    80000cb8:	c398                	sw	a4,0(a5)
    } 
    release(&kmem.lock);
    80000cba:	00010517          	auipc	a0,0x10
    80000cbe:	08650513          	addi	a0,a0,134 # 80010d40 <kmem>
    80000cc2:	00000097          	auipc	ra,0x0
    80000cc6:	1ca080e7          	jalr	458(ra) # 80000e8c <release>

    if (r)
        memset((char *)r, 5, PGSIZE); // fill with junk
    80000cca:	6605                	lui	a2,0x1
    80000ccc:	4595                	li	a1,5
    80000cce:	8526                	mv	a0,s1
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	204080e7          	jalr	516(ra) # 80000ed4 <memset>
    FREE_PAGES--;
    80000cd8:	00008717          	auipc	a4,0x8
    80000cdc:	df070713          	addi	a4,a4,-528 # 80008ac8 <FREE_PAGES>
    80000ce0:	631c                	ld	a5,0(a4)
    80000ce2:	17fd                	addi	a5,a5,-1
    80000ce4:	e31c                	sd	a5,0(a4)
    return (void *)r;
}
    80000ce6:	8526                	mv	a0,s1
    80000ce8:	60e2                	ld	ra,24(sp)
    80000cea:	6442                	ld	s0,16(sp)
    80000cec:	64a2                	ld	s1,8(sp)
    80000cee:	6105                	addi	sp,sp,32
    80000cf0:	8082                	ret
    assert(FREE_PAGES > 0);
    80000cf2:	06c00693          	li	a3,108
    80000cf6:	00007617          	auipc	a2,0x7
    80000cfa:	30a60613          	addi	a2,a2,778 # 80008000 <etext>
    80000cfe:	00007597          	auipc	a1,0x7
    80000d02:	38a58593          	addi	a1,a1,906 # 80008088 <digits+0x38>
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	39250513          	addi	a0,a0,914 # 80008098 <digits+0x48>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	88a080e7          	jalr	-1910(ra) # 80000598 <printf>
    80000d16:	00007517          	auipc	a0,0x7
    80000d1a:	39250513          	addi	a0,a0,914 # 800080a8 <digits+0x58>
    80000d1e:	00000097          	auipc	ra,0x0
    80000d22:	81e080e7          	jalr	-2018(ra) # 8000053c <panic>
            panic("kalloc");
    80000d26:	00007517          	auipc	a0,0x7
    80000d2a:	3a250513          	addi	a0,a0,930 # 800080c8 <digits+0x78>
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	80e080e7          	jalr	-2034(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000d36:	00010517          	auipc	a0,0x10
    80000d3a:	00a50513          	addi	a0,a0,10 # 80010d40 <kmem>
    80000d3e:	00000097          	auipc	ra,0x0
    80000d42:	14e080e7          	jalr	334(ra) # 80000e8c <release>
    if (r)
    80000d46:	bf49                	j	80000cd8 <kalloc+0x7a>

0000000080000d48 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000d48:	1141                	addi	sp,sp,-16
    80000d4a:	e422                	sd	s0,8(sp)
    80000d4c:	0800                	addi	s0,sp,16
  lk->name = name;
    80000d4e:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000d50:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000d54:	00053823          	sd	zero,16(a0)
}
    80000d58:	6422                	ld	s0,8(sp)
    80000d5a:	0141                	addi	sp,sp,16
    80000d5c:	8082                	ret

0000000080000d5e <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000d5e:	411c                	lw	a5,0(a0)
    80000d60:	e399                	bnez	a5,80000d66 <holding+0x8>
    80000d62:	4501                	li	a0,0
  return r;
}
    80000d64:	8082                	ret
{
    80000d66:	1101                	addi	sp,sp,-32
    80000d68:	ec06                	sd	ra,24(sp)
    80000d6a:	e822                	sd	s0,16(sp)
    80000d6c:	e426                	sd	s1,8(sp)
    80000d6e:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000d70:	6904                	ld	s1,16(a0)
    80000d72:	00001097          	auipc	ra,0x1
    80000d76:	fde080e7          	jalr	-34(ra) # 80001d50 <mycpu>
    80000d7a:	40a48533          	sub	a0,s1,a0
    80000d7e:	00153513          	seqz	a0,a0
}
    80000d82:	60e2                	ld	ra,24(sp)
    80000d84:	6442                	ld	s0,16(sp)
    80000d86:	64a2                	ld	s1,8(sp)
    80000d88:	6105                	addi	sp,sp,32
    80000d8a:	8082                	ret

0000000080000d8c <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d8c:	1101                	addi	sp,sp,-32
    80000d8e:	ec06                	sd	ra,24(sp)
    80000d90:	e822                	sd	s0,16(sp)
    80000d92:	e426                	sd	s1,8(sp)
    80000d94:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d96:	100024f3          	csrr	s1,sstatus
    80000d9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000da0:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000da4:	00001097          	auipc	ra,0x1
    80000da8:	fac080e7          	jalr	-84(ra) # 80001d50 <mycpu>
    80000dac:	5d3c                	lw	a5,120(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000db0:	00001097          	auipc	ra,0x1
    80000db4:	fa0080e7          	jalr	-96(ra) # 80001d50 <mycpu>
    80000db8:	5d3c                	lw	a5,120(a0)
    80000dba:	2785                	addiw	a5,a5,1
    80000dbc:	dd3c                	sw	a5,120(a0)
}
    80000dbe:	60e2                	ld	ra,24(sp)
    80000dc0:	6442                	ld	s0,16(sp)
    80000dc2:	64a2                	ld	s1,8(sp)
    80000dc4:	6105                	addi	sp,sp,32
    80000dc6:	8082                	ret
    mycpu()->intena = old;
    80000dc8:	00001097          	auipc	ra,0x1
    80000dcc:	f88080e7          	jalr	-120(ra) # 80001d50 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000dd0:	8085                	srli	s1,s1,0x1
    80000dd2:	8885                	andi	s1,s1,1
    80000dd4:	dd64                	sw	s1,124(a0)
    80000dd6:	bfe9                	j	80000db0 <push_off+0x24>

0000000080000dd8 <acquire>:
{
    80000dd8:	1101                	addi	sp,sp,-32
    80000dda:	ec06                	sd	ra,24(sp)
    80000ddc:	e822                	sd	s0,16(sp)
    80000dde:	e426                	sd	s1,8(sp)
    80000de0:	1000                	addi	s0,sp,32
    80000de2:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000de4:	00000097          	auipc	ra,0x0
    80000de8:	fa8080e7          	jalr	-88(ra) # 80000d8c <push_off>
  if(holding(lk))
    80000dec:	8526                	mv	a0,s1
    80000dee:	00000097          	auipc	ra,0x0
    80000df2:	f70080e7          	jalr	-144(ra) # 80000d5e <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000df6:	4705                	li	a4,1
  if(holding(lk))
    80000df8:	e115                	bnez	a0,80000e1c <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000dfa:	87ba                	mv	a5,a4
    80000dfc:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000e00:	2781                	sext.w	a5,a5
    80000e02:	ffe5                	bnez	a5,80000dfa <acquire+0x22>
  __sync_synchronize();
    80000e04:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000e08:	00001097          	auipc	ra,0x1
    80000e0c:	f48080e7          	jalr	-184(ra) # 80001d50 <mycpu>
    80000e10:	e888                	sd	a0,16(s1)
}
    80000e12:	60e2                	ld	ra,24(sp)
    80000e14:	6442                	ld	s0,16(sp)
    80000e16:	64a2                	ld	s1,8(sp)
    80000e18:	6105                	addi	sp,sp,32
    80000e1a:	8082                	ret
    panic("acquire");
    80000e1c:	00007517          	auipc	a0,0x7
    80000e20:	2b450513          	addi	a0,a0,692 # 800080d0 <digits+0x80>
    80000e24:	fffff097          	auipc	ra,0xfffff
    80000e28:	718080e7          	jalr	1816(ra) # 8000053c <panic>

0000000080000e2c <pop_off>:

void
pop_off(void)
{
    80000e2c:	1141                	addi	sp,sp,-16
    80000e2e:	e406                	sd	ra,8(sp)
    80000e30:	e022                	sd	s0,0(sp)
    80000e32:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000e34:	00001097          	auipc	ra,0x1
    80000e38:	f1c080e7          	jalr	-228(ra) # 80001d50 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e3c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000e40:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000e42:	e78d                	bnez	a5,80000e6c <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000e44:	5d3c                	lw	a5,120(a0)
    80000e46:	02f05b63          	blez	a5,80000e7c <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000e4a:	37fd                	addiw	a5,a5,-1
    80000e4c:	0007871b          	sext.w	a4,a5
    80000e50:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000e52:	eb09                	bnez	a4,80000e64 <pop_off+0x38>
    80000e54:	5d7c                	lw	a5,124(a0)
    80000e56:	c799                	beqz	a5,80000e64 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e58:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e5c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e60:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e64:	60a2                	ld	ra,8(sp)
    80000e66:	6402                	ld	s0,0(sp)
    80000e68:	0141                	addi	sp,sp,16
    80000e6a:	8082                	ret
    panic("pop_off - interruptible");
    80000e6c:	00007517          	auipc	a0,0x7
    80000e70:	26c50513          	addi	a0,a0,620 # 800080d8 <digits+0x88>
    80000e74:	fffff097          	auipc	ra,0xfffff
    80000e78:	6c8080e7          	jalr	1736(ra) # 8000053c <panic>
    panic("pop_off");
    80000e7c:	00007517          	auipc	a0,0x7
    80000e80:	27450513          	addi	a0,a0,628 # 800080f0 <digits+0xa0>
    80000e84:	fffff097          	auipc	ra,0xfffff
    80000e88:	6b8080e7          	jalr	1720(ra) # 8000053c <panic>

0000000080000e8c <release>:
{
    80000e8c:	1101                	addi	sp,sp,-32
    80000e8e:	ec06                	sd	ra,24(sp)
    80000e90:	e822                	sd	s0,16(sp)
    80000e92:	e426                	sd	s1,8(sp)
    80000e94:	1000                	addi	s0,sp,32
    80000e96:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e98:	00000097          	auipc	ra,0x0
    80000e9c:	ec6080e7          	jalr	-314(ra) # 80000d5e <holding>
    80000ea0:	c115                	beqz	a0,80000ec4 <release+0x38>
  lk->cpu = 0;
    80000ea2:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ea6:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000eaa:	0f50000f          	fence	iorw,ow
    80000eae:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000eb2:	00000097          	auipc	ra,0x0
    80000eb6:	f7a080e7          	jalr	-134(ra) # 80000e2c <pop_off>
}
    80000eba:	60e2                	ld	ra,24(sp)
    80000ebc:	6442                	ld	s0,16(sp)
    80000ebe:	64a2                	ld	s1,8(sp)
    80000ec0:	6105                	addi	sp,sp,32
    80000ec2:	8082                	ret
    panic("release");
    80000ec4:	00007517          	auipc	a0,0x7
    80000ec8:	23450513          	addi	a0,a0,564 # 800080f8 <digits+0xa8>
    80000ecc:	fffff097          	auipc	ra,0xfffff
    80000ed0:	670080e7          	jalr	1648(ra) # 8000053c <panic>

0000000080000ed4 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ed4:	1141                	addi	sp,sp,-16
    80000ed6:	e422                	sd	s0,8(sp)
    80000ed8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000eda:	ca19                	beqz	a2,80000ef0 <memset+0x1c>
    80000edc:	87aa                	mv	a5,a0
    80000ede:	1602                	slli	a2,a2,0x20
    80000ee0:	9201                	srli	a2,a2,0x20
    80000ee2:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ee6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000eea:	0785                	addi	a5,a5,1
    80000eec:	fee79de3          	bne	a5,a4,80000ee6 <memset+0x12>
  }
  return dst;
}
    80000ef0:	6422                	ld	s0,8(sp)
    80000ef2:	0141                	addi	sp,sp,16
    80000ef4:	8082                	ret

0000000080000ef6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000ef6:	1141                	addi	sp,sp,-16
    80000ef8:	e422                	sd	s0,8(sp)
    80000efa:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000efc:	ca05                	beqz	a2,80000f2c <memcmp+0x36>
    80000efe:	fff6069b          	addiw	a3,a2,-1
    80000f02:	1682                	slli	a3,a3,0x20
    80000f04:	9281                	srli	a3,a3,0x20
    80000f06:	0685                	addi	a3,a3,1
    80000f08:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000f0a:	00054783          	lbu	a5,0(a0)
    80000f0e:	0005c703          	lbu	a4,0(a1)
    80000f12:	00e79863          	bne	a5,a4,80000f22 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000f16:	0505                	addi	a0,a0,1
    80000f18:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000f1a:	fed518e3          	bne	a0,a3,80000f0a <memcmp+0x14>
  }

  return 0;
    80000f1e:	4501                	li	a0,0
    80000f20:	a019                	j	80000f26 <memcmp+0x30>
      return *s1 - *s2;
    80000f22:	40e7853b          	subw	a0,a5,a4
}
    80000f26:	6422                	ld	s0,8(sp)
    80000f28:	0141                	addi	sp,sp,16
    80000f2a:	8082                	ret
  return 0;
    80000f2c:	4501                	li	a0,0
    80000f2e:	bfe5                	j	80000f26 <memcmp+0x30>

0000000080000f30 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000f30:	1141                	addi	sp,sp,-16
    80000f32:	e422                	sd	s0,8(sp)
    80000f34:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000f36:	c205                	beqz	a2,80000f56 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000f38:	02a5e263          	bltu	a1,a0,80000f5c <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000f3c:	1602                	slli	a2,a2,0x20
    80000f3e:	9201                	srli	a2,a2,0x20
    80000f40:	00c587b3          	add	a5,a1,a2
{
    80000f44:	872a                	mv	a4,a0
      *d++ = *s++;
    80000f46:	0585                	addi	a1,a1,1
    80000f48:	0705                	addi	a4,a4,1
    80000f4a:	fff5c683          	lbu	a3,-1(a1)
    80000f4e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000f52:	fef59ae3          	bne	a1,a5,80000f46 <memmove+0x16>

  return dst;
}
    80000f56:	6422                	ld	s0,8(sp)
    80000f58:	0141                	addi	sp,sp,16
    80000f5a:	8082                	ret
  if(s < d && s + n > d){
    80000f5c:	02061693          	slli	a3,a2,0x20
    80000f60:	9281                	srli	a3,a3,0x20
    80000f62:	00d58733          	add	a4,a1,a3
    80000f66:	fce57be3          	bgeu	a0,a4,80000f3c <memmove+0xc>
    d += n;
    80000f6a:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000f6c:	fff6079b          	addiw	a5,a2,-1
    80000f70:	1782                	slli	a5,a5,0x20
    80000f72:	9381                	srli	a5,a5,0x20
    80000f74:	fff7c793          	not	a5,a5
    80000f78:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000f7a:	177d                	addi	a4,a4,-1
    80000f7c:	16fd                	addi	a3,a3,-1
    80000f7e:	00074603          	lbu	a2,0(a4)
    80000f82:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000f86:	fee79ae3          	bne	a5,a4,80000f7a <memmove+0x4a>
    80000f8a:	b7f1                	j	80000f56 <memmove+0x26>

0000000080000f8c <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000f8c:	1141                	addi	sp,sp,-16
    80000f8e:	e406                	sd	ra,8(sp)
    80000f90:	e022                	sd	s0,0(sp)
    80000f92:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000f94:	00000097          	auipc	ra,0x0
    80000f98:	f9c080e7          	jalr	-100(ra) # 80000f30 <memmove>
}
    80000f9c:	60a2                	ld	ra,8(sp)
    80000f9e:	6402                	ld	s0,0(sp)
    80000fa0:	0141                	addi	sp,sp,16
    80000fa2:	8082                	ret

0000000080000fa4 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000faa:	ce11                	beqz	a2,80000fc6 <strncmp+0x22>
    80000fac:	00054783          	lbu	a5,0(a0)
    80000fb0:	cf89                	beqz	a5,80000fca <strncmp+0x26>
    80000fb2:	0005c703          	lbu	a4,0(a1)
    80000fb6:	00f71a63          	bne	a4,a5,80000fca <strncmp+0x26>
    n--, p++, q++;
    80000fba:	367d                	addiw	a2,a2,-1
    80000fbc:	0505                	addi	a0,a0,1
    80000fbe:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000fc0:	f675                	bnez	a2,80000fac <strncmp+0x8>
  if(n == 0)
    return 0;
    80000fc2:	4501                	li	a0,0
    80000fc4:	a809                	j	80000fd6 <strncmp+0x32>
    80000fc6:	4501                	li	a0,0
    80000fc8:	a039                	j	80000fd6 <strncmp+0x32>
  if(n == 0)
    80000fca:	ca09                	beqz	a2,80000fdc <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000fcc:	00054503          	lbu	a0,0(a0)
    80000fd0:	0005c783          	lbu	a5,0(a1)
    80000fd4:	9d1d                	subw	a0,a0,a5
}
    80000fd6:	6422                	ld	s0,8(sp)
    80000fd8:	0141                	addi	sp,sp,16
    80000fda:	8082                	ret
    return 0;
    80000fdc:	4501                	li	a0,0
    80000fde:	bfe5                	j	80000fd6 <strncmp+0x32>

0000000080000fe0 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000fe0:	1141                	addi	sp,sp,-16
    80000fe2:	e422                	sd	s0,8(sp)
    80000fe4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000fe6:	87aa                	mv	a5,a0
    80000fe8:	86b2                	mv	a3,a2
    80000fea:	367d                	addiw	a2,a2,-1
    80000fec:	00d05963          	blez	a3,80000ffe <strncpy+0x1e>
    80000ff0:	0785                	addi	a5,a5,1
    80000ff2:	0005c703          	lbu	a4,0(a1)
    80000ff6:	fee78fa3          	sb	a4,-1(a5)
    80000ffa:	0585                	addi	a1,a1,1
    80000ffc:	f775                	bnez	a4,80000fe8 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000ffe:	873e                	mv	a4,a5
    80001000:	9fb5                	addw	a5,a5,a3
    80001002:	37fd                	addiw	a5,a5,-1
    80001004:	00c05963          	blez	a2,80001016 <strncpy+0x36>
    *s++ = 0;
    80001008:	0705                	addi	a4,a4,1
    8000100a:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    8000100e:	40e786bb          	subw	a3,a5,a4
    80001012:	fed04be3          	bgtz	a3,80001008 <strncpy+0x28>
  return os;
}
    80001016:	6422                	ld	s0,8(sp)
    80001018:	0141                	addi	sp,sp,16
    8000101a:	8082                	ret

000000008000101c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000101c:	1141                	addi	sp,sp,-16
    8000101e:	e422                	sd	s0,8(sp)
    80001020:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001022:	02c05363          	blez	a2,80001048 <safestrcpy+0x2c>
    80001026:	fff6069b          	addiw	a3,a2,-1
    8000102a:	1682                	slli	a3,a3,0x20
    8000102c:	9281                	srli	a3,a3,0x20
    8000102e:	96ae                	add	a3,a3,a1
    80001030:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001032:	00d58963          	beq	a1,a3,80001044 <safestrcpy+0x28>
    80001036:	0585                	addi	a1,a1,1
    80001038:	0785                	addi	a5,a5,1
    8000103a:	fff5c703          	lbu	a4,-1(a1)
    8000103e:	fee78fa3          	sb	a4,-1(a5)
    80001042:	fb65                	bnez	a4,80001032 <safestrcpy+0x16>
    ;
  *s = 0;
    80001044:	00078023          	sb	zero,0(a5)
  return os;
}
    80001048:	6422                	ld	s0,8(sp)
    8000104a:	0141                	addi	sp,sp,16
    8000104c:	8082                	ret

000000008000104e <strlen>:

int
strlen(const char *s)
{
    8000104e:	1141                	addi	sp,sp,-16
    80001050:	e422                	sd	s0,8(sp)
    80001052:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001054:	00054783          	lbu	a5,0(a0)
    80001058:	cf91                	beqz	a5,80001074 <strlen+0x26>
    8000105a:	0505                	addi	a0,a0,1
    8000105c:	87aa                	mv	a5,a0
    8000105e:	86be                	mv	a3,a5
    80001060:	0785                	addi	a5,a5,1
    80001062:	fff7c703          	lbu	a4,-1(a5)
    80001066:	ff65                	bnez	a4,8000105e <strlen+0x10>
    80001068:	40a6853b          	subw	a0,a3,a0
    8000106c:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    8000106e:	6422                	ld	s0,8(sp)
    80001070:	0141                	addi	sp,sp,16
    80001072:	8082                	ret
  for(n = 0; s[n]; n++)
    80001074:	4501                	li	a0,0
    80001076:	bfe5                	j	8000106e <strlen+0x20>

0000000080001078 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80001078:	1141                	addi	sp,sp,-16
    8000107a:	e406                	sd	ra,8(sp)
    8000107c:	e022                	sd	s0,0(sp)
    8000107e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001080:	00001097          	auipc	ra,0x1
    80001084:	cc0080e7          	jalr	-832(ra) # 80001d40 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001088:	00008717          	auipc	a4,0x8
    8000108c:	a5070713          	addi	a4,a4,-1456 # 80008ad8 <started>
  if(cpuid() == 0){
    80001090:	c139                	beqz	a0,800010d6 <main+0x5e>
    while(started == 0)
    80001092:	431c                	lw	a5,0(a4)
    80001094:	2781                	sext.w	a5,a5
    80001096:	dff5                	beqz	a5,80001092 <main+0x1a>
      ;
    __sync_synchronize();
    80001098:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000109c:	00001097          	auipc	ra,0x1
    800010a0:	ca4080e7          	jalr	-860(ra) # 80001d40 <cpuid>
    800010a4:	85aa                	mv	a1,a0
    800010a6:	00007517          	auipc	a0,0x7
    800010aa:	07250513          	addi	a0,a0,114 # 80008118 <digits+0xc8>
    800010ae:	fffff097          	auipc	ra,0xfffff
    800010b2:	4ea080e7          	jalr	1258(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	0d8080e7          	jalr	216(ra) # 8000118e <kvminithart>
    trapinithart();   // install kernel trap vector
    800010be:	00002097          	auipc	ra,0x2
    800010c2:	aee080e7          	jalr	-1298(ra) # 80002bac <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800010c6:	00005097          	auipc	ra,0x5
    800010ca:	24a080e7          	jalr	586(ra) # 80006310 <plicinithart>
  }

  scheduler();        
    800010ce:	00001097          	auipc	ra,0x1
    800010d2:	2e4080e7          	jalr	740(ra) # 800023b2 <scheduler>
    consoleinit();
    800010d6:	fffff097          	auipc	ra,0xfffff
    800010da:	376080e7          	jalr	886(ra) # 8000044c <consoleinit>
    printfinit();
    800010de:	fffff097          	auipc	ra,0xfffff
    800010e2:	69a080e7          	jalr	1690(ra) # 80000778 <printfinit>
    printf("\n");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	fba50513          	addi	a0,a0,-70 # 800080a0 <digits+0x50>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	4aa080e7          	jalr	1194(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	00a50513          	addi	a0,a0,10 # 80008100 <digits+0xb0>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	49a080e7          	jalr	1178(ra) # 80000598 <printf>
    printf("\n");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	f9a50513          	addi	a0,a0,-102 # 800080a0 <digits+0x50>
    8000110e:	fffff097          	auipc	ra,0xfffff
    80001112:	48a080e7          	jalr	1162(ra) # 80000598 <printf>
    kinit();         // physical page allocator
    80001116:	00000097          	auipc	ra,0x0
    8000111a:	afc080e7          	jalr	-1284(ra) # 80000c12 <kinit>
    kvminit();       // create kernel page table
    8000111e:	00000097          	auipc	ra,0x0
    80001122:	326080e7          	jalr	806(ra) # 80001444 <kvminit>
    kvminithart();   // turn on paging
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	068080e7          	jalr	104(ra) # 8000118e <kvminithart>
    procinit();      // process table
    8000112e:	00001097          	auipc	ra,0x1
    80001132:	b3a080e7          	jalr	-1222(ra) # 80001c68 <procinit>
    trapinit();      // trap vectors
    80001136:	00002097          	auipc	ra,0x2
    8000113a:	a4e080e7          	jalr	-1458(ra) # 80002b84 <trapinit>
    trapinithart();  // install kernel trap vector
    8000113e:	00002097          	auipc	ra,0x2
    80001142:	a6e080e7          	jalr	-1426(ra) # 80002bac <trapinithart>
    plicinit();      // set up interrupt controller
    80001146:	00005097          	auipc	ra,0x5
    8000114a:	1b4080e7          	jalr	436(ra) # 800062fa <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000114e:	00005097          	auipc	ra,0x5
    80001152:	1c2080e7          	jalr	450(ra) # 80006310 <plicinithart>
    binit();         // buffer cache
    80001156:	00002097          	auipc	ra,0x2
    8000115a:	3ba080e7          	jalr	954(ra) # 80003510 <binit>
    iinit();         // inode table
    8000115e:	00003097          	auipc	ra,0x3
    80001162:	a58080e7          	jalr	-1448(ra) # 80003bb6 <iinit>
    fileinit();      // file table
    80001166:	00004097          	auipc	ra,0x4
    8000116a:	9ce080e7          	jalr	-1586(ra) # 80004b34 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000116e:	00005097          	auipc	ra,0x5
    80001172:	2aa080e7          	jalr	682(ra) # 80006418 <virtio_disk_init>
    userinit();      // first user process
    80001176:	00001097          	auipc	ra,0x1
    8000117a:	ece080e7          	jalr	-306(ra) # 80002044 <userinit>
    __sync_synchronize();
    8000117e:	0ff0000f          	fence
    started = 1;
    80001182:	4785                	li	a5,1
    80001184:	00008717          	auipc	a4,0x8
    80001188:	94f72a23          	sw	a5,-1708(a4) # 80008ad8 <started>
    8000118c:	b789                	j	800010ce <main+0x56>

000000008000118e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000118e:	1141                	addi	sp,sp,-16
    80001190:	e422                	sd	s0,8(sp)
    80001192:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001194:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001198:	00008797          	auipc	a5,0x8
    8000119c:	9487b783          	ld	a5,-1720(a5) # 80008ae0 <kernel_pagetable>
    800011a0:	83b1                	srli	a5,a5,0xc
    800011a2:	577d                	li	a4,-1
    800011a4:	177e                	slli	a4,a4,0x3f
    800011a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800011a8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800011ac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    800011b0:	6422                	ld	s0,8(sp)
    800011b2:	0141                	addi	sp,sp,16
    800011b4:	8082                	ret

00000000800011b6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800011b6:	7139                	addi	sp,sp,-64
    800011b8:	fc06                	sd	ra,56(sp)
    800011ba:	f822                	sd	s0,48(sp)
    800011bc:	f426                	sd	s1,40(sp)
    800011be:	f04a                	sd	s2,32(sp)
    800011c0:	ec4e                	sd	s3,24(sp)
    800011c2:	e852                	sd	s4,16(sp)
    800011c4:	e456                	sd	s5,8(sp)
    800011c6:	e05a                	sd	s6,0(sp)
    800011c8:	0080                	addi	s0,sp,64
    800011ca:	84aa                	mv	s1,a0
    800011cc:	89ae                	mv	s3,a1
    800011ce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800011d0:	57fd                	li	a5,-1
    800011d2:	83e9                	srli	a5,a5,0x1a
    800011d4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800011d6:	4b31                	li	s6,12
  if(va >= MAXVA)
    800011d8:	04b7f263          	bgeu	a5,a1,8000121c <walk+0x66>
    panic("walk");
    800011dc:	00007517          	auipc	a0,0x7
    800011e0:	f5450513          	addi	a0,a0,-172 # 80008130 <digits+0xe0>
    800011e4:	fffff097          	auipc	ra,0xfffff
    800011e8:	358080e7          	jalr	856(ra) # 8000053c <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800011ec:	060a8663          	beqz	s5,80001258 <walk+0xa2>
    800011f0:	00000097          	auipc	ra,0x0
    800011f4:	a6e080e7          	jalr	-1426(ra) # 80000c5e <kalloc>
    800011f8:	84aa                	mv	s1,a0
    800011fa:	c529                	beqz	a0,80001244 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800011fc:	6605                	lui	a2,0x1
    800011fe:	4581                	li	a1,0
    80001200:	00000097          	auipc	ra,0x0
    80001204:	cd4080e7          	jalr	-812(ra) # 80000ed4 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001208:	00c4d793          	srli	a5,s1,0xc
    8000120c:	07aa                	slli	a5,a5,0xa
    8000120e:	0017e793          	ori	a5,a5,1
    80001212:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001216:	3a5d                	addiw	s4,s4,-9 # ff7 <_entry-0x7ffff009>
    80001218:	036a0063          	beq	s4,s6,80001238 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000121c:	0149d933          	srl	s2,s3,s4
    80001220:	1ff97913          	andi	s2,s2,511
    80001224:	090e                	slli	s2,s2,0x3
    80001226:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001228:	00093483          	ld	s1,0(s2)
    8000122c:	0014f793          	andi	a5,s1,1
    80001230:	dfd5                	beqz	a5,800011ec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001232:	80a9                	srli	s1,s1,0xa
    80001234:	04b2                	slli	s1,s1,0xc
    80001236:	b7c5                	j	80001216 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001238:	00c9d513          	srli	a0,s3,0xc
    8000123c:	1ff57513          	andi	a0,a0,511
    80001240:	050e                	slli	a0,a0,0x3
    80001242:	9526                	add	a0,a0,s1
}
    80001244:	70e2                	ld	ra,56(sp)
    80001246:	7442                	ld	s0,48(sp)
    80001248:	74a2                	ld	s1,40(sp)
    8000124a:	7902                	ld	s2,32(sp)
    8000124c:	69e2                	ld	s3,24(sp)
    8000124e:	6a42                	ld	s4,16(sp)
    80001250:	6aa2                	ld	s5,8(sp)
    80001252:	6b02                	ld	s6,0(sp)
    80001254:	6121                	addi	sp,sp,64
    80001256:	8082                	ret
        return 0;
    80001258:	4501                	li	a0,0
    8000125a:	b7ed                	j	80001244 <walk+0x8e>

000000008000125c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000125c:	57fd                	li	a5,-1
    8000125e:	83e9                	srli	a5,a5,0x1a
    80001260:	00b7f463          	bgeu	a5,a1,80001268 <walkaddr+0xc>
    return 0;
    80001264:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001266:	8082                	ret
{
    80001268:	1141                	addi	sp,sp,-16
    8000126a:	e406                	sd	ra,8(sp)
    8000126c:	e022                	sd	s0,0(sp)
    8000126e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001270:	4601                	li	a2,0
    80001272:	00000097          	auipc	ra,0x0
    80001276:	f44080e7          	jalr	-188(ra) # 800011b6 <walk>
  if(pte == 0)
    8000127a:	c105                	beqz	a0,8000129a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000127c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000127e:	0117f693          	andi	a3,a5,17
    80001282:	4745                	li	a4,17
    return 0;
    80001284:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001286:	00e68663          	beq	a3,a4,80001292 <walkaddr+0x36>
}
    8000128a:	60a2                	ld	ra,8(sp)
    8000128c:	6402                	ld	s0,0(sp)
    8000128e:	0141                	addi	sp,sp,16
    80001290:	8082                	ret
  pa = PTE2PA(*pte);
    80001292:	83a9                	srli	a5,a5,0xa
    80001294:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001298:	bfcd                	j	8000128a <walkaddr+0x2e>
    return 0;
    8000129a:	4501                	li	a0,0
    8000129c:	b7fd                	j	8000128a <walkaddr+0x2e>

000000008000129e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000129e:	715d                	addi	sp,sp,-80
    800012a0:	e486                	sd	ra,72(sp)
    800012a2:	e0a2                	sd	s0,64(sp)
    800012a4:	fc26                	sd	s1,56(sp)
    800012a6:	f84a                	sd	s2,48(sp)
    800012a8:	f44e                	sd	s3,40(sp)
    800012aa:	f052                	sd	s4,32(sp)
    800012ac:	ec56                	sd	s5,24(sp)
    800012ae:	e85a                	sd	s6,16(sp)
    800012b0:	e45e                	sd	s7,8(sp)
    800012b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800012b4:	c639                	beqz	a2,80001302 <mappages+0x64>
    800012b6:	8aaa                	mv	s5,a0
    800012b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800012ba:	777d                	lui	a4,0xfffff
    800012bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800012c0:	fff58993          	addi	s3,a1,-1
    800012c4:	99b2                	add	s3,s3,a2
    800012c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800012ca:	893e                	mv	s2,a5
    800012cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800012d0:	6b85                	lui	s7,0x1
    800012d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800012d6:	4605                	li	a2,1
    800012d8:	85ca                	mv	a1,s2
    800012da:	8556                	mv	a0,s5
    800012dc:	00000097          	auipc	ra,0x0
    800012e0:	eda080e7          	jalr	-294(ra) # 800011b6 <walk>
    800012e4:	cd1d                	beqz	a0,80001322 <mappages+0x84>
    if(*pte & PTE_V)
    800012e6:	611c                	ld	a5,0(a0)
    800012e8:	8b85                	andi	a5,a5,1
    800012ea:	e785                	bnez	a5,80001312 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800012ec:	80b1                	srli	s1,s1,0xc
    800012ee:	04aa                	slli	s1,s1,0xa
    800012f0:	0164e4b3          	or	s1,s1,s6
    800012f4:	0014e493          	ori	s1,s1,1
    800012f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800012fa:	05390063          	beq	s2,s3,8000133a <mappages+0x9c>
    a += PGSIZE;
    800012fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001300:	bfc9                	j	800012d2 <mappages+0x34>
    panic("mappages: size");
    80001302:	00007517          	auipc	a0,0x7
    80001306:	e3650513          	addi	a0,a0,-458 # 80008138 <digits+0xe8>
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	232080e7          	jalr	562(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001312:	00007517          	auipc	a0,0x7
    80001316:	e3650513          	addi	a0,a0,-458 # 80008148 <digits+0xf8>
    8000131a:	fffff097          	auipc	ra,0xfffff
    8000131e:	222080e7          	jalr	546(ra) # 8000053c <panic>
      return -1;
    80001322:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001324:	60a6                	ld	ra,72(sp)
    80001326:	6406                	ld	s0,64(sp)
    80001328:	74e2                	ld	s1,56(sp)
    8000132a:	7942                	ld	s2,48(sp)
    8000132c:	79a2                	ld	s3,40(sp)
    8000132e:	7a02                	ld	s4,32(sp)
    80001330:	6ae2                	ld	s5,24(sp)
    80001332:	6b42                	ld	s6,16(sp)
    80001334:	6ba2                	ld	s7,8(sp)
    80001336:	6161                	addi	sp,sp,80
    80001338:	8082                	ret
  return 0;
    8000133a:	4501                	li	a0,0
    8000133c:	b7e5                	j	80001324 <mappages+0x86>

000000008000133e <kvmmap>:
{
    8000133e:	1141                	addi	sp,sp,-16
    80001340:	e406                	sd	ra,8(sp)
    80001342:	e022                	sd	s0,0(sp)
    80001344:	0800                	addi	s0,sp,16
    80001346:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001348:	86b2                	mv	a3,a2
    8000134a:	863e                	mv	a2,a5
    8000134c:	00000097          	auipc	ra,0x0
    80001350:	f52080e7          	jalr	-174(ra) # 8000129e <mappages>
    80001354:	e509                	bnez	a0,8000135e <kvmmap+0x20>
}
    80001356:	60a2                	ld	ra,8(sp)
    80001358:	6402                	ld	s0,0(sp)
    8000135a:	0141                	addi	sp,sp,16
    8000135c:	8082                	ret
    panic("kvmmap");
    8000135e:	00007517          	auipc	a0,0x7
    80001362:	dfa50513          	addi	a0,a0,-518 # 80008158 <digits+0x108>
    80001366:	fffff097          	auipc	ra,0xfffff
    8000136a:	1d6080e7          	jalr	470(ra) # 8000053c <panic>

000000008000136e <kvmmake>:
{
    8000136e:	1101                	addi	sp,sp,-32
    80001370:	ec06                	sd	ra,24(sp)
    80001372:	e822                	sd	s0,16(sp)
    80001374:	e426                	sd	s1,8(sp)
    80001376:	e04a                	sd	s2,0(sp)
    80001378:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000137a:	00000097          	auipc	ra,0x0
    8000137e:	8e4080e7          	jalr	-1820(ra) # 80000c5e <kalloc>
    80001382:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001384:	6605                	lui	a2,0x1
    80001386:	4581                	li	a1,0
    80001388:	00000097          	auipc	ra,0x0
    8000138c:	b4c080e7          	jalr	-1204(ra) # 80000ed4 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001390:	4719                	li	a4,6
    80001392:	6685                	lui	a3,0x1
    80001394:	10000637          	lui	a2,0x10000
    80001398:	100005b7          	lui	a1,0x10000
    8000139c:	8526                	mv	a0,s1
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	fa0080e7          	jalr	-96(ra) # 8000133e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800013a6:	4719                	li	a4,6
    800013a8:	6685                	lui	a3,0x1
    800013aa:	10001637          	lui	a2,0x10001
    800013ae:	100015b7          	lui	a1,0x10001
    800013b2:	8526                	mv	a0,s1
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	f8a080e7          	jalr	-118(ra) # 8000133e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800013bc:	4719                	li	a4,6
    800013be:	004006b7          	lui	a3,0x400
    800013c2:	0c000637          	lui	a2,0xc000
    800013c6:	0c0005b7          	lui	a1,0xc000
    800013ca:	8526                	mv	a0,s1
    800013cc:	00000097          	auipc	ra,0x0
    800013d0:	f72080e7          	jalr	-142(ra) # 8000133e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800013d4:	00007917          	auipc	s2,0x7
    800013d8:	c2c90913          	addi	s2,s2,-980 # 80008000 <etext>
    800013dc:	4729                	li	a4,10
    800013de:	80007697          	auipc	a3,0x80007
    800013e2:	c2268693          	addi	a3,a3,-990 # 8000 <_entry-0x7fff8000>
    800013e6:	4605                	li	a2,1
    800013e8:	067e                	slli	a2,a2,0x1f
    800013ea:	85b2                	mv	a1,a2
    800013ec:	8526                	mv	a0,s1
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	f50080e7          	jalr	-176(ra) # 8000133e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800013f6:	4719                	li	a4,6
    800013f8:	46c5                	li	a3,17
    800013fa:	06ee                	slli	a3,a3,0x1b
    800013fc:	412686b3          	sub	a3,a3,s2
    80001400:	864a                	mv	a2,s2
    80001402:	85ca                	mv	a1,s2
    80001404:	8526                	mv	a0,s1
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	f38080e7          	jalr	-200(ra) # 8000133e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000140e:	4729                	li	a4,10
    80001410:	6685                	lui	a3,0x1
    80001412:	00006617          	auipc	a2,0x6
    80001416:	bee60613          	addi	a2,a2,-1042 # 80007000 <_trampoline>
    8000141a:	040005b7          	lui	a1,0x4000
    8000141e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001420:	05b2                	slli	a1,a1,0xc
    80001422:	8526                	mv	a0,s1
    80001424:	00000097          	auipc	ra,0x0
    80001428:	f1a080e7          	jalr	-230(ra) # 8000133e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000142c:	8526                	mv	a0,s1
    8000142e:	00000097          	auipc	ra,0x0
    80001432:	7a4080e7          	jalr	1956(ra) # 80001bd2 <proc_mapstacks>
}
    80001436:	8526                	mv	a0,s1
    80001438:	60e2                	ld	ra,24(sp)
    8000143a:	6442                	ld	s0,16(sp)
    8000143c:	64a2                	ld	s1,8(sp)
    8000143e:	6902                	ld	s2,0(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret

0000000080001444 <kvminit>:
{
    80001444:	1141                	addi	sp,sp,-16
    80001446:	e406                	sd	ra,8(sp)
    80001448:	e022                	sd	s0,0(sp)
    8000144a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000144c:	00000097          	auipc	ra,0x0
    80001450:	f22080e7          	jalr	-222(ra) # 8000136e <kvmmake>
    80001454:	00007797          	auipc	a5,0x7
    80001458:	68a7b623          	sd	a0,1676(a5) # 80008ae0 <kernel_pagetable>
}
    8000145c:	60a2                	ld	ra,8(sp)
    8000145e:	6402                	ld	s0,0(sp)
    80001460:	0141                	addi	sp,sp,16
    80001462:	8082                	ret

0000000080001464 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001464:	715d                	addi	sp,sp,-80
    80001466:	e486                	sd	ra,72(sp)
    80001468:	e0a2                	sd	s0,64(sp)
    8000146a:	fc26                	sd	s1,56(sp)
    8000146c:	f84a                	sd	s2,48(sp)
    8000146e:	f44e                	sd	s3,40(sp)
    80001470:	f052                	sd	s4,32(sp)
    80001472:	ec56                	sd	s5,24(sp)
    80001474:	e85a                	sd	s6,16(sp)
    80001476:	e45e                	sd	s7,8(sp)
    80001478:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000147a:	03459793          	slli	a5,a1,0x34
    8000147e:	e795                	bnez	a5,800014aa <uvmunmap+0x46>
    80001480:	8a2a                	mv	s4,a0
    80001482:	892e                	mv	s2,a1
    80001484:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001486:	0632                	slli	a2,a2,0xc
    80001488:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000148c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000148e:	6b05                	lui	s6,0x1
    80001490:	0735e263          	bltu	a1,s3,800014f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001494:	60a6                	ld	ra,72(sp)
    80001496:	6406                	ld	s0,64(sp)
    80001498:	74e2                	ld	s1,56(sp)
    8000149a:	7942                	ld	s2,48(sp)
    8000149c:	79a2                	ld	s3,40(sp)
    8000149e:	7a02                	ld	s4,32(sp)
    800014a0:	6ae2                	ld	s5,24(sp)
    800014a2:	6b42                	ld	s6,16(sp)
    800014a4:	6ba2                	ld	s7,8(sp)
    800014a6:	6161                	addi	sp,sp,80
    800014a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800014aa:	00007517          	auipc	a0,0x7
    800014ae:	cb650513          	addi	a0,a0,-842 # 80008160 <digits+0x110>
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	08a080e7          	jalr	138(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800014ba:	00007517          	auipc	a0,0x7
    800014be:	cbe50513          	addi	a0,a0,-834 # 80008178 <digits+0x128>
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	07a080e7          	jalr	122(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800014ca:	00007517          	auipc	a0,0x7
    800014ce:	cbe50513          	addi	a0,a0,-834 # 80008188 <digits+0x138>
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	06a080e7          	jalr	106(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800014da:	00007517          	auipc	a0,0x7
    800014de:	cc650513          	addi	a0,a0,-826 # 800081a0 <digits+0x150>
    800014e2:	fffff097          	auipc	ra,0xfffff
    800014e6:	05a080e7          	jalr	90(ra) # 8000053c <panic>
    *pte = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800014ee:	995a                	add	s2,s2,s6
    800014f0:	fb3972e3          	bgeu	s2,s3,80001494 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800014f4:	4601                	li	a2,0
    800014f6:	85ca                	mv	a1,s2
    800014f8:	8552                	mv	a0,s4
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	cbc080e7          	jalr	-836(ra) # 800011b6 <walk>
    80001502:	84aa                	mv	s1,a0
    80001504:	d95d                	beqz	a0,800014ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001506:	6108                	ld	a0,0(a0)
    80001508:	00157793          	andi	a5,a0,1
    8000150c:	dfdd                	beqz	a5,800014ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000150e:	3ff57793          	andi	a5,a0,1023
    80001512:	fd7784e3          	beq	a5,s7,800014da <uvmunmap+0x76>
    if(do_free){
    80001516:	fc0a8ae3          	beqz	s5,800014ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000151a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000151c:	0532                	slli	a0,a0,0xc
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	554080e7          	jalr	1364(ra) # 80000a72 <kfree>
    80001526:	b7d1                	j	800014ea <uvmunmap+0x86>

0000000080001528 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001528:	1101                	addi	sp,sp,-32
    8000152a:	ec06                	sd	ra,24(sp)
    8000152c:	e822                	sd	s0,16(sp)
    8000152e:	e426                	sd	s1,8(sp)
    80001530:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001532:	fffff097          	auipc	ra,0xfffff
    80001536:	72c080e7          	jalr	1836(ra) # 80000c5e <kalloc>
    8000153a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000153c:	c519                	beqz	a0,8000154a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000153e:	6605                	lui	a2,0x1
    80001540:	4581                	li	a1,0
    80001542:	00000097          	auipc	ra,0x0
    80001546:	992080e7          	jalr	-1646(ra) # 80000ed4 <memset>
  return pagetable;
}
    8000154a:	8526                	mv	a0,s1
    8000154c:	60e2                	ld	ra,24(sp)
    8000154e:	6442                	ld	s0,16(sp)
    80001550:	64a2                	ld	s1,8(sp)
    80001552:	6105                	addi	sp,sp,32
    80001554:	8082                	ret

0000000080001556 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001556:	7179                	addi	sp,sp,-48
    80001558:	f406                	sd	ra,40(sp)
    8000155a:	f022                	sd	s0,32(sp)
    8000155c:	ec26                	sd	s1,24(sp)
    8000155e:	e84a                	sd	s2,16(sp)
    80001560:	e44e                	sd	s3,8(sp)
    80001562:	e052                	sd	s4,0(sp)
    80001564:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001566:	6785                	lui	a5,0x1
    80001568:	04f67863          	bgeu	a2,a5,800015b8 <uvmfirst+0x62>
    8000156c:	8a2a                	mv	s4,a0
    8000156e:	89ae                	mv	s3,a1
    80001570:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001572:	fffff097          	auipc	ra,0xfffff
    80001576:	6ec080e7          	jalr	1772(ra) # 80000c5e <kalloc>
    8000157a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000157c:	6605                	lui	a2,0x1
    8000157e:	4581                	li	a1,0
    80001580:	00000097          	auipc	ra,0x0
    80001584:	954080e7          	jalr	-1708(ra) # 80000ed4 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001588:	4779                	li	a4,30
    8000158a:	86ca                	mv	a3,s2
    8000158c:	6605                	lui	a2,0x1
    8000158e:	4581                	li	a1,0
    80001590:	8552                	mv	a0,s4
    80001592:	00000097          	auipc	ra,0x0
    80001596:	d0c080e7          	jalr	-756(ra) # 8000129e <mappages>
  memmove(mem, src, sz);
    8000159a:	8626                	mv	a2,s1
    8000159c:	85ce                	mv	a1,s3
    8000159e:	854a                	mv	a0,s2
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	990080e7          	jalr	-1648(ra) # 80000f30 <memmove>
}
    800015a8:	70a2                	ld	ra,40(sp)
    800015aa:	7402                	ld	s0,32(sp)
    800015ac:	64e2                	ld	s1,24(sp)
    800015ae:	6942                	ld	s2,16(sp)
    800015b0:	69a2                	ld	s3,8(sp)
    800015b2:	6a02                	ld	s4,0(sp)
    800015b4:	6145                	addi	sp,sp,48
    800015b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800015b8:	00007517          	auipc	a0,0x7
    800015bc:	c0050513          	addi	a0,a0,-1024 # 800081b8 <digits+0x168>
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	f7c080e7          	jalr	-132(ra) # 8000053c <panic>

00000000800015c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800015c8:	1101                	addi	sp,sp,-32
    800015ca:	ec06                	sd	ra,24(sp)
    800015cc:	e822                	sd	s0,16(sp)
    800015ce:	e426                	sd	s1,8(sp)
    800015d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800015d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800015d4:	00b67d63          	bgeu	a2,a1,800015ee <uvmdealloc+0x26>
    800015d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800015da:	6785                	lui	a5,0x1
    800015dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800015de:	00f60733          	add	a4,a2,a5
    800015e2:	76fd                	lui	a3,0xfffff
    800015e4:	8f75                	and	a4,a4,a3
    800015e6:	97ae                	add	a5,a5,a1
    800015e8:	8ff5                	and	a5,a5,a3
    800015ea:	00f76863          	bltu	a4,a5,800015fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800015ee:	8526                	mv	a0,s1
    800015f0:	60e2                	ld	ra,24(sp)
    800015f2:	6442                	ld	s0,16(sp)
    800015f4:	64a2                	ld	s1,8(sp)
    800015f6:	6105                	addi	sp,sp,32
    800015f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800015fa:	8f99                	sub	a5,a5,a4
    800015fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800015fe:	4685                	li	a3,1
    80001600:	0007861b          	sext.w	a2,a5
    80001604:	85ba                	mv	a1,a4
    80001606:	00000097          	auipc	ra,0x0
    8000160a:	e5e080e7          	jalr	-418(ra) # 80001464 <uvmunmap>
    8000160e:	b7c5                	j	800015ee <uvmdealloc+0x26>

0000000080001610 <uvmalloc>:
  if(newsz < oldsz)
    80001610:	0ab66563          	bltu	a2,a1,800016ba <uvmalloc+0xaa>
{
    80001614:	7139                	addi	sp,sp,-64
    80001616:	fc06                	sd	ra,56(sp)
    80001618:	f822                	sd	s0,48(sp)
    8000161a:	f426                	sd	s1,40(sp)
    8000161c:	f04a                	sd	s2,32(sp)
    8000161e:	ec4e                	sd	s3,24(sp)
    80001620:	e852                	sd	s4,16(sp)
    80001622:	e456                	sd	s5,8(sp)
    80001624:	e05a                	sd	s6,0(sp)
    80001626:	0080                	addi	s0,sp,64
    80001628:	8aaa                	mv	s5,a0
    8000162a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000162c:	6785                	lui	a5,0x1
    8000162e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001630:	95be                	add	a1,a1,a5
    80001632:	77fd                	lui	a5,0xfffff
    80001634:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001638:	08c9f363          	bgeu	s3,a2,800016be <uvmalloc+0xae>
    8000163c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000163e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001642:	fffff097          	auipc	ra,0xfffff
    80001646:	61c080e7          	jalr	1564(ra) # 80000c5e <kalloc>
    8000164a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000164c:	c51d                	beqz	a0,8000167a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000164e:	6605                	lui	a2,0x1
    80001650:	4581                	li	a1,0
    80001652:	00000097          	auipc	ra,0x0
    80001656:	882080e7          	jalr	-1918(ra) # 80000ed4 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000165a:	875a                	mv	a4,s6
    8000165c:	86a6                	mv	a3,s1
    8000165e:	6605                	lui	a2,0x1
    80001660:	85ca                	mv	a1,s2
    80001662:	8556                	mv	a0,s5
    80001664:	00000097          	auipc	ra,0x0
    80001668:	c3a080e7          	jalr	-966(ra) # 8000129e <mappages>
    8000166c:	e90d                	bnez	a0,8000169e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000166e:	6785                	lui	a5,0x1
    80001670:	993e                	add	s2,s2,a5
    80001672:	fd4968e3          	bltu	s2,s4,80001642 <uvmalloc+0x32>
  return newsz;
    80001676:	8552                	mv	a0,s4
    80001678:	a809                	j	8000168a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000167a:	864e                	mv	a2,s3
    8000167c:	85ca                	mv	a1,s2
    8000167e:	8556                	mv	a0,s5
    80001680:	00000097          	auipc	ra,0x0
    80001684:	f48080e7          	jalr	-184(ra) # 800015c8 <uvmdealloc>
      return 0;
    80001688:	4501                	li	a0,0
}
    8000168a:	70e2                	ld	ra,56(sp)
    8000168c:	7442                	ld	s0,48(sp)
    8000168e:	74a2                	ld	s1,40(sp)
    80001690:	7902                	ld	s2,32(sp)
    80001692:	69e2                	ld	s3,24(sp)
    80001694:	6a42                	ld	s4,16(sp)
    80001696:	6aa2                	ld	s5,8(sp)
    80001698:	6b02                	ld	s6,0(sp)
    8000169a:	6121                	addi	sp,sp,64
    8000169c:	8082                	ret
      kfree(mem);
    8000169e:	8526                	mv	a0,s1
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	3d2080e7          	jalr	978(ra) # 80000a72 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800016a8:	864e                	mv	a2,s3
    800016aa:	85ca                	mv	a1,s2
    800016ac:	8556                	mv	a0,s5
    800016ae:	00000097          	auipc	ra,0x0
    800016b2:	f1a080e7          	jalr	-230(ra) # 800015c8 <uvmdealloc>
      return 0;
    800016b6:	4501                	li	a0,0
    800016b8:	bfc9                	j	8000168a <uvmalloc+0x7a>
    return oldsz;
    800016ba:	852e                	mv	a0,a1
}
    800016bc:	8082                	ret
  return newsz;
    800016be:	8532                	mv	a0,a2
    800016c0:	b7e9                	j	8000168a <uvmalloc+0x7a>

00000000800016c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800016c2:	7179                	addi	sp,sp,-48
    800016c4:	f406                	sd	ra,40(sp)
    800016c6:	f022                	sd	s0,32(sp)
    800016c8:	ec26                	sd	s1,24(sp)
    800016ca:	e84a                	sd	s2,16(sp)
    800016cc:	e44e                	sd	s3,8(sp)
    800016ce:	e052                	sd	s4,0(sp)
    800016d0:	1800                	addi	s0,sp,48
    800016d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800016d4:	84aa                	mv	s1,a0
    800016d6:	6905                	lui	s2,0x1
    800016d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016da:	4985                	li	s3,1
    800016dc:	a829                	j	800016f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800016de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800016e0:	00c79513          	slli	a0,a5,0xc
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	fde080e7          	jalr	-34(ra) # 800016c2 <freewalk>
      pagetable[i] = 0;
    800016ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800016f0:	04a1                	addi	s1,s1,8
    800016f2:	03248163          	beq	s1,s2,80001714 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800016f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800016f8:	00f7f713          	andi	a4,a5,15
    800016fc:	ff3701e3          	beq	a4,s3,800016de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001700:	8b85                	andi	a5,a5,1
    80001702:	d7fd                	beqz	a5,800016f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001704:	00007517          	auipc	a0,0x7
    80001708:	ad450513          	addi	a0,a0,-1324 # 800081d8 <digits+0x188>
    8000170c:	fffff097          	auipc	ra,0xfffff
    80001710:	e30080e7          	jalr	-464(ra) # 8000053c <panic>
    }
  }
  kfree((void*)pagetable);
    80001714:	8552                	mv	a0,s4
    80001716:	fffff097          	auipc	ra,0xfffff
    8000171a:	35c080e7          	jalr	860(ra) # 80000a72 <kfree>
}
    8000171e:	70a2                	ld	ra,40(sp)
    80001720:	7402                	ld	s0,32(sp)
    80001722:	64e2                	ld	s1,24(sp)
    80001724:	6942                	ld	s2,16(sp)
    80001726:	69a2                	ld	s3,8(sp)
    80001728:	6a02                	ld	s4,0(sp)
    8000172a:	6145                	addi	sp,sp,48
    8000172c:	8082                	ret

000000008000172e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000172e:	1101                	addi	sp,sp,-32
    80001730:	ec06                	sd	ra,24(sp)
    80001732:	e822                	sd	s0,16(sp)
    80001734:	e426                	sd	s1,8(sp)
    80001736:	1000                	addi	s0,sp,32
    80001738:	84aa                	mv	s1,a0
  if(sz > 0)
    8000173a:	e999                	bnez	a1,80001750 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000173c:	8526                	mv	a0,s1
    8000173e:	00000097          	auipc	ra,0x0
    80001742:	f84080e7          	jalr	-124(ra) # 800016c2 <freewalk>
}
    80001746:	60e2                	ld	ra,24(sp)
    80001748:	6442                	ld	s0,16(sp)
    8000174a:	64a2                	ld	s1,8(sp)
    8000174c:	6105                	addi	sp,sp,32
    8000174e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001750:	6785                	lui	a5,0x1
    80001752:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001754:	95be                	add	a1,a1,a5
    80001756:	4685                	li	a3,1
    80001758:	00c5d613          	srli	a2,a1,0xc
    8000175c:	4581                	li	a1,0
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	d06080e7          	jalr	-762(ra) # 80001464 <uvmunmap>
    80001766:	bfd9                	j	8000173c <uvmfree+0xe>

0000000080001768 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001768:	c679                	beqz	a2,80001836 <uvmcopy+0xce>
{
    8000176a:	715d                	addi	sp,sp,-80
    8000176c:	e486                	sd	ra,72(sp)
    8000176e:	e0a2                	sd	s0,64(sp)
    80001770:	fc26                	sd	s1,56(sp)
    80001772:	f84a                	sd	s2,48(sp)
    80001774:	f44e                	sd	s3,40(sp)
    80001776:	f052                	sd	s4,32(sp)
    80001778:	ec56                	sd	s5,24(sp)
    8000177a:	e85a                	sd	s6,16(sp)
    8000177c:	e45e                	sd	s7,8(sp)
    8000177e:	0880                	addi	s0,sp,80
    80001780:	8b2a                	mv	s6,a0
    80001782:	8aae                	mv	s5,a1
    80001784:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001786:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001788:	4601                	li	a2,0
    8000178a:	85ce                	mv	a1,s3
    8000178c:	855a                	mv	a0,s6
    8000178e:	00000097          	auipc	ra,0x0
    80001792:	a28080e7          	jalr	-1496(ra) # 800011b6 <walk>
    80001796:	c531                	beqz	a0,800017e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001798:	6118                	ld	a4,0(a0)
    8000179a:	00177793          	andi	a5,a4,1
    8000179e:	cbb1                	beqz	a5,800017f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017a0:	00a75593          	srli	a1,a4,0xa
    800017a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800017ac:	fffff097          	auipc	ra,0xfffff
    800017b0:	4b2080e7          	jalr	1202(ra) # 80000c5e <kalloc>
    800017b4:	892a                	mv	s2,a0
    800017b6:	c939                	beqz	a0,8000180c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800017b8:	6605                	lui	a2,0x1
    800017ba:	85de                	mv	a1,s7
    800017bc:	fffff097          	auipc	ra,0xfffff
    800017c0:	774080e7          	jalr	1908(ra) # 80000f30 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800017c4:	8726                	mv	a4,s1
    800017c6:	86ca                	mv	a3,s2
    800017c8:	6605                	lui	a2,0x1
    800017ca:	85ce                	mv	a1,s3
    800017cc:	8556                	mv	a0,s5
    800017ce:	00000097          	auipc	ra,0x0
    800017d2:	ad0080e7          	jalr	-1328(ra) # 8000129e <mappages>
    800017d6:	e515                	bnez	a0,80001802 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800017d8:	6785                	lui	a5,0x1
    800017da:	99be                	add	s3,s3,a5
    800017dc:	fb49e6e3          	bltu	s3,s4,80001788 <uvmcopy+0x20>
    800017e0:	a081                	j	80001820 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800017e2:	00007517          	auipc	a0,0x7
    800017e6:	a0650513          	addi	a0,a0,-1530 # 800081e8 <digits+0x198>
    800017ea:	fffff097          	auipc	ra,0xfffff
    800017ee:	d52080e7          	jalr	-686(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800017f2:	00007517          	auipc	a0,0x7
    800017f6:	a1650513          	addi	a0,a0,-1514 # 80008208 <digits+0x1b8>
    800017fa:	fffff097          	auipc	ra,0xfffff
    800017fe:	d42080e7          	jalr	-702(ra) # 8000053c <panic>
      kfree(mem);
    80001802:	854a                	mv	a0,s2
    80001804:	fffff097          	auipc	ra,0xfffff
    80001808:	26e080e7          	jalr	622(ra) # 80000a72 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000180c:	4685                	li	a3,1
    8000180e:	00c9d613          	srli	a2,s3,0xc
    80001812:	4581                	li	a1,0
    80001814:	8556                	mv	a0,s5
    80001816:	00000097          	auipc	ra,0x0
    8000181a:	c4e080e7          	jalr	-946(ra) # 80001464 <uvmunmap>
  return -1;
    8000181e:	557d                	li	a0,-1
}
    80001820:	60a6                	ld	ra,72(sp)
    80001822:	6406                	ld	s0,64(sp)
    80001824:	74e2                	ld	s1,56(sp)
    80001826:	7942                	ld	s2,48(sp)
    80001828:	79a2                	ld	s3,40(sp)
    8000182a:	7a02                	ld	s4,32(sp)
    8000182c:	6ae2                	ld	s5,24(sp)
    8000182e:	6b42                	ld	s6,16(sp)
    80001830:	6ba2                	ld	s7,8(sp)
    80001832:	6161                	addi	sp,sp,80
    80001834:	8082                	ret
  return 0;
    80001836:	4501                	li	a0,0
}
    80001838:	8082                	ret

000000008000183a <uvmshare>:
int uvmshare(pagetable_t old, pagetable_t new, uint64 sz) {
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    8000183a:	ca55                	beqz	a2,800018ee <uvmshare+0xb4>
int uvmshare(pagetable_t old, pagetable_t new, uint64 sz) {
    8000183c:	7139                	addi	sp,sp,-64
    8000183e:	fc06                	sd	ra,56(sp)
    80001840:	f822                	sd	s0,48(sp)
    80001842:	f426                	sd	s1,40(sp)
    80001844:	f04a                	sd	s2,32(sp)
    80001846:	ec4e                	sd	s3,24(sp)
    80001848:	e852                	sd	s4,16(sp)
    8000184a:	e456                	sd	s5,8(sp)
    8000184c:	e05a                	sd	s6,0(sp)
    8000184e:	0080                	addi	s0,sp,64
    80001850:	8b2a                	mv	s6,a0
    80001852:	8aae                	mv	s5,a1
    80001854:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001856:	4901                	li	s2,0
    if((pte = walk(old, i, 0)) == 0)
    80001858:	4601                	li	a2,0
    8000185a:	85ca                	mv	a1,s2
    8000185c:	855a                	mv	a0,s6
    8000185e:	00000097          	auipc	ra,0x0
    80001862:	958080e7          	jalr	-1704(ra) # 800011b6 <walk>
    80001866:	c121                	beqz	a0,800018a6 <uvmshare+0x6c>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001868:	6118                	ld	a4,0(a0)
    8000186a:	00177793          	andi	a5,a4,1
    8000186e:	c7a1                	beqz	a5,800018b6 <uvmshare+0x7c>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001870:	00a75993          	srli	s3,a4,0xa
    80001874:	09b2                	slli	s3,s3,0xc
    *pte &= ~PTE_W; // Set flag
    80001876:	ffb77493          	andi	s1,a4,-5
    8000187a:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);
    increment_refcount(pa); // increment reference
    8000187c:	854e                	mv	a0,s3
    8000187e:	fffff097          	auipc	ra,0xfffff
    80001882:	178080e7          	jalr	376(ra) # 800009f6 <increment_refcount>

    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    80001886:	3fb4f713          	andi	a4,s1,1019
    8000188a:	86ce                	mv	a3,s3
    8000188c:	6605                	lui	a2,0x1
    8000188e:	85ca                	mv	a1,s2
    80001890:	8556                	mv	a0,s5
    80001892:	00000097          	auipc	ra,0x0
    80001896:	a0c080e7          	jalr	-1524(ra) # 8000129e <mappages>
    8000189a:	e515                	bnez	a0,800018c6 <uvmshare+0x8c>
  for(i = 0; i < sz; i += PGSIZE){
    8000189c:	6785                	lui	a5,0x1
    8000189e:	993e                	add	s2,s2,a5
    800018a0:	fb496ce3          	bltu	s2,s4,80001858 <uvmshare+0x1e>
    800018a4:	a81d                	j	800018da <uvmshare+0xa0>
      panic("uvmcopy: pte should exist");
    800018a6:	00007517          	auipc	a0,0x7
    800018aa:	94250513          	addi	a0,a0,-1726 # 800081e8 <digits+0x198>
    800018ae:	fffff097          	auipc	ra,0xfffff
    800018b2:	c8e080e7          	jalr	-882(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	95250513          	addi	a0,a0,-1710 # 80008208 <digits+0x1b8>
    800018be:	fffff097          	auipc	ra,0xfffff
    800018c2:	c7e080e7          	jalr	-898(ra) # 8000053c <panic>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800018c6:	4685                	li	a3,1
    800018c8:	00c95613          	srli	a2,s2,0xc
    800018cc:	4581                	li	a1,0
    800018ce:	8556                	mv	a0,s5
    800018d0:	00000097          	auipc	ra,0x0
    800018d4:	b94080e7          	jalr	-1132(ra) # 80001464 <uvmunmap>
  return -1;
    800018d8:	557d                	li	a0,-1
}
    800018da:	70e2                	ld	ra,56(sp)
    800018dc:	7442                	ld	s0,48(sp)
    800018de:	74a2                	ld	s1,40(sp)
    800018e0:	7902                	ld	s2,32(sp)
    800018e2:	69e2                	ld	s3,24(sp)
    800018e4:	6a42                	ld	s4,16(sp)
    800018e6:	6aa2                	ld	s5,8(sp)
    800018e8:	6b02                	ld	s6,0(sp)
    800018ea:	6121                	addi	sp,sp,64
    800018ec:	8082                	ret
  return 0;
    800018ee:	4501                	li	a0,0
}
    800018f0:	8082                	ret

00000000800018f2 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800018f2:	1141                	addi	sp,sp,-16
    800018f4:	e406                	sd	ra,8(sp)
    800018f6:	e022                	sd	s0,0(sp)
    800018f8:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800018fa:	4601                	li	a2,0
    800018fc:	00000097          	auipc	ra,0x0
    80001900:	8ba080e7          	jalr	-1862(ra) # 800011b6 <walk>
  if(pte == 0)
    80001904:	c901                	beqz	a0,80001914 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001906:	611c                	ld	a5,0(a0)
    80001908:	9bbd                	andi	a5,a5,-17
    8000190a:	e11c                	sd	a5,0(a0)
}
    8000190c:	60a2                	ld	ra,8(sp)
    8000190e:	6402                	ld	s0,0(sp)
    80001910:	0141                	addi	sp,sp,16
    80001912:	8082                	ret
    panic("uvmclear");
    80001914:	00007517          	auipc	a0,0x7
    80001918:	91450513          	addi	a0,a0,-1772 # 80008228 <digits+0x1d8>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	c20080e7          	jalr	-992(ra) # 8000053c <panic>

0000000080001924 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001924:	c2c1                	beqz	a3,800019a4 <copyout+0x80>
{
    80001926:	711d                	addi	sp,sp,-96
    80001928:	ec86                	sd	ra,88(sp)
    8000192a:	e8a2                	sd	s0,80(sp)
    8000192c:	e4a6                	sd	s1,72(sp)
    8000192e:	e0ca                	sd	s2,64(sp)
    80001930:	fc4e                	sd	s3,56(sp)
    80001932:	f852                	sd	s4,48(sp)
    80001934:	f456                	sd	s5,40(sp)
    80001936:	f05a                	sd	s6,32(sp)
    80001938:	ec5e                	sd	s7,24(sp)
    8000193a:	e862                	sd	s8,16(sp)
    8000193c:	e466                	sd	s9,8(sp)
    8000193e:	1080                	addi	s0,sp,96
    80001940:	8baa                	mv	s7,a0
    80001942:	892e                	mv	s2,a1
    80001944:	8ab2                	mv	s5,a2
    80001946:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001948:	7cfd                	lui	s9,0xfffff
    pte_t* pte = walk(pagetable, va0, 0);
    pa0 = PTE2PA(*pte);
    if(va0 >= MAXVA)
    8000194a:	5c7d                	li	s8,-1
    8000194c:	01ac5c13          	srli	s8,s8,0x1a
      return -1;
    


    n = PGSIZE - (dstva - va0);
    80001950:	6b05                	lui	s6,0x1
    80001952:	a015                	j	80001976 <copyout+0x52>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001954:	41390533          	sub	a0,s2,s3
    80001958:	0004861b          	sext.w	a2,s1
    8000195c:	85d6                	mv	a1,s5
    8000195e:	953e                	add	a0,a0,a5
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	5d0080e7          	jalr	1488(ra) # 80000f30 <memmove>

    len -= n;
    80001968:	409a0a33          	sub	s4,s4,s1
    src += n;
    8000196c:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    8000196e:	01698933          	add	s2,s3,s6
  while(len > 0){
    80001972:	020a0763          	beqz	s4,800019a0 <copyout+0x7c>
    va0 = PGROUNDDOWN(dstva);
    80001976:	019979b3          	and	s3,s2,s9
    pte_t* pte = walk(pagetable, va0, 0);
    8000197a:	4601                	li	a2,0
    8000197c:	85ce                	mv	a1,s3
    8000197e:	855e                	mv	a0,s7
    80001980:	00000097          	auipc	ra,0x0
    80001984:	836080e7          	jalr	-1994(ra) # 800011b6 <walk>
    pa0 = PTE2PA(*pte);
    80001988:	611c                	ld	a5,0(a0)
    8000198a:	83a9                	srli	a5,a5,0xa
    8000198c:	07b2                	slli	a5,a5,0xc
    if(va0 >= MAXVA)
    8000198e:	013c6d63          	bltu	s8,s3,800019a8 <copyout+0x84>
    n = PGSIZE - (dstva - va0);
    80001992:	412984b3          	sub	s1,s3,s2
    80001996:	94da                	add	s1,s1,s6
    80001998:	fa9a7ee3          	bgeu	s4,s1,80001954 <copyout+0x30>
    8000199c:	84d2                	mv	s1,s4
    8000199e:	bf5d                	j	80001954 <copyout+0x30>
  }
  return 0;
    800019a0:	4501                	li	a0,0
    800019a2:	a021                	j	800019aa <copyout+0x86>
    800019a4:	4501                	li	a0,0
}
    800019a6:	8082                	ret
      return -1;
    800019a8:	557d                	li	a0,-1
}
    800019aa:	60e6                	ld	ra,88(sp)
    800019ac:	6446                	ld	s0,80(sp)
    800019ae:	64a6                	ld	s1,72(sp)
    800019b0:	6906                	ld	s2,64(sp)
    800019b2:	79e2                	ld	s3,56(sp)
    800019b4:	7a42                	ld	s4,48(sp)
    800019b6:	7aa2                	ld	s5,40(sp)
    800019b8:	7b02                	ld	s6,32(sp)
    800019ba:	6be2                	ld	s7,24(sp)
    800019bc:	6c42                	ld	s8,16(sp)
    800019be:	6ca2                	ld	s9,8(sp)
    800019c0:	6125                	addi	sp,sp,96
    800019c2:	8082                	ret

00000000800019c4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800019c4:	caa5                	beqz	a3,80001a34 <copyin+0x70>
{
    800019c6:	715d                	addi	sp,sp,-80
    800019c8:	e486                	sd	ra,72(sp)
    800019ca:	e0a2                	sd	s0,64(sp)
    800019cc:	fc26                	sd	s1,56(sp)
    800019ce:	f84a                	sd	s2,48(sp)
    800019d0:	f44e                	sd	s3,40(sp)
    800019d2:	f052                	sd	s4,32(sp)
    800019d4:	ec56                	sd	s5,24(sp)
    800019d6:	e85a                	sd	s6,16(sp)
    800019d8:	e45e                	sd	s7,8(sp)
    800019da:	e062                	sd	s8,0(sp)
    800019dc:	0880                	addi	s0,sp,80
    800019de:	8b2a                	mv	s6,a0
    800019e0:	8a2e                	mv	s4,a1
    800019e2:	8c32                	mv	s8,a2
    800019e4:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800019e6:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800019e8:	6a85                	lui	s5,0x1
    800019ea:	a01d                	j	80001a10 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800019ec:	018505b3          	add	a1,a0,s8
    800019f0:	0004861b          	sext.w	a2,s1
    800019f4:	412585b3          	sub	a1,a1,s2
    800019f8:	8552                	mv	a0,s4
    800019fa:	fffff097          	auipc	ra,0xfffff
    800019fe:	536080e7          	jalr	1334(ra) # 80000f30 <memmove>

    len -= n;
    80001a02:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001a06:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001a08:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a0c:	02098263          	beqz	s3,80001a30 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001a10:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a14:	85ca                	mv	a1,s2
    80001a16:	855a                	mv	a0,s6
    80001a18:	00000097          	auipc	ra,0x0
    80001a1c:	844080e7          	jalr	-1980(ra) # 8000125c <walkaddr>
    if(pa0 == 0)
    80001a20:	cd01                	beqz	a0,80001a38 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001a22:	418904b3          	sub	s1,s2,s8
    80001a26:	94d6                	add	s1,s1,s5
    80001a28:	fc99f2e3          	bgeu	s3,s1,800019ec <copyin+0x28>
    80001a2c:	84ce                	mv	s1,s3
    80001a2e:	bf7d                	j	800019ec <copyin+0x28>
  }
  return 0;
    80001a30:	4501                	li	a0,0
    80001a32:	a021                	j	80001a3a <copyin+0x76>
    80001a34:	4501                	li	a0,0
}
    80001a36:	8082                	ret
      return -1;
    80001a38:	557d                	li	a0,-1
}
    80001a3a:	60a6                	ld	ra,72(sp)
    80001a3c:	6406                	ld	s0,64(sp)
    80001a3e:	74e2                	ld	s1,56(sp)
    80001a40:	7942                	ld	s2,48(sp)
    80001a42:	79a2                	ld	s3,40(sp)
    80001a44:	7a02                	ld	s4,32(sp)
    80001a46:	6ae2                	ld	s5,24(sp)
    80001a48:	6b42                	ld	s6,16(sp)
    80001a4a:	6ba2                	ld	s7,8(sp)
    80001a4c:	6c02                	ld	s8,0(sp)
    80001a4e:	6161                	addi	sp,sp,80
    80001a50:	8082                	ret

0000000080001a52 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001a52:	c2dd                	beqz	a3,80001af8 <copyinstr+0xa6>
{
    80001a54:	715d                	addi	sp,sp,-80
    80001a56:	e486                	sd	ra,72(sp)
    80001a58:	e0a2                	sd	s0,64(sp)
    80001a5a:	fc26                	sd	s1,56(sp)
    80001a5c:	f84a                	sd	s2,48(sp)
    80001a5e:	f44e                	sd	s3,40(sp)
    80001a60:	f052                	sd	s4,32(sp)
    80001a62:	ec56                	sd	s5,24(sp)
    80001a64:	e85a                	sd	s6,16(sp)
    80001a66:	e45e                	sd	s7,8(sp)
    80001a68:	0880                	addi	s0,sp,80
    80001a6a:	8a2a                	mv	s4,a0
    80001a6c:	8b2e                	mv	s6,a1
    80001a6e:	8bb2                	mv	s7,a2
    80001a70:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001a72:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a74:	6985                	lui	s3,0x1
    80001a76:	a02d                	j	80001aa0 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a78:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a7c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a7e:	37fd                	addiw	a5,a5,-1
    80001a80:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001a84:	60a6                	ld	ra,72(sp)
    80001a86:	6406                	ld	s0,64(sp)
    80001a88:	74e2                	ld	s1,56(sp)
    80001a8a:	7942                	ld	s2,48(sp)
    80001a8c:	79a2                	ld	s3,40(sp)
    80001a8e:	7a02                	ld	s4,32(sp)
    80001a90:	6ae2                	ld	s5,24(sp)
    80001a92:	6b42                	ld	s6,16(sp)
    80001a94:	6ba2                	ld	s7,8(sp)
    80001a96:	6161                	addi	sp,sp,80
    80001a98:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a9a:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a9e:	c8a9                	beqz	s1,80001af0 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001aa0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001aa4:	85ca                	mv	a1,s2
    80001aa6:	8552                	mv	a0,s4
    80001aa8:	fffff097          	auipc	ra,0xfffff
    80001aac:	7b4080e7          	jalr	1972(ra) # 8000125c <walkaddr>
    if(pa0 == 0)
    80001ab0:	c131                	beqz	a0,80001af4 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001ab2:	417906b3          	sub	a3,s2,s7
    80001ab6:	96ce                	add	a3,a3,s3
    80001ab8:	00d4f363          	bgeu	s1,a3,80001abe <copyinstr+0x6c>
    80001abc:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001abe:	955e                	add	a0,a0,s7
    80001ac0:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001ac4:	daf9                	beqz	a3,80001a9a <copyinstr+0x48>
    80001ac6:	87da                	mv	a5,s6
    80001ac8:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001aca:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001ace:	96da                	add	a3,a3,s6
    80001ad0:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001ad2:	00f60733          	add	a4,a2,a5
    80001ad6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbd090>
    80001ada:	df59                	beqz	a4,80001a78 <copyinstr+0x26>
        *dst = *p;
    80001adc:	00e78023          	sb	a4,0(a5)
      dst++;
    80001ae0:	0785                	addi	a5,a5,1
    while(n > 0){
    80001ae2:	fed797e3          	bne	a5,a3,80001ad0 <copyinstr+0x7e>
    80001ae6:	14fd                	addi	s1,s1,-1
    80001ae8:	94c2                	add	s1,s1,a6
      --max;
    80001aea:	8c8d                	sub	s1,s1,a1
      dst++;
    80001aec:	8b3e                	mv	s6,a5
    80001aee:	b775                	j	80001a9a <copyinstr+0x48>
    80001af0:	4781                	li	a5,0
    80001af2:	b771                	j	80001a7e <copyinstr+0x2c>
      return -1;
    80001af4:	557d                	li	a0,-1
    80001af6:	b779                	j	80001a84 <copyinstr+0x32>
  int got_null = 0;
    80001af8:	4781                	li	a5,0
  if(got_null){
    80001afa:	37fd                	addiw	a5,a5,-1
    80001afc:	0007851b          	sext.w	a0,a5
}
    80001b00:	8082                	ret

0000000080001b02 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001b02:	715d                	addi	sp,sp,-80
    80001b04:	e486                	sd	ra,72(sp)
    80001b06:	e0a2                	sd	s0,64(sp)
    80001b08:	fc26                	sd	s1,56(sp)
    80001b0a:	f84a                	sd	s2,48(sp)
    80001b0c:	f44e                	sd	s3,40(sp)
    80001b0e:	f052                	sd	s4,32(sp)
    80001b10:	ec56                	sd	s5,24(sp)
    80001b12:	e85a                	sd	s6,16(sp)
    80001b14:	e45e                	sd	s7,8(sp)
    80001b16:	e062                	sd	s8,0(sp)
    80001b18:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b1a:	8792                	mv	a5,tp
    int id = r_tp();
    80001b1c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001b1e:	0022fa97          	auipc	s5,0x22f
    80001b22:	242a8a93          	addi	s5,s5,578 # 80230d60 <cpus>
    80001b26:	00779713          	slli	a4,a5,0x7
    80001b2a:	00ea86b3          	add	a3,s5,a4
    80001b2e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fdbd090>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001b32:	0721                	addi	a4,a4,8
    80001b34:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001b36:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001b38:	00007c17          	auipc	s8,0x7
    80001b3c:	f00c0c13          	addi	s8,s8,-256 # 80008a38 <sched_pointer>
    80001b40:	00000b97          	auipc	s7,0x0
    80001b44:	fc2b8b93          	addi	s7,s7,-62 # 80001b02 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b48:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001b4c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001b50:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001b54:	0022f497          	auipc	s1,0x22f
    80001b58:	63c48493          	addi	s1,s1,1596 # 80231190 <proc>
            if (p->state == RUNNABLE)
    80001b5c:	498d                	li	s3,3
                p->state = RUNNING;
    80001b5e:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001b60:	00235a17          	auipc	s4,0x235
    80001b64:	030a0a13          	addi	s4,s4,48 # 80236b90 <tickslock>
    80001b68:	a81d                	j	80001b9e <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	fffff097          	auipc	ra,0xfffff
    80001b70:	320080e7          	jalr	800(ra) # 80000e8c <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001b74:	60a6                	ld	ra,72(sp)
    80001b76:	6406                	ld	s0,64(sp)
    80001b78:	74e2                	ld	s1,56(sp)
    80001b7a:	7942                	ld	s2,48(sp)
    80001b7c:	79a2                	ld	s3,40(sp)
    80001b7e:	7a02                	ld	s4,32(sp)
    80001b80:	6ae2                	ld	s5,24(sp)
    80001b82:	6b42                	ld	s6,16(sp)
    80001b84:	6ba2                	ld	s7,8(sp)
    80001b86:	6c02                	ld	s8,0(sp)
    80001b88:	6161                	addi	sp,sp,80
    80001b8a:	8082                	ret
            release(&p->lock);
    80001b8c:	8526                	mv	a0,s1
    80001b8e:	fffff097          	auipc	ra,0xfffff
    80001b92:	2fe080e7          	jalr	766(ra) # 80000e8c <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001b96:	16848493          	addi	s1,s1,360
    80001b9a:	fb4487e3          	beq	s1,s4,80001b48 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	fffff097          	auipc	ra,0xfffff
    80001ba4:	238080e7          	jalr	568(ra) # 80000dd8 <acquire>
            if (p->state == RUNNABLE)
    80001ba8:	4c9c                	lw	a5,24(s1)
    80001baa:	ff3791e3          	bne	a5,s3,80001b8c <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001bae:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001bb2:	00993023          	sd	s1,0(s2) # 1000 <_entry-0x7ffff000>
                swtch(&c->context, &p->context);
    80001bb6:	06048593          	addi	a1,s1,96
    80001bba:	8556                	mv	a0,s5
    80001bbc:	00001097          	auipc	ra,0x1
    80001bc0:	f5e080e7          	jalr	-162(ra) # 80002b1a <swtch>
                if (sched_pointer != &rr_scheduler)
    80001bc4:	000c3783          	ld	a5,0(s8)
    80001bc8:	fb7791e3          	bne	a5,s7,80001b6a <rr_scheduler+0x68>
                c->proc = 0;
    80001bcc:	00093023          	sd	zero,0(s2)
    80001bd0:	bf75                	j	80001b8c <rr_scheduler+0x8a>

0000000080001bd2 <proc_mapstacks>:
{
    80001bd2:	7139                	addi	sp,sp,-64
    80001bd4:	fc06                	sd	ra,56(sp)
    80001bd6:	f822                	sd	s0,48(sp)
    80001bd8:	f426                	sd	s1,40(sp)
    80001bda:	f04a                	sd	s2,32(sp)
    80001bdc:	ec4e                	sd	s3,24(sp)
    80001bde:	e852                	sd	s4,16(sp)
    80001be0:	e456                	sd	s5,8(sp)
    80001be2:	e05a                	sd	s6,0(sp)
    80001be4:	0080                	addi	s0,sp,64
    80001be6:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001be8:	0022f497          	auipc	s1,0x22f
    80001bec:	5a848493          	addi	s1,s1,1448 # 80231190 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001bf0:	8b26                	mv	s6,s1
    80001bf2:	00006a97          	auipc	s5,0x6
    80001bf6:	41ea8a93          	addi	s5,s5,1054 # 80008010 <__func__.1+0x8>
    80001bfa:	04000937          	lui	s2,0x4000
    80001bfe:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c00:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c02:	00235a17          	auipc	s4,0x235
    80001c06:	f8ea0a13          	addi	s4,s4,-114 # 80236b90 <tickslock>
        char *pa = kalloc();
    80001c0a:	fffff097          	auipc	ra,0xfffff
    80001c0e:	054080e7          	jalr	84(ra) # 80000c5e <kalloc>
    80001c12:	862a                	mv	a2,a0
        if (pa == 0)
    80001c14:	c131                	beqz	a0,80001c58 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001c16:	416485b3          	sub	a1,s1,s6
    80001c1a:	858d                	srai	a1,a1,0x3
    80001c1c:	000ab783          	ld	a5,0(s5)
    80001c20:	02f585b3          	mul	a1,a1,a5
    80001c24:	2585                	addiw	a1,a1,1
    80001c26:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c2a:	4719                	li	a4,6
    80001c2c:	6685                	lui	a3,0x1
    80001c2e:	40b905b3          	sub	a1,s2,a1
    80001c32:	854e                	mv	a0,s3
    80001c34:	fffff097          	auipc	ra,0xfffff
    80001c38:	70a080e7          	jalr	1802(ra) # 8000133e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001c3c:	16848493          	addi	s1,s1,360
    80001c40:	fd4495e3          	bne	s1,s4,80001c0a <proc_mapstacks+0x38>
}
    80001c44:	70e2                	ld	ra,56(sp)
    80001c46:	7442                	ld	s0,48(sp)
    80001c48:	74a2                	ld	s1,40(sp)
    80001c4a:	7902                	ld	s2,32(sp)
    80001c4c:	69e2                	ld	s3,24(sp)
    80001c4e:	6a42                	ld	s4,16(sp)
    80001c50:	6aa2                	ld	s5,8(sp)
    80001c52:	6b02                	ld	s6,0(sp)
    80001c54:	6121                	addi	sp,sp,64
    80001c56:	8082                	ret
            panic("kalloc");
    80001c58:	00006517          	auipc	a0,0x6
    80001c5c:	47050513          	addi	a0,a0,1136 # 800080c8 <digits+0x78>
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	8dc080e7          	jalr	-1828(ra) # 8000053c <panic>

0000000080001c68 <procinit>:
{
    80001c68:	7139                	addi	sp,sp,-64
    80001c6a:	fc06                	sd	ra,56(sp)
    80001c6c:	f822                	sd	s0,48(sp)
    80001c6e:	f426                	sd	s1,40(sp)
    80001c70:	f04a                	sd	s2,32(sp)
    80001c72:	ec4e                	sd	s3,24(sp)
    80001c74:	e852                	sd	s4,16(sp)
    80001c76:	e456                	sd	s5,8(sp)
    80001c78:	e05a                	sd	s6,0(sp)
    80001c7a:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001c7c:	00006597          	auipc	a1,0x6
    80001c80:	5bc58593          	addi	a1,a1,1468 # 80008238 <digits+0x1e8>
    80001c84:	0022f517          	auipc	a0,0x22f
    80001c88:	4dc50513          	addi	a0,a0,1244 # 80231160 <pid_lock>
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	0bc080e7          	jalr	188(ra) # 80000d48 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001c94:	00006597          	auipc	a1,0x6
    80001c98:	5ac58593          	addi	a1,a1,1452 # 80008240 <digits+0x1f0>
    80001c9c:	0022f517          	auipc	a0,0x22f
    80001ca0:	4dc50513          	addi	a0,a0,1244 # 80231178 <wait_lock>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0a4080e7          	jalr	164(ra) # 80000d48 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001cac:	0022f497          	auipc	s1,0x22f
    80001cb0:	4e448493          	addi	s1,s1,1252 # 80231190 <proc>
        initlock(&p->lock, "proc");
    80001cb4:	00006b17          	auipc	s6,0x6
    80001cb8:	59cb0b13          	addi	s6,s6,1436 # 80008250 <digits+0x200>
        p->kstack = KSTACK((int)(p - proc));
    80001cbc:	8aa6                	mv	s5,s1
    80001cbe:	00006a17          	auipc	s4,0x6
    80001cc2:	352a0a13          	addi	s4,s4,850 # 80008010 <__func__.1+0x8>
    80001cc6:	04000937          	lui	s2,0x4000
    80001cca:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001ccc:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001cce:	00235997          	auipc	s3,0x235
    80001cd2:	ec298993          	addi	s3,s3,-318 # 80236b90 <tickslock>
        initlock(&p->lock, "proc");
    80001cd6:	85da                	mv	a1,s6
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	06e080e7          	jalr	110(ra) # 80000d48 <initlock>
        p->state = UNUSED;
    80001ce2:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001ce6:	415487b3          	sub	a5,s1,s5
    80001cea:	878d                	srai	a5,a5,0x3
    80001cec:	000a3703          	ld	a4,0(s4)
    80001cf0:	02e787b3          	mul	a5,a5,a4
    80001cf4:	2785                	addiw	a5,a5,1
    80001cf6:	00d7979b          	slliw	a5,a5,0xd
    80001cfa:	40f907b3          	sub	a5,s2,a5
    80001cfe:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001d00:	16848493          	addi	s1,s1,360
    80001d04:	fd3499e3          	bne	s1,s3,80001cd6 <procinit+0x6e>
}
    80001d08:	70e2                	ld	ra,56(sp)
    80001d0a:	7442                	ld	s0,48(sp)
    80001d0c:	74a2                	ld	s1,40(sp)
    80001d0e:	7902                	ld	s2,32(sp)
    80001d10:	69e2                	ld	s3,24(sp)
    80001d12:	6a42                	ld	s4,16(sp)
    80001d14:	6aa2                	ld	s5,8(sp)
    80001d16:	6b02                	ld	s6,0(sp)
    80001d18:	6121                	addi	sp,sp,64
    80001d1a:	8082                	ret

0000000080001d1c <copy_array>:
{
    80001d1c:	1141                	addi	sp,sp,-16
    80001d1e:	e422                	sd	s0,8(sp)
    80001d20:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001d22:	00c05c63          	blez	a2,80001d3a <copy_array+0x1e>
    80001d26:	87aa                	mv	a5,a0
    80001d28:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001d2a:	0007c703          	lbu	a4,0(a5)
    80001d2e:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001d32:	0785                	addi	a5,a5,1
    80001d34:	0585                	addi	a1,a1,1
    80001d36:	fea79ae3          	bne	a5,a0,80001d2a <copy_array+0xe>
}
    80001d3a:	6422                	ld	s0,8(sp)
    80001d3c:	0141                	addi	sp,sp,16
    80001d3e:	8082                	ret

0000000080001d40 <cpuid>:
{
    80001d40:	1141                	addi	sp,sp,-16
    80001d42:	e422                	sd	s0,8(sp)
    80001d44:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d46:	8512                	mv	a0,tp
}
    80001d48:	2501                	sext.w	a0,a0
    80001d4a:	6422                	ld	s0,8(sp)
    80001d4c:	0141                	addi	sp,sp,16
    80001d4e:	8082                	ret

0000000080001d50 <mycpu>:
{
    80001d50:	1141                	addi	sp,sp,-16
    80001d52:	e422                	sd	s0,8(sp)
    80001d54:	0800                	addi	s0,sp,16
    80001d56:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001d58:	2781                	sext.w	a5,a5
    80001d5a:	079e                	slli	a5,a5,0x7
}
    80001d5c:	0022f517          	auipc	a0,0x22f
    80001d60:	00450513          	addi	a0,a0,4 # 80230d60 <cpus>
    80001d64:	953e                	add	a0,a0,a5
    80001d66:	6422                	ld	s0,8(sp)
    80001d68:	0141                	addi	sp,sp,16
    80001d6a:	8082                	ret

0000000080001d6c <myproc>:
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	1000                	addi	s0,sp,32
    push_off();
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	016080e7          	jalr	22(ra) # 80000d8c <push_off>
    80001d7e:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001d80:	2781                	sext.w	a5,a5
    80001d82:	079e                	slli	a5,a5,0x7
    80001d84:	0022f717          	auipc	a4,0x22f
    80001d88:	fdc70713          	addi	a4,a4,-36 # 80230d60 <cpus>
    80001d8c:	97ba                	add	a5,a5,a4
    80001d8e:	6384                	ld	s1,0(a5)
    pop_off();
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	09c080e7          	jalr	156(ra) # 80000e2c <pop_off>
}
    80001d98:	8526                	mv	a0,s1
    80001d9a:	60e2                	ld	ra,24(sp)
    80001d9c:	6442                	ld	s0,16(sp)
    80001d9e:	64a2                	ld	s1,8(sp)
    80001da0:	6105                	addi	sp,sp,32
    80001da2:	8082                	ret

0000000080001da4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001da4:	1141                	addi	sp,sp,-16
    80001da6:	e406                	sd	ra,8(sp)
    80001da8:	e022                	sd	s0,0(sp)
    80001daa:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001dac:	00000097          	auipc	ra,0x0
    80001db0:	fc0080e7          	jalr	-64(ra) # 80001d6c <myproc>
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	0d8080e7          	jalr	216(ra) # 80000e8c <release>

    if (first)
    80001dbc:	00007797          	auipc	a5,0x7
    80001dc0:	c747a783          	lw	a5,-908(a5) # 80008a30 <first.1>
    80001dc4:	eb89                	bnez	a5,80001dd6 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001dc6:	00001097          	auipc	ra,0x1
    80001dca:	dfe080e7          	jalr	-514(ra) # 80002bc4 <usertrapret>
}
    80001dce:	60a2                	ld	ra,8(sp)
    80001dd0:	6402                	ld	s0,0(sp)
    80001dd2:	0141                	addi	sp,sp,16
    80001dd4:	8082                	ret
        first = 0;
    80001dd6:	00007797          	auipc	a5,0x7
    80001dda:	c407ad23          	sw	zero,-934(a5) # 80008a30 <first.1>
        fsinit(ROOTDEV);
    80001dde:	4505                	li	a0,1
    80001de0:	00002097          	auipc	ra,0x2
    80001de4:	d56080e7          	jalr	-682(ra) # 80003b36 <fsinit>
    80001de8:	bff9                	j	80001dc6 <forkret+0x22>

0000000080001dea <allocpid>:
{
    80001dea:	1101                	addi	sp,sp,-32
    80001dec:	ec06                	sd	ra,24(sp)
    80001dee:	e822                	sd	s0,16(sp)
    80001df0:	e426                	sd	s1,8(sp)
    80001df2:	e04a                	sd	s2,0(sp)
    80001df4:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001df6:	0022f917          	auipc	s2,0x22f
    80001dfa:	36a90913          	addi	s2,s2,874 # 80231160 <pid_lock>
    80001dfe:	854a                	mv	a0,s2
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	fd8080e7          	jalr	-40(ra) # 80000dd8 <acquire>
    pid = nextpid;
    80001e08:	00007797          	auipc	a5,0x7
    80001e0c:	c3878793          	addi	a5,a5,-968 # 80008a40 <nextpid>
    80001e10:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001e12:	0014871b          	addiw	a4,s1,1
    80001e16:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001e18:	854a                	mv	a0,s2
    80001e1a:	fffff097          	auipc	ra,0xfffff
    80001e1e:	072080e7          	jalr	114(ra) # 80000e8c <release>
}
    80001e22:	8526                	mv	a0,s1
    80001e24:	60e2                	ld	ra,24(sp)
    80001e26:	6442                	ld	s0,16(sp)
    80001e28:	64a2                	ld	s1,8(sp)
    80001e2a:	6902                	ld	s2,0(sp)
    80001e2c:	6105                	addi	sp,sp,32
    80001e2e:	8082                	ret

0000000080001e30 <proc_pagetable>:
{
    80001e30:	1101                	addi	sp,sp,-32
    80001e32:	ec06                	sd	ra,24(sp)
    80001e34:	e822                	sd	s0,16(sp)
    80001e36:	e426                	sd	s1,8(sp)
    80001e38:	e04a                	sd	s2,0(sp)
    80001e3a:	1000                	addi	s0,sp,32
    80001e3c:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001e3e:	fffff097          	auipc	ra,0xfffff
    80001e42:	6ea080e7          	jalr	1770(ra) # 80001528 <uvmcreate>
    80001e46:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001e48:	c121                	beqz	a0,80001e88 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e4a:	4729                	li	a4,10
    80001e4c:	00005697          	auipc	a3,0x5
    80001e50:	1b468693          	addi	a3,a3,436 # 80007000 <_trampoline>
    80001e54:	6605                	lui	a2,0x1
    80001e56:	040005b7          	lui	a1,0x4000
    80001e5a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e5c:	05b2                	slli	a1,a1,0xc
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	440080e7          	jalr	1088(ra) # 8000129e <mappages>
    80001e66:	02054863          	bltz	a0,80001e96 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001e6a:	4719                	li	a4,6
    80001e6c:	05893683          	ld	a3,88(s2)
    80001e70:	6605                	lui	a2,0x1
    80001e72:	020005b7          	lui	a1,0x2000
    80001e76:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001e78:	05b6                	slli	a1,a1,0xd
    80001e7a:	8526                	mv	a0,s1
    80001e7c:	fffff097          	auipc	ra,0xfffff
    80001e80:	422080e7          	jalr	1058(ra) # 8000129e <mappages>
    80001e84:	02054163          	bltz	a0,80001ea6 <proc_pagetable+0x76>
}
    80001e88:	8526                	mv	a0,s1
    80001e8a:	60e2                	ld	ra,24(sp)
    80001e8c:	6442                	ld	s0,16(sp)
    80001e8e:	64a2                	ld	s1,8(sp)
    80001e90:	6902                	ld	s2,0(sp)
    80001e92:	6105                	addi	sp,sp,32
    80001e94:	8082                	ret
        uvmfree(pagetable, 0);
    80001e96:	4581                	li	a1,0
    80001e98:	8526                	mv	a0,s1
    80001e9a:	00000097          	auipc	ra,0x0
    80001e9e:	894080e7          	jalr	-1900(ra) # 8000172e <uvmfree>
        return 0;
    80001ea2:	4481                	li	s1,0
    80001ea4:	b7d5                	j	80001e88 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ea6:	4681                	li	a3,0
    80001ea8:	4605                	li	a2,1
    80001eaa:	040005b7          	lui	a1,0x4000
    80001eae:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001eb0:	05b2                	slli	a1,a1,0xc
    80001eb2:	8526                	mv	a0,s1
    80001eb4:	fffff097          	auipc	ra,0xfffff
    80001eb8:	5b0080e7          	jalr	1456(ra) # 80001464 <uvmunmap>
        uvmfree(pagetable, 0);
    80001ebc:	4581                	li	a1,0
    80001ebe:	8526                	mv	a0,s1
    80001ec0:	00000097          	auipc	ra,0x0
    80001ec4:	86e080e7          	jalr	-1938(ra) # 8000172e <uvmfree>
        return 0;
    80001ec8:	4481                	li	s1,0
    80001eca:	bf7d                	j	80001e88 <proc_pagetable+0x58>

0000000080001ecc <proc_freepagetable>:
{
    80001ecc:	1101                	addi	sp,sp,-32
    80001ece:	ec06                	sd	ra,24(sp)
    80001ed0:	e822                	sd	s0,16(sp)
    80001ed2:	e426                	sd	s1,8(sp)
    80001ed4:	e04a                	sd	s2,0(sp)
    80001ed6:	1000                	addi	s0,sp,32
    80001ed8:	84aa                	mv	s1,a0
    80001eda:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001edc:	4681                	li	a3,0
    80001ede:	4605                	li	a2,1
    80001ee0:	040005b7          	lui	a1,0x4000
    80001ee4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ee6:	05b2                	slli	a1,a1,0xc
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	57c080e7          	jalr	1404(ra) # 80001464 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001ef0:	4681                	li	a3,0
    80001ef2:	4605                	li	a2,1
    80001ef4:	020005b7          	lui	a1,0x2000
    80001ef8:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001efa:	05b6                	slli	a1,a1,0xd
    80001efc:	8526                	mv	a0,s1
    80001efe:	fffff097          	auipc	ra,0xfffff
    80001f02:	566080e7          	jalr	1382(ra) # 80001464 <uvmunmap>
    uvmfree(pagetable, sz);
    80001f06:	85ca                	mv	a1,s2
    80001f08:	8526                	mv	a0,s1
    80001f0a:	00000097          	auipc	ra,0x0
    80001f0e:	824080e7          	jalr	-2012(ra) # 8000172e <uvmfree>
}
    80001f12:	60e2                	ld	ra,24(sp)
    80001f14:	6442                	ld	s0,16(sp)
    80001f16:	64a2                	ld	s1,8(sp)
    80001f18:	6902                	ld	s2,0(sp)
    80001f1a:	6105                	addi	sp,sp,32
    80001f1c:	8082                	ret

0000000080001f1e <freeproc>:
{
    80001f1e:	1101                	addi	sp,sp,-32
    80001f20:	ec06                	sd	ra,24(sp)
    80001f22:	e822                	sd	s0,16(sp)
    80001f24:	e426                	sd	s1,8(sp)
    80001f26:	1000                	addi	s0,sp,32
    80001f28:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001f2a:	6d28                	ld	a0,88(a0)
    80001f2c:	c509                	beqz	a0,80001f36 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001f2e:	fffff097          	auipc	ra,0xfffff
    80001f32:	b44080e7          	jalr	-1212(ra) # 80000a72 <kfree>
    p->trapframe = 0;
    80001f36:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001f3a:	68a8                	ld	a0,80(s1)
    80001f3c:	c511                	beqz	a0,80001f48 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001f3e:	64ac                	ld	a1,72(s1)
    80001f40:	00000097          	auipc	ra,0x0
    80001f44:	f8c080e7          	jalr	-116(ra) # 80001ecc <proc_freepagetable>
    p->pagetable = 0;
    80001f48:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001f4c:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001f50:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001f54:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001f58:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001f5c:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001f60:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001f64:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001f68:	0004ac23          	sw	zero,24(s1)
}
    80001f6c:	60e2                	ld	ra,24(sp)
    80001f6e:	6442                	ld	s0,16(sp)
    80001f70:	64a2                	ld	s1,8(sp)
    80001f72:	6105                	addi	sp,sp,32
    80001f74:	8082                	ret

0000000080001f76 <allocproc>:
{
    80001f76:	1101                	addi	sp,sp,-32
    80001f78:	ec06                	sd	ra,24(sp)
    80001f7a:	e822                	sd	s0,16(sp)
    80001f7c:	e426                	sd	s1,8(sp)
    80001f7e:	e04a                	sd	s2,0(sp)
    80001f80:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001f82:	0022f497          	auipc	s1,0x22f
    80001f86:	20e48493          	addi	s1,s1,526 # 80231190 <proc>
    80001f8a:	00235917          	auipc	s2,0x235
    80001f8e:	c0690913          	addi	s2,s2,-1018 # 80236b90 <tickslock>
        acquire(&p->lock);
    80001f92:	8526                	mv	a0,s1
    80001f94:	fffff097          	auipc	ra,0xfffff
    80001f98:	e44080e7          	jalr	-444(ra) # 80000dd8 <acquire>
        if (p->state == UNUSED)
    80001f9c:	4c9c                	lw	a5,24(s1)
    80001f9e:	cf81                	beqz	a5,80001fb6 <allocproc+0x40>
            release(&p->lock);
    80001fa0:	8526                	mv	a0,s1
    80001fa2:	fffff097          	auipc	ra,0xfffff
    80001fa6:	eea080e7          	jalr	-278(ra) # 80000e8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001faa:	16848493          	addi	s1,s1,360
    80001fae:	ff2492e3          	bne	s1,s2,80001f92 <allocproc+0x1c>
    return 0;
    80001fb2:	4481                	li	s1,0
    80001fb4:	a889                	j	80002006 <allocproc+0x90>
    p->pid = allocpid();
    80001fb6:	00000097          	auipc	ra,0x0
    80001fba:	e34080e7          	jalr	-460(ra) # 80001dea <allocpid>
    80001fbe:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001fc0:	4785                	li	a5,1
    80001fc2:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c9a080e7          	jalr	-870(ra) # 80000c5e <kalloc>
    80001fcc:	892a                	mv	s2,a0
    80001fce:	eca8                	sd	a0,88(s1)
    80001fd0:	c131                	beqz	a0,80002014 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	e5c080e7          	jalr	-420(ra) # 80001e30 <proc_pagetable>
    80001fdc:	892a                	mv	s2,a0
    80001fde:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80001fe0:	c531                	beqz	a0,8000202c <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80001fe2:	07000613          	li	a2,112
    80001fe6:	4581                	li	a1,0
    80001fe8:	06048513          	addi	a0,s1,96
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	ee8080e7          	jalr	-280(ra) # 80000ed4 <memset>
    p->context.ra = (uint64)forkret;
    80001ff4:	00000797          	auipc	a5,0x0
    80001ff8:	db078793          	addi	a5,a5,-592 # 80001da4 <forkret>
    80001ffc:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001ffe:	60bc                	ld	a5,64(s1)
    80002000:	6705                	lui	a4,0x1
    80002002:	97ba                	add	a5,a5,a4
    80002004:	f4bc                	sd	a5,104(s1)
}
    80002006:	8526                	mv	a0,s1
    80002008:	60e2                	ld	ra,24(sp)
    8000200a:	6442                	ld	s0,16(sp)
    8000200c:	64a2                	ld	s1,8(sp)
    8000200e:	6902                	ld	s2,0(sp)
    80002010:	6105                	addi	sp,sp,32
    80002012:	8082                	ret
        freeproc(p);
    80002014:	8526                	mv	a0,s1
    80002016:	00000097          	auipc	ra,0x0
    8000201a:	f08080e7          	jalr	-248(ra) # 80001f1e <freeproc>
        release(&p->lock);
    8000201e:	8526                	mv	a0,s1
    80002020:	fffff097          	auipc	ra,0xfffff
    80002024:	e6c080e7          	jalr	-404(ra) # 80000e8c <release>
        return 0;
    80002028:	84ca                	mv	s1,s2
    8000202a:	bff1                	j	80002006 <allocproc+0x90>
        freeproc(p);
    8000202c:	8526                	mv	a0,s1
    8000202e:	00000097          	auipc	ra,0x0
    80002032:	ef0080e7          	jalr	-272(ra) # 80001f1e <freeproc>
        release(&p->lock);
    80002036:	8526                	mv	a0,s1
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	e54080e7          	jalr	-428(ra) # 80000e8c <release>
        return 0;
    80002040:	84ca                	mv	s1,s2
    80002042:	b7d1                	j	80002006 <allocproc+0x90>

0000000080002044 <userinit>:
{
    80002044:	1101                	addi	sp,sp,-32
    80002046:	ec06                	sd	ra,24(sp)
    80002048:	e822                	sd	s0,16(sp)
    8000204a:	e426                	sd	s1,8(sp)
    8000204c:	1000                	addi	s0,sp,32
    p = allocproc();
    8000204e:	00000097          	auipc	ra,0x0
    80002052:	f28080e7          	jalr	-216(ra) # 80001f76 <allocproc>
    80002056:	84aa                	mv	s1,a0
    initproc = p;
    80002058:	00007797          	auipc	a5,0x7
    8000205c:	a8a7b823          	sd	a0,-1392(a5) # 80008ae8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80002060:	03400613          	li	a2,52
    80002064:	00007597          	auipc	a1,0x7
    80002068:	9ec58593          	addi	a1,a1,-1556 # 80008a50 <initcode>
    8000206c:	6928                	ld	a0,80(a0)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	4e8080e7          	jalr	1256(ra) # 80001556 <uvmfirst>
    p->sz = PGSIZE;
    80002076:	6785                	lui	a5,0x1
    80002078:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    8000207a:	6cb8                	ld	a4,88(s1)
    8000207c:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80002080:	6cb8                	ld	a4,88(s1)
    80002082:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80002084:	4641                	li	a2,16
    80002086:	00006597          	auipc	a1,0x6
    8000208a:	1d258593          	addi	a1,a1,466 # 80008258 <digits+0x208>
    8000208e:	15848513          	addi	a0,s1,344
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	f8a080e7          	jalr	-118(ra) # 8000101c <safestrcpy>
    p->cwd = namei("/");
    8000209a:	00006517          	auipc	a0,0x6
    8000209e:	1ce50513          	addi	a0,a0,462 # 80008268 <digits+0x218>
    800020a2:	00002097          	auipc	ra,0x2
    800020a6:	4b2080e7          	jalr	1202(ra) # 80004554 <namei>
    800020aa:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    800020ae:	478d                	li	a5,3
    800020b0:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    800020b2:	8526                	mv	a0,s1
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	dd8080e7          	jalr	-552(ra) # 80000e8c <release>
}
    800020bc:	60e2                	ld	ra,24(sp)
    800020be:	6442                	ld	s0,16(sp)
    800020c0:	64a2                	ld	s1,8(sp)
    800020c2:	6105                	addi	sp,sp,32
    800020c4:	8082                	ret

00000000800020c6 <growproc>:
{
    800020c6:	1101                	addi	sp,sp,-32
    800020c8:	ec06                	sd	ra,24(sp)
    800020ca:	e822                	sd	s0,16(sp)
    800020cc:	e426                	sd	s1,8(sp)
    800020ce:	e04a                	sd	s2,0(sp)
    800020d0:	1000                	addi	s0,sp,32
    800020d2:	892a                	mv	s2,a0
    struct proc *p = myproc();
    800020d4:	00000097          	auipc	ra,0x0
    800020d8:	c98080e7          	jalr	-872(ra) # 80001d6c <myproc>
    800020dc:	84aa                	mv	s1,a0
    sz = p->sz;
    800020de:	652c                	ld	a1,72(a0)
    if (n > 0)
    800020e0:	01204c63          	bgtz	s2,800020f8 <growproc+0x32>
    else if (n < 0)
    800020e4:	02094663          	bltz	s2,80002110 <growproc+0x4a>
    p->sz = sz;
    800020e8:	e4ac                	sd	a1,72(s1)
    return 0;
    800020ea:	4501                	li	a0,0
}
    800020ec:	60e2                	ld	ra,24(sp)
    800020ee:	6442                	ld	s0,16(sp)
    800020f0:	64a2                	ld	s1,8(sp)
    800020f2:	6902                	ld	s2,0(sp)
    800020f4:	6105                	addi	sp,sp,32
    800020f6:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    800020f8:	4691                	li	a3,4
    800020fa:	00b90633          	add	a2,s2,a1
    800020fe:	6928                	ld	a0,80(a0)
    80002100:	fffff097          	auipc	ra,0xfffff
    80002104:	510080e7          	jalr	1296(ra) # 80001610 <uvmalloc>
    80002108:	85aa                	mv	a1,a0
    8000210a:	fd79                	bnez	a0,800020e8 <growproc+0x22>
            return -1;
    8000210c:	557d                	li	a0,-1
    8000210e:	bff9                	j	800020ec <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002110:	00b90633          	add	a2,s2,a1
    80002114:	6928                	ld	a0,80(a0)
    80002116:	fffff097          	auipc	ra,0xfffff
    8000211a:	4b2080e7          	jalr	1202(ra) # 800015c8 <uvmdealloc>
    8000211e:	85aa                	mv	a1,a0
    80002120:	b7e1                	j	800020e8 <growproc+0x22>

0000000080002122 <ps>:
{
    80002122:	715d                	addi	sp,sp,-80
    80002124:	e486                	sd	ra,72(sp)
    80002126:	e0a2                	sd	s0,64(sp)
    80002128:	fc26                	sd	s1,56(sp)
    8000212a:	f84a                	sd	s2,48(sp)
    8000212c:	f44e                	sd	s3,40(sp)
    8000212e:	f052                	sd	s4,32(sp)
    80002130:	ec56                	sd	s5,24(sp)
    80002132:	e85a                	sd	s6,16(sp)
    80002134:	e45e                	sd	s7,8(sp)
    80002136:	e062                	sd	s8,0(sp)
    80002138:	0880                	addi	s0,sp,80
    8000213a:	84aa                	mv	s1,a0
    8000213c:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    8000213e:	00000097          	auipc	ra,0x0
    80002142:	c2e080e7          	jalr	-978(ra) # 80001d6c <myproc>
    if (count == 0)
    80002146:	120b8063          	beqz	s7,80002266 <ps+0x144>
    void *result = (void *)myproc()->sz;
    8000214a:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    8000214e:	003b951b          	slliw	a0,s7,0x3
    80002152:	0175053b          	addw	a0,a0,s7
    80002156:	0025151b          	slliw	a0,a0,0x2
    8000215a:	00000097          	auipc	ra,0x0
    8000215e:	f6c080e7          	jalr	-148(ra) # 800020c6 <growproc>
    80002162:	10054463          	bltz	a0,8000226a <ps+0x148>
    struct user_proc loc_result[count];
    80002166:	003b9a13          	slli	s4,s7,0x3
    8000216a:	9a5e                	add	s4,s4,s7
    8000216c:	0a0a                	slli	s4,s4,0x2
    8000216e:	00fa0793          	addi	a5,s4,15
    80002172:	8391                	srli	a5,a5,0x4
    80002174:	0792                	slli	a5,a5,0x4
    80002176:	40f10133          	sub	sp,sp,a5
    8000217a:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    8000217c:	007e97b7          	lui	a5,0x7e9
    80002180:	02f484b3          	mul	s1,s1,a5
    80002184:	0022f797          	auipc	a5,0x22f
    80002188:	00c78793          	addi	a5,a5,12 # 80231190 <proc>
    8000218c:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000218e:	00235797          	auipc	a5,0x235
    80002192:	a0278793          	addi	a5,a5,-1534 # 80236b90 <tickslock>
    80002196:	0cf4fc63          	bgeu	s1,a5,8000226e <ps+0x14c>
        if (localCount == count)
    8000219a:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    8000219e:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800021a0:	8c3e                	mv	s8,a5
    800021a2:	a069                	j	8000222c <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    800021a4:	00399793          	slli	a5,s3,0x3
    800021a8:	97ce                	add	a5,a5,s3
    800021aa:	078a                	slli	a5,a5,0x2
    800021ac:	97d6                	add	a5,a5,s5
    800021ae:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800021b2:	8526                	mv	a0,s1
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	cd8080e7          	jalr	-808(ra) # 80000e8c <release>
    if (localCount < count)
    800021bc:	0179f963          	bgeu	s3,s7,800021ce <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    800021c0:	00399793          	slli	a5,s3,0x3
    800021c4:	97ce                	add	a5,a5,s3
    800021c6:	078a                	slli	a5,a5,0x2
    800021c8:	97d6                	add	a5,a5,s5
    800021ca:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    800021ce:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    800021d0:	00000097          	auipc	ra,0x0
    800021d4:	b9c080e7          	jalr	-1124(ra) # 80001d6c <myproc>
    800021d8:	86d2                	mv	a3,s4
    800021da:	8656                	mv	a2,s5
    800021dc:	85da                	mv	a1,s6
    800021de:	6928                	ld	a0,80(a0)
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	744080e7          	jalr	1860(ra) # 80001924 <copyout>
}
    800021e8:	8526                	mv	a0,s1
    800021ea:	fb040113          	addi	sp,s0,-80
    800021ee:	60a6                	ld	ra,72(sp)
    800021f0:	6406                	ld	s0,64(sp)
    800021f2:	74e2                	ld	s1,56(sp)
    800021f4:	7942                	ld	s2,48(sp)
    800021f6:	79a2                	ld	s3,40(sp)
    800021f8:	7a02                	ld	s4,32(sp)
    800021fa:	6ae2                	ld	s5,24(sp)
    800021fc:	6b42                	ld	s6,16(sp)
    800021fe:	6ba2                	ld	s7,8(sp)
    80002200:	6c02                	ld	s8,0(sp)
    80002202:	6161                	addi	sp,sp,80
    80002204:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002206:	5b9c                	lw	a5,48(a5)
    80002208:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000220c:	8526                	mv	a0,s1
    8000220e:	fffff097          	auipc	ra,0xfffff
    80002212:	c7e080e7          	jalr	-898(ra) # 80000e8c <release>
        localCount++;
    80002216:	2985                	addiw	s3,s3,1
    80002218:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000221c:	16848493          	addi	s1,s1,360
    80002220:	f984fee3          	bgeu	s1,s8,800021bc <ps+0x9a>
        if (localCount == count)
    80002224:	02490913          	addi	s2,s2,36
    80002228:	fb3b83e3          	beq	s7,s3,800021ce <ps+0xac>
        acquire(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	baa080e7          	jalr	-1110(ra) # 80000dd8 <acquire>
        if (p->state == UNUSED)
    80002236:	4c9c                	lw	a5,24(s1)
    80002238:	d7b5                	beqz	a5,800021a4 <ps+0x82>
        loc_result[localCount].state = p->state;
    8000223a:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000223e:	549c                	lw	a5,40(s1)
    80002240:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002244:	54dc                	lw	a5,44(s1)
    80002246:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    8000224a:	589c                	lw	a5,48(s1)
    8000224c:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002250:	4641                	li	a2,16
    80002252:	85ca                	mv	a1,s2
    80002254:	15848513          	addi	a0,s1,344
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	ac4080e7          	jalr	-1340(ra) # 80001d1c <copy_array>
        if (p->parent != 0) // init
    80002260:	7c9c                	ld	a5,56(s1)
    80002262:	f3d5                	bnez	a5,80002206 <ps+0xe4>
    80002264:	b765                	j	8000220c <ps+0xea>
        return result;
    80002266:	4481                	li	s1,0
    80002268:	b741                	j	800021e8 <ps+0xc6>
        return result;
    8000226a:	4481                	li	s1,0
    8000226c:	bfb5                	j	800021e8 <ps+0xc6>
        return result;
    8000226e:	4481                	li	s1,0
    80002270:	bfa5                	j	800021e8 <ps+0xc6>

0000000080002272 <fork>:
{
    80002272:	7139                	addi	sp,sp,-64
    80002274:	fc06                	sd	ra,56(sp)
    80002276:	f822                	sd	s0,48(sp)
    80002278:	f426                	sd	s1,40(sp)
    8000227a:	f04a                	sd	s2,32(sp)
    8000227c:	ec4e                	sd	s3,24(sp)
    8000227e:	e852                	sd	s4,16(sp)
    80002280:	e456                	sd	s5,8(sp)
    80002282:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80002284:	00000097          	auipc	ra,0x0
    80002288:	ae8080e7          	jalr	-1304(ra) # 80001d6c <myproc>
    8000228c:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    8000228e:	00000097          	auipc	ra,0x0
    80002292:	ce8080e7          	jalr	-792(ra) # 80001f76 <allocproc>
    80002296:	10050c63          	beqz	a0,800023ae <fork+0x13c>
    8000229a:	8a2a                	mv	s4,a0
    if (uvmshare(p->pagetable, np->pagetable, p->sz) < 0)
    8000229c:	048ab603          	ld	a2,72(s5)
    800022a0:	692c                	ld	a1,80(a0)
    800022a2:	050ab503          	ld	a0,80(s5)
    800022a6:	fffff097          	auipc	ra,0xfffff
    800022aa:	594080e7          	jalr	1428(ra) # 8000183a <uvmshare>
    800022ae:	04054863          	bltz	a0,800022fe <fork+0x8c>
    np->sz = p->sz;
    800022b2:	048ab783          	ld	a5,72(s5)
    800022b6:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800022ba:	058ab683          	ld	a3,88(s5)
    800022be:	87b6                	mv	a5,a3
    800022c0:	058a3703          	ld	a4,88(s4)
    800022c4:	12068693          	addi	a3,a3,288
    800022c8:	0007b803          	ld	a6,0(a5)
    800022cc:	6788                	ld	a0,8(a5)
    800022ce:	6b8c                	ld	a1,16(a5)
    800022d0:	6f90                	ld	a2,24(a5)
    800022d2:	01073023          	sd	a6,0(a4)
    800022d6:	e708                	sd	a0,8(a4)
    800022d8:	eb0c                	sd	a1,16(a4)
    800022da:	ef10                	sd	a2,24(a4)
    800022dc:	02078793          	addi	a5,a5,32
    800022e0:	02070713          	addi	a4,a4,32
    800022e4:	fed792e3          	bne	a5,a3,800022c8 <fork+0x56>
    np->trapframe->a0 = 0;
    800022e8:	058a3783          	ld	a5,88(s4)
    800022ec:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    800022f0:	0d0a8493          	addi	s1,s5,208
    800022f4:	0d0a0913          	addi	s2,s4,208
    800022f8:	150a8993          	addi	s3,s5,336
    800022fc:	a00d                	j	8000231e <fork+0xac>
        freeproc(np);
    800022fe:	8552                	mv	a0,s4
    80002300:	00000097          	auipc	ra,0x0
    80002304:	c1e080e7          	jalr	-994(ra) # 80001f1e <freeproc>
        release(&np->lock);
    80002308:	8552                	mv	a0,s4
    8000230a:	fffff097          	auipc	ra,0xfffff
    8000230e:	b82080e7          	jalr	-1150(ra) # 80000e8c <release>
        return -1;
    80002312:	597d                	li	s2,-1
    80002314:	a059                	j	8000239a <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002316:	04a1                	addi	s1,s1,8
    80002318:	0921                	addi	s2,s2,8
    8000231a:	01348b63          	beq	s1,s3,80002330 <fork+0xbe>
        if (p->ofile[i])
    8000231e:	6088                	ld	a0,0(s1)
    80002320:	d97d                	beqz	a0,80002316 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002322:	00003097          	auipc	ra,0x3
    80002326:	8a4080e7          	jalr	-1884(ra) # 80004bc6 <filedup>
    8000232a:	00a93023          	sd	a0,0(s2)
    8000232e:	b7e5                	j	80002316 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002330:	150ab503          	ld	a0,336(s5)
    80002334:	00002097          	auipc	ra,0x2
    80002338:	a3c080e7          	jalr	-1476(ra) # 80003d70 <idup>
    8000233c:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002340:	4641                	li	a2,16
    80002342:	158a8593          	addi	a1,s5,344
    80002346:	158a0513          	addi	a0,s4,344
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	cd2080e7          	jalr	-814(ra) # 8000101c <safestrcpy>
    pid = np->pid;
    80002352:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002356:	8552                	mv	a0,s4
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	b34080e7          	jalr	-1228(ra) # 80000e8c <release>
    acquire(&wait_lock);
    80002360:	0022f497          	auipc	s1,0x22f
    80002364:	e1848493          	addi	s1,s1,-488 # 80231178 <wait_lock>
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	a6e080e7          	jalr	-1426(ra) # 80000dd8 <acquire>
    np->parent = p;
    80002372:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	b14080e7          	jalr	-1260(ra) # 80000e8c <release>
    acquire(&np->lock);
    80002380:	8552                	mv	a0,s4
    80002382:	fffff097          	auipc	ra,0xfffff
    80002386:	a56080e7          	jalr	-1450(ra) # 80000dd8 <acquire>
    np->state = RUNNABLE;
    8000238a:	478d                	li	a5,3
    8000238c:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    80002390:	8552                	mv	a0,s4
    80002392:	fffff097          	auipc	ra,0xfffff
    80002396:	afa080e7          	jalr	-1286(ra) # 80000e8c <release>
}
    8000239a:	854a                	mv	a0,s2
    8000239c:	70e2                	ld	ra,56(sp)
    8000239e:	7442                	ld	s0,48(sp)
    800023a0:	74a2                	ld	s1,40(sp)
    800023a2:	7902                	ld	s2,32(sp)
    800023a4:	69e2                	ld	s3,24(sp)
    800023a6:	6a42                	ld	s4,16(sp)
    800023a8:	6aa2                	ld	s5,8(sp)
    800023aa:	6121                	addi	sp,sp,64
    800023ac:	8082                	ret
        return -1;
    800023ae:	597d                	li	s2,-1
    800023b0:	b7ed                	j	8000239a <fork+0x128>

00000000800023b2 <scheduler>:
{
    800023b2:	1101                	addi	sp,sp,-32
    800023b4:	ec06                	sd	ra,24(sp)
    800023b6:	e822                	sd	s0,16(sp)
    800023b8:	e426                	sd	s1,8(sp)
    800023ba:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800023bc:	00006497          	auipc	s1,0x6
    800023c0:	67c48493          	addi	s1,s1,1660 # 80008a38 <sched_pointer>
    800023c4:	609c                	ld	a5,0(s1)
    800023c6:	9782                	jalr	a5
    while (1)
    800023c8:	bff5                	j	800023c4 <scheduler+0x12>

00000000800023ca <sched>:
{
    800023ca:	7179                	addi	sp,sp,-48
    800023cc:	f406                	sd	ra,40(sp)
    800023ce:	f022                	sd	s0,32(sp)
    800023d0:	ec26                	sd	s1,24(sp)
    800023d2:	e84a                	sd	s2,16(sp)
    800023d4:	e44e                	sd	s3,8(sp)
    800023d6:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    800023d8:	00000097          	auipc	ra,0x0
    800023dc:	994080e7          	jalr	-1644(ra) # 80001d6c <myproc>
    800023e0:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    800023e2:	fffff097          	auipc	ra,0xfffff
    800023e6:	97c080e7          	jalr	-1668(ra) # 80000d5e <holding>
    800023ea:	c53d                	beqz	a0,80002458 <sched+0x8e>
    800023ec:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    800023ee:	2781                	sext.w	a5,a5
    800023f0:	079e                	slli	a5,a5,0x7
    800023f2:	0022f717          	auipc	a4,0x22f
    800023f6:	96e70713          	addi	a4,a4,-1682 # 80230d60 <cpus>
    800023fa:	97ba                	add	a5,a5,a4
    800023fc:	5fb8                	lw	a4,120(a5)
    800023fe:	4785                	li	a5,1
    80002400:	06f71463          	bne	a4,a5,80002468 <sched+0x9e>
    if (p->state == RUNNING)
    80002404:	4c98                	lw	a4,24(s1)
    80002406:	4791                	li	a5,4
    80002408:	06f70863          	beq	a4,a5,80002478 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000240c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002410:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002412:	ebbd                	bnez	a5,80002488 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002414:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002416:	0022f917          	auipc	s2,0x22f
    8000241a:	94a90913          	addi	s2,s2,-1718 # 80230d60 <cpus>
    8000241e:	2781                	sext.w	a5,a5
    80002420:	079e                	slli	a5,a5,0x7
    80002422:	97ca                	add	a5,a5,s2
    80002424:	07c7a983          	lw	s3,124(a5)
    80002428:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000242a:	2581                	sext.w	a1,a1
    8000242c:	059e                	slli	a1,a1,0x7
    8000242e:	05a1                	addi	a1,a1,8
    80002430:	95ca                	add	a1,a1,s2
    80002432:	06048513          	addi	a0,s1,96
    80002436:	00000097          	auipc	ra,0x0
    8000243a:	6e4080e7          	jalr	1764(ra) # 80002b1a <swtch>
    8000243e:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002440:	2781                	sext.w	a5,a5
    80002442:	079e                	slli	a5,a5,0x7
    80002444:	993e                	add	s2,s2,a5
    80002446:	07392e23          	sw	s3,124(s2)
}
    8000244a:	70a2                	ld	ra,40(sp)
    8000244c:	7402                	ld	s0,32(sp)
    8000244e:	64e2                	ld	s1,24(sp)
    80002450:	6942                	ld	s2,16(sp)
    80002452:	69a2                	ld	s3,8(sp)
    80002454:	6145                	addi	sp,sp,48
    80002456:	8082                	ret
        panic("sched p->lock");
    80002458:	00006517          	auipc	a0,0x6
    8000245c:	e1850513          	addi	a0,a0,-488 # 80008270 <digits+0x220>
    80002460:	ffffe097          	auipc	ra,0xffffe
    80002464:	0dc080e7          	jalr	220(ra) # 8000053c <panic>
        panic("sched locks");
    80002468:	00006517          	auipc	a0,0x6
    8000246c:	e1850513          	addi	a0,a0,-488 # 80008280 <digits+0x230>
    80002470:	ffffe097          	auipc	ra,0xffffe
    80002474:	0cc080e7          	jalr	204(ra) # 8000053c <panic>
        panic("sched running");
    80002478:	00006517          	auipc	a0,0x6
    8000247c:	e1850513          	addi	a0,a0,-488 # 80008290 <digits+0x240>
    80002480:	ffffe097          	auipc	ra,0xffffe
    80002484:	0bc080e7          	jalr	188(ra) # 8000053c <panic>
        panic("sched interruptible");
    80002488:	00006517          	auipc	a0,0x6
    8000248c:	e1850513          	addi	a0,a0,-488 # 800082a0 <digits+0x250>
    80002490:	ffffe097          	auipc	ra,0xffffe
    80002494:	0ac080e7          	jalr	172(ra) # 8000053c <panic>

0000000080002498 <yield>:
{
    80002498:	1101                	addi	sp,sp,-32
    8000249a:	ec06                	sd	ra,24(sp)
    8000249c:	e822                	sd	s0,16(sp)
    8000249e:	e426                	sd	s1,8(sp)
    800024a0:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	8ca080e7          	jalr	-1846(ra) # 80001d6c <myproc>
    800024aa:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800024ac:	fffff097          	auipc	ra,0xfffff
    800024b0:	92c080e7          	jalr	-1748(ra) # 80000dd8 <acquire>
    p->state = RUNNABLE;
    800024b4:	478d                	li	a5,3
    800024b6:	cc9c                	sw	a5,24(s1)
    sched();
    800024b8:	00000097          	auipc	ra,0x0
    800024bc:	f12080e7          	jalr	-238(ra) # 800023ca <sched>
    release(&p->lock);
    800024c0:	8526                	mv	a0,s1
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	9ca080e7          	jalr	-1590(ra) # 80000e8c <release>
}
    800024ca:	60e2                	ld	ra,24(sp)
    800024cc:	6442                	ld	s0,16(sp)
    800024ce:	64a2                	ld	s1,8(sp)
    800024d0:	6105                	addi	sp,sp,32
    800024d2:	8082                	ret

00000000800024d4 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800024d4:	7179                	addi	sp,sp,-48
    800024d6:	f406                	sd	ra,40(sp)
    800024d8:	f022                	sd	s0,32(sp)
    800024da:	ec26                	sd	s1,24(sp)
    800024dc:	e84a                	sd	s2,16(sp)
    800024de:	e44e                	sd	s3,8(sp)
    800024e0:	1800                	addi	s0,sp,48
    800024e2:	89aa                	mv	s3,a0
    800024e4:	892e                	mv	s2,a1
    struct proc *p = myproc();
    800024e6:	00000097          	auipc	ra,0x0
    800024ea:	886080e7          	jalr	-1914(ra) # 80001d6c <myproc>
    800024ee:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	8e8080e7          	jalr	-1816(ra) # 80000dd8 <acquire>
    release(lk);
    800024f8:	854a                	mv	a0,s2
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	992080e7          	jalr	-1646(ra) # 80000e8c <release>

    // Go to sleep.
    p->chan = chan;
    80002502:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002506:	4789                	li	a5,2
    80002508:	cc9c                	sw	a5,24(s1)

    sched();
    8000250a:	00000097          	auipc	ra,0x0
    8000250e:	ec0080e7          	jalr	-320(ra) # 800023ca <sched>

    // Tidy up.
    p->chan = 0;
    80002512:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002516:	8526                	mv	a0,s1
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	974080e7          	jalr	-1676(ra) # 80000e8c <release>
    acquire(lk);
    80002520:	854a                	mv	a0,s2
    80002522:	fffff097          	auipc	ra,0xfffff
    80002526:	8b6080e7          	jalr	-1866(ra) # 80000dd8 <acquire>
}
    8000252a:	70a2                	ld	ra,40(sp)
    8000252c:	7402                	ld	s0,32(sp)
    8000252e:	64e2                	ld	s1,24(sp)
    80002530:	6942                	ld	s2,16(sp)
    80002532:	69a2                	ld	s3,8(sp)
    80002534:	6145                	addi	sp,sp,48
    80002536:	8082                	ret

0000000080002538 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002538:	7139                	addi	sp,sp,-64
    8000253a:	fc06                	sd	ra,56(sp)
    8000253c:	f822                	sd	s0,48(sp)
    8000253e:	f426                	sd	s1,40(sp)
    80002540:	f04a                	sd	s2,32(sp)
    80002542:	ec4e                	sd	s3,24(sp)
    80002544:	e852                	sd	s4,16(sp)
    80002546:	e456                	sd	s5,8(sp)
    80002548:	0080                	addi	s0,sp,64
    8000254a:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000254c:	0022f497          	auipc	s1,0x22f
    80002550:	c4448493          	addi	s1,s1,-956 # 80231190 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002554:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002556:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002558:	00234917          	auipc	s2,0x234
    8000255c:	63890913          	addi	s2,s2,1592 # 80236b90 <tickslock>
    80002560:	a811                	j	80002574 <wakeup+0x3c>
            }
            release(&p->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	fffff097          	auipc	ra,0xfffff
    80002568:	928080e7          	jalr	-1752(ra) # 80000e8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000256c:	16848493          	addi	s1,s1,360
    80002570:	03248663          	beq	s1,s2,8000259c <wakeup+0x64>
        if (p != myproc())
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	7f8080e7          	jalr	2040(ra) # 80001d6c <myproc>
    8000257c:	fea488e3          	beq	s1,a0,8000256c <wakeup+0x34>
            acquire(&p->lock);
    80002580:	8526                	mv	a0,s1
    80002582:	fffff097          	auipc	ra,0xfffff
    80002586:	856080e7          	jalr	-1962(ra) # 80000dd8 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    8000258a:	4c9c                	lw	a5,24(s1)
    8000258c:	fd379be3          	bne	a5,s3,80002562 <wakeup+0x2a>
    80002590:	709c                	ld	a5,32(s1)
    80002592:	fd4798e3          	bne	a5,s4,80002562 <wakeup+0x2a>
                p->state = RUNNABLE;
    80002596:	0154ac23          	sw	s5,24(s1)
    8000259a:	b7e1                	j	80002562 <wakeup+0x2a>
        }
    }
}
    8000259c:	70e2                	ld	ra,56(sp)
    8000259e:	7442                	ld	s0,48(sp)
    800025a0:	74a2                	ld	s1,40(sp)
    800025a2:	7902                	ld	s2,32(sp)
    800025a4:	69e2                	ld	s3,24(sp)
    800025a6:	6a42                	ld	s4,16(sp)
    800025a8:	6aa2                	ld	s5,8(sp)
    800025aa:	6121                	addi	sp,sp,64
    800025ac:	8082                	ret

00000000800025ae <reparent>:
{
    800025ae:	7179                	addi	sp,sp,-48
    800025b0:	f406                	sd	ra,40(sp)
    800025b2:	f022                	sd	s0,32(sp)
    800025b4:	ec26                	sd	s1,24(sp)
    800025b6:	e84a                	sd	s2,16(sp)
    800025b8:	e44e                	sd	s3,8(sp)
    800025ba:	e052                	sd	s4,0(sp)
    800025bc:	1800                	addi	s0,sp,48
    800025be:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025c0:	0022f497          	auipc	s1,0x22f
    800025c4:	bd048493          	addi	s1,s1,-1072 # 80231190 <proc>
            pp->parent = initproc;
    800025c8:	00006a17          	auipc	s4,0x6
    800025cc:	520a0a13          	addi	s4,s4,1312 # 80008ae8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025d0:	00234997          	auipc	s3,0x234
    800025d4:	5c098993          	addi	s3,s3,1472 # 80236b90 <tickslock>
    800025d8:	a029                	j	800025e2 <reparent+0x34>
    800025da:	16848493          	addi	s1,s1,360
    800025de:	01348d63          	beq	s1,s3,800025f8 <reparent+0x4a>
        if (pp->parent == p)
    800025e2:	7c9c                	ld	a5,56(s1)
    800025e4:	ff279be3          	bne	a5,s2,800025da <reparent+0x2c>
            pp->parent = initproc;
    800025e8:	000a3503          	ld	a0,0(s4)
    800025ec:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    800025ee:	00000097          	auipc	ra,0x0
    800025f2:	f4a080e7          	jalr	-182(ra) # 80002538 <wakeup>
    800025f6:	b7d5                	j	800025da <reparent+0x2c>
}
    800025f8:	70a2                	ld	ra,40(sp)
    800025fa:	7402                	ld	s0,32(sp)
    800025fc:	64e2                	ld	s1,24(sp)
    800025fe:	6942                	ld	s2,16(sp)
    80002600:	69a2                	ld	s3,8(sp)
    80002602:	6a02                	ld	s4,0(sp)
    80002604:	6145                	addi	sp,sp,48
    80002606:	8082                	ret

0000000080002608 <exit>:
{
    80002608:	7179                	addi	sp,sp,-48
    8000260a:	f406                	sd	ra,40(sp)
    8000260c:	f022                	sd	s0,32(sp)
    8000260e:	ec26                	sd	s1,24(sp)
    80002610:	e84a                	sd	s2,16(sp)
    80002612:	e44e                	sd	s3,8(sp)
    80002614:	e052                	sd	s4,0(sp)
    80002616:	1800                	addi	s0,sp,48
    80002618:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	752080e7          	jalr	1874(ra) # 80001d6c <myproc>
    80002622:	89aa                	mv	s3,a0
    if (p == initproc)
    80002624:	00006797          	auipc	a5,0x6
    80002628:	4c47b783          	ld	a5,1220(a5) # 80008ae8 <initproc>
    8000262c:	0d050493          	addi	s1,a0,208
    80002630:	15050913          	addi	s2,a0,336
    80002634:	02a79363          	bne	a5,a0,8000265a <exit+0x52>
        panic("init exiting");
    80002638:	00006517          	auipc	a0,0x6
    8000263c:	c8050513          	addi	a0,a0,-896 # 800082b8 <digits+0x268>
    80002640:	ffffe097          	auipc	ra,0xffffe
    80002644:	efc080e7          	jalr	-260(ra) # 8000053c <panic>
            fileclose(f);
    80002648:	00002097          	auipc	ra,0x2
    8000264c:	5d0080e7          	jalr	1488(ra) # 80004c18 <fileclose>
            p->ofile[fd] = 0;
    80002650:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002654:	04a1                	addi	s1,s1,8
    80002656:	01248563          	beq	s1,s2,80002660 <exit+0x58>
        if (p->ofile[fd])
    8000265a:	6088                	ld	a0,0(s1)
    8000265c:	f575                	bnez	a0,80002648 <exit+0x40>
    8000265e:	bfdd                	j	80002654 <exit+0x4c>
    begin_op();
    80002660:	00002097          	auipc	ra,0x2
    80002664:	0f4080e7          	jalr	244(ra) # 80004754 <begin_op>
    iput(p->cwd);
    80002668:	1509b503          	ld	a0,336(s3)
    8000266c:	00002097          	auipc	ra,0x2
    80002670:	8fc080e7          	jalr	-1796(ra) # 80003f68 <iput>
    end_op();
    80002674:	00002097          	auipc	ra,0x2
    80002678:	15a080e7          	jalr	346(ra) # 800047ce <end_op>
    p->cwd = 0;
    8000267c:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002680:	0022f497          	auipc	s1,0x22f
    80002684:	af848493          	addi	s1,s1,-1288 # 80231178 <wait_lock>
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	74e080e7          	jalr	1870(ra) # 80000dd8 <acquire>
    reparent(p);
    80002692:	854e                	mv	a0,s3
    80002694:	00000097          	auipc	ra,0x0
    80002698:	f1a080e7          	jalr	-230(ra) # 800025ae <reparent>
    wakeup(p->parent);
    8000269c:	0389b503          	ld	a0,56(s3)
    800026a0:	00000097          	auipc	ra,0x0
    800026a4:	e98080e7          	jalr	-360(ra) # 80002538 <wakeup>
    acquire(&p->lock);
    800026a8:	854e                	mv	a0,s3
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	72e080e7          	jalr	1838(ra) # 80000dd8 <acquire>
    p->xstate = status;
    800026b2:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800026b6:	4795                	li	a5,5
    800026b8:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800026bc:	8526                	mv	a0,s1
    800026be:	ffffe097          	auipc	ra,0xffffe
    800026c2:	7ce080e7          	jalr	1998(ra) # 80000e8c <release>
    sched();
    800026c6:	00000097          	auipc	ra,0x0
    800026ca:	d04080e7          	jalr	-764(ra) # 800023ca <sched>
    panic("zombie exit");
    800026ce:	00006517          	auipc	a0,0x6
    800026d2:	bfa50513          	addi	a0,a0,-1030 # 800082c8 <digits+0x278>
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	e66080e7          	jalr	-410(ra) # 8000053c <panic>

00000000800026de <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800026de:	7179                	addi	sp,sp,-48
    800026e0:	f406                	sd	ra,40(sp)
    800026e2:	f022                	sd	s0,32(sp)
    800026e4:	ec26                	sd	s1,24(sp)
    800026e6:	e84a                	sd	s2,16(sp)
    800026e8:	e44e                	sd	s3,8(sp)
    800026ea:	1800                	addi	s0,sp,48
    800026ec:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800026ee:	0022f497          	auipc	s1,0x22f
    800026f2:	aa248493          	addi	s1,s1,-1374 # 80231190 <proc>
    800026f6:	00234997          	auipc	s3,0x234
    800026fa:	49a98993          	addi	s3,s3,1178 # 80236b90 <tickslock>
    {
        acquire(&p->lock);
    800026fe:	8526                	mv	a0,s1
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	6d8080e7          	jalr	1752(ra) # 80000dd8 <acquire>
        if (p->pid == pid)
    80002708:	589c                	lw	a5,48(s1)
    8000270a:	01278d63          	beq	a5,s2,80002724 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000270e:	8526                	mv	a0,s1
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	77c080e7          	jalr	1916(ra) # 80000e8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002718:	16848493          	addi	s1,s1,360
    8000271c:	ff3491e3          	bne	s1,s3,800026fe <kill+0x20>
    }
    return -1;
    80002720:	557d                	li	a0,-1
    80002722:	a829                	j	8000273c <kill+0x5e>
            p->killed = 1;
    80002724:	4785                	li	a5,1
    80002726:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002728:	4c98                	lw	a4,24(s1)
    8000272a:	4789                	li	a5,2
    8000272c:	00f70f63          	beq	a4,a5,8000274a <kill+0x6c>
            release(&p->lock);
    80002730:	8526                	mv	a0,s1
    80002732:	ffffe097          	auipc	ra,0xffffe
    80002736:	75a080e7          	jalr	1882(ra) # 80000e8c <release>
            return 0;
    8000273a:	4501                	li	a0,0
}
    8000273c:	70a2                	ld	ra,40(sp)
    8000273e:	7402                	ld	s0,32(sp)
    80002740:	64e2                	ld	s1,24(sp)
    80002742:	6942                	ld	s2,16(sp)
    80002744:	69a2                	ld	s3,8(sp)
    80002746:	6145                	addi	sp,sp,48
    80002748:	8082                	ret
                p->state = RUNNABLE;
    8000274a:	478d                	li	a5,3
    8000274c:	cc9c                	sw	a5,24(s1)
    8000274e:	b7cd                	j	80002730 <kill+0x52>

0000000080002750 <setkilled>:

void setkilled(struct proc *p)
{
    80002750:	1101                	addi	sp,sp,-32
    80002752:	ec06                	sd	ra,24(sp)
    80002754:	e822                	sd	s0,16(sp)
    80002756:	e426                	sd	s1,8(sp)
    80002758:	1000                	addi	s0,sp,32
    8000275a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000275c:	ffffe097          	auipc	ra,0xffffe
    80002760:	67c080e7          	jalr	1660(ra) # 80000dd8 <acquire>
    p->killed = 1;
    80002764:	4785                	li	a5,1
    80002766:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	722080e7          	jalr	1826(ra) # 80000e8c <release>
}
    80002772:	60e2                	ld	ra,24(sp)
    80002774:	6442                	ld	s0,16(sp)
    80002776:	64a2                	ld	s1,8(sp)
    80002778:	6105                	addi	sp,sp,32
    8000277a:	8082                	ret

000000008000277c <killed>:

int killed(struct proc *p)
{
    8000277c:	1101                	addi	sp,sp,-32
    8000277e:	ec06                	sd	ra,24(sp)
    80002780:	e822                	sd	s0,16(sp)
    80002782:	e426                	sd	s1,8(sp)
    80002784:	e04a                	sd	s2,0(sp)
    80002786:	1000                	addi	s0,sp,32
    80002788:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    8000278a:	ffffe097          	auipc	ra,0xffffe
    8000278e:	64e080e7          	jalr	1614(ra) # 80000dd8 <acquire>
    k = p->killed;
    80002792:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    80002796:	8526                	mv	a0,s1
    80002798:	ffffe097          	auipc	ra,0xffffe
    8000279c:	6f4080e7          	jalr	1780(ra) # 80000e8c <release>
    return k;
}
    800027a0:	854a                	mv	a0,s2
    800027a2:	60e2                	ld	ra,24(sp)
    800027a4:	6442                	ld	s0,16(sp)
    800027a6:	64a2                	ld	s1,8(sp)
    800027a8:	6902                	ld	s2,0(sp)
    800027aa:	6105                	addi	sp,sp,32
    800027ac:	8082                	ret

00000000800027ae <wait>:
{
    800027ae:	715d                	addi	sp,sp,-80
    800027b0:	e486                	sd	ra,72(sp)
    800027b2:	e0a2                	sd	s0,64(sp)
    800027b4:	fc26                	sd	s1,56(sp)
    800027b6:	f84a                	sd	s2,48(sp)
    800027b8:	f44e                	sd	s3,40(sp)
    800027ba:	f052                	sd	s4,32(sp)
    800027bc:	ec56                	sd	s5,24(sp)
    800027be:	e85a                	sd	s6,16(sp)
    800027c0:	e45e                	sd	s7,8(sp)
    800027c2:	e062                	sd	s8,0(sp)
    800027c4:	0880                	addi	s0,sp,80
    800027c6:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    800027c8:	fffff097          	auipc	ra,0xfffff
    800027cc:	5a4080e7          	jalr	1444(ra) # 80001d6c <myproc>
    800027d0:	892a                	mv	s2,a0
    acquire(&wait_lock);
    800027d2:	0022f517          	auipc	a0,0x22f
    800027d6:	9a650513          	addi	a0,a0,-1626 # 80231178 <wait_lock>
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	5fe080e7          	jalr	1534(ra) # 80000dd8 <acquire>
        havekids = 0;
    800027e2:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    800027e4:	4a15                	li	s4,5
                havekids = 1;
    800027e6:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800027e8:	00234997          	auipc	s3,0x234
    800027ec:	3a898993          	addi	s3,s3,936 # 80236b90 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027f0:	0022fc17          	auipc	s8,0x22f
    800027f4:	988c0c13          	addi	s8,s8,-1656 # 80231178 <wait_lock>
    800027f8:	a0d1                	j	800028bc <wait+0x10e>
                    pid = pp->pid;
    800027fa:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800027fe:	000b0e63          	beqz	s6,8000281a <wait+0x6c>
    80002802:	4691                	li	a3,4
    80002804:	02c48613          	addi	a2,s1,44
    80002808:	85da                	mv	a1,s6
    8000280a:	05093503          	ld	a0,80(s2)
    8000280e:	fffff097          	auipc	ra,0xfffff
    80002812:	116080e7          	jalr	278(ra) # 80001924 <copyout>
    80002816:	04054163          	bltz	a0,80002858 <wait+0xaa>
                    freeproc(pp);
    8000281a:	8526                	mv	a0,s1
    8000281c:	fffff097          	auipc	ra,0xfffff
    80002820:	702080e7          	jalr	1794(ra) # 80001f1e <freeproc>
                    release(&pp->lock);
    80002824:	8526                	mv	a0,s1
    80002826:	ffffe097          	auipc	ra,0xffffe
    8000282a:	666080e7          	jalr	1638(ra) # 80000e8c <release>
                    release(&wait_lock);
    8000282e:	0022f517          	auipc	a0,0x22f
    80002832:	94a50513          	addi	a0,a0,-1718 # 80231178 <wait_lock>
    80002836:	ffffe097          	auipc	ra,0xffffe
    8000283a:	656080e7          	jalr	1622(ra) # 80000e8c <release>
}
    8000283e:	854e                	mv	a0,s3
    80002840:	60a6                	ld	ra,72(sp)
    80002842:	6406                	ld	s0,64(sp)
    80002844:	74e2                	ld	s1,56(sp)
    80002846:	7942                	ld	s2,48(sp)
    80002848:	79a2                	ld	s3,40(sp)
    8000284a:	7a02                	ld	s4,32(sp)
    8000284c:	6ae2                	ld	s5,24(sp)
    8000284e:	6b42                	ld	s6,16(sp)
    80002850:	6ba2                	ld	s7,8(sp)
    80002852:	6c02                	ld	s8,0(sp)
    80002854:	6161                	addi	sp,sp,80
    80002856:	8082                	ret
                        release(&pp->lock);
    80002858:	8526                	mv	a0,s1
    8000285a:	ffffe097          	auipc	ra,0xffffe
    8000285e:	632080e7          	jalr	1586(ra) # 80000e8c <release>
                        release(&wait_lock);
    80002862:	0022f517          	auipc	a0,0x22f
    80002866:	91650513          	addi	a0,a0,-1770 # 80231178 <wait_lock>
    8000286a:	ffffe097          	auipc	ra,0xffffe
    8000286e:	622080e7          	jalr	1570(ra) # 80000e8c <release>
                        return -1;
    80002872:	59fd                	li	s3,-1
    80002874:	b7e9                	j	8000283e <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002876:	16848493          	addi	s1,s1,360
    8000287a:	03348463          	beq	s1,s3,800028a2 <wait+0xf4>
            if (pp->parent == p)
    8000287e:	7c9c                	ld	a5,56(s1)
    80002880:	ff279be3          	bne	a5,s2,80002876 <wait+0xc8>
                acquire(&pp->lock);
    80002884:	8526                	mv	a0,s1
    80002886:	ffffe097          	auipc	ra,0xffffe
    8000288a:	552080e7          	jalr	1362(ra) # 80000dd8 <acquire>
                if (pp->state == ZOMBIE)
    8000288e:	4c9c                	lw	a5,24(s1)
    80002890:	f74785e3          	beq	a5,s4,800027fa <wait+0x4c>
                release(&pp->lock);
    80002894:	8526                	mv	a0,s1
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	5f6080e7          	jalr	1526(ra) # 80000e8c <release>
                havekids = 1;
    8000289e:	8756                	mv	a4,s5
    800028a0:	bfd9                	j	80002876 <wait+0xc8>
        if (!havekids || killed(p))
    800028a2:	c31d                	beqz	a4,800028c8 <wait+0x11a>
    800028a4:	854a                	mv	a0,s2
    800028a6:	00000097          	auipc	ra,0x0
    800028aa:	ed6080e7          	jalr	-298(ra) # 8000277c <killed>
    800028ae:	ed09                	bnez	a0,800028c8 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800028b0:	85e2                	mv	a1,s8
    800028b2:	854a                	mv	a0,s2
    800028b4:	00000097          	auipc	ra,0x0
    800028b8:	c20080e7          	jalr	-992(ra) # 800024d4 <sleep>
        havekids = 0;
    800028bc:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800028be:	0022f497          	auipc	s1,0x22f
    800028c2:	8d248493          	addi	s1,s1,-1838 # 80231190 <proc>
    800028c6:	bf65                	j	8000287e <wait+0xd0>
            release(&wait_lock);
    800028c8:	0022f517          	auipc	a0,0x22f
    800028cc:	8b050513          	addi	a0,a0,-1872 # 80231178 <wait_lock>
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	5bc080e7          	jalr	1468(ra) # 80000e8c <release>
            return -1;
    800028d8:	59fd                	li	s3,-1
    800028da:	b795                	j	8000283e <wait+0x90>

00000000800028dc <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800028dc:	7179                	addi	sp,sp,-48
    800028de:	f406                	sd	ra,40(sp)
    800028e0:	f022                	sd	s0,32(sp)
    800028e2:	ec26                	sd	s1,24(sp)
    800028e4:	e84a                	sd	s2,16(sp)
    800028e6:	e44e                	sd	s3,8(sp)
    800028e8:	e052                	sd	s4,0(sp)
    800028ea:	1800                	addi	s0,sp,48
    800028ec:	84aa                	mv	s1,a0
    800028ee:	892e                	mv	s2,a1
    800028f0:	89b2                	mv	s3,a2
    800028f2:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028f4:	fffff097          	auipc	ra,0xfffff
    800028f8:	478080e7          	jalr	1144(ra) # 80001d6c <myproc>
    if (user_dst)
    800028fc:	c08d                	beqz	s1,8000291e <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    800028fe:	86d2                	mv	a3,s4
    80002900:	864e                	mv	a2,s3
    80002902:	85ca                	mv	a1,s2
    80002904:	6928                	ld	a0,80(a0)
    80002906:	fffff097          	auipc	ra,0xfffff
    8000290a:	01e080e7          	jalr	30(ra) # 80001924 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000290e:	70a2                	ld	ra,40(sp)
    80002910:	7402                	ld	s0,32(sp)
    80002912:	64e2                	ld	s1,24(sp)
    80002914:	6942                	ld	s2,16(sp)
    80002916:	69a2                	ld	s3,8(sp)
    80002918:	6a02                	ld	s4,0(sp)
    8000291a:	6145                	addi	sp,sp,48
    8000291c:	8082                	ret
        memmove((char *)dst, src, len);
    8000291e:	000a061b          	sext.w	a2,s4
    80002922:	85ce                	mv	a1,s3
    80002924:	854a                	mv	a0,s2
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	60a080e7          	jalr	1546(ra) # 80000f30 <memmove>
        return 0;
    8000292e:	8526                	mv	a0,s1
    80002930:	bff9                	j	8000290e <either_copyout+0x32>

0000000080002932 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002932:	7179                	addi	sp,sp,-48
    80002934:	f406                	sd	ra,40(sp)
    80002936:	f022                	sd	s0,32(sp)
    80002938:	ec26                	sd	s1,24(sp)
    8000293a:	e84a                	sd	s2,16(sp)
    8000293c:	e44e                	sd	s3,8(sp)
    8000293e:	e052                	sd	s4,0(sp)
    80002940:	1800                	addi	s0,sp,48
    80002942:	892a                	mv	s2,a0
    80002944:	84ae                	mv	s1,a1
    80002946:	89b2                	mv	s3,a2
    80002948:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	422080e7          	jalr	1058(ra) # 80001d6c <myproc>
    if (user_src)
    80002952:	c08d                	beqz	s1,80002974 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002954:	86d2                	mv	a3,s4
    80002956:	864e                	mv	a2,s3
    80002958:	85ca                	mv	a1,s2
    8000295a:	6928                	ld	a0,80(a0)
    8000295c:	fffff097          	auipc	ra,0xfffff
    80002960:	068080e7          	jalr	104(ra) # 800019c4 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    80002964:	70a2                	ld	ra,40(sp)
    80002966:	7402                	ld	s0,32(sp)
    80002968:	64e2                	ld	s1,24(sp)
    8000296a:	6942                	ld	s2,16(sp)
    8000296c:	69a2                	ld	s3,8(sp)
    8000296e:	6a02                	ld	s4,0(sp)
    80002970:	6145                	addi	sp,sp,48
    80002972:	8082                	ret
        memmove(dst, (char *)src, len);
    80002974:	000a061b          	sext.w	a2,s4
    80002978:	85ce                	mv	a1,s3
    8000297a:	854a                	mv	a0,s2
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	5b4080e7          	jalr	1460(ra) # 80000f30 <memmove>
        return 0;
    80002984:	8526                	mv	a0,s1
    80002986:	bff9                	j	80002964 <either_copyin+0x32>

0000000080002988 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002988:	715d                	addi	sp,sp,-80
    8000298a:	e486                	sd	ra,72(sp)
    8000298c:	e0a2                	sd	s0,64(sp)
    8000298e:	fc26                	sd	s1,56(sp)
    80002990:	f84a                	sd	s2,48(sp)
    80002992:	f44e                	sd	s3,40(sp)
    80002994:	f052                	sd	s4,32(sp)
    80002996:	ec56                	sd	s5,24(sp)
    80002998:	e85a                	sd	s6,16(sp)
    8000299a:	e45e                	sd	s7,8(sp)
    8000299c:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    8000299e:	00005517          	auipc	a0,0x5
    800029a2:	70250513          	addi	a0,a0,1794 # 800080a0 <digits+0x50>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	bf2080e7          	jalr	-1038(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800029ae:	0022f497          	auipc	s1,0x22f
    800029b2:	93a48493          	addi	s1,s1,-1734 # 802312e8 <proc+0x158>
    800029b6:	00234917          	auipc	s2,0x234
    800029ba:	33290913          	addi	s2,s2,818 # 80236ce8 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029be:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    800029c0:	00006997          	auipc	s3,0x6
    800029c4:	91898993          	addi	s3,s3,-1768 # 800082d8 <digits+0x288>
        printf("%d <%s %s", p->pid, state, p->name);
    800029c8:	00006a97          	auipc	s5,0x6
    800029cc:	918a8a93          	addi	s5,s5,-1768 # 800082e0 <digits+0x290>
        printf("\n");
    800029d0:	00005a17          	auipc	s4,0x5
    800029d4:	6d0a0a13          	addi	s4,s4,1744 # 800080a0 <digits+0x50>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029d8:	00006b97          	auipc	s7,0x6
    800029dc:	a18b8b93          	addi	s7,s7,-1512 # 800083f0 <states.0>
    800029e0:	a00d                	j	80002a02 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    800029e2:	ed86a583          	lw	a1,-296(a3)
    800029e6:	8556                	mv	a0,s5
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	bb0080e7          	jalr	-1104(ra) # 80000598 <printf>
        printf("\n");
    800029f0:	8552                	mv	a0,s4
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	ba6080e7          	jalr	-1114(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800029fa:	16848493          	addi	s1,s1,360
    800029fe:	03248263          	beq	s1,s2,80002a22 <procdump+0x9a>
        if (p->state == UNUSED)
    80002a02:	86a6                	mv	a3,s1
    80002a04:	ec04a783          	lw	a5,-320(s1)
    80002a08:	dbed                	beqz	a5,800029fa <procdump+0x72>
            state = "???";
    80002a0a:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a0c:	fcfb6be3          	bltu	s6,a5,800029e2 <procdump+0x5a>
    80002a10:	02079713          	slli	a4,a5,0x20
    80002a14:	01d75793          	srli	a5,a4,0x1d
    80002a18:	97de                	add	a5,a5,s7
    80002a1a:	6390                	ld	a2,0(a5)
    80002a1c:	f279                	bnez	a2,800029e2 <procdump+0x5a>
            state = "???";
    80002a1e:	864e                	mv	a2,s3
    80002a20:	b7c9                	j	800029e2 <procdump+0x5a>
    }
}
    80002a22:	60a6                	ld	ra,72(sp)
    80002a24:	6406                	ld	s0,64(sp)
    80002a26:	74e2                	ld	s1,56(sp)
    80002a28:	7942                	ld	s2,48(sp)
    80002a2a:	79a2                	ld	s3,40(sp)
    80002a2c:	7a02                	ld	s4,32(sp)
    80002a2e:	6ae2                	ld	s5,24(sp)
    80002a30:	6b42                	ld	s6,16(sp)
    80002a32:	6ba2                	ld	s7,8(sp)
    80002a34:	6161                	addi	sp,sp,80
    80002a36:	8082                	ret

0000000080002a38 <schedls>:

void schedls()
{
    80002a38:	1141                	addi	sp,sp,-16
    80002a3a:	e406                	sd	ra,8(sp)
    80002a3c:	e022                	sd	s0,0(sp)
    80002a3e:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002a40:	00006517          	auipc	a0,0x6
    80002a44:	8b050513          	addi	a0,a0,-1872 # 800082f0 <digits+0x2a0>
    80002a48:	ffffe097          	auipc	ra,0xffffe
    80002a4c:	b50080e7          	jalr	-1200(ra) # 80000598 <printf>
    printf("====================================\n");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	8c850513          	addi	a0,a0,-1848 # 80008318 <digits+0x2c8>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	b40080e7          	jalr	-1216(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002a60:	00006717          	auipc	a4,0x6
    80002a64:	03873703          	ld	a4,56(a4) # 80008a98 <available_schedulers+0x10>
    80002a68:	00006797          	auipc	a5,0x6
    80002a6c:	fd07b783          	ld	a5,-48(a5) # 80008a38 <sched_pointer>
    80002a70:	04f70663          	beq	a4,a5,80002abc <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002a74:	00006517          	auipc	a0,0x6
    80002a78:	8d450513          	addi	a0,a0,-1836 # 80008348 <digits+0x2f8>
    80002a7c:	ffffe097          	auipc	ra,0xffffe
    80002a80:	b1c080e7          	jalr	-1252(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a84:	00006617          	auipc	a2,0x6
    80002a88:	01c62603          	lw	a2,28(a2) # 80008aa0 <available_schedulers+0x18>
    80002a8c:	00006597          	auipc	a1,0x6
    80002a90:	ffc58593          	addi	a1,a1,-4 # 80008a88 <available_schedulers>
    80002a94:	00006517          	auipc	a0,0x6
    80002a98:	8bc50513          	addi	a0,a0,-1860 # 80008350 <digits+0x300>
    80002a9c:	ffffe097          	auipc	ra,0xffffe
    80002aa0:	afc080e7          	jalr	-1284(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002aa4:	00006517          	auipc	a0,0x6
    80002aa8:	8b450513          	addi	a0,a0,-1868 # 80008358 <digits+0x308>
    80002aac:	ffffe097          	auipc	ra,0xffffe
    80002ab0:	aec080e7          	jalr	-1300(ra) # 80000598 <printf>
}
    80002ab4:	60a2                	ld	ra,8(sp)
    80002ab6:	6402                	ld	s0,0(sp)
    80002ab8:	0141                	addi	sp,sp,16
    80002aba:	8082                	ret
            printf("[*]\t");
    80002abc:	00006517          	auipc	a0,0x6
    80002ac0:	88450513          	addi	a0,a0,-1916 # 80008340 <digits+0x2f0>
    80002ac4:	ffffe097          	auipc	ra,0xffffe
    80002ac8:	ad4080e7          	jalr	-1324(ra) # 80000598 <printf>
    80002acc:	bf65                	j	80002a84 <schedls+0x4c>

0000000080002ace <schedset>:

void schedset(int id)
{
    80002ace:	1141                	addi	sp,sp,-16
    80002ad0:	e406                	sd	ra,8(sp)
    80002ad2:	e022                	sd	s0,0(sp)
    80002ad4:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002ad6:	e90d                	bnez	a0,80002b08 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002ad8:	00006797          	auipc	a5,0x6
    80002adc:	fc07b783          	ld	a5,-64(a5) # 80008a98 <available_schedulers+0x10>
    80002ae0:	00006717          	auipc	a4,0x6
    80002ae4:	f4f73c23          	sd	a5,-168(a4) # 80008a38 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002ae8:	00006597          	auipc	a1,0x6
    80002aec:	fa058593          	addi	a1,a1,-96 # 80008a88 <available_schedulers>
    80002af0:	00006517          	auipc	a0,0x6
    80002af4:	8a850513          	addi	a0,a0,-1880 # 80008398 <digits+0x348>
    80002af8:	ffffe097          	auipc	ra,0xffffe
    80002afc:	aa0080e7          	jalr	-1376(ra) # 80000598 <printf>
    80002b00:	60a2                	ld	ra,8(sp)
    80002b02:	6402                	ld	s0,0(sp)
    80002b04:	0141                	addi	sp,sp,16
    80002b06:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002b08:	00006517          	auipc	a0,0x6
    80002b0c:	86850513          	addi	a0,a0,-1944 # 80008370 <digits+0x320>
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	a88080e7          	jalr	-1400(ra) # 80000598 <printf>
        return;
    80002b18:	b7e5                	j	80002b00 <schedset+0x32>

0000000080002b1a <swtch>:
    80002b1a:	00153023          	sd	ra,0(a0)
    80002b1e:	00253423          	sd	sp,8(a0)
    80002b22:	e900                	sd	s0,16(a0)
    80002b24:	ed04                	sd	s1,24(a0)
    80002b26:	03253023          	sd	s2,32(a0)
    80002b2a:	03353423          	sd	s3,40(a0)
    80002b2e:	03453823          	sd	s4,48(a0)
    80002b32:	03553c23          	sd	s5,56(a0)
    80002b36:	05653023          	sd	s6,64(a0)
    80002b3a:	05753423          	sd	s7,72(a0)
    80002b3e:	05853823          	sd	s8,80(a0)
    80002b42:	05953c23          	sd	s9,88(a0)
    80002b46:	07a53023          	sd	s10,96(a0)
    80002b4a:	07b53423          	sd	s11,104(a0)
    80002b4e:	0005b083          	ld	ra,0(a1)
    80002b52:	0085b103          	ld	sp,8(a1)
    80002b56:	6980                	ld	s0,16(a1)
    80002b58:	6d84                	ld	s1,24(a1)
    80002b5a:	0205b903          	ld	s2,32(a1)
    80002b5e:	0285b983          	ld	s3,40(a1)
    80002b62:	0305ba03          	ld	s4,48(a1)
    80002b66:	0385ba83          	ld	s5,56(a1)
    80002b6a:	0405bb03          	ld	s6,64(a1)
    80002b6e:	0485bb83          	ld	s7,72(a1)
    80002b72:	0505bc03          	ld	s8,80(a1)
    80002b76:	0585bc83          	ld	s9,88(a1)
    80002b7a:	0605bd03          	ld	s10,96(a1)
    80002b7e:	0685bd83          	ld	s11,104(a1)
    80002b82:	8082                	ret

0000000080002b84 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b84:	1141                	addi	sp,sp,-16
    80002b86:	e406                	sd	ra,8(sp)
    80002b88:	e022                	sd	s0,0(sp)
    80002b8a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b8c:	00006597          	auipc	a1,0x6
    80002b90:	89458593          	addi	a1,a1,-1900 # 80008420 <states.0+0x30>
    80002b94:	00234517          	auipc	a0,0x234
    80002b98:	ffc50513          	addi	a0,a0,-4 # 80236b90 <tickslock>
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	1ac080e7          	jalr	428(ra) # 80000d48 <initlock>
}
    80002ba4:	60a2                	ld	ra,8(sp)
    80002ba6:	6402                	ld	s0,0(sp)
    80002ba8:	0141                	addi	sp,sp,16
    80002baa:	8082                	ret

0000000080002bac <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bac:	1141                	addi	sp,sp,-16
    80002bae:	e422                	sd	s0,8(sp)
    80002bb0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb2:	00003797          	auipc	a5,0x3
    80002bb6:	68e78793          	addi	a5,a5,1678 # 80006240 <kernelvec>
    80002bba:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bbe:	6422                	ld	s0,8(sp)
    80002bc0:	0141                	addi	sp,sp,16
    80002bc2:	8082                	ret

0000000080002bc4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bc4:	1141                	addi	sp,sp,-16
    80002bc6:	e406                	sd	ra,8(sp)
    80002bc8:	e022                	sd	s0,0(sp)
    80002bca:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bcc:	fffff097          	auipc	ra,0xfffff
    80002bd0:	1a0080e7          	jalr	416(ra) # 80001d6c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bd8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bda:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bde:	00004697          	auipc	a3,0x4
    80002be2:	42268693          	addi	a3,a3,1058 # 80007000 <_trampoline>
    80002be6:	00004717          	auipc	a4,0x4
    80002bea:	41a70713          	addi	a4,a4,1050 # 80007000 <_trampoline>
    80002bee:	8f15                	sub	a4,a4,a3
    80002bf0:	040007b7          	lui	a5,0x4000
    80002bf4:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bf6:	07b2                	slli	a5,a5,0xc
    80002bf8:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bfa:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bfe:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c00:	18002673          	csrr	a2,satp
    80002c04:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c06:	6d30                	ld	a2,88(a0)
    80002c08:	6138                	ld	a4,64(a0)
    80002c0a:	6585                	lui	a1,0x1
    80002c0c:	972e                	add	a4,a4,a1
    80002c0e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c10:	6d38                	ld	a4,88(a0)
    80002c12:	00000617          	auipc	a2,0x0
    80002c16:	2a860613          	addi	a2,a2,680 # 80002eba <usertrap>
    80002c1a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c1c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c1e:	8612                	mv	a2,tp
    80002c20:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c22:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c26:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c2a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c32:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c34:	6f18                	ld	a4,24(a4)
    80002c36:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c3a:	6928                	ld	a0,80(a0)
    80002c3c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c3e:	00004717          	auipc	a4,0x4
    80002c42:	45e70713          	addi	a4,a4,1118 # 8000709c <userret>
    80002c46:	8f15                	sub	a4,a4,a3
    80002c48:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c4a:	577d                	li	a4,-1
    80002c4c:	177e                	slli	a4,a4,0x3f
    80002c4e:	8d59                	or	a0,a0,a4
    80002c50:	9782                	jalr	a5
}
    80002c52:	60a2                	ld	ra,8(sp)
    80002c54:	6402                	ld	s0,0(sp)
    80002c56:	0141                	addi	sp,sp,16
    80002c58:	8082                	ret

0000000080002c5a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c5a:	1101                	addi	sp,sp,-32
    80002c5c:	ec06                	sd	ra,24(sp)
    80002c5e:	e822                	sd	s0,16(sp)
    80002c60:	e426                	sd	s1,8(sp)
    80002c62:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c64:	00234497          	auipc	s1,0x234
    80002c68:	f2c48493          	addi	s1,s1,-212 # 80236b90 <tickslock>
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	16a080e7          	jalr	362(ra) # 80000dd8 <acquire>
  ticks++;
    80002c76:	00006517          	auipc	a0,0x6
    80002c7a:	e7a50513          	addi	a0,a0,-390 # 80008af0 <ticks>
    80002c7e:	411c                	lw	a5,0(a0)
    80002c80:	2785                	addiw	a5,a5,1
    80002c82:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c84:	00000097          	auipc	ra,0x0
    80002c88:	8b4080e7          	jalr	-1868(ra) # 80002538 <wakeup>
  release(&tickslock);
    80002c8c:	8526                	mv	a0,s1
    80002c8e:	ffffe097          	auipc	ra,0xffffe
    80002c92:	1fe080e7          	jalr	510(ra) # 80000e8c <release>
}
    80002c96:	60e2                	ld	ra,24(sp)
    80002c98:	6442                	ld	s0,16(sp)
    80002c9a:	64a2                	ld	s1,8(sp)
    80002c9c:	6105                	addi	sp,sp,32
    80002c9e:	8082                	ret

0000000080002ca0 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca0:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ca4:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002ca6:	0807df63          	bgez	a5,80002d44 <devintr+0xa4>
{
    80002caa:	1101                	addi	sp,sp,-32
    80002cac:	ec06                	sd	ra,24(sp)
    80002cae:	e822                	sd	s0,16(sp)
    80002cb0:	e426                	sd	s1,8(sp)
    80002cb2:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002cb4:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002cb8:	46a5                	li	a3,9
    80002cba:	00d70d63          	beq	a4,a3,80002cd4 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002cbe:	577d                	li	a4,-1
    80002cc0:	177e                	slli	a4,a4,0x3f
    80002cc2:	0705                	addi	a4,a4,1
    return 0;
    80002cc4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cc6:	04e78e63          	beq	a5,a4,80002d22 <devintr+0x82>
  }
}
    80002cca:	60e2                	ld	ra,24(sp)
    80002ccc:	6442                	ld	s0,16(sp)
    80002cce:	64a2                	ld	s1,8(sp)
    80002cd0:	6105                	addi	sp,sp,32
    80002cd2:	8082                	ret
    int irq = plic_claim();
    80002cd4:	00003097          	auipc	ra,0x3
    80002cd8:	674080e7          	jalr	1652(ra) # 80006348 <plic_claim>
    80002cdc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cde:	47a9                	li	a5,10
    80002ce0:	02f50763          	beq	a0,a5,80002d0e <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002ce4:	4785                	li	a5,1
    80002ce6:	02f50963          	beq	a0,a5,80002d18 <devintr+0x78>
    return 1;
    80002cea:	4505                	li	a0,1
    } else if(irq){
    80002cec:	dcf9                	beqz	s1,80002cca <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cee:	85a6                	mv	a1,s1
    80002cf0:	00005517          	auipc	a0,0x5
    80002cf4:	73850513          	addi	a0,a0,1848 # 80008428 <states.0+0x38>
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	8a0080e7          	jalr	-1888(ra) # 80000598 <printf>
      plic_complete(irq);
    80002d00:	8526                	mv	a0,s1
    80002d02:	00003097          	auipc	ra,0x3
    80002d06:	66a080e7          	jalr	1642(ra) # 8000636c <plic_complete>
    return 1;
    80002d0a:	4505                	li	a0,1
    80002d0c:	bf7d                	j	80002cca <devintr+0x2a>
      uartintr();
    80002d0e:	ffffe097          	auipc	ra,0xffffe
    80002d12:	c98080e7          	jalr	-872(ra) # 800009a6 <uartintr>
    if(irq)
    80002d16:	b7ed                	j	80002d00 <devintr+0x60>
      virtio_disk_intr();
    80002d18:	00004097          	auipc	ra,0x4
    80002d1c:	b1a080e7          	jalr	-1254(ra) # 80006832 <virtio_disk_intr>
    if(irq)
    80002d20:	b7c5                	j	80002d00 <devintr+0x60>
    if(cpuid() == 0){
    80002d22:	fffff097          	auipc	ra,0xfffff
    80002d26:	01e080e7          	jalr	30(ra) # 80001d40 <cpuid>
    80002d2a:	c901                	beqz	a0,80002d3a <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d2c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d30:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d32:	14479073          	csrw	sip,a5
    return 2;
    80002d36:	4509                	li	a0,2
    80002d38:	bf49                	j	80002cca <devintr+0x2a>
      clockintr();
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	f20080e7          	jalr	-224(ra) # 80002c5a <clockintr>
    80002d42:	b7ed                	j	80002d2c <devintr+0x8c>
}
    80002d44:	8082                	ret

0000000080002d46 <kerneltrap>:
{
    80002d46:	7179                	addi	sp,sp,-48
    80002d48:	f406                	sd	ra,40(sp)
    80002d4a:	f022                	sd	s0,32(sp)
    80002d4c:	ec26                	sd	s1,24(sp)
    80002d4e:	e84a                	sd	s2,16(sp)
    80002d50:	e44e                	sd	s3,8(sp)
    80002d52:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d54:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d58:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d5c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002d60:	1004f793          	andi	a5,s1,256
    80002d64:	cb85                	beqz	a5,80002d94 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d66:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002d6a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002d6c:	ef85                	bnez	a5,80002da4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002d6e:	00000097          	auipc	ra,0x0
    80002d72:	f32080e7          	jalr	-206(ra) # 80002ca0 <devintr>
    80002d76:	cd1d                	beqz	a0,80002db4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d78:	4789                	li	a5,2
    80002d7a:	06f50a63          	beq	a0,a5,80002dee <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002d7e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002d82:	10049073          	csrw	sstatus,s1
}
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	64e2                	ld	s1,24(sp)
    80002d8c:	6942                	ld	s2,16(sp)
    80002d8e:	69a2                	ld	s3,8(sp)
    80002d90:	6145                	addi	sp,sp,48
    80002d92:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002d94:	00005517          	auipc	a0,0x5
    80002d98:	6b450513          	addi	a0,a0,1716 # 80008448 <states.0+0x58>
    80002d9c:	ffffd097          	auipc	ra,0xffffd
    80002da0:	7a0080e7          	jalr	1952(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002da4:	00005517          	auipc	a0,0x5
    80002da8:	6cc50513          	addi	a0,a0,1740 # 80008470 <states.0+0x80>
    80002dac:	ffffd097          	auipc	ra,0xffffd
    80002db0:	790080e7          	jalr	1936(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002db4:	85ce                	mv	a1,s3
    80002db6:	00005517          	auipc	a0,0x5
    80002dba:	6da50513          	addi	a0,a0,1754 # 80008490 <states.0+0xa0>
    80002dbe:	ffffd097          	auipc	ra,0xffffd
    80002dc2:	7da080e7          	jalr	2010(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002dc6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002dca:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002dce:	00005517          	auipc	a0,0x5
    80002dd2:	6d250513          	addi	a0,a0,1746 # 800084a0 <states.0+0xb0>
    80002dd6:	ffffd097          	auipc	ra,0xffffd
    80002dda:	7c2080e7          	jalr	1986(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002dde:	00005517          	auipc	a0,0x5
    80002de2:	6da50513          	addi	a0,a0,1754 # 800084b8 <states.0+0xc8>
    80002de6:	ffffd097          	auipc	ra,0xffffd
    80002dea:	756080e7          	jalr	1878(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002dee:	fffff097          	auipc	ra,0xfffff
    80002df2:	f7e080e7          	jalr	-130(ra) # 80001d6c <myproc>
    80002df6:	d541                	beqz	a0,80002d7e <kerneltrap+0x38>
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	f74080e7          	jalr	-140(ra) # 80001d6c <myproc>
    80002e00:	4d18                	lw	a4,24(a0)
    80002e02:	4791                	li	a5,4
    80002e04:	f6f71de3          	bne	a4,a5,80002d7e <kerneltrap+0x38>
    yield();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	690080e7          	jalr	1680(ra) # 80002498 <yield>
    80002e10:	b7bd                	j	80002d7e <kerneltrap+0x38>

0000000080002e12 <handle_page_fault>:

int
 handle_page_fault(pagetable_t pagetable, uint64 va)
 {
    80002e12:	7179                	addi	sp,sp,-48
    80002e14:	f406                	sd	ra,40(sp)
    80002e16:	f022                	sd	s0,32(sp)
    80002e18:	ec26                	sd	s1,24(sp)
    80002e1a:	e84a                	sd	s2,16(sp)
    80002e1c:	e44e                	sd	s3,8(sp)
    80002e1e:	1800                	addi	s0,sp,48
   if (va >= MAXVA) {
    80002e20:	57fd                	li	a5,-1
    80002e22:	83e9                	srli	a5,a5,0x1a
    80002e24:	04b7ed63          	bltu	a5,a1,80002e7e <handle_page_fault+0x6c>
    printf("Virtual adress too large (from handle_page_fault)");
    return -1;
   }

   pte_t* pte = walk(pagetable, va, 0);
    80002e28:	4601                	li	a2,0
    80002e2a:	ffffe097          	auipc	ra,0xffffe
    80002e2e:	38c080e7          	jalr	908(ra) # 800011b6 <walk>
    80002e32:	89aa                	mv	s3,a0
   if (pte == 0) {
    80002e34:	cd39                	beqz	a0,80002e92 <handle_page_fault+0x80>
    printf("Error getting page table entry (from handle_page_fault)");
    return -1;
   }

   uint64 pa1 = PTE2PA(*pte);
    80002e36:	00053903          	ld	s2,0(a0)
    80002e3a:	00a95913          	srli	s2,s2,0xa
    80002e3e:	0932                	slli	s2,s2,0xc
   uint64 pa2 = (uint64) kalloc();
    80002e40:	ffffe097          	auipc	ra,0xffffe
    80002e44:	e1e080e7          	jalr	-482(ra) # 80000c5e <kalloc>
    80002e48:	84aa                	mv	s1,a0
   if (pa2 == 0) {
    80002e4a:	cd31                	beqz	a0,80002ea6 <handle_page_fault+0x94>
     printf("kalloc in handle_page_fault failed\n");
     return -1;
   }

   memmove((void*) pa2, (void*) pa1, PGSIZE);
    80002e4c:	6605                	lui	a2,0x1
    80002e4e:	85ca                	mv	a1,s2
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	0e0080e7          	jalr	224(ra) # 80000f30 <memmove>
   kfree((void*) pa1);
    80002e58:	854a                	mv	a0,s2
    80002e5a:	ffffe097          	auipc	ra,0xffffe
    80002e5e:	c18080e7          	jalr	-1000(ra) # 80000a72 <kfree>

   *pte = PA2PTE(pa2) | PTE_V | PTE_U | PTE_R | PTE_W | PTE_X;
    80002e62:	80b1                	srli	s1,s1,0xc
    80002e64:	04aa                	slli	s1,s1,0xa
    80002e66:	01f4e493          	ori	s1,s1,31
    80002e6a:	0099b023          	sd	s1,0(s3)

   return 0;
    80002e6e:	4501                	li	a0,0
 }
    80002e70:	70a2                	ld	ra,40(sp)
    80002e72:	7402                	ld	s0,32(sp)
    80002e74:	64e2                	ld	s1,24(sp)
    80002e76:	6942                	ld	s2,16(sp)
    80002e78:	69a2                	ld	s3,8(sp)
    80002e7a:	6145                	addi	sp,sp,48
    80002e7c:	8082                	ret
    printf("Virtual adress too large (from handle_page_fault)");
    80002e7e:	00005517          	auipc	a0,0x5
    80002e82:	64a50513          	addi	a0,a0,1610 # 800084c8 <states.0+0xd8>
    80002e86:	ffffd097          	auipc	ra,0xffffd
    80002e8a:	712080e7          	jalr	1810(ra) # 80000598 <printf>
    return -1;
    80002e8e:	557d                	li	a0,-1
    80002e90:	b7c5                	j	80002e70 <handle_page_fault+0x5e>
    printf("Error getting page table entry (from handle_page_fault)");
    80002e92:	00005517          	auipc	a0,0x5
    80002e96:	66e50513          	addi	a0,a0,1646 # 80008500 <states.0+0x110>
    80002e9a:	ffffd097          	auipc	ra,0xffffd
    80002e9e:	6fe080e7          	jalr	1790(ra) # 80000598 <printf>
    return -1;
    80002ea2:	557d                	li	a0,-1
    80002ea4:	b7f1                	j	80002e70 <handle_page_fault+0x5e>
     printf("kalloc in handle_page_fault failed\n");
    80002ea6:	00005517          	auipc	a0,0x5
    80002eaa:	69250513          	addi	a0,a0,1682 # 80008538 <states.0+0x148>
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6ea080e7          	jalr	1770(ra) # 80000598 <printf>
     return -1;
    80002eb6:	557d                	li	a0,-1
    80002eb8:	bf65                	j	80002e70 <handle_page_fault+0x5e>

0000000080002eba <usertrap>:
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	e426                	sd	s1,8(sp)
    80002ec2:	e04a                	sd	s2,0(sp)
    80002ec4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ec6:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002eca:	1007f793          	andi	a5,a5,256
    80002ece:	efad                	bnez	a5,80002f48 <usertrap+0x8e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ed0:	00003797          	auipc	a5,0x3
    80002ed4:	37078793          	addi	a5,a5,880 # 80006240 <kernelvec>
    80002ed8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	e90080e7          	jalr	-368(ra) # 80001d6c <myproc>
    80002ee4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002ee6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ee8:	14102773          	csrr	a4,sepc
    80002eec:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002eee:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002ef2:	47a1                	li	a5,8
    80002ef4:	06f70263          	beq	a4,a5,80002f58 <usertrap+0x9e>
  } else if((which_dev = devintr()) != 0){
    80002ef8:	00000097          	auipc	ra,0x0
    80002efc:	da8080e7          	jalr	-600(ra) # 80002ca0 <devintr>
    80002f00:	892a                	mv	s2,a0
    80002f02:	e161                	bnez	a0,80002fc2 <usertrap+0x108>
    80002f04:	14202773          	csrr	a4,scause
  } else if (r_scause() == 0xf) {
    80002f08:	47bd                	li	a5,15
    80002f0a:	0af70063          	beq	a4,a5,80002faa <usertrap+0xf0>
    80002f0e:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f12:	5890                	lw	a2,48(s1)
    80002f14:	00005517          	auipc	a0,0x5
    80002f18:	66c50513          	addi	a0,a0,1644 # 80008580 <states.0+0x190>
    80002f1c:	ffffd097          	auipc	ra,0xffffd
    80002f20:	67c080e7          	jalr	1660(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f24:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f28:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f2c:	00005517          	auipc	a0,0x5
    80002f30:	68450513          	addi	a0,a0,1668 # 800085b0 <states.0+0x1c0>
    80002f34:	ffffd097          	auipc	ra,0xffffd
    80002f38:	664080e7          	jalr	1636(ra) # 80000598 <printf>
    setkilled(p);
    80002f3c:	8526                	mv	a0,s1
    80002f3e:	00000097          	auipc	ra,0x0
    80002f42:	812080e7          	jalr	-2030(ra) # 80002750 <setkilled>
    80002f46:	a825                	j	80002f7e <usertrap+0xc4>
    panic("usertrap: not from user mode");
    80002f48:	00005517          	auipc	a0,0x5
    80002f4c:	61850513          	addi	a0,a0,1560 # 80008560 <states.0+0x170>
    80002f50:	ffffd097          	auipc	ra,0xffffd
    80002f54:	5ec080e7          	jalr	1516(ra) # 8000053c <panic>
    if(killed(p))
    80002f58:	00000097          	auipc	ra,0x0
    80002f5c:	824080e7          	jalr	-2012(ra) # 8000277c <killed>
    80002f60:	ed1d                	bnez	a0,80002f9e <usertrap+0xe4>
    p->trapframe->epc += 4;
    80002f62:	6cb8                	ld	a4,88(s1)
    80002f64:	6f1c                	ld	a5,24(a4)
    80002f66:	0791                	addi	a5,a5,4
    80002f68:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f6a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f6e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f72:	10079073          	csrw	sstatus,a5
    syscall();
    80002f76:	00000097          	auipc	ra,0x0
    80002f7a:	1f4080e7          	jalr	500(ra) # 8000316a <syscall>
  if(killed(p))
    80002f7e:	8526                	mv	a0,s1
    80002f80:	fffff097          	auipc	ra,0xfffff
    80002f84:	7fc080e7          	jalr	2044(ra) # 8000277c <killed>
    80002f88:	e521                	bnez	a0,80002fd0 <usertrap+0x116>
  usertrapret();
    80002f8a:	00000097          	auipc	ra,0x0
    80002f8e:	c3a080e7          	jalr	-966(ra) # 80002bc4 <usertrapret>
}
    80002f92:	60e2                	ld	ra,24(sp)
    80002f94:	6442                	ld	s0,16(sp)
    80002f96:	64a2                	ld	s1,8(sp)
    80002f98:	6902                	ld	s2,0(sp)
    80002f9a:	6105                	addi	sp,sp,32
    80002f9c:	8082                	ret
      exit(-1);
    80002f9e:	557d                	li	a0,-1
    80002fa0:	fffff097          	auipc	ra,0xfffff
    80002fa4:	668080e7          	jalr	1640(ra) # 80002608 <exit>
    80002fa8:	bf6d                	j	80002f62 <usertrap+0xa8>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002faa:	143025f3          	csrr	a1,stval
     if (0 > handle_page_fault(p->pagetable, r_stval())) {
    80002fae:	68a8                	ld	a0,80(s1)
    80002fb0:	00000097          	auipc	ra,0x0
    80002fb4:	e62080e7          	jalr	-414(ra) # 80002e12 <handle_page_fault>
    80002fb8:	fc0553e3          	bgez	a0,80002f7e <usertrap+0xc4>
       p->killed = 1;
    80002fbc:	4785                	li	a5,1
    80002fbe:	d49c                	sw	a5,40(s1)
    80002fc0:	bf7d                	j	80002f7e <usertrap+0xc4>
  if(killed(p))
    80002fc2:	8526                	mv	a0,s1
    80002fc4:	fffff097          	auipc	ra,0xfffff
    80002fc8:	7b8080e7          	jalr	1976(ra) # 8000277c <killed>
    80002fcc:	c901                	beqz	a0,80002fdc <usertrap+0x122>
    80002fce:	a011                	j	80002fd2 <usertrap+0x118>
    80002fd0:	4901                	li	s2,0
    exit(-1);
    80002fd2:	557d                	li	a0,-1
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	634080e7          	jalr	1588(ra) # 80002608 <exit>
  if(which_dev == 2)
    80002fdc:	4789                	li	a5,2
    80002fde:	faf916e3          	bne	s2,a5,80002f8a <usertrap+0xd0>
    yield();
    80002fe2:	fffff097          	auipc	ra,0xfffff
    80002fe6:	4b6080e7          	jalr	1206(ra) # 80002498 <yield>
    80002fea:	b745                	j	80002f8a <usertrap+0xd0>

0000000080002fec <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002fec:	1101                	addi	sp,sp,-32
    80002fee:	ec06                	sd	ra,24(sp)
    80002ff0:	e822                	sd	s0,16(sp)
    80002ff2:	e426                	sd	s1,8(sp)
    80002ff4:	1000                	addi	s0,sp,32
    80002ff6:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002ff8:	fffff097          	auipc	ra,0xfffff
    80002ffc:	d74080e7          	jalr	-652(ra) # 80001d6c <myproc>
    switch (n)
    80003000:	4795                	li	a5,5
    80003002:	0497e163          	bltu	a5,s1,80003044 <argraw+0x58>
    80003006:	048a                	slli	s1,s1,0x2
    80003008:	00005717          	auipc	a4,0x5
    8000300c:	5f070713          	addi	a4,a4,1520 # 800085f8 <states.0+0x208>
    80003010:	94ba                	add	s1,s1,a4
    80003012:	409c                	lw	a5,0(s1)
    80003014:	97ba                	add	a5,a5,a4
    80003016:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80003018:	6d3c                	ld	a5,88(a0)
    8000301a:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    8000301c:	60e2                	ld	ra,24(sp)
    8000301e:	6442                	ld	s0,16(sp)
    80003020:	64a2                	ld	s1,8(sp)
    80003022:	6105                	addi	sp,sp,32
    80003024:	8082                	ret
        return p->trapframe->a1;
    80003026:	6d3c                	ld	a5,88(a0)
    80003028:	7fa8                	ld	a0,120(a5)
    8000302a:	bfcd                	j	8000301c <argraw+0x30>
        return p->trapframe->a2;
    8000302c:	6d3c                	ld	a5,88(a0)
    8000302e:	63c8                	ld	a0,128(a5)
    80003030:	b7f5                	j	8000301c <argraw+0x30>
        return p->trapframe->a3;
    80003032:	6d3c                	ld	a5,88(a0)
    80003034:	67c8                	ld	a0,136(a5)
    80003036:	b7dd                	j	8000301c <argraw+0x30>
        return p->trapframe->a4;
    80003038:	6d3c                	ld	a5,88(a0)
    8000303a:	6bc8                	ld	a0,144(a5)
    8000303c:	b7c5                	j	8000301c <argraw+0x30>
        return p->trapframe->a5;
    8000303e:	6d3c                	ld	a5,88(a0)
    80003040:	6fc8                	ld	a0,152(a5)
    80003042:	bfe9                	j	8000301c <argraw+0x30>
    panic("argraw");
    80003044:	00005517          	auipc	a0,0x5
    80003048:	58c50513          	addi	a0,a0,1420 # 800085d0 <states.0+0x1e0>
    8000304c:	ffffd097          	auipc	ra,0xffffd
    80003050:	4f0080e7          	jalr	1264(ra) # 8000053c <panic>

0000000080003054 <fetchaddr>:
{
    80003054:	1101                	addi	sp,sp,-32
    80003056:	ec06                	sd	ra,24(sp)
    80003058:	e822                	sd	s0,16(sp)
    8000305a:	e426                	sd	s1,8(sp)
    8000305c:	e04a                	sd	s2,0(sp)
    8000305e:	1000                	addi	s0,sp,32
    80003060:	84aa                	mv	s1,a0
    80003062:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80003064:	fffff097          	auipc	ra,0xfffff
    80003068:	d08080e7          	jalr	-760(ra) # 80001d6c <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000306c:	653c                	ld	a5,72(a0)
    8000306e:	02f4f863          	bgeu	s1,a5,8000309e <fetchaddr+0x4a>
    80003072:	00848713          	addi	a4,s1,8
    80003076:	02e7e663          	bltu	a5,a4,800030a2 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000307a:	46a1                	li	a3,8
    8000307c:	8626                	mv	a2,s1
    8000307e:	85ca                	mv	a1,s2
    80003080:	6928                	ld	a0,80(a0)
    80003082:	fffff097          	auipc	ra,0xfffff
    80003086:	942080e7          	jalr	-1726(ra) # 800019c4 <copyin>
    8000308a:	00a03533          	snez	a0,a0
    8000308e:	40a00533          	neg	a0,a0
}
    80003092:	60e2                	ld	ra,24(sp)
    80003094:	6442                	ld	s0,16(sp)
    80003096:	64a2                	ld	s1,8(sp)
    80003098:	6902                	ld	s2,0(sp)
    8000309a:	6105                	addi	sp,sp,32
    8000309c:	8082                	ret
        return -1;
    8000309e:	557d                	li	a0,-1
    800030a0:	bfcd                	j	80003092 <fetchaddr+0x3e>
    800030a2:	557d                	li	a0,-1
    800030a4:	b7fd                	j	80003092 <fetchaddr+0x3e>

00000000800030a6 <fetchstr>:
{
    800030a6:	7179                	addi	sp,sp,-48
    800030a8:	f406                	sd	ra,40(sp)
    800030aa:	f022                	sd	s0,32(sp)
    800030ac:	ec26                	sd	s1,24(sp)
    800030ae:	e84a                	sd	s2,16(sp)
    800030b0:	e44e                	sd	s3,8(sp)
    800030b2:	1800                	addi	s0,sp,48
    800030b4:	892a                	mv	s2,a0
    800030b6:	84ae                	mv	s1,a1
    800030b8:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    800030ba:	fffff097          	auipc	ra,0xfffff
    800030be:	cb2080e7          	jalr	-846(ra) # 80001d6c <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800030c2:	86ce                	mv	a3,s3
    800030c4:	864a                	mv	a2,s2
    800030c6:	85a6                	mv	a1,s1
    800030c8:	6928                	ld	a0,80(a0)
    800030ca:	fffff097          	auipc	ra,0xfffff
    800030ce:	988080e7          	jalr	-1656(ra) # 80001a52 <copyinstr>
    800030d2:	00054e63          	bltz	a0,800030ee <fetchstr+0x48>
    return strlen(buf);
    800030d6:	8526                	mv	a0,s1
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	f76080e7          	jalr	-138(ra) # 8000104e <strlen>
}
    800030e0:	70a2                	ld	ra,40(sp)
    800030e2:	7402                	ld	s0,32(sp)
    800030e4:	64e2                	ld	s1,24(sp)
    800030e6:	6942                	ld	s2,16(sp)
    800030e8:	69a2                	ld	s3,8(sp)
    800030ea:	6145                	addi	sp,sp,48
    800030ec:	8082                	ret
        return -1;
    800030ee:	557d                	li	a0,-1
    800030f0:	bfc5                	j	800030e0 <fetchstr+0x3a>

00000000800030f2 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    800030f2:	1101                	addi	sp,sp,-32
    800030f4:	ec06                	sd	ra,24(sp)
    800030f6:	e822                	sd	s0,16(sp)
    800030f8:	e426                	sd	s1,8(sp)
    800030fa:	1000                	addi	s0,sp,32
    800030fc:	84ae                	mv	s1,a1
    *ip = argraw(n);
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	eee080e7          	jalr	-274(ra) # 80002fec <argraw>
    80003106:	c088                	sw	a0,0(s1)
}
    80003108:	60e2                	ld	ra,24(sp)
    8000310a:	6442                	ld	s0,16(sp)
    8000310c:	64a2                	ld	s1,8(sp)
    8000310e:	6105                	addi	sp,sp,32
    80003110:	8082                	ret

0000000080003112 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000311e:	00000097          	auipc	ra,0x0
    80003122:	ece080e7          	jalr	-306(ra) # 80002fec <argraw>
    80003126:	e088                	sd	a0,0(s1)
}
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	64a2                	ld	s1,8(sp)
    8000312e:	6105                	addi	sp,sp,32
    80003130:	8082                	ret

0000000080003132 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003132:	7179                	addi	sp,sp,-48
    80003134:	f406                	sd	ra,40(sp)
    80003136:	f022                	sd	s0,32(sp)
    80003138:	ec26                	sd	s1,24(sp)
    8000313a:	e84a                	sd	s2,16(sp)
    8000313c:	1800                	addi	s0,sp,48
    8000313e:	84ae                	mv	s1,a1
    80003140:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003142:	fd840593          	addi	a1,s0,-40
    80003146:	00000097          	auipc	ra,0x0
    8000314a:	fcc080e7          	jalr	-52(ra) # 80003112 <argaddr>
    return fetchstr(addr, buf, max);
    8000314e:	864a                	mv	a2,s2
    80003150:	85a6                	mv	a1,s1
    80003152:	fd843503          	ld	a0,-40(s0)
    80003156:	00000097          	auipc	ra,0x0
    8000315a:	f50080e7          	jalr	-176(ra) # 800030a6 <fetchstr>
}
    8000315e:	70a2                	ld	ra,40(sp)
    80003160:	7402                	ld	s0,32(sp)
    80003162:	64e2                	ld	s1,24(sp)
    80003164:	6942                	ld	s2,16(sp)
    80003166:	6145                	addi	sp,sp,48
    80003168:	8082                	ret

000000008000316a <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    8000316a:	1101                	addi	sp,sp,-32
    8000316c:	ec06                	sd	ra,24(sp)
    8000316e:	e822                	sd	s0,16(sp)
    80003170:	e426                	sd	s1,8(sp)
    80003172:	e04a                	sd	s2,0(sp)
    80003174:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    80003176:	fffff097          	auipc	ra,0xfffff
    8000317a:	bf6080e7          	jalr	-1034(ra) # 80001d6c <myproc>
    8000317e:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    80003180:	05853903          	ld	s2,88(a0)
    80003184:	0a893783          	ld	a5,168(s2)
    80003188:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    8000318c:	37fd                	addiw	a5,a5,-1
    8000318e:	4765                	li	a4,25
    80003190:	00f76f63          	bltu	a4,a5,800031ae <syscall+0x44>
    80003194:	00369713          	slli	a4,a3,0x3
    80003198:	00005797          	auipc	a5,0x5
    8000319c:	47878793          	addi	a5,a5,1144 # 80008610 <syscalls>
    800031a0:	97ba                	add	a5,a5,a4
    800031a2:	639c                	ld	a5,0(a5)
    800031a4:	c789                	beqz	a5,800031ae <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800031a6:	9782                	jalr	a5
    800031a8:	06a93823          	sd	a0,112(s2)
    800031ac:	a839                	j	800031ca <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800031ae:	15848613          	addi	a2,s1,344
    800031b2:	588c                	lw	a1,48(s1)
    800031b4:	00005517          	auipc	a0,0x5
    800031b8:	42450513          	addi	a0,a0,1060 # 800085d8 <states.0+0x1e8>
    800031bc:	ffffd097          	auipc	ra,0xffffd
    800031c0:	3dc080e7          	jalr	988(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800031c4:	6cbc                	ld	a5,88(s1)
    800031c6:	577d                	li	a4,-1
    800031c8:	fbb8                	sd	a4,112(a5)
    }
}
    800031ca:	60e2                	ld	ra,24(sp)
    800031cc:	6442                	ld	s0,16(sp)
    800031ce:	64a2                	ld	s1,8(sp)
    800031d0:	6902                	ld	s2,0(sp)
    800031d2:	6105                	addi	sp,sp,32
    800031d4:	8082                	ret

00000000800031d6 <sys_exit>:
extern uint64 FREE_PAGES; // kalloc.c keeps track of those
extern struct proc proc[];

uint64
sys_exit(void)
{
    800031d6:	1101                	addi	sp,sp,-32
    800031d8:	ec06                	sd	ra,24(sp)
    800031da:	e822                	sd	s0,16(sp)
    800031dc:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    800031de:	fec40593          	addi	a1,s0,-20
    800031e2:	4501                	li	a0,0
    800031e4:	00000097          	auipc	ra,0x0
    800031e8:	f0e080e7          	jalr	-242(ra) # 800030f2 <argint>
    exit(n);
    800031ec:	fec42503          	lw	a0,-20(s0)
    800031f0:	fffff097          	auipc	ra,0xfffff
    800031f4:	418080e7          	jalr	1048(ra) # 80002608 <exit>
    return 0; // not reached
}
    800031f8:	4501                	li	a0,0
    800031fa:	60e2                	ld	ra,24(sp)
    800031fc:	6442                	ld	s0,16(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003202:	1141                	addi	sp,sp,-16
    80003204:	e406                	sd	ra,8(sp)
    80003206:	e022                	sd	s0,0(sp)
    80003208:	0800                	addi	s0,sp,16
    return myproc()->pid;
    8000320a:	fffff097          	auipc	ra,0xfffff
    8000320e:	b62080e7          	jalr	-1182(ra) # 80001d6c <myproc>
}
    80003212:	5908                	lw	a0,48(a0)
    80003214:	60a2                	ld	ra,8(sp)
    80003216:	6402                	ld	s0,0(sp)
    80003218:	0141                	addi	sp,sp,16
    8000321a:	8082                	ret

000000008000321c <sys_fork>:

uint64
sys_fork(void)
{
    8000321c:	1141                	addi	sp,sp,-16
    8000321e:	e406                	sd	ra,8(sp)
    80003220:	e022                	sd	s0,0(sp)
    80003222:	0800                	addi	s0,sp,16
    return fork();
    80003224:	fffff097          	auipc	ra,0xfffff
    80003228:	04e080e7          	jalr	78(ra) # 80002272 <fork>
}
    8000322c:	60a2                	ld	ra,8(sp)
    8000322e:	6402                	ld	s0,0(sp)
    80003230:	0141                	addi	sp,sp,16
    80003232:	8082                	ret

0000000080003234 <sys_wait>:

uint64
sys_wait(void)
{
    80003234:	1101                	addi	sp,sp,-32
    80003236:	ec06                	sd	ra,24(sp)
    80003238:	e822                	sd	s0,16(sp)
    8000323a:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000323c:	fe840593          	addi	a1,s0,-24
    80003240:	4501                	li	a0,0
    80003242:	00000097          	auipc	ra,0x0
    80003246:	ed0080e7          	jalr	-304(ra) # 80003112 <argaddr>
    return wait(p);
    8000324a:	fe843503          	ld	a0,-24(s0)
    8000324e:	fffff097          	auipc	ra,0xfffff
    80003252:	560080e7          	jalr	1376(ra) # 800027ae <wait>
}
    80003256:	60e2                	ld	ra,24(sp)
    80003258:	6442                	ld	s0,16(sp)
    8000325a:	6105                	addi	sp,sp,32
    8000325c:	8082                	ret

000000008000325e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000325e:	7179                	addi	sp,sp,-48
    80003260:	f406                	sd	ra,40(sp)
    80003262:	f022                	sd	s0,32(sp)
    80003264:	ec26                	sd	s1,24(sp)
    80003266:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003268:	fdc40593          	addi	a1,s0,-36
    8000326c:	4501                	li	a0,0
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	e84080e7          	jalr	-380(ra) # 800030f2 <argint>
    addr = myproc()->sz;
    80003276:	fffff097          	auipc	ra,0xfffff
    8000327a:	af6080e7          	jalr	-1290(ra) # 80001d6c <myproc>
    8000327e:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    80003280:	fdc42503          	lw	a0,-36(s0)
    80003284:	fffff097          	auipc	ra,0xfffff
    80003288:	e42080e7          	jalr	-446(ra) # 800020c6 <growproc>
    8000328c:	00054863          	bltz	a0,8000329c <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    80003290:	8526                	mv	a0,s1
    80003292:	70a2                	ld	ra,40(sp)
    80003294:	7402                	ld	s0,32(sp)
    80003296:	64e2                	ld	s1,24(sp)
    80003298:	6145                	addi	sp,sp,48
    8000329a:	8082                	ret
        return -1;
    8000329c:	54fd                	li	s1,-1
    8000329e:	bfcd                	j	80003290 <sys_sbrk+0x32>

00000000800032a0 <sys_sleep>:

uint64
sys_sleep(void)
{
    800032a0:	7139                	addi	sp,sp,-64
    800032a2:	fc06                	sd	ra,56(sp)
    800032a4:	f822                	sd	s0,48(sp)
    800032a6:	f426                	sd	s1,40(sp)
    800032a8:	f04a                	sd	s2,32(sp)
    800032aa:	ec4e                	sd	s3,24(sp)
    800032ac:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800032ae:	fcc40593          	addi	a1,s0,-52
    800032b2:	4501                	li	a0,0
    800032b4:	00000097          	auipc	ra,0x0
    800032b8:	e3e080e7          	jalr	-450(ra) # 800030f2 <argint>
    acquire(&tickslock);
    800032bc:	00234517          	auipc	a0,0x234
    800032c0:	8d450513          	addi	a0,a0,-1836 # 80236b90 <tickslock>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	b14080e7          	jalr	-1260(ra) # 80000dd8 <acquire>
    ticks0 = ticks;
    800032cc:	00006917          	auipc	s2,0x6
    800032d0:	82492903          	lw	s2,-2012(s2) # 80008af0 <ticks>
    while (ticks - ticks0 < n)
    800032d4:	fcc42783          	lw	a5,-52(s0)
    800032d8:	cf9d                	beqz	a5,80003316 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    800032da:	00234997          	auipc	s3,0x234
    800032de:	8b698993          	addi	s3,s3,-1866 # 80236b90 <tickslock>
    800032e2:	00006497          	auipc	s1,0x6
    800032e6:	80e48493          	addi	s1,s1,-2034 # 80008af0 <ticks>
        if (killed(myproc()))
    800032ea:	fffff097          	auipc	ra,0xfffff
    800032ee:	a82080e7          	jalr	-1406(ra) # 80001d6c <myproc>
    800032f2:	fffff097          	auipc	ra,0xfffff
    800032f6:	48a080e7          	jalr	1162(ra) # 8000277c <killed>
    800032fa:	ed15                	bnez	a0,80003336 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    800032fc:	85ce                	mv	a1,s3
    800032fe:	8526                	mv	a0,s1
    80003300:	fffff097          	auipc	ra,0xfffff
    80003304:	1d4080e7          	jalr	468(ra) # 800024d4 <sleep>
    while (ticks - ticks0 < n)
    80003308:	409c                	lw	a5,0(s1)
    8000330a:	412787bb          	subw	a5,a5,s2
    8000330e:	fcc42703          	lw	a4,-52(s0)
    80003312:	fce7ece3          	bltu	a5,a4,800032ea <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003316:	00234517          	auipc	a0,0x234
    8000331a:	87a50513          	addi	a0,a0,-1926 # 80236b90 <tickslock>
    8000331e:	ffffe097          	auipc	ra,0xffffe
    80003322:	b6e080e7          	jalr	-1170(ra) # 80000e8c <release>
    return 0;
    80003326:	4501                	li	a0,0
}
    80003328:	70e2                	ld	ra,56(sp)
    8000332a:	7442                	ld	s0,48(sp)
    8000332c:	74a2                	ld	s1,40(sp)
    8000332e:	7902                	ld	s2,32(sp)
    80003330:	69e2                	ld	s3,24(sp)
    80003332:	6121                	addi	sp,sp,64
    80003334:	8082                	ret
            release(&tickslock);
    80003336:	00234517          	auipc	a0,0x234
    8000333a:	85a50513          	addi	a0,a0,-1958 # 80236b90 <tickslock>
    8000333e:	ffffe097          	auipc	ra,0xffffe
    80003342:	b4e080e7          	jalr	-1202(ra) # 80000e8c <release>
            return -1;
    80003346:	557d                	li	a0,-1
    80003348:	b7c5                	j	80003328 <sys_sleep+0x88>

000000008000334a <sys_kill>:

uint64
sys_kill(void)
{
    8000334a:	1101                	addi	sp,sp,-32
    8000334c:	ec06                	sd	ra,24(sp)
    8000334e:	e822                	sd	s0,16(sp)
    80003350:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003352:	fec40593          	addi	a1,s0,-20
    80003356:	4501                	li	a0,0
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	d9a080e7          	jalr	-614(ra) # 800030f2 <argint>
    return kill(pid);
    80003360:	fec42503          	lw	a0,-20(s0)
    80003364:	fffff097          	auipc	ra,0xfffff
    80003368:	37a080e7          	jalr	890(ra) # 800026de <kill>
}
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003374:	1101                	addi	sp,sp,-32
    80003376:	ec06                	sd	ra,24(sp)
    80003378:	e822                	sd	s0,16(sp)
    8000337a:	e426                	sd	s1,8(sp)
    8000337c:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    8000337e:	00234517          	auipc	a0,0x234
    80003382:	81250513          	addi	a0,a0,-2030 # 80236b90 <tickslock>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	a52080e7          	jalr	-1454(ra) # 80000dd8 <acquire>
    xticks = ticks;
    8000338e:	00005497          	auipc	s1,0x5
    80003392:	7624a483          	lw	s1,1890(s1) # 80008af0 <ticks>
    release(&tickslock);
    80003396:	00233517          	auipc	a0,0x233
    8000339a:	7fa50513          	addi	a0,a0,2042 # 80236b90 <tickslock>
    8000339e:	ffffe097          	auipc	ra,0xffffe
    800033a2:	aee080e7          	jalr	-1298(ra) # 80000e8c <release>
    return xticks;
}
    800033a6:	02049513          	slli	a0,s1,0x20
    800033aa:	9101                	srli	a0,a0,0x20
    800033ac:	60e2                	ld	ra,24(sp)
    800033ae:	6442                	ld	s0,16(sp)
    800033b0:	64a2                	ld	s1,8(sp)
    800033b2:	6105                	addi	sp,sp,32
    800033b4:	8082                	ret

00000000800033b6 <sys_ps>:

void *
sys_ps(void)
{
    800033b6:	1101                	addi	sp,sp,-32
    800033b8:	ec06                	sd	ra,24(sp)
    800033ba:	e822                	sd	s0,16(sp)
    800033bc:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800033be:	fe042623          	sw	zero,-20(s0)
    800033c2:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800033c6:	fec40593          	addi	a1,s0,-20
    800033ca:	4501                	li	a0,0
    800033cc:	00000097          	auipc	ra,0x0
    800033d0:	d26080e7          	jalr	-730(ra) # 800030f2 <argint>
    argint(1, &count);
    800033d4:	fe840593          	addi	a1,s0,-24
    800033d8:	4505                	li	a0,1
    800033da:	00000097          	auipc	ra,0x0
    800033de:	d18080e7          	jalr	-744(ra) # 800030f2 <argint>
    return ps((uint8)start, (uint8)count);
    800033e2:	fe844583          	lbu	a1,-24(s0)
    800033e6:	fec44503          	lbu	a0,-20(s0)
    800033ea:	fffff097          	auipc	ra,0xfffff
    800033ee:	d38080e7          	jalr	-712(ra) # 80002122 <ps>
}
    800033f2:	60e2                	ld	ra,24(sp)
    800033f4:	6442                	ld	s0,16(sp)
    800033f6:	6105                	addi	sp,sp,32
    800033f8:	8082                	ret

00000000800033fa <sys_schedls>:

uint64 sys_schedls(void)
{
    800033fa:	1141                	addi	sp,sp,-16
    800033fc:	e406                	sd	ra,8(sp)
    800033fe:	e022                	sd	s0,0(sp)
    80003400:	0800                	addi	s0,sp,16
    schedls();
    80003402:	fffff097          	auipc	ra,0xfffff
    80003406:	636080e7          	jalr	1590(ra) # 80002a38 <schedls>
    return 0;
}
    8000340a:	4501                	li	a0,0
    8000340c:	60a2                	ld	ra,8(sp)
    8000340e:	6402                	ld	s0,0(sp)
    80003410:	0141                	addi	sp,sp,16
    80003412:	8082                	ret

0000000080003414 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003414:	1101                	addi	sp,sp,-32
    80003416:	ec06                	sd	ra,24(sp)
    80003418:	e822                	sd	s0,16(sp)
    8000341a:	1000                	addi	s0,sp,32
    int id = 0;
    8000341c:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    80003420:	fec40593          	addi	a1,s0,-20
    80003424:	4501                	li	a0,0
    80003426:	00000097          	auipc	ra,0x0
    8000342a:	ccc080e7          	jalr	-820(ra) # 800030f2 <argint>
    schedset(id - 1);
    8000342e:	fec42503          	lw	a0,-20(s0)
    80003432:	357d                	addiw	a0,a0,-1
    80003434:	fffff097          	auipc	ra,0xfffff
    80003438:	69a080e7          	jalr	1690(ra) # 80002ace <schedset>
    return 0;
}
    8000343c:	4501                	li	a0,0
    8000343e:	60e2                	ld	ra,24(sp)
    80003440:	6442                	ld	s0,16(sp)
    80003442:	6105                	addi	sp,sp,32
    80003444:	8082                	ret

0000000080003446 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003446:	7179                	addi	sp,sp,-48
    80003448:	f406                	sd	ra,40(sp)
    8000344a:	f022                	sd	s0,32(sp)
    8000344c:	ec26                	sd	s1,24(sp)
    8000344e:	e84a                	sd	s2,16(sp)
    80003450:	1800                	addi	s0,sp,48
    int pid = 0;
    80003452:	fc042e23          	sw	zero,-36(s0)
    uint64 va = 0;
    80003456:	fc043823          	sd	zero,-48(s0)
    
    argint(1, &pid);
    8000345a:	fdc40593          	addi	a1,s0,-36
    8000345e:	4505                	li	a0,1
    80003460:	00000097          	auipc	ra,0x0
    80003464:	c92080e7          	jalr	-878(ra) # 800030f2 <argint>
    argaddr(0, &va);
    80003468:	fd040593          	addi	a1,s0,-48
    8000346c:	4501                	li	a0,0
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	ca4080e7          	jalr	-860(ra) # 80003112 <argaddr>

    struct proc *p;
    int pidExists = 0;

    if (pid != 0) {
    80003476:	fdc42783          	lw	a5,-36(s0)
    8000347a:	c3a5                	beqz	a5,800034da <sys_va2pa+0x94>
        for (p = proc; p < &proc[NPROC]; p++) {
    8000347c:	0022e497          	auipc	s1,0x22e
    80003480:	d1448493          	addi	s1,s1,-748 # 80231190 <proc>
    80003484:	00233917          	auipc	s2,0x233
    80003488:	70c90913          	addi	s2,s2,1804 # 80236b90 <tickslock>
            acquire(&p->lock);
    8000348c:	8526                	mv	a0,s1
    8000348e:	ffffe097          	auipc	ra,0xffffe
    80003492:	94a080e7          	jalr	-1718(ra) # 80000dd8 <acquire>
            if (p->pid == pid) {
    80003496:	5898                	lw	a4,48(s1)
    80003498:	fdc42783          	lw	a5,-36(s0)
    8000349c:	00f70d63          	beq	a4,a5,800034b6 <sys_va2pa+0x70>
                release(&p->lock);
                pidExists = 1;
                break;
            }
            release(&p->lock);
    800034a0:	8526                	mv	a0,s1
    800034a2:	ffffe097          	auipc	ra,0xffffe
    800034a6:	9ea080e7          	jalr	-1558(ra) # 80000e8c <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    800034aa:	16848493          	addi	s1,s1,360
    800034ae:	fd249fe3          	bne	s1,s2,8000348c <sys_va2pa+0x46>
        }
        if (pidExists == 0) {
            return 0;
    800034b2:	4501                	li	a0,0
    800034b4:	a829                	j	800034ce <sys_va2pa+0x88>
                release(&p->lock);
    800034b6:	8526                	mv	a0,s1
    800034b8:	ffffe097          	auipc	ra,0xffffe
    800034bc:	9d4080e7          	jalr	-1580(ra) # 80000e8c <release>
    } else {
        p = myproc();
    }

    pagetable_t pagetable = p->pagetable;
    uint64 pa = walkaddr(pagetable, va);
    800034c0:	fd043583          	ld	a1,-48(s0)
    800034c4:	68a8                	ld	a0,80(s1)
    800034c6:	ffffe097          	auipc	ra,0xffffe
    800034ca:	d96080e7          	jalr	-618(ra) # 8000125c <walkaddr>
    } else {
        return pa;
    }

    return 0;
}
    800034ce:	70a2                	ld	ra,40(sp)
    800034d0:	7402                	ld	s0,32(sp)
    800034d2:	64e2                	ld	s1,24(sp)
    800034d4:	6942                	ld	s2,16(sp)
    800034d6:	6145                	addi	sp,sp,48
    800034d8:	8082                	ret
        p = myproc();
    800034da:	fffff097          	auipc	ra,0xfffff
    800034de:	892080e7          	jalr	-1902(ra) # 80001d6c <myproc>
    800034e2:	84aa                	mv	s1,a0
    800034e4:	bff1                	j	800034c0 <sys_va2pa+0x7a>

00000000800034e6 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    800034e6:	1141                	addi	sp,sp,-16
    800034e8:	e406                	sd	ra,8(sp)
    800034ea:	e022                	sd	s0,0(sp)
    800034ec:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    800034ee:	00005597          	auipc	a1,0x5
    800034f2:	5da5b583          	ld	a1,1498(a1) # 80008ac8 <FREE_PAGES>
    800034f6:	00005517          	auipc	a0,0x5
    800034fa:	0fa50513          	addi	a0,a0,250 # 800085f0 <states.0+0x200>
    800034fe:	ffffd097          	auipc	ra,0xffffd
    80003502:	09a080e7          	jalr	154(ra) # 80000598 <printf>
    return 0;
    80003506:	4501                	li	a0,0
    80003508:	60a2                	ld	ra,8(sp)
    8000350a:	6402                	ld	s0,0(sp)
    8000350c:	0141                	addi	sp,sp,16
    8000350e:	8082                	ret

0000000080003510 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003510:	7179                	addi	sp,sp,-48
    80003512:	f406                	sd	ra,40(sp)
    80003514:	f022                	sd	s0,32(sp)
    80003516:	ec26                	sd	s1,24(sp)
    80003518:	e84a                	sd	s2,16(sp)
    8000351a:	e44e                	sd	s3,8(sp)
    8000351c:	e052                	sd	s4,0(sp)
    8000351e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003520:	00005597          	auipc	a1,0x5
    80003524:	1c858593          	addi	a1,a1,456 # 800086e8 <syscalls+0xd8>
    80003528:	00233517          	auipc	a0,0x233
    8000352c:	68050513          	addi	a0,a0,1664 # 80236ba8 <bcache>
    80003530:	ffffe097          	auipc	ra,0xffffe
    80003534:	818080e7          	jalr	-2024(ra) # 80000d48 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003538:	0023b797          	auipc	a5,0x23b
    8000353c:	67078793          	addi	a5,a5,1648 # 8023eba8 <bcache+0x8000>
    80003540:	0023c717          	auipc	a4,0x23c
    80003544:	8d070713          	addi	a4,a4,-1840 # 8023ee10 <bcache+0x8268>
    80003548:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000354c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003550:	00233497          	auipc	s1,0x233
    80003554:	67048493          	addi	s1,s1,1648 # 80236bc0 <bcache+0x18>
    b->next = bcache.head.next;
    80003558:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000355a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000355c:	00005a17          	auipc	s4,0x5
    80003560:	194a0a13          	addi	s4,s4,404 # 800086f0 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003564:	2b893783          	ld	a5,696(s2)
    80003568:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000356a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000356e:	85d2                	mv	a1,s4
    80003570:	01048513          	addi	a0,s1,16
    80003574:	00001097          	auipc	ra,0x1
    80003578:	496080e7          	jalr	1174(ra) # 80004a0a <initsleeplock>
    bcache.head.next->prev = b;
    8000357c:	2b893783          	ld	a5,696(s2)
    80003580:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003582:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003586:	45848493          	addi	s1,s1,1112
    8000358a:	fd349de3          	bne	s1,s3,80003564 <binit+0x54>
  }
}
    8000358e:	70a2                	ld	ra,40(sp)
    80003590:	7402                	ld	s0,32(sp)
    80003592:	64e2                	ld	s1,24(sp)
    80003594:	6942                	ld	s2,16(sp)
    80003596:	69a2                	ld	s3,8(sp)
    80003598:	6a02                	ld	s4,0(sp)
    8000359a:	6145                	addi	sp,sp,48
    8000359c:	8082                	ret

000000008000359e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000359e:	7179                	addi	sp,sp,-48
    800035a0:	f406                	sd	ra,40(sp)
    800035a2:	f022                	sd	s0,32(sp)
    800035a4:	ec26                	sd	s1,24(sp)
    800035a6:	e84a                	sd	s2,16(sp)
    800035a8:	e44e                	sd	s3,8(sp)
    800035aa:	1800                	addi	s0,sp,48
    800035ac:	892a                	mv	s2,a0
    800035ae:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035b0:	00233517          	auipc	a0,0x233
    800035b4:	5f850513          	addi	a0,a0,1528 # 80236ba8 <bcache>
    800035b8:	ffffe097          	auipc	ra,0xffffe
    800035bc:	820080e7          	jalr	-2016(ra) # 80000dd8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035c0:	0023c497          	auipc	s1,0x23c
    800035c4:	8a04b483          	ld	s1,-1888(s1) # 8023ee60 <bcache+0x82b8>
    800035c8:	0023c797          	auipc	a5,0x23c
    800035cc:	84878793          	addi	a5,a5,-1976 # 8023ee10 <bcache+0x8268>
    800035d0:	02f48f63          	beq	s1,a5,8000360e <bread+0x70>
    800035d4:	873e                	mv	a4,a5
    800035d6:	a021                	j	800035de <bread+0x40>
    800035d8:	68a4                	ld	s1,80(s1)
    800035da:	02e48a63          	beq	s1,a4,8000360e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035de:	449c                	lw	a5,8(s1)
    800035e0:	ff279ce3          	bne	a5,s2,800035d8 <bread+0x3a>
    800035e4:	44dc                	lw	a5,12(s1)
    800035e6:	ff3799e3          	bne	a5,s3,800035d8 <bread+0x3a>
      b->refcnt++;
    800035ea:	40bc                	lw	a5,64(s1)
    800035ec:	2785                	addiw	a5,a5,1
    800035ee:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035f0:	00233517          	auipc	a0,0x233
    800035f4:	5b850513          	addi	a0,a0,1464 # 80236ba8 <bcache>
    800035f8:	ffffe097          	auipc	ra,0xffffe
    800035fc:	894080e7          	jalr	-1900(ra) # 80000e8c <release>
      acquiresleep(&b->lock);
    80003600:	01048513          	addi	a0,s1,16
    80003604:	00001097          	auipc	ra,0x1
    80003608:	440080e7          	jalr	1088(ra) # 80004a44 <acquiresleep>
      return b;
    8000360c:	a8b9                	j	8000366a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000360e:	0023c497          	auipc	s1,0x23c
    80003612:	84a4b483          	ld	s1,-1974(s1) # 8023ee58 <bcache+0x82b0>
    80003616:	0023b797          	auipc	a5,0x23b
    8000361a:	7fa78793          	addi	a5,a5,2042 # 8023ee10 <bcache+0x8268>
    8000361e:	00f48863          	beq	s1,a5,8000362e <bread+0x90>
    80003622:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003624:	40bc                	lw	a5,64(s1)
    80003626:	cf81                	beqz	a5,8000363e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003628:	64a4                	ld	s1,72(s1)
    8000362a:	fee49de3          	bne	s1,a4,80003624 <bread+0x86>
  panic("bget: no buffers");
    8000362e:	00005517          	auipc	a0,0x5
    80003632:	0ca50513          	addi	a0,a0,202 # 800086f8 <syscalls+0xe8>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	f06080e7          	jalr	-250(ra) # 8000053c <panic>
      b->dev = dev;
    8000363e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003642:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003646:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000364a:	4785                	li	a5,1
    8000364c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000364e:	00233517          	auipc	a0,0x233
    80003652:	55a50513          	addi	a0,a0,1370 # 80236ba8 <bcache>
    80003656:	ffffe097          	auipc	ra,0xffffe
    8000365a:	836080e7          	jalr	-1994(ra) # 80000e8c <release>
      acquiresleep(&b->lock);
    8000365e:	01048513          	addi	a0,s1,16
    80003662:	00001097          	auipc	ra,0x1
    80003666:	3e2080e7          	jalr	994(ra) # 80004a44 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000366a:	409c                	lw	a5,0(s1)
    8000366c:	cb89                	beqz	a5,8000367e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000366e:	8526                	mv	a0,s1
    80003670:	70a2                	ld	ra,40(sp)
    80003672:	7402                	ld	s0,32(sp)
    80003674:	64e2                	ld	s1,24(sp)
    80003676:	6942                	ld	s2,16(sp)
    80003678:	69a2                	ld	s3,8(sp)
    8000367a:	6145                	addi	sp,sp,48
    8000367c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000367e:	4581                	li	a1,0
    80003680:	8526                	mv	a0,s1
    80003682:	00003097          	auipc	ra,0x3
    80003686:	f80080e7          	jalr	-128(ra) # 80006602 <virtio_disk_rw>
    b->valid = 1;
    8000368a:	4785                	li	a5,1
    8000368c:	c09c                	sw	a5,0(s1)
  return b;
    8000368e:	b7c5                	j	8000366e <bread+0xd0>

0000000080003690 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003690:	1101                	addi	sp,sp,-32
    80003692:	ec06                	sd	ra,24(sp)
    80003694:	e822                	sd	s0,16(sp)
    80003696:	e426                	sd	s1,8(sp)
    80003698:	1000                	addi	s0,sp,32
    8000369a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000369c:	0541                	addi	a0,a0,16
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	440080e7          	jalr	1088(ra) # 80004ade <holdingsleep>
    800036a6:	cd01                	beqz	a0,800036be <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036a8:	4585                	li	a1,1
    800036aa:	8526                	mv	a0,s1
    800036ac:	00003097          	auipc	ra,0x3
    800036b0:	f56080e7          	jalr	-170(ra) # 80006602 <virtio_disk_rw>
}
    800036b4:	60e2                	ld	ra,24(sp)
    800036b6:	6442                	ld	s0,16(sp)
    800036b8:	64a2                	ld	s1,8(sp)
    800036ba:	6105                	addi	sp,sp,32
    800036bc:	8082                	ret
    panic("bwrite");
    800036be:	00005517          	auipc	a0,0x5
    800036c2:	05250513          	addi	a0,a0,82 # 80008710 <syscalls+0x100>
    800036c6:	ffffd097          	auipc	ra,0xffffd
    800036ca:	e76080e7          	jalr	-394(ra) # 8000053c <panic>

00000000800036ce <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036ce:	1101                	addi	sp,sp,-32
    800036d0:	ec06                	sd	ra,24(sp)
    800036d2:	e822                	sd	s0,16(sp)
    800036d4:	e426                	sd	s1,8(sp)
    800036d6:	e04a                	sd	s2,0(sp)
    800036d8:	1000                	addi	s0,sp,32
    800036da:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036dc:	01050913          	addi	s2,a0,16
    800036e0:	854a                	mv	a0,s2
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	3fc080e7          	jalr	1020(ra) # 80004ade <holdingsleep>
    800036ea:	c925                	beqz	a0,8000375a <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800036ec:	854a                	mv	a0,s2
    800036ee:	00001097          	auipc	ra,0x1
    800036f2:	3ac080e7          	jalr	940(ra) # 80004a9a <releasesleep>

  acquire(&bcache.lock);
    800036f6:	00233517          	auipc	a0,0x233
    800036fa:	4b250513          	addi	a0,a0,1202 # 80236ba8 <bcache>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	6da080e7          	jalr	1754(ra) # 80000dd8 <acquire>
  b->refcnt--;
    80003706:	40bc                	lw	a5,64(s1)
    80003708:	37fd                	addiw	a5,a5,-1
    8000370a:	0007871b          	sext.w	a4,a5
    8000370e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003710:	e71d                	bnez	a4,8000373e <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003712:	68b8                	ld	a4,80(s1)
    80003714:	64bc                	ld	a5,72(s1)
    80003716:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003718:	68b8                	ld	a4,80(s1)
    8000371a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000371c:	0023b797          	auipc	a5,0x23b
    80003720:	48c78793          	addi	a5,a5,1164 # 8023eba8 <bcache+0x8000>
    80003724:	2b87b703          	ld	a4,696(a5)
    80003728:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000372a:	0023b717          	auipc	a4,0x23b
    8000372e:	6e670713          	addi	a4,a4,1766 # 8023ee10 <bcache+0x8268>
    80003732:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003734:	2b87b703          	ld	a4,696(a5)
    80003738:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000373a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000373e:	00233517          	auipc	a0,0x233
    80003742:	46a50513          	addi	a0,a0,1130 # 80236ba8 <bcache>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	746080e7          	jalr	1862(ra) # 80000e8c <release>
}
    8000374e:	60e2                	ld	ra,24(sp)
    80003750:	6442                	ld	s0,16(sp)
    80003752:	64a2                	ld	s1,8(sp)
    80003754:	6902                	ld	s2,0(sp)
    80003756:	6105                	addi	sp,sp,32
    80003758:	8082                	ret
    panic("brelse");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	fbe50513          	addi	a0,a0,-66 # 80008718 <syscalls+0x108>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	dda080e7          	jalr	-550(ra) # 8000053c <panic>

000000008000376a <bpin>:

void
bpin(struct buf *b) {
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	e426                	sd	s1,8(sp)
    80003772:	1000                	addi	s0,sp,32
    80003774:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003776:	00233517          	auipc	a0,0x233
    8000377a:	43250513          	addi	a0,a0,1074 # 80236ba8 <bcache>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	65a080e7          	jalr	1626(ra) # 80000dd8 <acquire>
  b->refcnt++;
    80003786:	40bc                	lw	a5,64(s1)
    80003788:	2785                	addiw	a5,a5,1
    8000378a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000378c:	00233517          	auipc	a0,0x233
    80003790:	41c50513          	addi	a0,a0,1052 # 80236ba8 <bcache>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	6f8080e7          	jalr	1784(ra) # 80000e8c <release>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret

00000000800037a6 <bunpin>:

void
bunpin(struct buf *b) {
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b2:	00233517          	auipc	a0,0x233
    800037b6:	3f650513          	addi	a0,a0,1014 # 80236ba8 <bcache>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	61e080e7          	jalr	1566(ra) # 80000dd8 <acquire>
  b->refcnt--;
    800037c2:	40bc                	lw	a5,64(s1)
    800037c4:	37fd                	addiw	a5,a5,-1
    800037c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037c8:	00233517          	auipc	a0,0x233
    800037cc:	3e050513          	addi	a0,a0,992 # 80236ba8 <bcache>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	6bc080e7          	jalr	1724(ra) # 80000e8c <release>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret

00000000800037e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	e04a                	sd	s2,0(sp)
    800037ec:	1000                	addi	s0,sp,32
    800037ee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037f0:	00d5d59b          	srliw	a1,a1,0xd
    800037f4:	0023c797          	auipc	a5,0x23c
    800037f8:	a907a783          	lw	a5,-1392(a5) # 8023f284 <sb+0x1c>
    800037fc:	9dbd                	addw	a1,a1,a5
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	da0080e7          	jalr	-608(ra) # 8000359e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003806:	0074f713          	andi	a4,s1,7
    8000380a:	4785                	li	a5,1
    8000380c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003810:	14ce                	slli	s1,s1,0x33
    80003812:	90d9                	srli	s1,s1,0x36
    80003814:	00950733          	add	a4,a0,s1
    80003818:	05874703          	lbu	a4,88(a4)
    8000381c:	00e7f6b3          	and	a3,a5,a4
    80003820:	c69d                	beqz	a3,8000384e <bfree+0x6c>
    80003822:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003824:	94aa                	add	s1,s1,a0
    80003826:	fff7c793          	not	a5,a5
    8000382a:	8f7d                	and	a4,a4,a5
    8000382c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003830:	00001097          	auipc	ra,0x1
    80003834:	0f6080e7          	jalr	246(ra) # 80004926 <log_write>
  brelse(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	e94080e7          	jalr	-364(ra) # 800036ce <brelse>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6902                	ld	s2,0(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret
    panic("freeing free block");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	ed250513          	addi	a0,a0,-302 # 80008720 <syscalls+0x110>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	ce6080e7          	jalr	-794(ra) # 8000053c <panic>

000000008000385e <balloc>:
{
    8000385e:	711d                	addi	sp,sp,-96
    80003860:	ec86                	sd	ra,88(sp)
    80003862:	e8a2                	sd	s0,80(sp)
    80003864:	e4a6                	sd	s1,72(sp)
    80003866:	e0ca                	sd	s2,64(sp)
    80003868:	fc4e                	sd	s3,56(sp)
    8000386a:	f852                	sd	s4,48(sp)
    8000386c:	f456                	sd	s5,40(sp)
    8000386e:	f05a                	sd	s6,32(sp)
    80003870:	ec5e                	sd	s7,24(sp)
    80003872:	e862                	sd	s8,16(sp)
    80003874:	e466                	sd	s9,8(sp)
    80003876:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003878:	0023c797          	auipc	a5,0x23c
    8000387c:	9f47a783          	lw	a5,-1548(a5) # 8023f26c <sb+0x4>
    80003880:	cff5                	beqz	a5,8000397c <balloc+0x11e>
    80003882:	8baa                	mv	s7,a0
    80003884:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003886:	0023cb17          	auipc	s6,0x23c
    8000388a:	9e2b0b13          	addi	s6,s6,-1566 # 8023f268 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000388e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003890:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003892:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003894:	6c89                	lui	s9,0x2
    80003896:	a061                	j	8000391e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003898:	97ca                	add	a5,a5,s2
    8000389a:	8e55                	or	a2,a2,a3
    8000389c:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800038a0:	854a                	mv	a0,s2
    800038a2:	00001097          	auipc	ra,0x1
    800038a6:	084080e7          	jalr	132(ra) # 80004926 <log_write>
        brelse(bp);
    800038aa:	854a                	mv	a0,s2
    800038ac:	00000097          	auipc	ra,0x0
    800038b0:	e22080e7          	jalr	-478(ra) # 800036ce <brelse>
  bp = bread(dev, bno);
    800038b4:	85a6                	mv	a1,s1
    800038b6:	855e                	mv	a0,s7
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	ce6080e7          	jalr	-794(ra) # 8000359e <bread>
    800038c0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038c2:	40000613          	li	a2,1024
    800038c6:	4581                	li	a1,0
    800038c8:	05850513          	addi	a0,a0,88
    800038cc:	ffffd097          	auipc	ra,0xffffd
    800038d0:	608080e7          	jalr	1544(ra) # 80000ed4 <memset>
  log_write(bp);
    800038d4:	854a                	mv	a0,s2
    800038d6:	00001097          	auipc	ra,0x1
    800038da:	050080e7          	jalr	80(ra) # 80004926 <log_write>
  brelse(bp);
    800038de:	854a                	mv	a0,s2
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	dee080e7          	jalr	-530(ra) # 800036ce <brelse>
}
    800038e8:	8526                	mv	a0,s1
    800038ea:	60e6                	ld	ra,88(sp)
    800038ec:	6446                	ld	s0,80(sp)
    800038ee:	64a6                	ld	s1,72(sp)
    800038f0:	6906                	ld	s2,64(sp)
    800038f2:	79e2                	ld	s3,56(sp)
    800038f4:	7a42                	ld	s4,48(sp)
    800038f6:	7aa2                	ld	s5,40(sp)
    800038f8:	7b02                	ld	s6,32(sp)
    800038fa:	6be2                	ld	s7,24(sp)
    800038fc:	6c42                	ld	s8,16(sp)
    800038fe:	6ca2                	ld	s9,8(sp)
    80003900:	6125                	addi	sp,sp,96
    80003902:	8082                	ret
    brelse(bp);
    80003904:	854a                	mv	a0,s2
    80003906:	00000097          	auipc	ra,0x0
    8000390a:	dc8080e7          	jalr	-568(ra) # 800036ce <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000390e:	015c87bb          	addw	a5,s9,s5
    80003912:	00078a9b          	sext.w	s5,a5
    80003916:	004b2703          	lw	a4,4(s6)
    8000391a:	06eaf163          	bgeu	s5,a4,8000397c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000391e:	41fad79b          	sraiw	a5,s5,0x1f
    80003922:	0137d79b          	srliw	a5,a5,0x13
    80003926:	015787bb          	addw	a5,a5,s5
    8000392a:	40d7d79b          	sraiw	a5,a5,0xd
    8000392e:	01cb2583          	lw	a1,28(s6)
    80003932:	9dbd                	addw	a1,a1,a5
    80003934:	855e                	mv	a0,s7
    80003936:	00000097          	auipc	ra,0x0
    8000393a:	c68080e7          	jalr	-920(ra) # 8000359e <bread>
    8000393e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003940:	004b2503          	lw	a0,4(s6)
    80003944:	000a849b          	sext.w	s1,s5
    80003948:	8762                	mv	a4,s8
    8000394a:	faa4fde3          	bgeu	s1,a0,80003904 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000394e:	00777693          	andi	a3,a4,7
    80003952:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003956:	41f7579b          	sraiw	a5,a4,0x1f
    8000395a:	01d7d79b          	srliw	a5,a5,0x1d
    8000395e:	9fb9                	addw	a5,a5,a4
    80003960:	4037d79b          	sraiw	a5,a5,0x3
    80003964:	00f90633          	add	a2,s2,a5
    80003968:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000396c:	00c6f5b3          	and	a1,a3,a2
    80003970:	d585                	beqz	a1,80003898 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003972:	2705                	addiw	a4,a4,1
    80003974:	2485                	addiw	s1,s1,1
    80003976:	fd471ae3          	bne	a4,s4,8000394a <balloc+0xec>
    8000397a:	b769                	j	80003904 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000397c:	00005517          	auipc	a0,0x5
    80003980:	dbc50513          	addi	a0,a0,-580 # 80008738 <syscalls+0x128>
    80003984:	ffffd097          	auipc	ra,0xffffd
    80003988:	c14080e7          	jalr	-1004(ra) # 80000598 <printf>
  return 0;
    8000398c:	4481                	li	s1,0
    8000398e:	bfa9                	j	800038e8 <balloc+0x8a>

0000000080003990 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003990:	7179                	addi	sp,sp,-48
    80003992:	f406                	sd	ra,40(sp)
    80003994:	f022                	sd	s0,32(sp)
    80003996:	ec26                	sd	s1,24(sp)
    80003998:	e84a                	sd	s2,16(sp)
    8000399a:	e44e                	sd	s3,8(sp)
    8000399c:	e052                	sd	s4,0(sp)
    8000399e:	1800                	addi	s0,sp,48
    800039a0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039a2:	47ad                	li	a5,11
    800039a4:	02b7e863          	bltu	a5,a1,800039d4 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800039a8:	02059793          	slli	a5,a1,0x20
    800039ac:	01e7d593          	srli	a1,a5,0x1e
    800039b0:	00b504b3          	add	s1,a0,a1
    800039b4:	0504a903          	lw	s2,80(s1)
    800039b8:	06091e63          	bnez	s2,80003a34 <bmap+0xa4>
      addr = balloc(ip->dev);
    800039bc:	4108                	lw	a0,0(a0)
    800039be:	00000097          	auipc	ra,0x0
    800039c2:	ea0080e7          	jalr	-352(ra) # 8000385e <balloc>
    800039c6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039ca:	06090563          	beqz	s2,80003a34 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800039ce:	0524a823          	sw	s2,80(s1)
    800039d2:	a08d                	j	80003a34 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039d4:	ff45849b          	addiw	s1,a1,-12
    800039d8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039dc:	0ff00793          	li	a5,255
    800039e0:	08e7e563          	bltu	a5,a4,80003a6a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039e4:	08052903          	lw	s2,128(a0)
    800039e8:	00091d63          	bnez	s2,80003a02 <bmap+0x72>
      addr = balloc(ip->dev);
    800039ec:	4108                	lw	a0,0(a0)
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	e70080e7          	jalr	-400(ra) # 8000385e <balloc>
    800039f6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039fa:	02090d63          	beqz	s2,80003a34 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800039fe:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a02:	85ca                	mv	a1,s2
    80003a04:	0009a503          	lw	a0,0(s3)
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	b96080e7          	jalr	-1130(ra) # 8000359e <bread>
    80003a10:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a12:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a16:	02049713          	slli	a4,s1,0x20
    80003a1a:	01e75593          	srli	a1,a4,0x1e
    80003a1e:	00b784b3          	add	s1,a5,a1
    80003a22:	0004a903          	lw	s2,0(s1)
    80003a26:	02090063          	beqz	s2,80003a46 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a2a:	8552                	mv	a0,s4
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	ca2080e7          	jalr	-862(ra) # 800036ce <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a34:	854a                	mv	a0,s2
    80003a36:	70a2                	ld	ra,40(sp)
    80003a38:	7402                	ld	s0,32(sp)
    80003a3a:	64e2                	ld	s1,24(sp)
    80003a3c:	6942                	ld	s2,16(sp)
    80003a3e:	69a2                	ld	s3,8(sp)
    80003a40:	6a02                	ld	s4,0(sp)
    80003a42:	6145                	addi	sp,sp,48
    80003a44:	8082                	ret
      addr = balloc(ip->dev);
    80003a46:	0009a503          	lw	a0,0(s3)
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	e14080e7          	jalr	-492(ra) # 8000385e <balloc>
    80003a52:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a56:	fc090ae3          	beqz	s2,80003a2a <bmap+0x9a>
        a[bn] = addr;
    80003a5a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a5e:	8552                	mv	a0,s4
    80003a60:	00001097          	auipc	ra,0x1
    80003a64:	ec6080e7          	jalr	-314(ra) # 80004926 <log_write>
    80003a68:	b7c9                	j	80003a2a <bmap+0x9a>
  panic("bmap: out of range");
    80003a6a:	00005517          	auipc	a0,0x5
    80003a6e:	ce650513          	addi	a0,a0,-794 # 80008750 <syscalls+0x140>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	aca080e7          	jalr	-1334(ra) # 8000053c <panic>

0000000080003a7a <iget>:
{
    80003a7a:	7179                	addi	sp,sp,-48
    80003a7c:	f406                	sd	ra,40(sp)
    80003a7e:	f022                	sd	s0,32(sp)
    80003a80:	ec26                	sd	s1,24(sp)
    80003a82:	e84a                	sd	s2,16(sp)
    80003a84:	e44e                	sd	s3,8(sp)
    80003a86:	e052                	sd	s4,0(sp)
    80003a88:	1800                	addi	s0,sp,48
    80003a8a:	89aa                	mv	s3,a0
    80003a8c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a8e:	0023b517          	auipc	a0,0x23b
    80003a92:	7fa50513          	addi	a0,a0,2042 # 8023f288 <itable>
    80003a96:	ffffd097          	auipc	ra,0xffffd
    80003a9a:	342080e7          	jalr	834(ra) # 80000dd8 <acquire>
  empty = 0;
    80003a9e:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aa0:	0023c497          	auipc	s1,0x23c
    80003aa4:	80048493          	addi	s1,s1,-2048 # 8023f2a0 <itable+0x18>
    80003aa8:	0023d697          	auipc	a3,0x23d
    80003aac:	28868693          	addi	a3,a3,648 # 80240d30 <log>
    80003ab0:	a039                	j	80003abe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ab2:	02090b63          	beqz	s2,80003ae8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ab6:	08848493          	addi	s1,s1,136
    80003aba:	02d48a63          	beq	s1,a3,80003aee <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003abe:	449c                	lw	a5,8(s1)
    80003ac0:	fef059e3          	blez	a5,80003ab2 <iget+0x38>
    80003ac4:	4098                	lw	a4,0(s1)
    80003ac6:	ff3716e3          	bne	a4,s3,80003ab2 <iget+0x38>
    80003aca:	40d8                	lw	a4,4(s1)
    80003acc:	ff4713e3          	bne	a4,s4,80003ab2 <iget+0x38>
      ip->ref++;
    80003ad0:	2785                	addiw	a5,a5,1
    80003ad2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ad4:	0023b517          	auipc	a0,0x23b
    80003ad8:	7b450513          	addi	a0,a0,1972 # 8023f288 <itable>
    80003adc:	ffffd097          	auipc	ra,0xffffd
    80003ae0:	3b0080e7          	jalr	944(ra) # 80000e8c <release>
      return ip;
    80003ae4:	8926                	mv	s2,s1
    80003ae6:	a03d                	j	80003b14 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ae8:	f7f9                	bnez	a5,80003ab6 <iget+0x3c>
    80003aea:	8926                	mv	s2,s1
    80003aec:	b7e9                	j	80003ab6 <iget+0x3c>
  if(empty == 0)
    80003aee:	02090c63          	beqz	s2,80003b26 <iget+0xac>
  ip->dev = dev;
    80003af2:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003af6:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003afa:	4785                	li	a5,1
    80003afc:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b00:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b04:	0023b517          	auipc	a0,0x23b
    80003b08:	78450513          	addi	a0,a0,1924 # 8023f288 <itable>
    80003b0c:	ffffd097          	auipc	ra,0xffffd
    80003b10:	380080e7          	jalr	896(ra) # 80000e8c <release>
}
    80003b14:	854a                	mv	a0,s2
    80003b16:	70a2                	ld	ra,40(sp)
    80003b18:	7402                	ld	s0,32(sp)
    80003b1a:	64e2                	ld	s1,24(sp)
    80003b1c:	6942                	ld	s2,16(sp)
    80003b1e:	69a2                	ld	s3,8(sp)
    80003b20:	6a02                	ld	s4,0(sp)
    80003b22:	6145                	addi	sp,sp,48
    80003b24:	8082                	ret
    panic("iget: no inodes");
    80003b26:	00005517          	auipc	a0,0x5
    80003b2a:	c4250513          	addi	a0,a0,-958 # 80008768 <syscalls+0x158>
    80003b2e:	ffffd097          	auipc	ra,0xffffd
    80003b32:	a0e080e7          	jalr	-1522(ra) # 8000053c <panic>

0000000080003b36 <fsinit>:
fsinit(int dev) {
    80003b36:	7179                	addi	sp,sp,-48
    80003b38:	f406                	sd	ra,40(sp)
    80003b3a:	f022                	sd	s0,32(sp)
    80003b3c:	ec26                	sd	s1,24(sp)
    80003b3e:	e84a                	sd	s2,16(sp)
    80003b40:	e44e                	sd	s3,8(sp)
    80003b42:	1800                	addi	s0,sp,48
    80003b44:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b46:	4585                	li	a1,1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	a56080e7          	jalr	-1450(ra) # 8000359e <bread>
    80003b50:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b52:	0023b997          	auipc	s3,0x23b
    80003b56:	71698993          	addi	s3,s3,1814 # 8023f268 <sb>
    80003b5a:	02000613          	li	a2,32
    80003b5e:	05850593          	addi	a1,a0,88
    80003b62:	854e                	mv	a0,s3
    80003b64:	ffffd097          	auipc	ra,0xffffd
    80003b68:	3cc080e7          	jalr	972(ra) # 80000f30 <memmove>
  brelse(bp);
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	b60080e7          	jalr	-1184(ra) # 800036ce <brelse>
  if(sb.magic != FSMAGIC)
    80003b76:	0009a703          	lw	a4,0(s3)
    80003b7a:	102037b7          	lui	a5,0x10203
    80003b7e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b82:	02f71263          	bne	a4,a5,80003ba6 <fsinit+0x70>
  initlog(dev, &sb);
    80003b86:	0023b597          	auipc	a1,0x23b
    80003b8a:	6e258593          	addi	a1,a1,1762 # 8023f268 <sb>
    80003b8e:	854a                	mv	a0,s2
    80003b90:	00001097          	auipc	ra,0x1
    80003b94:	b2c080e7          	jalr	-1236(ra) # 800046bc <initlog>
}
    80003b98:	70a2                	ld	ra,40(sp)
    80003b9a:	7402                	ld	s0,32(sp)
    80003b9c:	64e2                	ld	s1,24(sp)
    80003b9e:	6942                	ld	s2,16(sp)
    80003ba0:	69a2                	ld	s3,8(sp)
    80003ba2:	6145                	addi	sp,sp,48
    80003ba4:	8082                	ret
    panic("invalid file system");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	bd250513          	addi	a0,a0,-1070 # 80008778 <syscalls+0x168>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	98e080e7          	jalr	-1650(ra) # 8000053c <panic>

0000000080003bb6 <iinit>:
{
    80003bb6:	7179                	addi	sp,sp,-48
    80003bb8:	f406                	sd	ra,40(sp)
    80003bba:	f022                	sd	s0,32(sp)
    80003bbc:	ec26                	sd	s1,24(sp)
    80003bbe:	e84a                	sd	s2,16(sp)
    80003bc0:	e44e                	sd	s3,8(sp)
    80003bc2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bc4:	00005597          	auipc	a1,0x5
    80003bc8:	bcc58593          	addi	a1,a1,-1076 # 80008790 <syscalls+0x180>
    80003bcc:	0023b517          	auipc	a0,0x23b
    80003bd0:	6bc50513          	addi	a0,a0,1724 # 8023f288 <itable>
    80003bd4:	ffffd097          	auipc	ra,0xffffd
    80003bd8:	174080e7          	jalr	372(ra) # 80000d48 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bdc:	0023b497          	auipc	s1,0x23b
    80003be0:	6d448493          	addi	s1,s1,1748 # 8023f2b0 <itable+0x28>
    80003be4:	0023d997          	auipc	s3,0x23d
    80003be8:	15c98993          	addi	s3,s3,348 # 80240d40 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bec:	00005917          	auipc	s2,0x5
    80003bf0:	bac90913          	addi	s2,s2,-1108 # 80008798 <syscalls+0x188>
    80003bf4:	85ca                	mv	a1,s2
    80003bf6:	8526                	mv	a0,s1
    80003bf8:	00001097          	auipc	ra,0x1
    80003bfc:	e12080e7          	jalr	-494(ra) # 80004a0a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c00:	08848493          	addi	s1,s1,136
    80003c04:	ff3498e3          	bne	s1,s3,80003bf4 <iinit+0x3e>
}
    80003c08:	70a2                	ld	ra,40(sp)
    80003c0a:	7402                	ld	s0,32(sp)
    80003c0c:	64e2                	ld	s1,24(sp)
    80003c0e:	6942                	ld	s2,16(sp)
    80003c10:	69a2                	ld	s3,8(sp)
    80003c12:	6145                	addi	sp,sp,48
    80003c14:	8082                	ret

0000000080003c16 <ialloc>:
{
    80003c16:	7139                	addi	sp,sp,-64
    80003c18:	fc06                	sd	ra,56(sp)
    80003c1a:	f822                	sd	s0,48(sp)
    80003c1c:	f426                	sd	s1,40(sp)
    80003c1e:	f04a                	sd	s2,32(sp)
    80003c20:	ec4e                	sd	s3,24(sp)
    80003c22:	e852                	sd	s4,16(sp)
    80003c24:	e456                	sd	s5,8(sp)
    80003c26:	e05a                	sd	s6,0(sp)
    80003c28:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c2a:	0023b717          	auipc	a4,0x23b
    80003c2e:	64a72703          	lw	a4,1610(a4) # 8023f274 <sb+0xc>
    80003c32:	4785                	li	a5,1
    80003c34:	04e7f863          	bgeu	a5,a4,80003c84 <ialloc+0x6e>
    80003c38:	8aaa                	mv	s5,a0
    80003c3a:	8b2e                	mv	s6,a1
    80003c3c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c3e:	0023ba17          	auipc	s4,0x23b
    80003c42:	62aa0a13          	addi	s4,s4,1578 # 8023f268 <sb>
    80003c46:	00495593          	srli	a1,s2,0x4
    80003c4a:	018a2783          	lw	a5,24(s4)
    80003c4e:	9dbd                	addw	a1,a1,a5
    80003c50:	8556                	mv	a0,s5
    80003c52:	00000097          	auipc	ra,0x0
    80003c56:	94c080e7          	jalr	-1716(ra) # 8000359e <bread>
    80003c5a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c5c:	05850993          	addi	s3,a0,88
    80003c60:	00f97793          	andi	a5,s2,15
    80003c64:	079a                	slli	a5,a5,0x6
    80003c66:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c68:	00099783          	lh	a5,0(s3)
    80003c6c:	cf9d                	beqz	a5,80003caa <ialloc+0x94>
    brelse(bp);
    80003c6e:	00000097          	auipc	ra,0x0
    80003c72:	a60080e7          	jalr	-1440(ra) # 800036ce <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c76:	0905                	addi	s2,s2,1
    80003c78:	00ca2703          	lw	a4,12(s4)
    80003c7c:	0009079b          	sext.w	a5,s2
    80003c80:	fce7e3e3          	bltu	a5,a4,80003c46 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003c84:	00005517          	auipc	a0,0x5
    80003c88:	b1c50513          	addi	a0,a0,-1252 # 800087a0 <syscalls+0x190>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	90c080e7          	jalr	-1780(ra) # 80000598 <printf>
  return 0;
    80003c94:	4501                	li	a0,0
}
    80003c96:	70e2                	ld	ra,56(sp)
    80003c98:	7442                	ld	s0,48(sp)
    80003c9a:	74a2                	ld	s1,40(sp)
    80003c9c:	7902                	ld	s2,32(sp)
    80003c9e:	69e2                	ld	s3,24(sp)
    80003ca0:	6a42                	ld	s4,16(sp)
    80003ca2:	6aa2                	ld	s5,8(sp)
    80003ca4:	6b02                	ld	s6,0(sp)
    80003ca6:	6121                	addi	sp,sp,64
    80003ca8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003caa:	04000613          	li	a2,64
    80003cae:	4581                	li	a1,0
    80003cb0:	854e                	mv	a0,s3
    80003cb2:	ffffd097          	auipc	ra,0xffffd
    80003cb6:	222080e7          	jalr	546(ra) # 80000ed4 <memset>
      dip->type = type;
    80003cba:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cbe:	8526                	mv	a0,s1
    80003cc0:	00001097          	auipc	ra,0x1
    80003cc4:	c66080e7          	jalr	-922(ra) # 80004926 <log_write>
      brelse(bp);
    80003cc8:	8526                	mv	a0,s1
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	a04080e7          	jalr	-1532(ra) # 800036ce <brelse>
      return iget(dev, inum);
    80003cd2:	0009059b          	sext.w	a1,s2
    80003cd6:	8556                	mv	a0,s5
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	da2080e7          	jalr	-606(ra) # 80003a7a <iget>
    80003ce0:	bf5d                	j	80003c96 <ialloc+0x80>

0000000080003ce2 <iupdate>:
{
    80003ce2:	1101                	addi	sp,sp,-32
    80003ce4:	ec06                	sd	ra,24(sp)
    80003ce6:	e822                	sd	s0,16(sp)
    80003ce8:	e426                	sd	s1,8(sp)
    80003cea:	e04a                	sd	s2,0(sp)
    80003cec:	1000                	addi	s0,sp,32
    80003cee:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cf0:	415c                	lw	a5,4(a0)
    80003cf2:	0047d79b          	srliw	a5,a5,0x4
    80003cf6:	0023b597          	auipc	a1,0x23b
    80003cfa:	58a5a583          	lw	a1,1418(a1) # 8023f280 <sb+0x18>
    80003cfe:	9dbd                	addw	a1,a1,a5
    80003d00:	4108                	lw	a0,0(a0)
    80003d02:	00000097          	auipc	ra,0x0
    80003d06:	89c080e7          	jalr	-1892(ra) # 8000359e <bread>
    80003d0a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d0c:	05850793          	addi	a5,a0,88
    80003d10:	40d8                	lw	a4,4(s1)
    80003d12:	8b3d                	andi	a4,a4,15
    80003d14:	071a                	slli	a4,a4,0x6
    80003d16:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d18:	04449703          	lh	a4,68(s1)
    80003d1c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d20:	04649703          	lh	a4,70(s1)
    80003d24:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d28:	04849703          	lh	a4,72(s1)
    80003d2c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d30:	04a49703          	lh	a4,74(s1)
    80003d34:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d38:	44f8                	lw	a4,76(s1)
    80003d3a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d3c:	03400613          	li	a2,52
    80003d40:	05048593          	addi	a1,s1,80
    80003d44:	00c78513          	addi	a0,a5,12
    80003d48:	ffffd097          	auipc	ra,0xffffd
    80003d4c:	1e8080e7          	jalr	488(ra) # 80000f30 <memmove>
  log_write(bp);
    80003d50:	854a                	mv	a0,s2
    80003d52:	00001097          	auipc	ra,0x1
    80003d56:	bd4080e7          	jalr	-1068(ra) # 80004926 <log_write>
  brelse(bp);
    80003d5a:	854a                	mv	a0,s2
    80003d5c:	00000097          	auipc	ra,0x0
    80003d60:	972080e7          	jalr	-1678(ra) # 800036ce <brelse>
}
    80003d64:	60e2                	ld	ra,24(sp)
    80003d66:	6442                	ld	s0,16(sp)
    80003d68:	64a2                	ld	s1,8(sp)
    80003d6a:	6902                	ld	s2,0(sp)
    80003d6c:	6105                	addi	sp,sp,32
    80003d6e:	8082                	ret

0000000080003d70 <idup>:
{
    80003d70:	1101                	addi	sp,sp,-32
    80003d72:	ec06                	sd	ra,24(sp)
    80003d74:	e822                	sd	s0,16(sp)
    80003d76:	e426                	sd	s1,8(sp)
    80003d78:	1000                	addi	s0,sp,32
    80003d7a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d7c:	0023b517          	auipc	a0,0x23b
    80003d80:	50c50513          	addi	a0,a0,1292 # 8023f288 <itable>
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	054080e7          	jalr	84(ra) # 80000dd8 <acquire>
  ip->ref++;
    80003d8c:	449c                	lw	a5,8(s1)
    80003d8e:	2785                	addiw	a5,a5,1
    80003d90:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d92:	0023b517          	auipc	a0,0x23b
    80003d96:	4f650513          	addi	a0,a0,1270 # 8023f288 <itable>
    80003d9a:	ffffd097          	auipc	ra,0xffffd
    80003d9e:	0f2080e7          	jalr	242(ra) # 80000e8c <release>
}
    80003da2:	8526                	mv	a0,s1
    80003da4:	60e2                	ld	ra,24(sp)
    80003da6:	6442                	ld	s0,16(sp)
    80003da8:	64a2                	ld	s1,8(sp)
    80003daa:	6105                	addi	sp,sp,32
    80003dac:	8082                	ret

0000000080003dae <ilock>:
{
    80003dae:	1101                	addi	sp,sp,-32
    80003db0:	ec06                	sd	ra,24(sp)
    80003db2:	e822                	sd	s0,16(sp)
    80003db4:	e426                	sd	s1,8(sp)
    80003db6:	e04a                	sd	s2,0(sp)
    80003db8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dba:	c115                	beqz	a0,80003dde <ilock+0x30>
    80003dbc:	84aa                	mv	s1,a0
    80003dbe:	451c                	lw	a5,8(a0)
    80003dc0:	00f05f63          	blez	a5,80003dde <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dc4:	0541                	addi	a0,a0,16
    80003dc6:	00001097          	auipc	ra,0x1
    80003dca:	c7e080e7          	jalr	-898(ra) # 80004a44 <acquiresleep>
  if(ip->valid == 0){
    80003dce:	40bc                	lw	a5,64(s1)
    80003dd0:	cf99                	beqz	a5,80003dee <ilock+0x40>
}
    80003dd2:	60e2                	ld	ra,24(sp)
    80003dd4:	6442                	ld	s0,16(sp)
    80003dd6:	64a2                	ld	s1,8(sp)
    80003dd8:	6902                	ld	s2,0(sp)
    80003dda:	6105                	addi	sp,sp,32
    80003ddc:	8082                	ret
    panic("ilock");
    80003dde:	00005517          	auipc	a0,0x5
    80003de2:	9da50513          	addi	a0,a0,-1574 # 800087b8 <syscalls+0x1a8>
    80003de6:	ffffc097          	auipc	ra,0xffffc
    80003dea:	756080e7          	jalr	1878(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dee:	40dc                	lw	a5,4(s1)
    80003df0:	0047d79b          	srliw	a5,a5,0x4
    80003df4:	0023b597          	auipc	a1,0x23b
    80003df8:	48c5a583          	lw	a1,1164(a1) # 8023f280 <sb+0x18>
    80003dfc:	9dbd                	addw	a1,a1,a5
    80003dfe:	4088                	lw	a0,0(s1)
    80003e00:	fffff097          	auipc	ra,0xfffff
    80003e04:	79e080e7          	jalr	1950(ra) # 8000359e <bread>
    80003e08:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e0a:	05850593          	addi	a1,a0,88
    80003e0e:	40dc                	lw	a5,4(s1)
    80003e10:	8bbd                	andi	a5,a5,15
    80003e12:	079a                	slli	a5,a5,0x6
    80003e14:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e16:	00059783          	lh	a5,0(a1)
    80003e1a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e1e:	00259783          	lh	a5,2(a1)
    80003e22:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e26:	00459783          	lh	a5,4(a1)
    80003e2a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e2e:	00659783          	lh	a5,6(a1)
    80003e32:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e36:	459c                	lw	a5,8(a1)
    80003e38:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e3a:	03400613          	li	a2,52
    80003e3e:	05b1                	addi	a1,a1,12
    80003e40:	05048513          	addi	a0,s1,80
    80003e44:	ffffd097          	auipc	ra,0xffffd
    80003e48:	0ec080e7          	jalr	236(ra) # 80000f30 <memmove>
    brelse(bp);
    80003e4c:	854a                	mv	a0,s2
    80003e4e:	00000097          	auipc	ra,0x0
    80003e52:	880080e7          	jalr	-1920(ra) # 800036ce <brelse>
    ip->valid = 1;
    80003e56:	4785                	li	a5,1
    80003e58:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e5a:	04449783          	lh	a5,68(s1)
    80003e5e:	fbb5                	bnez	a5,80003dd2 <ilock+0x24>
      panic("ilock: no type");
    80003e60:	00005517          	auipc	a0,0x5
    80003e64:	96050513          	addi	a0,a0,-1696 # 800087c0 <syscalls+0x1b0>
    80003e68:	ffffc097          	auipc	ra,0xffffc
    80003e6c:	6d4080e7          	jalr	1748(ra) # 8000053c <panic>

0000000080003e70 <iunlock>:
{
    80003e70:	1101                	addi	sp,sp,-32
    80003e72:	ec06                	sd	ra,24(sp)
    80003e74:	e822                	sd	s0,16(sp)
    80003e76:	e426                	sd	s1,8(sp)
    80003e78:	e04a                	sd	s2,0(sp)
    80003e7a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e7c:	c905                	beqz	a0,80003eac <iunlock+0x3c>
    80003e7e:	84aa                	mv	s1,a0
    80003e80:	01050913          	addi	s2,a0,16
    80003e84:	854a                	mv	a0,s2
    80003e86:	00001097          	auipc	ra,0x1
    80003e8a:	c58080e7          	jalr	-936(ra) # 80004ade <holdingsleep>
    80003e8e:	cd19                	beqz	a0,80003eac <iunlock+0x3c>
    80003e90:	449c                	lw	a5,8(s1)
    80003e92:	00f05d63          	blez	a5,80003eac <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e96:	854a                	mv	a0,s2
    80003e98:	00001097          	auipc	ra,0x1
    80003e9c:	c02080e7          	jalr	-1022(ra) # 80004a9a <releasesleep>
}
    80003ea0:	60e2                	ld	ra,24(sp)
    80003ea2:	6442                	ld	s0,16(sp)
    80003ea4:	64a2                	ld	s1,8(sp)
    80003ea6:	6902                	ld	s2,0(sp)
    80003ea8:	6105                	addi	sp,sp,32
    80003eaa:	8082                	ret
    panic("iunlock");
    80003eac:	00005517          	auipc	a0,0x5
    80003eb0:	92450513          	addi	a0,a0,-1756 # 800087d0 <syscalls+0x1c0>
    80003eb4:	ffffc097          	auipc	ra,0xffffc
    80003eb8:	688080e7          	jalr	1672(ra) # 8000053c <panic>

0000000080003ebc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ebc:	7179                	addi	sp,sp,-48
    80003ebe:	f406                	sd	ra,40(sp)
    80003ec0:	f022                	sd	s0,32(sp)
    80003ec2:	ec26                	sd	s1,24(sp)
    80003ec4:	e84a                	sd	s2,16(sp)
    80003ec6:	e44e                	sd	s3,8(sp)
    80003ec8:	e052                	sd	s4,0(sp)
    80003eca:	1800                	addi	s0,sp,48
    80003ecc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ece:	05050493          	addi	s1,a0,80
    80003ed2:	08050913          	addi	s2,a0,128
    80003ed6:	a021                	j	80003ede <itrunc+0x22>
    80003ed8:	0491                	addi	s1,s1,4
    80003eda:	01248d63          	beq	s1,s2,80003ef4 <itrunc+0x38>
    if(ip->addrs[i]){
    80003ede:	408c                	lw	a1,0(s1)
    80003ee0:	dde5                	beqz	a1,80003ed8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ee2:	0009a503          	lw	a0,0(s3)
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	8fc080e7          	jalr	-1796(ra) # 800037e2 <bfree>
      ip->addrs[i] = 0;
    80003eee:	0004a023          	sw	zero,0(s1)
    80003ef2:	b7dd                	j	80003ed8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003ef4:	0809a583          	lw	a1,128(s3)
    80003ef8:	e185                	bnez	a1,80003f18 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003efa:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003efe:	854e                	mv	a0,s3
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	de2080e7          	jalr	-542(ra) # 80003ce2 <iupdate>
}
    80003f08:	70a2                	ld	ra,40(sp)
    80003f0a:	7402                	ld	s0,32(sp)
    80003f0c:	64e2                	ld	s1,24(sp)
    80003f0e:	6942                	ld	s2,16(sp)
    80003f10:	69a2                	ld	s3,8(sp)
    80003f12:	6a02                	ld	s4,0(sp)
    80003f14:	6145                	addi	sp,sp,48
    80003f16:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f18:	0009a503          	lw	a0,0(s3)
    80003f1c:	fffff097          	auipc	ra,0xfffff
    80003f20:	682080e7          	jalr	1666(ra) # 8000359e <bread>
    80003f24:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f26:	05850493          	addi	s1,a0,88
    80003f2a:	45850913          	addi	s2,a0,1112
    80003f2e:	a021                	j	80003f36 <itrunc+0x7a>
    80003f30:	0491                	addi	s1,s1,4
    80003f32:	01248b63          	beq	s1,s2,80003f48 <itrunc+0x8c>
      if(a[j])
    80003f36:	408c                	lw	a1,0(s1)
    80003f38:	dde5                	beqz	a1,80003f30 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f3a:	0009a503          	lw	a0,0(s3)
    80003f3e:	00000097          	auipc	ra,0x0
    80003f42:	8a4080e7          	jalr	-1884(ra) # 800037e2 <bfree>
    80003f46:	b7ed                	j	80003f30 <itrunc+0x74>
    brelse(bp);
    80003f48:	8552                	mv	a0,s4
    80003f4a:	fffff097          	auipc	ra,0xfffff
    80003f4e:	784080e7          	jalr	1924(ra) # 800036ce <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f52:	0809a583          	lw	a1,128(s3)
    80003f56:	0009a503          	lw	a0,0(s3)
    80003f5a:	00000097          	auipc	ra,0x0
    80003f5e:	888080e7          	jalr	-1912(ra) # 800037e2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f62:	0809a023          	sw	zero,128(s3)
    80003f66:	bf51                	j	80003efa <itrunc+0x3e>

0000000080003f68 <iput>:
{
    80003f68:	1101                	addi	sp,sp,-32
    80003f6a:	ec06                	sd	ra,24(sp)
    80003f6c:	e822                	sd	s0,16(sp)
    80003f6e:	e426                	sd	s1,8(sp)
    80003f70:	e04a                	sd	s2,0(sp)
    80003f72:	1000                	addi	s0,sp,32
    80003f74:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f76:	0023b517          	auipc	a0,0x23b
    80003f7a:	31250513          	addi	a0,a0,786 # 8023f288 <itable>
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	e5a080e7          	jalr	-422(ra) # 80000dd8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f86:	4498                	lw	a4,8(s1)
    80003f88:	4785                	li	a5,1
    80003f8a:	02f70363          	beq	a4,a5,80003fb0 <iput+0x48>
  ip->ref--;
    80003f8e:	449c                	lw	a5,8(s1)
    80003f90:	37fd                	addiw	a5,a5,-1
    80003f92:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f94:	0023b517          	auipc	a0,0x23b
    80003f98:	2f450513          	addi	a0,a0,756 # 8023f288 <itable>
    80003f9c:	ffffd097          	auipc	ra,0xffffd
    80003fa0:	ef0080e7          	jalr	-272(ra) # 80000e8c <release>
}
    80003fa4:	60e2                	ld	ra,24(sp)
    80003fa6:	6442                	ld	s0,16(sp)
    80003fa8:	64a2                	ld	s1,8(sp)
    80003faa:	6902                	ld	s2,0(sp)
    80003fac:	6105                	addi	sp,sp,32
    80003fae:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fb0:	40bc                	lw	a5,64(s1)
    80003fb2:	dff1                	beqz	a5,80003f8e <iput+0x26>
    80003fb4:	04a49783          	lh	a5,74(s1)
    80003fb8:	fbf9                	bnez	a5,80003f8e <iput+0x26>
    acquiresleep(&ip->lock);
    80003fba:	01048913          	addi	s2,s1,16
    80003fbe:	854a                	mv	a0,s2
    80003fc0:	00001097          	auipc	ra,0x1
    80003fc4:	a84080e7          	jalr	-1404(ra) # 80004a44 <acquiresleep>
    release(&itable.lock);
    80003fc8:	0023b517          	auipc	a0,0x23b
    80003fcc:	2c050513          	addi	a0,a0,704 # 8023f288 <itable>
    80003fd0:	ffffd097          	auipc	ra,0xffffd
    80003fd4:	ebc080e7          	jalr	-324(ra) # 80000e8c <release>
    itrunc(ip);
    80003fd8:	8526                	mv	a0,s1
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	ee2080e7          	jalr	-286(ra) # 80003ebc <itrunc>
    ip->type = 0;
    80003fe2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fe6:	8526                	mv	a0,s1
    80003fe8:	00000097          	auipc	ra,0x0
    80003fec:	cfa080e7          	jalr	-774(ra) # 80003ce2 <iupdate>
    ip->valid = 0;
    80003ff0:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ff4:	854a                	mv	a0,s2
    80003ff6:	00001097          	auipc	ra,0x1
    80003ffa:	aa4080e7          	jalr	-1372(ra) # 80004a9a <releasesleep>
    acquire(&itable.lock);
    80003ffe:	0023b517          	auipc	a0,0x23b
    80004002:	28a50513          	addi	a0,a0,650 # 8023f288 <itable>
    80004006:	ffffd097          	auipc	ra,0xffffd
    8000400a:	dd2080e7          	jalr	-558(ra) # 80000dd8 <acquire>
    8000400e:	b741                	j	80003f8e <iput+0x26>

0000000080004010 <iunlockput>:
{
    80004010:	1101                	addi	sp,sp,-32
    80004012:	ec06                	sd	ra,24(sp)
    80004014:	e822                	sd	s0,16(sp)
    80004016:	e426                	sd	s1,8(sp)
    80004018:	1000                	addi	s0,sp,32
    8000401a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000401c:	00000097          	auipc	ra,0x0
    80004020:	e54080e7          	jalr	-428(ra) # 80003e70 <iunlock>
  iput(ip);
    80004024:	8526                	mv	a0,s1
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	f42080e7          	jalr	-190(ra) # 80003f68 <iput>
}
    8000402e:	60e2                	ld	ra,24(sp)
    80004030:	6442                	ld	s0,16(sp)
    80004032:	64a2                	ld	s1,8(sp)
    80004034:	6105                	addi	sp,sp,32
    80004036:	8082                	ret

0000000080004038 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004038:	1141                	addi	sp,sp,-16
    8000403a:	e422                	sd	s0,8(sp)
    8000403c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000403e:	411c                	lw	a5,0(a0)
    80004040:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004042:	415c                	lw	a5,4(a0)
    80004044:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004046:	04451783          	lh	a5,68(a0)
    8000404a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000404e:	04a51783          	lh	a5,74(a0)
    80004052:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004056:	04c56783          	lwu	a5,76(a0)
    8000405a:	e99c                	sd	a5,16(a1)
}
    8000405c:	6422                	ld	s0,8(sp)
    8000405e:	0141                	addi	sp,sp,16
    80004060:	8082                	ret

0000000080004062 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004062:	457c                	lw	a5,76(a0)
    80004064:	0ed7e963          	bltu	a5,a3,80004156 <readi+0xf4>
{
    80004068:	7159                	addi	sp,sp,-112
    8000406a:	f486                	sd	ra,104(sp)
    8000406c:	f0a2                	sd	s0,96(sp)
    8000406e:	eca6                	sd	s1,88(sp)
    80004070:	e8ca                	sd	s2,80(sp)
    80004072:	e4ce                	sd	s3,72(sp)
    80004074:	e0d2                	sd	s4,64(sp)
    80004076:	fc56                	sd	s5,56(sp)
    80004078:	f85a                	sd	s6,48(sp)
    8000407a:	f45e                	sd	s7,40(sp)
    8000407c:	f062                	sd	s8,32(sp)
    8000407e:	ec66                	sd	s9,24(sp)
    80004080:	e86a                	sd	s10,16(sp)
    80004082:	e46e                	sd	s11,8(sp)
    80004084:	1880                	addi	s0,sp,112
    80004086:	8b2a                	mv	s6,a0
    80004088:	8bae                	mv	s7,a1
    8000408a:	8a32                	mv	s4,a2
    8000408c:	84b6                	mv	s1,a3
    8000408e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004090:	9f35                	addw	a4,a4,a3
    return 0;
    80004092:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004094:	0ad76063          	bltu	a4,a3,80004134 <readi+0xd2>
  if(off + n > ip->size)
    80004098:	00e7f463          	bgeu	a5,a4,800040a0 <readi+0x3e>
    n = ip->size - off;
    8000409c:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040a0:	0a0a8963          	beqz	s5,80004152 <readi+0xf0>
    800040a4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040a6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040aa:	5c7d                	li	s8,-1
    800040ac:	a82d                	j	800040e6 <readi+0x84>
    800040ae:	020d1d93          	slli	s11,s10,0x20
    800040b2:	020ddd93          	srli	s11,s11,0x20
    800040b6:	05890613          	addi	a2,s2,88
    800040ba:	86ee                	mv	a3,s11
    800040bc:	963a                	add	a2,a2,a4
    800040be:	85d2                	mv	a1,s4
    800040c0:	855e                	mv	a0,s7
    800040c2:	fffff097          	auipc	ra,0xfffff
    800040c6:	81a080e7          	jalr	-2022(ra) # 800028dc <either_copyout>
    800040ca:	05850d63          	beq	a0,s8,80004124 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040ce:	854a                	mv	a0,s2
    800040d0:	fffff097          	auipc	ra,0xfffff
    800040d4:	5fe080e7          	jalr	1534(ra) # 800036ce <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040d8:	013d09bb          	addw	s3,s10,s3
    800040dc:	009d04bb          	addw	s1,s10,s1
    800040e0:	9a6e                	add	s4,s4,s11
    800040e2:	0559f763          	bgeu	s3,s5,80004130 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040e6:	00a4d59b          	srliw	a1,s1,0xa
    800040ea:	855a                	mv	a0,s6
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	8a4080e7          	jalr	-1884(ra) # 80003990 <bmap>
    800040f4:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800040f8:	cd85                	beqz	a1,80004130 <readi+0xce>
    bp = bread(ip->dev, addr);
    800040fa:	000b2503          	lw	a0,0(s6)
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	4a0080e7          	jalr	1184(ra) # 8000359e <bread>
    80004106:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004108:	3ff4f713          	andi	a4,s1,1023
    8000410c:	40ec87bb          	subw	a5,s9,a4
    80004110:	413a86bb          	subw	a3,s5,s3
    80004114:	8d3e                	mv	s10,a5
    80004116:	2781                	sext.w	a5,a5
    80004118:	0006861b          	sext.w	a2,a3
    8000411c:	f8f679e3          	bgeu	a2,a5,800040ae <readi+0x4c>
    80004120:	8d36                	mv	s10,a3
    80004122:	b771                	j	800040ae <readi+0x4c>
      brelse(bp);
    80004124:	854a                	mv	a0,s2
    80004126:	fffff097          	auipc	ra,0xfffff
    8000412a:	5a8080e7          	jalr	1448(ra) # 800036ce <brelse>
      tot = -1;
    8000412e:	59fd                	li	s3,-1
  }
  return tot;
    80004130:	0009851b          	sext.w	a0,s3
}
    80004134:	70a6                	ld	ra,104(sp)
    80004136:	7406                	ld	s0,96(sp)
    80004138:	64e6                	ld	s1,88(sp)
    8000413a:	6946                	ld	s2,80(sp)
    8000413c:	69a6                	ld	s3,72(sp)
    8000413e:	6a06                	ld	s4,64(sp)
    80004140:	7ae2                	ld	s5,56(sp)
    80004142:	7b42                	ld	s6,48(sp)
    80004144:	7ba2                	ld	s7,40(sp)
    80004146:	7c02                	ld	s8,32(sp)
    80004148:	6ce2                	ld	s9,24(sp)
    8000414a:	6d42                	ld	s10,16(sp)
    8000414c:	6da2                	ld	s11,8(sp)
    8000414e:	6165                	addi	sp,sp,112
    80004150:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004152:	89d6                	mv	s3,s5
    80004154:	bff1                	j	80004130 <readi+0xce>
    return 0;
    80004156:	4501                	li	a0,0
}
    80004158:	8082                	ret

000000008000415a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000415a:	457c                	lw	a5,76(a0)
    8000415c:	10d7e863          	bltu	a5,a3,8000426c <writei+0x112>
{
    80004160:	7159                	addi	sp,sp,-112
    80004162:	f486                	sd	ra,104(sp)
    80004164:	f0a2                	sd	s0,96(sp)
    80004166:	eca6                	sd	s1,88(sp)
    80004168:	e8ca                	sd	s2,80(sp)
    8000416a:	e4ce                	sd	s3,72(sp)
    8000416c:	e0d2                	sd	s4,64(sp)
    8000416e:	fc56                	sd	s5,56(sp)
    80004170:	f85a                	sd	s6,48(sp)
    80004172:	f45e                	sd	s7,40(sp)
    80004174:	f062                	sd	s8,32(sp)
    80004176:	ec66                	sd	s9,24(sp)
    80004178:	e86a                	sd	s10,16(sp)
    8000417a:	e46e                	sd	s11,8(sp)
    8000417c:	1880                	addi	s0,sp,112
    8000417e:	8aaa                	mv	s5,a0
    80004180:	8bae                	mv	s7,a1
    80004182:	8a32                	mv	s4,a2
    80004184:	8936                	mv	s2,a3
    80004186:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004188:	00e687bb          	addw	a5,a3,a4
    8000418c:	0ed7e263          	bltu	a5,a3,80004270 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004190:	00043737          	lui	a4,0x43
    80004194:	0ef76063          	bltu	a4,a5,80004274 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004198:	0c0b0863          	beqz	s6,80004268 <writei+0x10e>
    8000419c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000419e:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041a2:	5c7d                	li	s8,-1
    800041a4:	a091                	j	800041e8 <writei+0x8e>
    800041a6:	020d1d93          	slli	s11,s10,0x20
    800041aa:	020ddd93          	srli	s11,s11,0x20
    800041ae:	05848513          	addi	a0,s1,88
    800041b2:	86ee                	mv	a3,s11
    800041b4:	8652                	mv	a2,s4
    800041b6:	85de                	mv	a1,s7
    800041b8:	953a                	add	a0,a0,a4
    800041ba:	ffffe097          	auipc	ra,0xffffe
    800041be:	778080e7          	jalr	1912(ra) # 80002932 <either_copyin>
    800041c2:	07850263          	beq	a0,s8,80004226 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041c6:	8526                	mv	a0,s1
    800041c8:	00000097          	auipc	ra,0x0
    800041cc:	75e080e7          	jalr	1886(ra) # 80004926 <log_write>
    brelse(bp);
    800041d0:	8526                	mv	a0,s1
    800041d2:	fffff097          	auipc	ra,0xfffff
    800041d6:	4fc080e7          	jalr	1276(ra) # 800036ce <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041da:	013d09bb          	addw	s3,s10,s3
    800041de:	012d093b          	addw	s2,s10,s2
    800041e2:	9a6e                	add	s4,s4,s11
    800041e4:	0569f663          	bgeu	s3,s6,80004230 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041e8:	00a9559b          	srliw	a1,s2,0xa
    800041ec:	8556                	mv	a0,s5
    800041ee:	fffff097          	auipc	ra,0xfffff
    800041f2:	7a2080e7          	jalr	1954(ra) # 80003990 <bmap>
    800041f6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    800041fa:	c99d                	beqz	a1,80004230 <writei+0xd6>
    bp = bread(ip->dev, addr);
    800041fc:	000aa503          	lw	a0,0(s5)
    80004200:	fffff097          	auipc	ra,0xfffff
    80004204:	39e080e7          	jalr	926(ra) # 8000359e <bread>
    80004208:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000420a:	3ff97713          	andi	a4,s2,1023
    8000420e:	40ec87bb          	subw	a5,s9,a4
    80004212:	413b06bb          	subw	a3,s6,s3
    80004216:	8d3e                	mv	s10,a5
    80004218:	2781                	sext.w	a5,a5
    8000421a:	0006861b          	sext.w	a2,a3
    8000421e:	f8f674e3          	bgeu	a2,a5,800041a6 <writei+0x4c>
    80004222:	8d36                	mv	s10,a3
    80004224:	b749                	j	800041a6 <writei+0x4c>
      brelse(bp);
    80004226:	8526                	mv	a0,s1
    80004228:	fffff097          	auipc	ra,0xfffff
    8000422c:	4a6080e7          	jalr	1190(ra) # 800036ce <brelse>
  }

  if(off > ip->size)
    80004230:	04caa783          	lw	a5,76(s5)
    80004234:	0127f463          	bgeu	a5,s2,8000423c <writei+0xe2>
    ip->size = off;
    80004238:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000423c:	8556                	mv	a0,s5
    8000423e:	00000097          	auipc	ra,0x0
    80004242:	aa4080e7          	jalr	-1372(ra) # 80003ce2 <iupdate>

  return tot;
    80004246:	0009851b          	sext.w	a0,s3
}
    8000424a:	70a6                	ld	ra,104(sp)
    8000424c:	7406                	ld	s0,96(sp)
    8000424e:	64e6                	ld	s1,88(sp)
    80004250:	6946                	ld	s2,80(sp)
    80004252:	69a6                	ld	s3,72(sp)
    80004254:	6a06                	ld	s4,64(sp)
    80004256:	7ae2                	ld	s5,56(sp)
    80004258:	7b42                	ld	s6,48(sp)
    8000425a:	7ba2                	ld	s7,40(sp)
    8000425c:	7c02                	ld	s8,32(sp)
    8000425e:	6ce2                	ld	s9,24(sp)
    80004260:	6d42                	ld	s10,16(sp)
    80004262:	6da2                	ld	s11,8(sp)
    80004264:	6165                	addi	sp,sp,112
    80004266:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004268:	89da                	mv	s3,s6
    8000426a:	bfc9                	j	8000423c <writei+0xe2>
    return -1;
    8000426c:	557d                	li	a0,-1
}
    8000426e:	8082                	ret
    return -1;
    80004270:	557d                	li	a0,-1
    80004272:	bfe1                	j	8000424a <writei+0xf0>
    return -1;
    80004274:	557d                	li	a0,-1
    80004276:	bfd1                	j	8000424a <writei+0xf0>

0000000080004278 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004278:	1141                	addi	sp,sp,-16
    8000427a:	e406                	sd	ra,8(sp)
    8000427c:	e022                	sd	s0,0(sp)
    8000427e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004280:	4639                	li	a2,14
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	d22080e7          	jalr	-734(ra) # 80000fa4 <strncmp>
}
    8000428a:	60a2                	ld	ra,8(sp)
    8000428c:	6402                	ld	s0,0(sp)
    8000428e:	0141                	addi	sp,sp,16
    80004290:	8082                	ret

0000000080004292 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004292:	7139                	addi	sp,sp,-64
    80004294:	fc06                	sd	ra,56(sp)
    80004296:	f822                	sd	s0,48(sp)
    80004298:	f426                	sd	s1,40(sp)
    8000429a:	f04a                	sd	s2,32(sp)
    8000429c:	ec4e                	sd	s3,24(sp)
    8000429e:	e852                	sd	s4,16(sp)
    800042a0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042a2:	04451703          	lh	a4,68(a0)
    800042a6:	4785                	li	a5,1
    800042a8:	00f71a63          	bne	a4,a5,800042bc <dirlookup+0x2a>
    800042ac:	892a                	mv	s2,a0
    800042ae:	89ae                	mv	s3,a1
    800042b0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b2:	457c                	lw	a5,76(a0)
    800042b4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042b6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042b8:	e79d                	bnez	a5,800042e6 <dirlookup+0x54>
    800042ba:	a8a5                	j	80004332 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042bc:	00004517          	auipc	a0,0x4
    800042c0:	51c50513          	addi	a0,a0,1308 # 800087d8 <syscalls+0x1c8>
    800042c4:	ffffc097          	auipc	ra,0xffffc
    800042c8:	278080e7          	jalr	632(ra) # 8000053c <panic>
      panic("dirlookup read");
    800042cc:	00004517          	auipc	a0,0x4
    800042d0:	52450513          	addi	a0,a0,1316 # 800087f0 <syscalls+0x1e0>
    800042d4:	ffffc097          	auipc	ra,0xffffc
    800042d8:	268080e7          	jalr	616(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042dc:	24c1                	addiw	s1,s1,16
    800042de:	04c92783          	lw	a5,76(s2)
    800042e2:	04f4f763          	bgeu	s1,a5,80004330 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042e6:	4741                	li	a4,16
    800042e8:	86a6                	mv	a3,s1
    800042ea:	fc040613          	addi	a2,s0,-64
    800042ee:	4581                	li	a1,0
    800042f0:	854a                	mv	a0,s2
    800042f2:	00000097          	auipc	ra,0x0
    800042f6:	d70080e7          	jalr	-656(ra) # 80004062 <readi>
    800042fa:	47c1                	li	a5,16
    800042fc:	fcf518e3          	bne	a0,a5,800042cc <dirlookup+0x3a>
    if(de.inum == 0)
    80004300:	fc045783          	lhu	a5,-64(s0)
    80004304:	dfe1                	beqz	a5,800042dc <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004306:	fc240593          	addi	a1,s0,-62
    8000430a:	854e                	mv	a0,s3
    8000430c:	00000097          	auipc	ra,0x0
    80004310:	f6c080e7          	jalr	-148(ra) # 80004278 <namecmp>
    80004314:	f561                	bnez	a0,800042dc <dirlookup+0x4a>
      if(poff)
    80004316:	000a0463          	beqz	s4,8000431e <dirlookup+0x8c>
        *poff = off;
    8000431a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000431e:	fc045583          	lhu	a1,-64(s0)
    80004322:	00092503          	lw	a0,0(s2)
    80004326:	fffff097          	auipc	ra,0xfffff
    8000432a:	754080e7          	jalr	1876(ra) # 80003a7a <iget>
    8000432e:	a011                	j	80004332 <dirlookup+0xa0>
  return 0;
    80004330:	4501                	li	a0,0
}
    80004332:	70e2                	ld	ra,56(sp)
    80004334:	7442                	ld	s0,48(sp)
    80004336:	74a2                	ld	s1,40(sp)
    80004338:	7902                	ld	s2,32(sp)
    8000433a:	69e2                	ld	s3,24(sp)
    8000433c:	6a42                	ld	s4,16(sp)
    8000433e:	6121                	addi	sp,sp,64
    80004340:	8082                	ret

0000000080004342 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004342:	711d                	addi	sp,sp,-96
    80004344:	ec86                	sd	ra,88(sp)
    80004346:	e8a2                	sd	s0,80(sp)
    80004348:	e4a6                	sd	s1,72(sp)
    8000434a:	e0ca                	sd	s2,64(sp)
    8000434c:	fc4e                	sd	s3,56(sp)
    8000434e:	f852                	sd	s4,48(sp)
    80004350:	f456                	sd	s5,40(sp)
    80004352:	f05a                	sd	s6,32(sp)
    80004354:	ec5e                	sd	s7,24(sp)
    80004356:	e862                	sd	s8,16(sp)
    80004358:	e466                	sd	s9,8(sp)
    8000435a:	1080                	addi	s0,sp,96
    8000435c:	84aa                	mv	s1,a0
    8000435e:	8b2e                	mv	s6,a1
    80004360:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004362:	00054703          	lbu	a4,0(a0)
    80004366:	02f00793          	li	a5,47
    8000436a:	02f70263          	beq	a4,a5,8000438e <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000436e:	ffffe097          	auipc	ra,0xffffe
    80004372:	9fe080e7          	jalr	-1538(ra) # 80001d6c <myproc>
    80004376:	15053503          	ld	a0,336(a0)
    8000437a:	00000097          	auipc	ra,0x0
    8000437e:	9f6080e7          	jalr	-1546(ra) # 80003d70 <idup>
    80004382:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004384:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004388:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000438a:	4b85                	li	s7,1
    8000438c:	a875                	j	80004448 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000438e:	4585                	li	a1,1
    80004390:	4505                	li	a0,1
    80004392:	fffff097          	auipc	ra,0xfffff
    80004396:	6e8080e7          	jalr	1768(ra) # 80003a7a <iget>
    8000439a:	8a2a                	mv	s4,a0
    8000439c:	b7e5                	j	80004384 <namex+0x42>
      iunlockput(ip);
    8000439e:	8552                	mv	a0,s4
    800043a0:	00000097          	auipc	ra,0x0
    800043a4:	c70080e7          	jalr	-912(ra) # 80004010 <iunlockput>
      return 0;
    800043a8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043aa:	8552                	mv	a0,s4
    800043ac:	60e6                	ld	ra,88(sp)
    800043ae:	6446                	ld	s0,80(sp)
    800043b0:	64a6                	ld	s1,72(sp)
    800043b2:	6906                	ld	s2,64(sp)
    800043b4:	79e2                	ld	s3,56(sp)
    800043b6:	7a42                	ld	s4,48(sp)
    800043b8:	7aa2                	ld	s5,40(sp)
    800043ba:	7b02                	ld	s6,32(sp)
    800043bc:	6be2                	ld	s7,24(sp)
    800043be:	6c42                	ld	s8,16(sp)
    800043c0:	6ca2                	ld	s9,8(sp)
    800043c2:	6125                	addi	sp,sp,96
    800043c4:	8082                	ret
      iunlock(ip);
    800043c6:	8552                	mv	a0,s4
    800043c8:	00000097          	auipc	ra,0x0
    800043cc:	aa8080e7          	jalr	-1368(ra) # 80003e70 <iunlock>
      return ip;
    800043d0:	bfe9                	j	800043aa <namex+0x68>
      iunlockput(ip);
    800043d2:	8552                	mv	a0,s4
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	c3c080e7          	jalr	-964(ra) # 80004010 <iunlockput>
      return 0;
    800043dc:	8a4e                	mv	s4,s3
    800043de:	b7f1                	j	800043aa <namex+0x68>
  len = path - s;
    800043e0:	40998633          	sub	a2,s3,s1
    800043e4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043e8:	099c5863          	bge	s8,s9,80004478 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800043ec:	4639                	li	a2,14
    800043ee:	85a6                	mv	a1,s1
    800043f0:	8556                	mv	a0,s5
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	b3e080e7          	jalr	-1218(ra) # 80000f30 <memmove>
    800043fa:	84ce                	mv	s1,s3
  while(*path == '/')
    800043fc:	0004c783          	lbu	a5,0(s1)
    80004400:	01279763          	bne	a5,s2,8000440e <namex+0xcc>
    path++;
    80004404:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004406:	0004c783          	lbu	a5,0(s1)
    8000440a:	ff278de3          	beq	a5,s2,80004404 <namex+0xc2>
    ilock(ip);
    8000440e:	8552                	mv	a0,s4
    80004410:	00000097          	auipc	ra,0x0
    80004414:	99e080e7          	jalr	-1634(ra) # 80003dae <ilock>
    if(ip->type != T_DIR){
    80004418:	044a1783          	lh	a5,68(s4)
    8000441c:	f97791e3          	bne	a5,s7,8000439e <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004420:	000b0563          	beqz	s6,8000442a <namex+0xe8>
    80004424:	0004c783          	lbu	a5,0(s1)
    80004428:	dfd9                	beqz	a5,800043c6 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000442a:	4601                	li	a2,0
    8000442c:	85d6                	mv	a1,s5
    8000442e:	8552                	mv	a0,s4
    80004430:	00000097          	auipc	ra,0x0
    80004434:	e62080e7          	jalr	-414(ra) # 80004292 <dirlookup>
    80004438:	89aa                	mv	s3,a0
    8000443a:	dd41                	beqz	a0,800043d2 <namex+0x90>
    iunlockput(ip);
    8000443c:	8552                	mv	a0,s4
    8000443e:	00000097          	auipc	ra,0x0
    80004442:	bd2080e7          	jalr	-1070(ra) # 80004010 <iunlockput>
    ip = next;
    80004446:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004448:	0004c783          	lbu	a5,0(s1)
    8000444c:	01279763          	bne	a5,s2,8000445a <namex+0x118>
    path++;
    80004450:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004452:	0004c783          	lbu	a5,0(s1)
    80004456:	ff278de3          	beq	a5,s2,80004450 <namex+0x10e>
  if(*path == 0)
    8000445a:	cb9d                	beqz	a5,80004490 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000445c:	0004c783          	lbu	a5,0(s1)
    80004460:	89a6                	mv	s3,s1
  len = path - s;
    80004462:	4c81                	li	s9,0
    80004464:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004466:	01278963          	beq	a5,s2,80004478 <namex+0x136>
    8000446a:	dbbd                	beqz	a5,800043e0 <namex+0x9e>
    path++;
    8000446c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000446e:	0009c783          	lbu	a5,0(s3)
    80004472:	ff279ce3          	bne	a5,s2,8000446a <namex+0x128>
    80004476:	b7ad                	j	800043e0 <namex+0x9e>
    memmove(name, s, len);
    80004478:	2601                	sext.w	a2,a2
    8000447a:	85a6                	mv	a1,s1
    8000447c:	8556                	mv	a0,s5
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	ab2080e7          	jalr	-1358(ra) # 80000f30 <memmove>
    name[len] = 0;
    80004486:	9cd6                	add	s9,s9,s5
    80004488:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000448c:	84ce                	mv	s1,s3
    8000448e:	b7bd                	j	800043fc <namex+0xba>
  if(nameiparent){
    80004490:	f00b0de3          	beqz	s6,800043aa <namex+0x68>
    iput(ip);
    80004494:	8552                	mv	a0,s4
    80004496:	00000097          	auipc	ra,0x0
    8000449a:	ad2080e7          	jalr	-1326(ra) # 80003f68 <iput>
    return 0;
    8000449e:	4a01                	li	s4,0
    800044a0:	b729                	j	800043aa <namex+0x68>

00000000800044a2 <dirlink>:
{
    800044a2:	7139                	addi	sp,sp,-64
    800044a4:	fc06                	sd	ra,56(sp)
    800044a6:	f822                	sd	s0,48(sp)
    800044a8:	f426                	sd	s1,40(sp)
    800044aa:	f04a                	sd	s2,32(sp)
    800044ac:	ec4e                	sd	s3,24(sp)
    800044ae:	e852                	sd	s4,16(sp)
    800044b0:	0080                	addi	s0,sp,64
    800044b2:	892a                	mv	s2,a0
    800044b4:	8a2e                	mv	s4,a1
    800044b6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044b8:	4601                	li	a2,0
    800044ba:	00000097          	auipc	ra,0x0
    800044be:	dd8080e7          	jalr	-552(ra) # 80004292 <dirlookup>
    800044c2:	e93d                	bnez	a0,80004538 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044c4:	04c92483          	lw	s1,76(s2)
    800044c8:	c49d                	beqz	s1,800044f6 <dirlink+0x54>
    800044ca:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044cc:	4741                	li	a4,16
    800044ce:	86a6                	mv	a3,s1
    800044d0:	fc040613          	addi	a2,s0,-64
    800044d4:	4581                	li	a1,0
    800044d6:	854a                	mv	a0,s2
    800044d8:	00000097          	auipc	ra,0x0
    800044dc:	b8a080e7          	jalr	-1142(ra) # 80004062 <readi>
    800044e0:	47c1                	li	a5,16
    800044e2:	06f51163          	bne	a0,a5,80004544 <dirlink+0xa2>
    if(de.inum == 0)
    800044e6:	fc045783          	lhu	a5,-64(s0)
    800044ea:	c791                	beqz	a5,800044f6 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ec:	24c1                	addiw	s1,s1,16
    800044ee:	04c92783          	lw	a5,76(s2)
    800044f2:	fcf4ede3          	bltu	s1,a5,800044cc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044f6:	4639                	li	a2,14
    800044f8:	85d2                	mv	a1,s4
    800044fa:	fc240513          	addi	a0,s0,-62
    800044fe:	ffffd097          	auipc	ra,0xffffd
    80004502:	ae2080e7          	jalr	-1310(ra) # 80000fe0 <strncpy>
  de.inum = inum;
    80004506:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000450a:	4741                	li	a4,16
    8000450c:	86a6                	mv	a3,s1
    8000450e:	fc040613          	addi	a2,s0,-64
    80004512:	4581                	li	a1,0
    80004514:	854a                	mv	a0,s2
    80004516:	00000097          	auipc	ra,0x0
    8000451a:	c44080e7          	jalr	-956(ra) # 8000415a <writei>
    8000451e:	1541                	addi	a0,a0,-16
    80004520:	00a03533          	snez	a0,a0
    80004524:	40a00533          	neg	a0,a0
}
    80004528:	70e2                	ld	ra,56(sp)
    8000452a:	7442                	ld	s0,48(sp)
    8000452c:	74a2                	ld	s1,40(sp)
    8000452e:	7902                	ld	s2,32(sp)
    80004530:	69e2                	ld	s3,24(sp)
    80004532:	6a42                	ld	s4,16(sp)
    80004534:	6121                	addi	sp,sp,64
    80004536:	8082                	ret
    iput(ip);
    80004538:	00000097          	auipc	ra,0x0
    8000453c:	a30080e7          	jalr	-1488(ra) # 80003f68 <iput>
    return -1;
    80004540:	557d                	li	a0,-1
    80004542:	b7dd                	j	80004528 <dirlink+0x86>
      panic("dirlink read");
    80004544:	00004517          	auipc	a0,0x4
    80004548:	2bc50513          	addi	a0,a0,700 # 80008800 <syscalls+0x1f0>
    8000454c:	ffffc097          	auipc	ra,0xffffc
    80004550:	ff0080e7          	jalr	-16(ra) # 8000053c <panic>

0000000080004554 <namei>:

struct inode*
namei(char *path)
{
    80004554:	1101                	addi	sp,sp,-32
    80004556:	ec06                	sd	ra,24(sp)
    80004558:	e822                	sd	s0,16(sp)
    8000455a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000455c:	fe040613          	addi	a2,s0,-32
    80004560:	4581                	li	a1,0
    80004562:	00000097          	auipc	ra,0x0
    80004566:	de0080e7          	jalr	-544(ra) # 80004342 <namex>
}
    8000456a:	60e2                	ld	ra,24(sp)
    8000456c:	6442                	ld	s0,16(sp)
    8000456e:	6105                	addi	sp,sp,32
    80004570:	8082                	ret

0000000080004572 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004572:	1141                	addi	sp,sp,-16
    80004574:	e406                	sd	ra,8(sp)
    80004576:	e022                	sd	s0,0(sp)
    80004578:	0800                	addi	s0,sp,16
    8000457a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000457c:	4585                	li	a1,1
    8000457e:	00000097          	auipc	ra,0x0
    80004582:	dc4080e7          	jalr	-572(ra) # 80004342 <namex>
}
    80004586:	60a2                	ld	ra,8(sp)
    80004588:	6402                	ld	s0,0(sp)
    8000458a:	0141                	addi	sp,sp,16
    8000458c:	8082                	ret

000000008000458e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000458e:	1101                	addi	sp,sp,-32
    80004590:	ec06                	sd	ra,24(sp)
    80004592:	e822                	sd	s0,16(sp)
    80004594:	e426                	sd	s1,8(sp)
    80004596:	e04a                	sd	s2,0(sp)
    80004598:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000459a:	0023c917          	auipc	s2,0x23c
    8000459e:	79690913          	addi	s2,s2,1942 # 80240d30 <log>
    800045a2:	01892583          	lw	a1,24(s2)
    800045a6:	02892503          	lw	a0,40(s2)
    800045aa:	fffff097          	auipc	ra,0xfffff
    800045ae:	ff4080e7          	jalr	-12(ra) # 8000359e <bread>
    800045b2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045b4:	02c92603          	lw	a2,44(s2)
    800045b8:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045ba:	00c05f63          	blez	a2,800045d8 <write_head+0x4a>
    800045be:	0023c717          	auipc	a4,0x23c
    800045c2:	7a270713          	addi	a4,a4,1954 # 80240d60 <log+0x30>
    800045c6:	87aa                	mv	a5,a0
    800045c8:	060a                	slli	a2,a2,0x2
    800045ca:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800045cc:	4314                	lw	a3,0(a4)
    800045ce:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800045d0:	0711                	addi	a4,a4,4
    800045d2:	0791                	addi	a5,a5,4
    800045d4:	fec79ce3          	bne	a5,a2,800045cc <write_head+0x3e>
  }
  bwrite(buf);
    800045d8:	8526                	mv	a0,s1
    800045da:	fffff097          	auipc	ra,0xfffff
    800045de:	0b6080e7          	jalr	182(ra) # 80003690 <bwrite>
  brelse(buf);
    800045e2:	8526                	mv	a0,s1
    800045e4:	fffff097          	auipc	ra,0xfffff
    800045e8:	0ea080e7          	jalr	234(ra) # 800036ce <brelse>
}
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6902                	ld	s2,0(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800045f8:	0023c797          	auipc	a5,0x23c
    800045fc:	7647a783          	lw	a5,1892(a5) # 80240d5c <log+0x2c>
    80004600:	0af05d63          	blez	a5,800046ba <install_trans+0xc2>
{
    80004604:	7139                	addi	sp,sp,-64
    80004606:	fc06                	sd	ra,56(sp)
    80004608:	f822                	sd	s0,48(sp)
    8000460a:	f426                	sd	s1,40(sp)
    8000460c:	f04a                	sd	s2,32(sp)
    8000460e:	ec4e                	sd	s3,24(sp)
    80004610:	e852                	sd	s4,16(sp)
    80004612:	e456                	sd	s5,8(sp)
    80004614:	e05a                	sd	s6,0(sp)
    80004616:	0080                	addi	s0,sp,64
    80004618:	8b2a                	mv	s6,a0
    8000461a:	0023ca97          	auipc	s5,0x23c
    8000461e:	746a8a93          	addi	s5,s5,1862 # 80240d60 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004622:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004624:	0023c997          	auipc	s3,0x23c
    80004628:	70c98993          	addi	s3,s3,1804 # 80240d30 <log>
    8000462c:	a00d                	j	8000464e <install_trans+0x56>
    brelse(lbuf);
    8000462e:	854a                	mv	a0,s2
    80004630:	fffff097          	auipc	ra,0xfffff
    80004634:	09e080e7          	jalr	158(ra) # 800036ce <brelse>
    brelse(dbuf);
    80004638:	8526                	mv	a0,s1
    8000463a:	fffff097          	auipc	ra,0xfffff
    8000463e:	094080e7          	jalr	148(ra) # 800036ce <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004642:	2a05                	addiw	s4,s4,1
    80004644:	0a91                	addi	s5,s5,4
    80004646:	02c9a783          	lw	a5,44(s3)
    8000464a:	04fa5e63          	bge	s4,a5,800046a6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000464e:	0189a583          	lw	a1,24(s3)
    80004652:	014585bb          	addw	a1,a1,s4
    80004656:	2585                	addiw	a1,a1,1
    80004658:	0289a503          	lw	a0,40(s3)
    8000465c:	fffff097          	auipc	ra,0xfffff
    80004660:	f42080e7          	jalr	-190(ra) # 8000359e <bread>
    80004664:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004666:	000aa583          	lw	a1,0(s5)
    8000466a:	0289a503          	lw	a0,40(s3)
    8000466e:	fffff097          	auipc	ra,0xfffff
    80004672:	f30080e7          	jalr	-208(ra) # 8000359e <bread>
    80004676:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004678:	40000613          	li	a2,1024
    8000467c:	05890593          	addi	a1,s2,88
    80004680:	05850513          	addi	a0,a0,88
    80004684:	ffffd097          	auipc	ra,0xffffd
    80004688:	8ac080e7          	jalr	-1876(ra) # 80000f30 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000468c:	8526                	mv	a0,s1
    8000468e:	fffff097          	auipc	ra,0xfffff
    80004692:	002080e7          	jalr	2(ra) # 80003690 <bwrite>
    if(recovering == 0)
    80004696:	f80b1ce3          	bnez	s6,8000462e <install_trans+0x36>
      bunpin(dbuf);
    8000469a:	8526                	mv	a0,s1
    8000469c:	fffff097          	auipc	ra,0xfffff
    800046a0:	10a080e7          	jalr	266(ra) # 800037a6 <bunpin>
    800046a4:	b769                	j	8000462e <install_trans+0x36>
}
    800046a6:	70e2                	ld	ra,56(sp)
    800046a8:	7442                	ld	s0,48(sp)
    800046aa:	74a2                	ld	s1,40(sp)
    800046ac:	7902                	ld	s2,32(sp)
    800046ae:	69e2                	ld	s3,24(sp)
    800046b0:	6a42                	ld	s4,16(sp)
    800046b2:	6aa2                	ld	s5,8(sp)
    800046b4:	6b02                	ld	s6,0(sp)
    800046b6:	6121                	addi	sp,sp,64
    800046b8:	8082                	ret
    800046ba:	8082                	ret

00000000800046bc <initlog>:
{
    800046bc:	7179                	addi	sp,sp,-48
    800046be:	f406                	sd	ra,40(sp)
    800046c0:	f022                	sd	s0,32(sp)
    800046c2:	ec26                	sd	s1,24(sp)
    800046c4:	e84a                	sd	s2,16(sp)
    800046c6:	e44e                	sd	s3,8(sp)
    800046c8:	1800                	addi	s0,sp,48
    800046ca:	892a                	mv	s2,a0
    800046cc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046ce:	0023c497          	auipc	s1,0x23c
    800046d2:	66248493          	addi	s1,s1,1634 # 80240d30 <log>
    800046d6:	00004597          	auipc	a1,0x4
    800046da:	13a58593          	addi	a1,a1,314 # 80008810 <syscalls+0x200>
    800046de:	8526                	mv	a0,s1
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	668080e7          	jalr	1640(ra) # 80000d48 <initlock>
  log.start = sb->logstart;
    800046e8:	0149a583          	lw	a1,20(s3)
    800046ec:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046ee:	0109a783          	lw	a5,16(s3)
    800046f2:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800046f4:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800046f8:	854a                	mv	a0,s2
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	ea4080e7          	jalr	-348(ra) # 8000359e <bread>
  log.lh.n = lh->n;
    80004702:	4d30                	lw	a2,88(a0)
    80004704:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004706:	00c05f63          	blez	a2,80004724 <initlog+0x68>
    8000470a:	87aa                	mv	a5,a0
    8000470c:	0023c717          	auipc	a4,0x23c
    80004710:	65470713          	addi	a4,a4,1620 # 80240d60 <log+0x30>
    80004714:	060a                	slli	a2,a2,0x2
    80004716:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004718:	4ff4                	lw	a3,92(a5)
    8000471a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000471c:	0791                	addi	a5,a5,4
    8000471e:	0711                	addi	a4,a4,4
    80004720:	fec79ce3          	bne	a5,a2,80004718 <initlog+0x5c>
  brelse(buf);
    80004724:	fffff097          	auipc	ra,0xfffff
    80004728:	faa080e7          	jalr	-86(ra) # 800036ce <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000472c:	4505                	li	a0,1
    8000472e:	00000097          	auipc	ra,0x0
    80004732:	eca080e7          	jalr	-310(ra) # 800045f8 <install_trans>
  log.lh.n = 0;
    80004736:	0023c797          	auipc	a5,0x23c
    8000473a:	6207a323          	sw	zero,1574(a5) # 80240d5c <log+0x2c>
  write_head(); // clear the log
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	e50080e7          	jalr	-432(ra) # 8000458e <write_head>
}
    80004746:	70a2                	ld	ra,40(sp)
    80004748:	7402                	ld	s0,32(sp)
    8000474a:	64e2                	ld	s1,24(sp)
    8000474c:	6942                	ld	s2,16(sp)
    8000474e:	69a2                	ld	s3,8(sp)
    80004750:	6145                	addi	sp,sp,48
    80004752:	8082                	ret

0000000080004754 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004754:	1101                	addi	sp,sp,-32
    80004756:	ec06                	sd	ra,24(sp)
    80004758:	e822                	sd	s0,16(sp)
    8000475a:	e426                	sd	s1,8(sp)
    8000475c:	e04a                	sd	s2,0(sp)
    8000475e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004760:	0023c517          	auipc	a0,0x23c
    80004764:	5d050513          	addi	a0,a0,1488 # 80240d30 <log>
    80004768:	ffffc097          	auipc	ra,0xffffc
    8000476c:	670080e7          	jalr	1648(ra) # 80000dd8 <acquire>
  while(1){
    if(log.committing){
    80004770:	0023c497          	auipc	s1,0x23c
    80004774:	5c048493          	addi	s1,s1,1472 # 80240d30 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004778:	4979                	li	s2,30
    8000477a:	a039                	j	80004788 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000477c:	85a6                	mv	a1,s1
    8000477e:	8526                	mv	a0,s1
    80004780:	ffffe097          	auipc	ra,0xffffe
    80004784:	d54080e7          	jalr	-684(ra) # 800024d4 <sleep>
    if(log.committing){
    80004788:	50dc                	lw	a5,36(s1)
    8000478a:	fbed                	bnez	a5,8000477c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000478c:	5098                	lw	a4,32(s1)
    8000478e:	2705                	addiw	a4,a4,1
    80004790:	0027179b          	slliw	a5,a4,0x2
    80004794:	9fb9                	addw	a5,a5,a4
    80004796:	0017979b          	slliw	a5,a5,0x1
    8000479a:	54d4                	lw	a3,44(s1)
    8000479c:	9fb5                	addw	a5,a5,a3
    8000479e:	00f95963          	bge	s2,a5,800047b0 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047a2:	85a6                	mv	a1,s1
    800047a4:	8526                	mv	a0,s1
    800047a6:	ffffe097          	auipc	ra,0xffffe
    800047aa:	d2e080e7          	jalr	-722(ra) # 800024d4 <sleep>
    800047ae:	bfe9                	j	80004788 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047b0:	0023c517          	auipc	a0,0x23c
    800047b4:	58050513          	addi	a0,a0,1408 # 80240d30 <log>
    800047b8:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	6d2080e7          	jalr	1746(ra) # 80000e8c <release>
      break;
    }
  }
}
    800047c2:	60e2                	ld	ra,24(sp)
    800047c4:	6442                	ld	s0,16(sp)
    800047c6:	64a2                	ld	s1,8(sp)
    800047c8:	6902                	ld	s2,0(sp)
    800047ca:	6105                	addi	sp,sp,32
    800047cc:	8082                	ret

00000000800047ce <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047ce:	7139                	addi	sp,sp,-64
    800047d0:	fc06                	sd	ra,56(sp)
    800047d2:	f822                	sd	s0,48(sp)
    800047d4:	f426                	sd	s1,40(sp)
    800047d6:	f04a                	sd	s2,32(sp)
    800047d8:	ec4e                	sd	s3,24(sp)
    800047da:	e852                	sd	s4,16(sp)
    800047dc:	e456                	sd	s5,8(sp)
    800047de:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047e0:	0023c497          	auipc	s1,0x23c
    800047e4:	55048493          	addi	s1,s1,1360 # 80240d30 <log>
    800047e8:	8526                	mv	a0,s1
    800047ea:	ffffc097          	auipc	ra,0xffffc
    800047ee:	5ee080e7          	jalr	1518(ra) # 80000dd8 <acquire>
  log.outstanding -= 1;
    800047f2:	509c                	lw	a5,32(s1)
    800047f4:	37fd                	addiw	a5,a5,-1
    800047f6:	0007891b          	sext.w	s2,a5
    800047fa:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800047fc:	50dc                	lw	a5,36(s1)
    800047fe:	e7b9                	bnez	a5,8000484c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004800:	04091e63          	bnez	s2,8000485c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004804:	0023c497          	auipc	s1,0x23c
    80004808:	52c48493          	addi	s1,s1,1324 # 80240d30 <log>
    8000480c:	4785                	li	a5,1
    8000480e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004810:	8526                	mv	a0,s1
    80004812:	ffffc097          	auipc	ra,0xffffc
    80004816:	67a080e7          	jalr	1658(ra) # 80000e8c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000481a:	54dc                	lw	a5,44(s1)
    8000481c:	06f04763          	bgtz	a5,8000488a <end_op+0xbc>
    acquire(&log.lock);
    80004820:	0023c497          	auipc	s1,0x23c
    80004824:	51048493          	addi	s1,s1,1296 # 80240d30 <log>
    80004828:	8526                	mv	a0,s1
    8000482a:	ffffc097          	auipc	ra,0xffffc
    8000482e:	5ae080e7          	jalr	1454(ra) # 80000dd8 <acquire>
    log.committing = 0;
    80004832:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004836:	8526                	mv	a0,s1
    80004838:	ffffe097          	auipc	ra,0xffffe
    8000483c:	d00080e7          	jalr	-768(ra) # 80002538 <wakeup>
    release(&log.lock);
    80004840:	8526                	mv	a0,s1
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	64a080e7          	jalr	1610(ra) # 80000e8c <release>
}
    8000484a:	a03d                	j	80004878 <end_op+0xaa>
    panic("log.committing");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	fcc50513          	addi	a0,a0,-52 # 80008818 <syscalls+0x208>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	ce8080e7          	jalr	-792(ra) # 8000053c <panic>
    wakeup(&log);
    8000485c:	0023c497          	auipc	s1,0x23c
    80004860:	4d448493          	addi	s1,s1,1236 # 80240d30 <log>
    80004864:	8526                	mv	a0,s1
    80004866:	ffffe097          	auipc	ra,0xffffe
    8000486a:	cd2080e7          	jalr	-814(ra) # 80002538 <wakeup>
  release(&log.lock);
    8000486e:	8526                	mv	a0,s1
    80004870:	ffffc097          	auipc	ra,0xffffc
    80004874:	61c080e7          	jalr	1564(ra) # 80000e8c <release>
}
    80004878:	70e2                	ld	ra,56(sp)
    8000487a:	7442                	ld	s0,48(sp)
    8000487c:	74a2                	ld	s1,40(sp)
    8000487e:	7902                	ld	s2,32(sp)
    80004880:	69e2                	ld	s3,24(sp)
    80004882:	6a42                	ld	s4,16(sp)
    80004884:	6aa2                	ld	s5,8(sp)
    80004886:	6121                	addi	sp,sp,64
    80004888:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000488a:	0023ca97          	auipc	s5,0x23c
    8000488e:	4d6a8a93          	addi	s5,s5,1238 # 80240d60 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004892:	0023ca17          	auipc	s4,0x23c
    80004896:	49ea0a13          	addi	s4,s4,1182 # 80240d30 <log>
    8000489a:	018a2583          	lw	a1,24(s4)
    8000489e:	012585bb          	addw	a1,a1,s2
    800048a2:	2585                	addiw	a1,a1,1
    800048a4:	028a2503          	lw	a0,40(s4)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	cf6080e7          	jalr	-778(ra) # 8000359e <bread>
    800048b0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048b2:	000aa583          	lw	a1,0(s5)
    800048b6:	028a2503          	lw	a0,40(s4)
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	ce4080e7          	jalr	-796(ra) # 8000359e <bread>
    800048c2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048c4:	40000613          	li	a2,1024
    800048c8:	05850593          	addi	a1,a0,88
    800048cc:	05848513          	addi	a0,s1,88
    800048d0:	ffffc097          	auipc	ra,0xffffc
    800048d4:	660080e7          	jalr	1632(ra) # 80000f30 <memmove>
    bwrite(to);  // write the log
    800048d8:	8526                	mv	a0,s1
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	db6080e7          	jalr	-586(ra) # 80003690 <bwrite>
    brelse(from);
    800048e2:	854e                	mv	a0,s3
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	dea080e7          	jalr	-534(ra) # 800036ce <brelse>
    brelse(to);
    800048ec:	8526                	mv	a0,s1
    800048ee:	fffff097          	auipc	ra,0xfffff
    800048f2:	de0080e7          	jalr	-544(ra) # 800036ce <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800048f6:	2905                	addiw	s2,s2,1
    800048f8:	0a91                	addi	s5,s5,4
    800048fa:	02ca2783          	lw	a5,44(s4)
    800048fe:	f8f94ee3          	blt	s2,a5,8000489a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004902:	00000097          	auipc	ra,0x0
    80004906:	c8c080e7          	jalr	-884(ra) # 8000458e <write_head>
    install_trans(0); // Now install writes to home locations
    8000490a:	4501                	li	a0,0
    8000490c:	00000097          	auipc	ra,0x0
    80004910:	cec080e7          	jalr	-788(ra) # 800045f8 <install_trans>
    log.lh.n = 0;
    80004914:	0023c797          	auipc	a5,0x23c
    80004918:	4407a423          	sw	zero,1096(a5) # 80240d5c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	c72080e7          	jalr	-910(ra) # 8000458e <write_head>
    80004924:	bdf5                	j	80004820 <end_op+0x52>

0000000080004926 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004926:	1101                	addi	sp,sp,-32
    80004928:	ec06                	sd	ra,24(sp)
    8000492a:	e822                	sd	s0,16(sp)
    8000492c:	e426                	sd	s1,8(sp)
    8000492e:	e04a                	sd	s2,0(sp)
    80004930:	1000                	addi	s0,sp,32
    80004932:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004934:	0023c917          	auipc	s2,0x23c
    80004938:	3fc90913          	addi	s2,s2,1020 # 80240d30 <log>
    8000493c:	854a                	mv	a0,s2
    8000493e:	ffffc097          	auipc	ra,0xffffc
    80004942:	49a080e7          	jalr	1178(ra) # 80000dd8 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004946:	02c92603          	lw	a2,44(s2)
    8000494a:	47f5                	li	a5,29
    8000494c:	06c7c563          	blt	a5,a2,800049b6 <log_write+0x90>
    80004950:	0023c797          	auipc	a5,0x23c
    80004954:	3fc7a783          	lw	a5,1020(a5) # 80240d4c <log+0x1c>
    80004958:	37fd                	addiw	a5,a5,-1
    8000495a:	04f65e63          	bge	a2,a5,800049b6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000495e:	0023c797          	auipc	a5,0x23c
    80004962:	3f27a783          	lw	a5,1010(a5) # 80240d50 <log+0x20>
    80004966:	06f05063          	blez	a5,800049c6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000496a:	4781                	li	a5,0
    8000496c:	06c05563          	blez	a2,800049d6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004970:	44cc                	lw	a1,12(s1)
    80004972:	0023c717          	auipc	a4,0x23c
    80004976:	3ee70713          	addi	a4,a4,1006 # 80240d60 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000497a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000497c:	4314                	lw	a3,0(a4)
    8000497e:	04b68c63          	beq	a3,a1,800049d6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004982:	2785                	addiw	a5,a5,1
    80004984:	0711                	addi	a4,a4,4
    80004986:	fef61be3          	bne	a2,a5,8000497c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000498a:	0621                	addi	a2,a2,8
    8000498c:	060a                	slli	a2,a2,0x2
    8000498e:	0023c797          	auipc	a5,0x23c
    80004992:	3a278793          	addi	a5,a5,930 # 80240d30 <log>
    80004996:	97b2                	add	a5,a5,a2
    80004998:	44d8                	lw	a4,12(s1)
    8000499a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000499c:	8526                	mv	a0,s1
    8000499e:	fffff097          	auipc	ra,0xfffff
    800049a2:	dcc080e7          	jalr	-564(ra) # 8000376a <bpin>
    log.lh.n++;
    800049a6:	0023c717          	auipc	a4,0x23c
    800049aa:	38a70713          	addi	a4,a4,906 # 80240d30 <log>
    800049ae:	575c                	lw	a5,44(a4)
    800049b0:	2785                	addiw	a5,a5,1
    800049b2:	d75c                	sw	a5,44(a4)
    800049b4:	a82d                	j	800049ee <log_write+0xc8>
    panic("too big a transaction");
    800049b6:	00004517          	auipc	a0,0x4
    800049ba:	e7250513          	addi	a0,a0,-398 # 80008828 <syscalls+0x218>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	b7e080e7          	jalr	-1154(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800049c6:	00004517          	auipc	a0,0x4
    800049ca:	e7a50513          	addi	a0,a0,-390 # 80008840 <syscalls+0x230>
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	b6e080e7          	jalr	-1170(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800049d6:	00878693          	addi	a3,a5,8
    800049da:	068a                	slli	a3,a3,0x2
    800049dc:	0023c717          	auipc	a4,0x23c
    800049e0:	35470713          	addi	a4,a4,852 # 80240d30 <log>
    800049e4:	9736                	add	a4,a4,a3
    800049e6:	44d4                	lw	a3,12(s1)
    800049e8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049ea:	faf609e3          	beq	a2,a5,8000499c <log_write+0x76>
  }
  release(&log.lock);
    800049ee:	0023c517          	auipc	a0,0x23c
    800049f2:	34250513          	addi	a0,a0,834 # 80240d30 <log>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	496080e7          	jalr	1174(ra) # 80000e8c <release>
}
    800049fe:	60e2                	ld	ra,24(sp)
    80004a00:	6442                	ld	s0,16(sp)
    80004a02:	64a2                	ld	s1,8(sp)
    80004a04:	6902                	ld	s2,0(sp)
    80004a06:	6105                	addi	sp,sp,32
    80004a08:	8082                	ret

0000000080004a0a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a0a:	1101                	addi	sp,sp,-32
    80004a0c:	ec06                	sd	ra,24(sp)
    80004a0e:	e822                	sd	s0,16(sp)
    80004a10:	e426                	sd	s1,8(sp)
    80004a12:	e04a                	sd	s2,0(sp)
    80004a14:	1000                	addi	s0,sp,32
    80004a16:	84aa                	mv	s1,a0
    80004a18:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a1a:	00004597          	auipc	a1,0x4
    80004a1e:	e4658593          	addi	a1,a1,-442 # 80008860 <syscalls+0x250>
    80004a22:	0521                	addi	a0,a0,8
    80004a24:	ffffc097          	auipc	ra,0xffffc
    80004a28:	324080e7          	jalr	804(ra) # 80000d48 <initlock>
  lk->name = name;
    80004a2c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a30:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a34:	0204a423          	sw	zero,40(s1)
}
    80004a38:	60e2                	ld	ra,24(sp)
    80004a3a:	6442                	ld	s0,16(sp)
    80004a3c:	64a2                	ld	s1,8(sp)
    80004a3e:	6902                	ld	s2,0(sp)
    80004a40:	6105                	addi	sp,sp,32
    80004a42:	8082                	ret

0000000080004a44 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a44:	1101                	addi	sp,sp,-32
    80004a46:	ec06                	sd	ra,24(sp)
    80004a48:	e822                	sd	s0,16(sp)
    80004a4a:	e426                	sd	s1,8(sp)
    80004a4c:	e04a                	sd	s2,0(sp)
    80004a4e:	1000                	addi	s0,sp,32
    80004a50:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a52:	00850913          	addi	s2,a0,8
    80004a56:	854a                	mv	a0,s2
    80004a58:	ffffc097          	auipc	ra,0xffffc
    80004a5c:	380080e7          	jalr	896(ra) # 80000dd8 <acquire>
  while (lk->locked) {
    80004a60:	409c                	lw	a5,0(s1)
    80004a62:	cb89                	beqz	a5,80004a74 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a64:	85ca                	mv	a1,s2
    80004a66:	8526                	mv	a0,s1
    80004a68:	ffffe097          	auipc	ra,0xffffe
    80004a6c:	a6c080e7          	jalr	-1428(ra) # 800024d4 <sleep>
  while (lk->locked) {
    80004a70:	409c                	lw	a5,0(s1)
    80004a72:	fbed                	bnez	a5,80004a64 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a74:	4785                	li	a5,1
    80004a76:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a78:	ffffd097          	auipc	ra,0xffffd
    80004a7c:	2f4080e7          	jalr	756(ra) # 80001d6c <myproc>
    80004a80:	591c                	lw	a5,48(a0)
    80004a82:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a84:	854a                	mv	a0,s2
    80004a86:	ffffc097          	auipc	ra,0xffffc
    80004a8a:	406080e7          	jalr	1030(ra) # 80000e8c <release>
}
    80004a8e:	60e2                	ld	ra,24(sp)
    80004a90:	6442                	ld	s0,16(sp)
    80004a92:	64a2                	ld	s1,8(sp)
    80004a94:	6902                	ld	s2,0(sp)
    80004a96:	6105                	addi	sp,sp,32
    80004a98:	8082                	ret

0000000080004a9a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004a9a:	1101                	addi	sp,sp,-32
    80004a9c:	ec06                	sd	ra,24(sp)
    80004a9e:	e822                	sd	s0,16(sp)
    80004aa0:	e426                	sd	s1,8(sp)
    80004aa2:	e04a                	sd	s2,0(sp)
    80004aa4:	1000                	addi	s0,sp,32
    80004aa6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004aa8:	00850913          	addi	s2,a0,8
    80004aac:	854a                	mv	a0,s2
    80004aae:	ffffc097          	auipc	ra,0xffffc
    80004ab2:	32a080e7          	jalr	810(ra) # 80000dd8 <acquire>
  lk->locked = 0;
    80004ab6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aba:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004abe:	8526                	mv	a0,s1
    80004ac0:	ffffe097          	auipc	ra,0xffffe
    80004ac4:	a78080e7          	jalr	-1416(ra) # 80002538 <wakeup>
  release(&lk->lk);
    80004ac8:	854a                	mv	a0,s2
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	3c2080e7          	jalr	962(ra) # 80000e8c <release>
}
    80004ad2:	60e2                	ld	ra,24(sp)
    80004ad4:	6442                	ld	s0,16(sp)
    80004ad6:	64a2                	ld	s1,8(sp)
    80004ad8:	6902                	ld	s2,0(sp)
    80004ada:	6105                	addi	sp,sp,32
    80004adc:	8082                	ret

0000000080004ade <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004ade:	7179                	addi	sp,sp,-48
    80004ae0:	f406                	sd	ra,40(sp)
    80004ae2:	f022                	sd	s0,32(sp)
    80004ae4:	ec26                	sd	s1,24(sp)
    80004ae6:	e84a                	sd	s2,16(sp)
    80004ae8:	e44e                	sd	s3,8(sp)
    80004aea:	1800                	addi	s0,sp,48
    80004aec:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004aee:	00850913          	addi	s2,a0,8
    80004af2:	854a                	mv	a0,s2
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	2e4080e7          	jalr	740(ra) # 80000dd8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004afc:	409c                	lw	a5,0(s1)
    80004afe:	ef99                	bnez	a5,80004b1c <holdingsleep+0x3e>
    80004b00:	4481                	li	s1,0
  release(&lk->lk);
    80004b02:	854a                	mv	a0,s2
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	388080e7          	jalr	904(ra) # 80000e8c <release>
  return r;
}
    80004b0c:	8526                	mv	a0,s1
    80004b0e:	70a2                	ld	ra,40(sp)
    80004b10:	7402                	ld	s0,32(sp)
    80004b12:	64e2                	ld	s1,24(sp)
    80004b14:	6942                	ld	s2,16(sp)
    80004b16:	69a2                	ld	s3,8(sp)
    80004b18:	6145                	addi	sp,sp,48
    80004b1a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b1c:	0284a983          	lw	s3,40(s1)
    80004b20:	ffffd097          	auipc	ra,0xffffd
    80004b24:	24c080e7          	jalr	588(ra) # 80001d6c <myproc>
    80004b28:	5904                	lw	s1,48(a0)
    80004b2a:	413484b3          	sub	s1,s1,s3
    80004b2e:	0014b493          	seqz	s1,s1
    80004b32:	bfc1                	j	80004b02 <holdingsleep+0x24>

0000000080004b34 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b34:	1141                	addi	sp,sp,-16
    80004b36:	e406                	sd	ra,8(sp)
    80004b38:	e022                	sd	s0,0(sp)
    80004b3a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b3c:	00004597          	auipc	a1,0x4
    80004b40:	d3458593          	addi	a1,a1,-716 # 80008870 <syscalls+0x260>
    80004b44:	0023c517          	auipc	a0,0x23c
    80004b48:	33450513          	addi	a0,a0,820 # 80240e78 <ftable>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	1fc080e7          	jalr	508(ra) # 80000d48 <initlock>
}
    80004b54:	60a2                	ld	ra,8(sp)
    80004b56:	6402                	ld	s0,0(sp)
    80004b58:	0141                	addi	sp,sp,16
    80004b5a:	8082                	ret

0000000080004b5c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b5c:	1101                	addi	sp,sp,-32
    80004b5e:	ec06                	sd	ra,24(sp)
    80004b60:	e822                	sd	s0,16(sp)
    80004b62:	e426                	sd	s1,8(sp)
    80004b64:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b66:	0023c517          	auipc	a0,0x23c
    80004b6a:	31250513          	addi	a0,a0,786 # 80240e78 <ftable>
    80004b6e:	ffffc097          	auipc	ra,0xffffc
    80004b72:	26a080e7          	jalr	618(ra) # 80000dd8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b76:	0023c497          	auipc	s1,0x23c
    80004b7a:	31a48493          	addi	s1,s1,794 # 80240e90 <ftable+0x18>
    80004b7e:	0023d717          	auipc	a4,0x23d
    80004b82:	2b270713          	addi	a4,a4,690 # 80241e30 <disk>
    if(f->ref == 0){
    80004b86:	40dc                	lw	a5,4(s1)
    80004b88:	cf99                	beqz	a5,80004ba6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b8a:	02848493          	addi	s1,s1,40
    80004b8e:	fee49ce3          	bne	s1,a4,80004b86 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004b92:	0023c517          	auipc	a0,0x23c
    80004b96:	2e650513          	addi	a0,a0,742 # 80240e78 <ftable>
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	2f2080e7          	jalr	754(ra) # 80000e8c <release>
  return 0;
    80004ba2:	4481                	li	s1,0
    80004ba4:	a819                	j	80004bba <filealloc+0x5e>
      f->ref = 1;
    80004ba6:	4785                	li	a5,1
    80004ba8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004baa:	0023c517          	auipc	a0,0x23c
    80004bae:	2ce50513          	addi	a0,a0,718 # 80240e78 <ftable>
    80004bb2:	ffffc097          	auipc	ra,0xffffc
    80004bb6:	2da080e7          	jalr	730(ra) # 80000e8c <release>
}
    80004bba:	8526                	mv	a0,s1
    80004bbc:	60e2                	ld	ra,24(sp)
    80004bbe:	6442                	ld	s0,16(sp)
    80004bc0:	64a2                	ld	s1,8(sp)
    80004bc2:	6105                	addi	sp,sp,32
    80004bc4:	8082                	ret

0000000080004bc6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bc6:	1101                	addi	sp,sp,-32
    80004bc8:	ec06                	sd	ra,24(sp)
    80004bca:	e822                	sd	s0,16(sp)
    80004bcc:	e426                	sd	s1,8(sp)
    80004bce:	1000                	addi	s0,sp,32
    80004bd0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bd2:	0023c517          	auipc	a0,0x23c
    80004bd6:	2a650513          	addi	a0,a0,678 # 80240e78 <ftable>
    80004bda:	ffffc097          	auipc	ra,0xffffc
    80004bde:	1fe080e7          	jalr	510(ra) # 80000dd8 <acquire>
  if(f->ref < 1)
    80004be2:	40dc                	lw	a5,4(s1)
    80004be4:	02f05263          	blez	a5,80004c08 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004be8:	2785                	addiw	a5,a5,1
    80004bea:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bec:	0023c517          	auipc	a0,0x23c
    80004bf0:	28c50513          	addi	a0,a0,652 # 80240e78 <ftable>
    80004bf4:	ffffc097          	auipc	ra,0xffffc
    80004bf8:	298080e7          	jalr	664(ra) # 80000e8c <release>
  return f;
}
    80004bfc:	8526                	mv	a0,s1
    80004bfe:	60e2                	ld	ra,24(sp)
    80004c00:	6442                	ld	s0,16(sp)
    80004c02:	64a2                	ld	s1,8(sp)
    80004c04:	6105                	addi	sp,sp,32
    80004c06:	8082                	ret
    panic("filedup");
    80004c08:	00004517          	auipc	a0,0x4
    80004c0c:	c7050513          	addi	a0,a0,-912 # 80008878 <syscalls+0x268>
    80004c10:	ffffc097          	auipc	ra,0xffffc
    80004c14:	92c080e7          	jalr	-1748(ra) # 8000053c <panic>

0000000080004c18 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c18:	7139                	addi	sp,sp,-64
    80004c1a:	fc06                	sd	ra,56(sp)
    80004c1c:	f822                	sd	s0,48(sp)
    80004c1e:	f426                	sd	s1,40(sp)
    80004c20:	f04a                	sd	s2,32(sp)
    80004c22:	ec4e                	sd	s3,24(sp)
    80004c24:	e852                	sd	s4,16(sp)
    80004c26:	e456                	sd	s5,8(sp)
    80004c28:	0080                	addi	s0,sp,64
    80004c2a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c2c:	0023c517          	auipc	a0,0x23c
    80004c30:	24c50513          	addi	a0,a0,588 # 80240e78 <ftable>
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	1a4080e7          	jalr	420(ra) # 80000dd8 <acquire>
  if(f->ref < 1)
    80004c3c:	40dc                	lw	a5,4(s1)
    80004c3e:	06f05163          	blez	a5,80004ca0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c42:	37fd                	addiw	a5,a5,-1
    80004c44:	0007871b          	sext.w	a4,a5
    80004c48:	c0dc                	sw	a5,4(s1)
    80004c4a:	06e04363          	bgtz	a4,80004cb0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c4e:	0004a903          	lw	s2,0(s1)
    80004c52:	0094ca83          	lbu	s5,9(s1)
    80004c56:	0104ba03          	ld	s4,16(s1)
    80004c5a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c5e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c62:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c66:	0023c517          	auipc	a0,0x23c
    80004c6a:	21250513          	addi	a0,a0,530 # 80240e78 <ftable>
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	21e080e7          	jalr	542(ra) # 80000e8c <release>

  if(ff.type == FD_PIPE){
    80004c76:	4785                	li	a5,1
    80004c78:	04f90d63          	beq	s2,a5,80004cd2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c7c:	3979                	addiw	s2,s2,-2
    80004c7e:	4785                	li	a5,1
    80004c80:	0527e063          	bltu	a5,s2,80004cc0 <fileclose+0xa8>
    begin_op();
    80004c84:	00000097          	auipc	ra,0x0
    80004c88:	ad0080e7          	jalr	-1328(ra) # 80004754 <begin_op>
    iput(ff.ip);
    80004c8c:	854e                	mv	a0,s3
    80004c8e:	fffff097          	auipc	ra,0xfffff
    80004c92:	2da080e7          	jalr	730(ra) # 80003f68 <iput>
    end_op();
    80004c96:	00000097          	auipc	ra,0x0
    80004c9a:	b38080e7          	jalr	-1224(ra) # 800047ce <end_op>
    80004c9e:	a00d                	j	80004cc0 <fileclose+0xa8>
    panic("fileclose");
    80004ca0:	00004517          	auipc	a0,0x4
    80004ca4:	be050513          	addi	a0,a0,-1056 # 80008880 <syscalls+0x270>
    80004ca8:	ffffc097          	auipc	ra,0xffffc
    80004cac:	894080e7          	jalr	-1900(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004cb0:	0023c517          	auipc	a0,0x23c
    80004cb4:	1c850513          	addi	a0,a0,456 # 80240e78 <ftable>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	1d4080e7          	jalr	468(ra) # 80000e8c <release>
  }
}
    80004cc0:	70e2                	ld	ra,56(sp)
    80004cc2:	7442                	ld	s0,48(sp)
    80004cc4:	74a2                	ld	s1,40(sp)
    80004cc6:	7902                	ld	s2,32(sp)
    80004cc8:	69e2                	ld	s3,24(sp)
    80004cca:	6a42                	ld	s4,16(sp)
    80004ccc:	6aa2                	ld	s5,8(sp)
    80004cce:	6121                	addi	sp,sp,64
    80004cd0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cd2:	85d6                	mv	a1,s5
    80004cd4:	8552                	mv	a0,s4
    80004cd6:	00000097          	auipc	ra,0x0
    80004cda:	348080e7          	jalr	840(ra) # 8000501e <pipeclose>
    80004cde:	b7cd                	j	80004cc0 <fileclose+0xa8>

0000000080004ce0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004ce0:	715d                	addi	sp,sp,-80
    80004ce2:	e486                	sd	ra,72(sp)
    80004ce4:	e0a2                	sd	s0,64(sp)
    80004ce6:	fc26                	sd	s1,56(sp)
    80004ce8:	f84a                	sd	s2,48(sp)
    80004cea:	f44e                	sd	s3,40(sp)
    80004cec:	0880                	addi	s0,sp,80
    80004cee:	84aa                	mv	s1,a0
    80004cf0:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004cf2:	ffffd097          	auipc	ra,0xffffd
    80004cf6:	07a080e7          	jalr	122(ra) # 80001d6c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004cfa:	409c                	lw	a5,0(s1)
    80004cfc:	37f9                	addiw	a5,a5,-2
    80004cfe:	4705                	li	a4,1
    80004d00:	04f76763          	bltu	a4,a5,80004d4e <filestat+0x6e>
    80004d04:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d06:	6c88                	ld	a0,24(s1)
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	0a6080e7          	jalr	166(ra) # 80003dae <ilock>
    stati(f->ip, &st);
    80004d10:	fb840593          	addi	a1,s0,-72
    80004d14:	6c88                	ld	a0,24(s1)
    80004d16:	fffff097          	auipc	ra,0xfffff
    80004d1a:	322080e7          	jalr	802(ra) # 80004038 <stati>
    iunlock(f->ip);
    80004d1e:	6c88                	ld	a0,24(s1)
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	150080e7          	jalr	336(ra) # 80003e70 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d28:	46e1                	li	a3,24
    80004d2a:	fb840613          	addi	a2,s0,-72
    80004d2e:	85ce                	mv	a1,s3
    80004d30:	05093503          	ld	a0,80(s2)
    80004d34:	ffffd097          	auipc	ra,0xffffd
    80004d38:	bf0080e7          	jalr	-1040(ra) # 80001924 <copyout>
    80004d3c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d40:	60a6                	ld	ra,72(sp)
    80004d42:	6406                	ld	s0,64(sp)
    80004d44:	74e2                	ld	s1,56(sp)
    80004d46:	7942                	ld	s2,48(sp)
    80004d48:	79a2                	ld	s3,40(sp)
    80004d4a:	6161                	addi	sp,sp,80
    80004d4c:	8082                	ret
  return -1;
    80004d4e:	557d                	li	a0,-1
    80004d50:	bfc5                	j	80004d40 <filestat+0x60>

0000000080004d52 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d52:	7179                	addi	sp,sp,-48
    80004d54:	f406                	sd	ra,40(sp)
    80004d56:	f022                	sd	s0,32(sp)
    80004d58:	ec26                	sd	s1,24(sp)
    80004d5a:	e84a                	sd	s2,16(sp)
    80004d5c:	e44e                	sd	s3,8(sp)
    80004d5e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d60:	00854783          	lbu	a5,8(a0)
    80004d64:	c3d5                	beqz	a5,80004e08 <fileread+0xb6>
    80004d66:	84aa                	mv	s1,a0
    80004d68:	89ae                	mv	s3,a1
    80004d6a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d6c:	411c                	lw	a5,0(a0)
    80004d6e:	4705                	li	a4,1
    80004d70:	04e78963          	beq	a5,a4,80004dc2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d74:	470d                	li	a4,3
    80004d76:	04e78d63          	beq	a5,a4,80004dd0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d7a:	4709                	li	a4,2
    80004d7c:	06e79e63          	bne	a5,a4,80004df8 <fileread+0xa6>
    ilock(f->ip);
    80004d80:	6d08                	ld	a0,24(a0)
    80004d82:	fffff097          	auipc	ra,0xfffff
    80004d86:	02c080e7          	jalr	44(ra) # 80003dae <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d8a:	874a                	mv	a4,s2
    80004d8c:	5094                	lw	a3,32(s1)
    80004d8e:	864e                	mv	a2,s3
    80004d90:	4585                	li	a1,1
    80004d92:	6c88                	ld	a0,24(s1)
    80004d94:	fffff097          	auipc	ra,0xfffff
    80004d98:	2ce080e7          	jalr	718(ra) # 80004062 <readi>
    80004d9c:	892a                	mv	s2,a0
    80004d9e:	00a05563          	blez	a0,80004da8 <fileread+0x56>
      f->off += r;
    80004da2:	509c                	lw	a5,32(s1)
    80004da4:	9fa9                	addw	a5,a5,a0
    80004da6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004da8:	6c88                	ld	a0,24(s1)
    80004daa:	fffff097          	auipc	ra,0xfffff
    80004dae:	0c6080e7          	jalr	198(ra) # 80003e70 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004db2:	854a                	mv	a0,s2
    80004db4:	70a2                	ld	ra,40(sp)
    80004db6:	7402                	ld	s0,32(sp)
    80004db8:	64e2                	ld	s1,24(sp)
    80004dba:	6942                	ld	s2,16(sp)
    80004dbc:	69a2                	ld	s3,8(sp)
    80004dbe:	6145                	addi	sp,sp,48
    80004dc0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dc2:	6908                	ld	a0,16(a0)
    80004dc4:	00000097          	auipc	ra,0x0
    80004dc8:	3c2080e7          	jalr	962(ra) # 80005186 <piperead>
    80004dcc:	892a                	mv	s2,a0
    80004dce:	b7d5                	j	80004db2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004dd0:	02451783          	lh	a5,36(a0)
    80004dd4:	03079693          	slli	a3,a5,0x30
    80004dd8:	92c1                	srli	a3,a3,0x30
    80004dda:	4725                	li	a4,9
    80004ddc:	02d76863          	bltu	a4,a3,80004e0c <fileread+0xba>
    80004de0:	0792                	slli	a5,a5,0x4
    80004de2:	0023c717          	auipc	a4,0x23c
    80004de6:	ff670713          	addi	a4,a4,-10 # 80240dd8 <devsw>
    80004dea:	97ba                	add	a5,a5,a4
    80004dec:	639c                	ld	a5,0(a5)
    80004dee:	c38d                	beqz	a5,80004e10 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004df0:	4505                	li	a0,1
    80004df2:	9782                	jalr	a5
    80004df4:	892a                	mv	s2,a0
    80004df6:	bf75                	j	80004db2 <fileread+0x60>
    panic("fileread");
    80004df8:	00004517          	auipc	a0,0x4
    80004dfc:	a9850513          	addi	a0,a0,-1384 # 80008890 <syscalls+0x280>
    80004e00:	ffffb097          	auipc	ra,0xffffb
    80004e04:	73c080e7          	jalr	1852(ra) # 8000053c <panic>
    return -1;
    80004e08:	597d                	li	s2,-1
    80004e0a:	b765                	j	80004db2 <fileread+0x60>
      return -1;
    80004e0c:	597d                	li	s2,-1
    80004e0e:	b755                	j	80004db2 <fileread+0x60>
    80004e10:	597d                	li	s2,-1
    80004e12:	b745                	j	80004db2 <fileread+0x60>

0000000080004e14 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004e14:	00954783          	lbu	a5,9(a0)
    80004e18:	10078e63          	beqz	a5,80004f34 <filewrite+0x120>
{
    80004e1c:	715d                	addi	sp,sp,-80
    80004e1e:	e486                	sd	ra,72(sp)
    80004e20:	e0a2                	sd	s0,64(sp)
    80004e22:	fc26                	sd	s1,56(sp)
    80004e24:	f84a                	sd	s2,48(sp)
    80004e26:	f44e                	sd	s3,40(sp)
    80004e28:	f052                	sd	s4,32(sp)
    80004e2a:	ec56                	sd	s5,24(sp)
    80004e2c:	e85a                	sd	s6,16(sp)
    80004e2e:	e45e                	sd	s7,8(sp)
    80004e30:	e062                	sd	s8,0(sp)
    80004e32:	0880                	addi	s0,sp,80
    80004e34:	892a                	mv	s2,a0
    80004e36:	8b2e                	mv	s6,a1
    80004e38:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e3a:	411c                	lw	a5,0(a0)
    80004e3c:	4705                	li	a4,1
    80004e3e:	02e78263          	beq	a5,a4,80004e62 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e42:	470d                	li	a4,3
    80004e44:	02e78563          	beq	a5,a4,80004e6e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e48:	4709                	li	a4,2
    80004e4a:	0ce79d63          	bne	a5,a4,80004f24 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e4e:	0ac05b63          	blez	a2,80004f04 <filewrite+0xf0>
    int i = 0;
    80004e52:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e54:	6b85                	lui	s7,0x1
    80004e56:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e5a:	6c05                	lui	s8,0x1
    80004e5c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e60:	a851                	j	80004ef4 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e62:	6908                	ld	a0,16(a0)
    80004e64:	00000097          	auipc	ra,0x0
    80004e68:	22a080e7          	jalr	554(ra) # 8000508e <pipewrite>
    80004e6c:	a045                	j	80004f0c <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e6e:	02451783          	lh	a5,36(a0)
    80004e72:	03079693          	slli	a3,a5,0x30
    80004e76:	92c1                	srli	a3,a3,0x30
    80004e78:	4725                	li	a4,9
    80004e7a:	0ad76f63          	bltu	a4,a3,80004f38 <filewrite+0x124>
    80004e7e:	0792                	slli	a5,a5,0x4
    80004e80:	0023c717          	auipc	a4,0x23c
    80004e84:	f5870713          	addi	a4,a4,-168 # 80240dd8 <devsw>
    80004e88:	97ba                	add	a5,a5,a4
    80004e8a:	679c                	ld	a5,8(a5)
    80004e8c:	cbc5                	beqz	a5,80004f3c <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004e8e:	4505                	li	a0,1
    80004e90:	9782                	jalr	a5
    80004e92:	a8ad                	j	80004f0c <filewrite+0xf8>
      if(n1 > max)
    80004e94:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004e98:	00000097          	auipc	ra,0x0
    80004e9c:	8bc080e7          	jalr	-1860(ra) # 80004754 <begin_op>
      ilock(f->ip);
    80004ea0:	01893503          	ld	a0,24(s2)
    80004ea4:	fffff097          	auipc	ra,0xfffff
    80004ea8:	f0a080e7          	jalr	-246(ra) # 80003dae <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004eac:	8756                	mv	a4,s5
    80004eae:	02092683          	lw	a3,32(s2)
    80004eb2:	01698633          	add	a2,s3,s6
    80004eb6:	4585                	li	a1,1
    80004eb8:	01893503          	ld	a0,24(s2)
    80004ebc:	fffff097          	auipc	ra,0xfffff
    80004ec0:	29e080e7          	jalr	670(ra) # 8000415a <writei>
    80004ec4:	84aa                	mv	s1,a0
    80004ec6:	00a05763          	blez	a0,80004ed4 <filewrite+0xc0>
        f->off += r;
    80004eca:	02092783          	lw	a5,32(s2)
    80004ece:	9fa9                	addw	a5,a5,a0
    80004ed0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ed4:	01893503          	ld	a0,24(s2)
    80004ed8:	fffff097          	auipc	ra,0xfffff
    80004edc:	f98080e7          	jalr	-104(ra) # 80003e70 <iunlock>
      end_op();
    80004ee0:	00000097          	auipc	ra,0x0
    80004ee4:	8ee080e7          	jalr	-1810(ra) # 800047ce <end_op>

      if(r != n1){
    80004ee8:	009a9f63          	bne	s5,s1,80004f06 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004eec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004ef0:	0149db63          	bge	s3,s4,80004f06 <filewrite+0xf2>
      int n1 = n - i;
    80004ef4:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004ef8:	0004879b          	sext.w	a5,s1
    80004efc:	f8fbdce3          	bge	s7,a5,80004e94 <filewrite+0x80>
    80004f00:	84e2                	mv	s1,s8
    80004f02:	bf49                	j	80004e94 <filewrite+0x80>
    int i = 0;
    80004f04:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f06:	033a1d63          	bne	s4,s3,80004f40 <filewrite+0x12c>
    80004f0a:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f0c:	60a6                	ld	ra,72(sp)
    80004f0e:	6406                	ld	s0,64(sp)
    80004f10:	74e2                	ld	s1,56(sp)
    80004f12:	7942                	ld	s2,48(sp)
    80004f14:	79a2                	ld	s3,40(sp)
    80004f16:	7a02                	ld	s4,32(sp)
    80004f18:	6ae2                	ld	s5,24(sp)
    80004f1a:	6b42                	ld	s6,16(sp)
    80004f1c:	6ba2                	ld	s7,8(sp)
    80004f1e:	6c02                	ld	s8,0(sp)
    80004f20:	6161                	addi	sp,sp,80
    80004f22:	8082                	ret
    panic("filewrite");
    80004f24:	00004517          	auipc	a0,0x4
    80004f28:	97c50513          	addi	a0,a0,-1668 # 800088a0 <syscalls+0x290>
    80004f2c:	ffffb097          	auipc	ra,0xffffb
    80004f30:	610080e7          	jalr	1552(ra) # 8000053c <panic>
    return -1;
    80004f34:	557d                	li	a0,-1
}
    80004f36:	8082                	ret
      return -1;
    80004f38:	557d                	li	a0,-1
    80004f3a:	bfc9                	j	80004f0c <filewrite+0xf8>
    80004f3c:	557d                	li	a0,-1
    80004f3e:	b7f9                	j	80004f0c <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004f40:	557d                	li	a0,-1
    80004f42:	b7e9                	j	80004f0c <filewrite+0xf8>

0000000080004f44 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f44:	7179                	addi	sp,sp,-48
    80004f46:	f406                	sd	ra,40(sp)
    80004f48:	f022                	sd	s0,32(sp)
    80004f4a:	ec26                	sd	s1,24(sp)
    80004f4c:	e84a                	sd	s2,16(sp)
    80004f4e:	e44e                	sd	s3,8(sp)
    80004f50:	e052                	sd	s4,0(sp)
    80004f52:	1800                	addi	s0,sp,48
    80004f54:	84aa                	mv	s1,a0
    80004f56:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f58:	0005b023          	sd	zero,0(a1)
    80004f5c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f60:	00000097          	auipc	ra,0x0
    80004f64:	bfc080e7          	jalr	-1028(ra) # 80004b5c <filealloc>
    80004f68:	e088                	sd	a0,0(s1)
    80004f6a:	c551                	beqz	a0,80004ff6 <pipealloc+0xb2>
    80004f6c:	00000097          	auipc	ra,0x0
    80004f70:	bf0080e7          	jalr	-1040(ra) # 80004b5c <filealloc>
    80004f74:	00aa3023          	sd	a0,0(s4)
    80004f78:	c92d                	beqz	a0,80004fea <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f7a:	ffffc097          	auipc	ra,0xffffc
    80004f7e:	ce4080e7          	jalr	-796(ra) # 80000c5e <kalloc>
    80004f82:	892a                	mv	s2,a0
    80004f84:	c125                	beqz	a0,80004fe4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f86:	4985                	li	s3,1
    80004f88:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f8c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004f90:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004f94:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004f98:	00004597          	auipc	a1,0x4
    80004f9c:	91858593          	addi	a1,a1,-1768 # 800088b0 <syscalls+0x2a0>
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	da8080e7          	jalr	-600(ra) # 80000d48 <initlock>
  (*f0)->type = FD_PIPE;
    80004fa8:	609c                	ld	a5,0(s1)
    80004faa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fae:	609c                	ld	a5,0(s1)
    80004fb0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fb4:	609c                	ld	a5,0(s1)
    80004fb6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004fba:	609c                	ld	a5,0(s1)
    80004fbc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004fc0:	000a3783          	ld	a5,0(s4)
    80004fc4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fc8:	000a3783          	ld	a5,0(s4)
    80004fcc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fd0:	000a3783          	ld	a5,0(s4)
    80004fd4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fd8:	000a3783          	ld	a5,0(s4)
    80004fdc:	0127b823          	sd	s2,16(a5)
  return 0;
    80004fe0:	4501                	li	a0,0
    80004fe2:	a025                	j	8000500a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004fe4:	6088                	ld	a0,0(s1)
    80004fe6:	e501                	bnez	a0,80004fee <pipealloc+0xaa>
    80004fe8:	a039                	j	80004ff6 <pipealloc+0xb2>
    80004fea:	6088                	ld	a0,0(s1)
    80004fec:	c51d                	beqz	a0,8000501a <pipealloc+0xd6>
    fileclose(*f0);
    80004fee:	00000097          	auipc	ra,0x0
    80004ff2:	c2a080e7          	jalr	-982(ra) # 80004c18 <fileclose>
  if(*f1)
    80004ff6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ffa:	557d                	li	a0,-1
  if(*f1)
    80004ffc:	c799                	beqz	a5,8000500a <pipealloc+0xc6>
    fileclose(*f1);
    80004ffe:	853e                	mv	a0,a5
    80005000:	00000097          	auipc	ra,0x0
    80005004:	c18080e7          	jalr	-1000(ra) # 80004c18 <fileclose>
  return -1;
    80005008:	557d                	li	a0,-1
}
    8000500a:	70a2                	ld	ra,40(sp)
    8000500c:	7402                	ld	s0,32(sp)
    8000500e:	64e2                	ld	s1,24(sp)
    80005010:	6942                	ld	s2,16(sp)
    80005012:	69a2                	ld	s3,8(sp)
    80005014:	6a02                	ld	s4,0(sp)
    80005016:	6145                	addi	sp,sp,48
    80005018:	8082                	ret
  return -1;
    8000501a:	557d                	li	a0,-1
    8000501c:	b7fd                	j	8000500a <pipealloc+0xc6>

000000008000501e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000501e:	1101                	addi	sp,sp,-32
    80005020:	ec06                	sd	ra,24(sp)
    80005022:	e822                	sd	s0,16(sp)
    80005024:	e426                	sd	s1,8(sp)
    80005026:	e04a                	sd	s2,0(sp)
    80005028:	1000                	addi	s0,sp,32
    8000502a:	84aa                	mv	s1,a0
    8000502c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000502e:	ffffc097          	auipc	ra,0xffffc
    80005032:	daa080e7          	jalr	-598(ra) # 80000dd8 <acquire>
  if(writable){
    80005036:	02090d63          	beqz	s2,80005070 <pipeclose+0x52>
    pi->writeopen = 0;
    8000503a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000503e:	21848513          	addi	a0,s1,536
    80005042:	ffffd097          	auipc	ra,0xffffd
    80005046:	4f6080e7          	jalr	1270(ra) # 80002538 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000504a:	2204b783          	ld	a5,544(s1)
    8000504e:	eb95                	bnez	a5,80005082 <pipeclose+0x64>
    release(&pi->lock);
    80005050:	8526                	mv	a0,s1
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	e3a080e7          	jalr	-454(ra) # 80000e8c <release>
    kfree((char*)pi);
    8000505a:	8526                	mv	a0,s1
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	a16080e7          	jalr	-1514(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80005064:	60e2                	ld	ra,24(sp)
    80005066:	6442                	ld	s0,16(sp)
    80005068:	64a2                	ld	s1,8(sp)
    8000506a:	6902                	ld	s2,0(sp)
    8000506c:	6105                	addi	sp,sp,32
    8000506e:	8082                	ret
    pi->readopen = 0;
    80005070:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005074:	21c48513          	addi	a0,s1,540
    80005078:	ffffd097          	auipc	ra,0xffffd
    8000507c:	4c0080e7          	jalr	1216(ra) # 80002538 <wakeup>
    80005080:	b7e9                	j	8000504a <pipeclose+0x2c>
    release(&pi->lock);
    80005082:	8526                	mv	a0,s1
    80005084:	ffffc097          	auipc	ra,0xffffc
    80005088:	e08080e7          	jalr	-504(ra) # 80000e8c <release>
}
    8000508c:	bfe1                	j	80005064 <pipeclose+0x46>

000000008000508e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000508e:	711d                	addi	sp,sp,-96
    80005090:	ec86                	sd	ra,88(sp)
    80005092:	e8a2                	sd	s0,80(sp)
    80005094:	e4a6                	sd	s1,72(sp)
    80005096:	e0ca                	sd	s2,64(sp)
    80005098:	fc4e                	sd	s3,56(sp)
    8000509a:	f852                	sd	s4,48(sp)
    8000509c:	f456                	sd	s5,40(sp)
    8000509e:	f05a                	sd	s6,32(sp)
    800050a0:	ec5e                	sd	s7,24(sp)
    800050a2:	e862                	sd	s8,16(sp)
    800050a4:	1080                	addi	s0,sp,96
    800050a6:	84aa                	mv	s1,a0
    800050a8:	8aae                	mv	s5,a1
    800050aa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050ac:	ffffd097          	auipc	ra,0xffffd
    800050b0:	cc0080e7          	jalr	-832(ra) # 80001d6c <myproc>
    800050b4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050b6:	8526                	mv	a0,s1
    800050b8:	ffffc097          	auipc	ra,0xffffc
    800050bc:	d20080e7          	jalr	-736(ra) # 80000dd8 <acquire>
  while(i < n){
    800050c0:	0b405663          	blez	s4,8000516c <pipewrite+0xde>
  int i = 0;
    800050c4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050c6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050c8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050cc:	21c48b93          	addi	s7,s1,540
    800050d0:	a089                	j	80005112 <pipewrite+0x84>
      release(&pi->lock);
    800050d2:	8526                	mv	a0,s1
    800050d4:	ffffc097          	auipc	ra,0xffffc
    800050d8:	db8080e7          	jalr	-584(ra) # 80000e8c <release>
      return -1;
    800050dc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050de:	854a                	mv	a0,s2
    800050e0:	60e6                	ld	ra,88(sp)
    800050e2:	6446                	ld	s0,80(sp)
    800050e4:	64a6                	ld	s1,72(sp)
    800050e6:	6906                	ld	s2,64(sp)
    800050e8:	79e2                	ld	s3,56(sp)
    800050ea:	7a42                	ld	s4,48(sp)
    800050ec:	7aa2                	ld	s5,40(sp)
    800050ee:	7b02                	ld	s6,32(sp)
    800050f0:	6be2                	ld	s7,24(sp)
    800050f2:	6c42                	ld	s8,16(sp)
    800050f4:	6125                	addi	sp,sp,96
    800050f6:	8082                	ret
      wakeup(&pi->nread);
    800050f8:	8562                	mv	a0,s8
    800050fa:	ffffd097          	auipc	ra,0xffffd
    800050fe:	43e080e7          	jalr	1086(ra) # 80002538 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005102:	85a6                	mv	a1,s1
    80005104:	855e                	mv	a0,s7
    80005106:	ffffd097          	auipc	ra,0xffffd
    8000510a:	3ce080e7          	jalr	974(ra) # 800024d4 <sleep>
  while(i < n){
    8000510e:	07495063          	bge	s2,s4,8000516e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005112:	2204a783          	lw	a5,544(s1)
    80005116:	dfd5                	beqz	a5,800050d2 <pipewrite+0x44>
    80005118:	854e                	mv	a0,s3
    8000511a:	ffffd097          	auipc	ra,0xffffd
    8000511e:	662080e7          	jalr	1634(ra) # 8000277c <killed>
    80005122:	f945                	bnez	a0,800050d2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005124:	2184a783          	lw	a5,536(s1)
    80005128:	21c4a703          	lw	a4,540(s1)
    8000512c:	2007879b          	addiw	a5,a5,512
    80005130:	fcf704e3          	beq	a4,a5,800050f8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005134:	4685                	li	a3,1
    80005136:	01590633          	add	a2,s2,s5
    8000513a:	faf40593          	addi	a1,s0,-81
    8000513e:	0509b503          	ld	a0,80(s3)
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	882080e7          	jalr	-1918(ra) # 800019c4 <copyin>
    8000514a:	03650263          	beq	a0,s6,8000516e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000514e:	21c4a783          	lw	a5,540(s1)
    80005152:	0017871b          	addiw	a4,a5,1
    80005156:	20e4ae23          	sw	a4,540(s1)
    8000515a:	1ff7f793          	andi	a5,a5,511
    8000515e:	97a6                	add	a5,a5,s1
    80005160:	faf44703          	lbu	a4,-81(s0)
    80005164:	00e78c23          	sb	a4,24(a5)
      i++;
    80005168:	2905                	addiw	s2,s2,1
    8000516a:	b755                	j	8000510e <pipewrite+0x80>
  int i = 0;
    8000516c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000516e:	21848513          	addi	a0,s1,536
    80005172:	ffffd097          	auipc	ra,0xffffd
    80005176:	3c6080e7          	jalr	966(ra) # 80002538 <wakeup>
  release(&pi->lock);
    8000517a:	8526                	mv	a0,s1
    8000517c:	ffffc097          	auipc	ra,0xffffc
    80005180:	d10080e7          	jalr	-752(ra) # 80000e8c <release>
  return i;
    80005184:	bfa9                	j	800050de <pipewrite+0x50>

0000000080005186 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005186:	715d                	addi	sp,sp,-80
    80005188:	e486                	sd	ra,72(sp)
    8000518a:	e0a2                	sd	s0,64(sp)
    8000518c:	fc26                	sd	s1,56(sp)
    8000518e:	f84a                	sd	s2,48(sp)
    80005190:	f44e                	sd	s3,40(sp)
    80005192:	f052                	sd	s4,32(sp)
    80005194:	ec56                	sd	s5,24(sp)
    80005196:	e85a                	sd	s6,16(sp)
    80005198:	0880                	addi	s0,sp,80
    8000519a:	84aa                	mv	s1,a0
    8000519c:	892e                	mv	s2,a1
    8000519e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051a0:	ffffd097          	auipc	ra,0xffffd
    800051a4:	bcc080e7          	jalr	-1076(ra) # 80001d6c <myproc>
    800051a8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	c2c080e7          	jalr	-980(ra) # 80000dd8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051b4:	2184a703          	lw	a4,536(s1)
    800051b8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051bc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c0:	02f71763          	bne	a4,a5,800051ee <piperead+0x68>
    800051c4:	2244a783          	lw	a5,548(s1)
    800051c8:	c39d                	beqz	a5,800051ee <piperead+0x68>
    if(killed(pr)){
    800051ca:	8552                	mv	a0,s4
    800051cc:	ffffd097          	auipc	ra,0xffffd
    800051d0:	5b0080e7          	jalr	1456(ra) # 8000277c <killed>
    800051d4:	e949                	bnez	a0,80005266 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051d6:	85a6                	mv	a1,s1
    800051d8:	854e                	mv	a0,s3
    800051da:	ffffd097          	auipc	ra,0xffffd
    800051de:	2fa080e7          	jalr	762(ra) # 800024d4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051e2:	2184a703          	lw	a4,536(s1)
    800051e6:	21c4a783          	lw	a5,540(s1)
    800051ea:	fcf70de3          	beq	a4,a5,800051c4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051ee:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800051f0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051f2:	05505463          	blez	s5,8000523a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    800051f6:	2184a783          	lw	a5,536(s1)
    800051fa:	21c4a703          	lw	a4,540(s1)
    800051fe:	02f70e63          	beq	a4,a5,8000523a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005202:	0017871b          	addiw	a4,a5,1
    80005206:	20e4ac23          	sw	a4,536(s1)
    8000520a:	1ff7f793          	andi	a5,a5,511
    8000520e:	97a6                	add	a5,a5,s1
    80005210:	0187c783          	lbu	a5,24(a5)
    80005214:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005218:	4685                	li	a3,1
    8000521a:	fbf40613          	addi	a2,s0,-65
    8000521e:	85ca                	mv	a1,s2
    80005220:	050a3503          	ld	a0,80(s4)
    80005224:	ffffc097          	auipc	ra,0xffffc
    80005228:	700080e7          	jalr	1792(ra) # 80001924 <copyout>
    8000522c:	01650763          	beq	a0,s6,8000523a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005230:	2985                	addiw	s3,s3,1
    80005232:	0905                	addi	s2,s2,1
    80005234:	fd3a91e3          	bne	s5,s3,800051f6 <piperead+0x70>
    80005238:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000523a:	21c48513          	addi	a0,s1,540
    8000523e:	ffffd097          	auipc	ra,0xffffd
    80005242:	2fa080e7          	jalr	762(ra) # 80002538 <wakeup>
  release(&pi->lock);
    80005246:	8526                	mv	a0,s1
    80005248:	ffffc097          	auipc	ra,0xffffc
    8000524c:	c44080e7          	jalr	-956(ra) # 80000e8c <release>
  return i;
}
    80005250:	854e                	mv	a0,s3
    80005252:	60a6                	ld	ra,72(sp)
    80005254:	6406                	ld	s0,64(sp)
    80005256:	74e2                	ld	s1,56(sp)
    80005258:	7942                	ld	s2,48(sp)
    8000525a:	79a2                	ld	s3,40(sp)
    8000525c:	7a02                	ld	s4,32(sp)
    8000525e:	6ae2                	ld	s5,24(sp)
    80005260:	6b42                	ld	s6,16(sp)
    80005262:	6161                	addi	sp,sp,80
    80005264:	8082                	ret
      release(&pi->lock);
    80005266:	8526                	mv	a0,s1
    80005268:	ffffc097          	auipc	ra,0xffffc
    8000526c:	c24080e7          	jalr	-988(ra) # 80000e8c <release>
      return -1;
    80005270:	59fd                	li	s3,-1
    80005272:	bff9                	j	80005250 <piperead+0xca>

0000000080005274 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005274:	1141                	addi	sp,sp,-16
    80005276:	e422                	sd	s0,8(sp)
    80005278:	0800                	addi	s0,sp,16
    8000527a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000527c:	8905                	andi	a0,a0,1
    8000527e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005280:	8b89                	andi	a5,a5,2
    80005282:	c399                	beqz	a5,80005288 <flags2perm+0x14>
      perm |= PTE_W;
    80005284:	00456513          	ori	a0,a0,4
    return perm;
}
    80005288:	6422                	ld	s0,8(sp)
    8000528a:	0141                	addi	sp,sp,16
    8000528c:	8082                	ret

000000008000528e <exec>:

int
exec(char *path, char **argv)
{
    8000528e:	df010113          	addi	sp,sp,-528
    80005292:	20113423          	sd	ra,520(sp)
    80005296:	20813023          	sd	s0,512(sp)
    8000529a:	ffa6                	sd	s1,504(sp)
    8000529c:	fbca                	sd	s2,496(sp)
    8000529e:	f7ce                	sd	s3,488(sp)
    800052a0:	f3d2                	sd	s4,480(sp)
    800052a2:	efd6                	sd	s5,472(sp)
    800052a4:	ebda                	sd	s6,464(sp)
    800052a6:	e7de                	sd	s7,456(sp)
    800052a8:	e3e2                	sd	s8,448(sp)
    800052aa:	ff66                	sd	s9,440(sp)
    800052ac:	fb6a                	sd	s10,432(sp)
    800052ae:	f76e                	sd	s11,424(sp)
    800052b0:	0c00                	addi	s0,sp,528
    800052b2:	892a                	mv	s2,a0
    800052b4:	dea43c23          	sd	a0,-520(s0)
    800052b8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052bc:	ffffd097          	auipc	ra,0xffffd
    800052c0:	ab0080e7          	jalr	-1360(ra) # 80001d6c <myproc>
    800052c4:	84aa                	mv	s1,a0

  begin_op();
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	48e080e7          	jalr	1166(ra) # 80004754 <begin_op>

  if((ip = namei(path)) == 0){
    800052ce:	854a                	mv	a0,s2
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	284080e7          	jalr	644(ra) # 80004554 <namei>
    800052d8:	c92d                	beqz	a0,8000534a <exec+0xbc>
    800052da:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052dc:	fffff097          	auipc	ra,0xfffff
    800052e0:	ad2080e7          	jalr	-1326(ra) # 80003dae <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052e4:	04000713          	li	a4,64
    800052e8:	4681                	li	a3,0
    800052ea:	e5040613          	addi	a2,s0,-432
    800052ee:	4581                	li	a1,0
    800052f0:	8552                	mv	a0,s4
    800052f2:	fffff097          	auipc	ra,0xfffff
    800052f6:	d70080e7          	jalr	-656(ra) # 80004062 <readi>
    800052fa:	04000793          	li	a5,64
    800052fe:	00f51a63          	bne	a0,a5,80005312 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005302:	e5042703          	lw	a4,-432(s0)
    80005306:	464c47b7          	lui	a5,0x464c4
    8000530a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000530e:	04f70463          	beq	a4,a5,80005356 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005312:	8552                	mv	a0,s4
    80005314:	fffff097          	auipc	ra,0xfffff
    80005318:	cfc080e7          	jalr	-772(ra) # 80004010 <iunlockput>
    end_op();
    8000531c:	fffff097          	auipc	ra,0xfffff
    80005320:	4b2080e7          	jalr	1202(ra) # 800047ce <end_op>
  }
  return -1;
    80005324:	557d                	li	a0,-1
}
    80005326:	20813083          	ld	ra,520(sp)
    8000532a:	20013403          	ld	s0,512(sp)
    8000532e:	74fe                	ld	s1,504(sp)
    80005330:	795e                	ld	s2,496(sp)
    80005332:	79be                	ld	s3,488(sp)
    80005334:	7a1e                	ld	s4,480(sp)
    80005336:	6afe                	ld	s5,472(sp)
    80005338:	6b5e                	ld	s6,464(sp)
    8000533a:	6bbe                	ld	s7,456(sp)
    8000533c:	6c1e                	ld	s8,448(sp)
    8000533e:	7cfa                	ld	s9,440(sp)
    80005340:	7d5a                	ld	s10,432(sp)
    80005342:	7dba                	ld	s11,424(sp)
    80005344:	21010113          	addi	sp,sp,528
    80005348:	8082                	ret
    end_op();
    8000534a:	fffff097          	auipc	ra,0xfffff
    8000534e:	484080e7          	jalr	1156(ra) # 800047ce <end_op>
    return -1;
    80005352:	557d                	li	a0,-1
    80005354:	bfc9                	j	80005326 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005356:	8526                	mv	a0,s1
    80005358:	ffffd097          	auipc	ra,0xffffd
    8000535c:	ad8080e7          	jalr	-1320(ra) # 80001e30 <proc_pagetable>
    80005360:	8b2a                	mv	s6,a0
    80005362:	d945                	beqz	a0,80005312 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005364:	e7042d03          	lw	s10,-400(s0)
    80005368:	e8845783          	lhu	a5,-376(s0)
    8000536c:	10078463          	beqz	a5,80005474 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005370:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005372:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005374:	6c85                	lui	s9,0x1
    80005376:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000537a:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000537e:	6a85                	lui	s5,0x1
    80005380:	a0b5                	j	800053ec <exec+0x15e>
      panic("loadseg: address should exist");
    80005382:	00003517          	auipc	a0,0x3
    80005386:	53650513          	addi	a0,a0,1334 # 800088b8 <syscalls+0x2a8>
    8000538a:	ffffb097          	auipc	ra,0xffffb
    8000538e:	1b2080e7          	jalr	434(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    80005392:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005394:	8726                	mv	a4,s1
    80005396:	012c06bb          	addw	a3,s8,s2
    8000539a:	4581                	li	a1,0
    8000539c:	8552                	mv	a0,s4
    8000539e:	fffff097          	auipc	ra,0xfffff
    800053a2:	cc4080e7          	jalr	-828(ra) # 80004062 <readi>
    800053a6:	2501                	sext.w	a0,a0
    800053a8:	24a49863          	bne	s1,a0,800055f8 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800053ac:	012a893b          	addw	s2,s5,s2
    800053b0:	03397563          	bgeu	s2,s3,800053da <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800053b4:	02091593          	slli	a1,s2,0x20
    800053b8:	9181                	srli	a1,a1,0x20
    800053ba:	95de                	add	a1,a1,s7
    800053bc:	855a                	mv	a0,s6
    800053be:	ffffc097          	auipc	ra,0xffffc
    800053c2:	e9e080e7          	jalr	-354(ra) # 8000125c <walkaddr>
    800053c6:	862a                	mv	a2,a0
    if(pa == 0)
    800053c8:	dd4d                	beqz	a0,80005382 <exec+0xf4>
    if(sz - i < PGSIZE)
    800053ca:	412984bb          	subw	s1,s3,s2
    800053ce:	0004879b          	sext.w	a5,s1
    800053d2:	fcfcf0e3          	bgeu	s9,a5,80005392 <exec+0x104>
    800053d6:	84d6                	mv	s1,s5
    800053d8:	bf6d                	j	80005392 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053da:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053de:	2d85                	addiw	s11,s11,1
    800053e0:	038d0d1b          	addiw	s10,s10,56
    800053e4:	e8845783          	lhu	a5,-376(s0)
    800053e8:	08fdd763          	bge	s11,a5,80005476 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053ec:	2d01                	sext.w	s10,s10
    800053ee:	03800713          	li	a4,56
    800053f2:	86ea                	mv	a3,s10
    800053f4:	e1840613          	addi	a2,s0,-488
    800053f8:	4581                	li	a1,0
    800053fa:	8552                	mv	a0,s4
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	c66080e7          	jalr	-922(ra) # 80004062 <readi>
    80005404:	03800793          	li	a5,56
    80005408:	1ef51663          	bne	a0,a5,800055f4 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000540c:	e1842783          	lw	a5,-488(s0)
    80005410:	4705                	li	a4,1
    80005412:	fce796e3          	bne	a5,a4,800053de <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005416:	e4043483          	ld	s1,-448(s0)
    8000541a:	e3843783          	ld	a5,-456(s0)
    8000541e:	1ef4e863          	bltu	s1,a5,8000560e <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005422:	e2843783          	ld	a5,-472(s0)
    80005426:	94be                	add	s1,s1,a5
    80005428:	1ef4e663          	bltu	s1,a5,80005614 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000542c:	df043703          	ld	a4,-528(s0)
    80005430:	8ff9                	and	a5,a5,a4
    80005432:	1e079463          	bnez	a5,8000561a <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005436:	e1c42503          	lw	a0,-484(s0)
    8000543a:	00000097          	auipc	ra,0x0
    8000543e:	e3a080e7          	jalr	-454(ra) # 80005274 <flags2perm>
    80005442:	86aa                	mv	a3,a0
    80005444:	8626                	mv	a2,s1
    80005446:	85ca                	mv	a1,s2
    80005448:	855a                	mv	a0,s6
    8000544a:	ffffc097          	auipc	ra,0xffffc
    8000544e:	1c6080e7          	jalr	454(ra) # 80001610 <uvmalloc>
    80005452:	e0a43423          	sd	a0,-504(s0)
    80005456:	1c050563          	beqz	a0,80005620 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000545a:	e2843b83          	ld	s7,-472(s0)
    8000545e:	e2042c03          	lw	s8,-480(s0)
    80005462:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005466:	00098463          	beqz	s3,8000546e <exec+0x1e0>
    8000546a:	4901                	li	s2,0
    8000546c:	b7a1                	j	800053b4 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000546e:	e0843903          	ld	s2,-504(s0)
    80005472:	b7b5                	j	800053de <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005474:	4901                	li	s2,0
  iunlockput(ip);
    80005476:	8552                	mv	a0,s4
    80005478:	fffff097          	auipc	ra,0xfffff
    8000547c:	b98080e7          	jalr	-1128(ra) # 80004010 <iunlockput>
  end_op();
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	34e080e7          	jalr	846(ra) # 800047ce <end_op>
  p = myproc();
    80005488:	ffffd097          	auipc	ra,0xffffd
    8000548c:	8e4080e7          	jalr	-1820(ra) # 80001d6c <myproc>
    80005490:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005492:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    80005496:	6985                	lui	s3,0x1
    80005498:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    8000549a:	99ca                	add	s3,s3,s2
    8000549c:	77fd                	lui	a5,0xfffff
    8000549e:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054a2:	4691                	li	a3,4
    800054a4:	6609                	lui	a2,0x2
    800054a6:	964e                	add	a2,a2,s3
    800054a8:	85ce                	mv	a1,s3
    800054aa:	855a                	mv	a0,s6
    800054ac:	ffffc097          	auipc	ra,0xffffc
    800054b0:	164080e7          	jalr	356(ra) # 80001610 <uvmalloc>
    800054b4:	892a                	mv	s2,a0
    800054b6:	e0a43423          	sd	a0,-504(s0)
    800054ba:	e509                	bnez	a0,800054c4 <exec+0x236>
  if(pagetable)
    800054bc:	e1343423          	sd	s3,-504(s0)
    800054c0:	4a01                	li	s4,0
    800054c2:	aa1d                	j	800055f8 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054c4:	75f9                	lui	a1,0xffffe
    800054c6:	95aa                	add	a1,a1,a0
    800054c8:	855a                	mv	a0,s6
    800054ca:	ffffc097          	auipc	ra,0xffffc
    800054ce:	428080e7          	jalr	1064(ra) # 800018f2 <uvmclear>
  stackbase = sp - PGSIZE;
    800054d2:	7bfd                	lui	s7,0xfffff
    800054d4:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800054d6:	e0043783          	ld	a5,-512(s0)
    800054da:	6388                	ld	a0,0(a5)
    800054dc:	c52d                	beqz	a0,80005546 <exec+0x2b8>
    800054de:	e9040993          	addi	s3,s0,-368
    800054e2:	f9040c13          	addi	s8,s0,-112
    800054e6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	b66080e7          	jalr	-1178(ra) # 8000104e <strlen>
    800054f0:	0015079b          	addiw	a5,a0,1
    800054f4:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800054f8:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800054fc:	13796563          	bltu	s2,s7,80005626 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005500:	e0043d03          	ld	s10,-512(s0)
    80005504:	000d3a03          	ld	s4,0(s10)
    80005508:	8552                	mv	a0,s4
    8000550a:	ffffc097          	auipc	ra,0xffffc
    8000550e:	b44080e7          	jalr	-1212(ra) # 8000104e <strlen>
    80005512:	0015069b          	addiw	a3,a0,1
    80005516:	8652                	mv	a2,s4
    80005518:	85ca                	mv	a1,s2
    8000551a:	855a                	mv	a0,s6
    8000551c:	ffffc097          	auipc	ra,0xffffc
    80005520:	408080e7          	jalr	1032(ra) # 80001924 <copyout>
    80005524:	10054363          	bltz	a0,8000562a <exec+0x39c>
    ustack[argc] = sp;
    80005528:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000552c:	0485                	addi	s1,s1,1
    8000552e:	008d0793          	addi	a5,s10,8
    80005532:	e0f43023          	sd	a5,-512(s0)
    80005536:	008d3503          	ld	a0,8(s10)
    8000553a:	c909                	beqz	a0,8000554c <exec+0x2be>
    if(argc >= MAXARG)
    8000553c:	09a1                	addi	s3,s3,8
    8000553e:	fb8995e3          	bne	s3,s8,800054e8 <exec+0x25a>
  ip = 0;
    80005542:	4a01                	li	s4,0
    80005544:	a855                	j	800055f8 <exec+0x36a>
  sp = sz;
    80005546:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000554a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000554c:	00349793          	slli	a5,s1,0x3
    80005550:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbd020>
    80005554:	97a2                	add	a5,a5,s0
    80005556:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000555a:	00148693          	addi	a3,s1,1
    8000555e:	068e                	slli	a3,a3,0x3
    80005560:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005564:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005568:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000556c:	f57968e3          	bltu	s2,s7,800054bc <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005570:	e9040613          	addi	a2,s0,-368
    80005574:	85ca                	mv	a1,s2
    80005576:	855a                	mv	a0,s6
    80005578:	ffffc097          	auipc	ra,0xffffc
    8000557c:	3ac080e7          	jalr	940(ra) # 80001924 <copyout>
    80005580:	0a054763          	bltz	a0,8000562e <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005584:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005588:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000558c:	df843783          	ld	a5,-520(s0)
    80005590:	0007c703          	lbu	a4,0(a5)
    80005594:	cf11                	beqz	a4,800055b0 <exec+0x322>
    80005596:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005598:	02f00693          	li	a3,47
    8000559c:	a039                	j	800055aa <exec+0x31c>
      last = s+1;
    8000559e:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055a2:	0785                	addi	a5,a5,1
    800055a4:	fff7c703          	lbu	a4,-1(a5)
    800055a8:	c701                	beqz	a4,800055b0 <exec+0x322>
    if(*s == '/')
    800055aa:	fed71ce3          	bne	a4,a3,800055a2 <exec+0x314>
    800055ae:	bfc5                	j	8000559e <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800055b0:	4641                	li	a2,16
    800055b2:	df843583          	ld	a1,-520(s0)
    800055b6:	158a8513          	addi	a0,s5,344
    800055ba:	ffffc097          	auipc	ra,0xffffc
    800055be:	a62080e7          	jalr	-1438(ra) # 8000101c <safestrcpy>
  oldpagetable = p->pagetable;
    800055c2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800055c6:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800055ca:	e0843783          	ld	a5,-504(s0)
    800055ce:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055d2:	058ab783          	ld	a5,88(s5)
    800055d6:	e6843703          	ld	a4,-408(s0)
    800055da:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055dc:	058ab783          	ld	a5,88(s5)
    800055e0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055e4:	85e6                	mv	a1,s9
    800055e6:	ffffd097          	auipc	ra,0xffffd
    800055ea:	8e6080e7          	jalr	-1818(ra) # 80001ecc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055ee:	0004851b          	sext.w	a0,s1
    800055f2:	bb15                	j	80005326 <exec+0x98>
    800055f4:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800055f8:	e0843583          	ld	a1,-504(s0)
    800055fc:	855a                	mv	a0,s6
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	8ce080e7          	jalr	-1842(ra) # 80001ecc <proc_freepagetable>
  return -1;
    80005606:	557d                	li	a0,-1
  if(ip){
    80005608:	d00a0fe3          	beqz	s4,80005326 <exec+0x98>
    8000560c:	b319                	j	80005312 <exec+0x84>
    8000560e:	e1243423          	sd	s2,-504(s0)
    80005612:	b7dd                	j	800055f8 <exec+0x36a>
    80005614:	e1243423          	sd	s2,-504(s0)
    80005618:	b7c5                	j	800055f8 <exec+0x36a>
    8000561a:	e1243423          	sd	s2,-504(s0)
    8000561e:	bfe9                	j	800055f8 <exec+0x36a>
    80005620:	e1243423          	sd	s2,-504(s0)
    80005624:	bfd1                	j	800055f8 <exec+0x36a>
  ip = 0;
    80005626:	4a01                	li	s4,0
    80005628:	bfc1                	j	800055f8 <exec+0x36a>
    8000562a:	4a01                	li	s4,0
  if(pagetable)
    8000562c:	b7f1                	j	800055f8 <exec+0x36a>
  sz = sz1;
    8000562e:	e0843983          	ld	s3,-504(s0)
    80005632:	b569                	j	800054bc <exec+0x22e>

0000000080005634 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005634:	7179                	addi	sp,sp,-48
    80005636:	f406                	sd	ra,40(sp)
    80005638:	f022                	sd	s0,32(sp)
    8000563a:	ec26                	sd	s1,24(sp)
    8000563c:	e84a                	sd	s2,16(sp)
    8000563e:	1800                	addi	s0,sp,48
    80005640:	892e                	mv	s2,a1
    80005642:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005644:	fdc40593          	addi	a1,s0,-36
    80005648:	ffffe097          	auipc	ra,0xffffe
    8000564c:	aaa080e7          	jalr	-1366(ra) # 800030f2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005650:	fdc42703          	lw	a4,-36(s0)
    80005654:	47bd                	li	a5,15
    80005656:	02e7eb63          	bltu	a5,a4,8000568c <argfd+0x58>
    8000565a:	ffffc097          	auipc	ra,0xffffc
    8000565e:	712080e7          	jalr	1810(ra) # 80001d6c <myproc>
    80005662:	fdc42703          	lw	a4,-36(s0)
    80005666:	01a70793          	addi	a5,a4,26
    8000566a:	078e                	slli	a5,a5,0x3
    8000566c:	953e                	add	a0,a0,a5
    8000566e:	611c                	ld	a5,0(a0)
    80005670:	c385                	beqz	a5,80005690 <argfd+0x5c>
    return -1;
  if(pfd)
    80005672:	00090463          	beqz	s2,8000567a <argfd+0x46>
    *pfd = fd;
    80005676:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000567a:	4501                	li	a0,0
  if(pf)
    8000567c:	c091                	beqz	s1,80005680 <argfd+0x4c>
    *pf = f;
    8000567e:	e09c                	sd	a5,0(s1)
}
    80005680:	70a2                	ld	ra,40(sp)
    80005682:	7402                	ld	s0,32(sp)
    80005684:	64e2                	ld	s1,24(sp)
    80005686:	6942                	ld	s2,16(sp)
    80005688:	6145                	addi	sp,sp,48
    8000568a:	8082                	ret
    return -1;
    8000568c:	557d                	li	a0,-1
    8000568e:	bfcd                	j	80005680 <argfd+0x4c>
    80005690:	557d                	li	a0,-1
    80005692:	b7fd                	j	80005680 <argfd+0x4c>

0000000080005694 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005694:	1101                	addi	sp,sp,-32
    80005696:	ec06                	sd	ra,24(sp)
    80005698:	e822                	sd	s0,16(sp)
    8000569a:	e426                	sd	s1,8(sp)
    8000569c:	1000                	addi	s0,sp,32
    8000569e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056a0:	ffffc097          	auipc	ra,0xffffc
    800056a4:	6cc080e7          	jalr	1740(ra) # 80001d6c <myproc>
    800056a8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056aa:	0d050793          	addi	a5,a0,208
    800056ae:	4501                	li	a0,0
    800056b0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056b2:	6398                	ld	a4,0(a5)
    800056b4:	cb19                	beqz	a4,800056ca <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056b6:	2505                	addiw	a0,a0,1
    800056b8:	07a1                	addi	a5,a5,8
    800056ba:	fed51ce3          	bne	a0,a3,800056b2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056be:	557d                	li	a0,-1
}
    800056c0:	60e2                	ld	ra,24(sp)
    800056c2:	6442                	ld	s0,16(sp)
    800056c4:	64a2                	ld	s1,8(sp)
    800056c6:	6105                	addi	sp,sp,32
    800056c8:	8082                	ret
      p->ofile[fd] = f;
    800056ca:	01a50793          	addi	a5,a0,26
    800056ce:	078e                	slli	a5,a5,0x3
    800056d0:	963e                	add	a2,a2,a5
    800056d2:	e204                	sd	s1,0(a2)
      return fd;
    800056d4:	b7f5                	j	800056c0 <fdalloc+0x2c>

00000000800056d6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056d6:	715d                	addi	sp,sp,-80
    800056d8:	e486                	sd	ra,72(sp)
    800056da:	e0a2                	sd	s0,64(sp)
    800056dc:	fc26                	sd	s1,56(sp)
    800056de:	f84a                	sd	s2,48(sp)
    800056e0:	f44e                	sd	s3,40(sp)
    800056e2:	f052                	sd	s4,32(sp)
    800056e4:	ec56                	sd	s5,24(sp)
    800056e6:	e85a                	sd	s6,16(sp)
    800056e8:	0880                	addi	s0,sp,80
    800056ea:	8b2e                	mv	s6,a1
    800056ec:	89b2                	mv	s3,a2
    800056ee:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800056f0:	fb040593          	addi	a1,s0,-80
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	e7e080e7          	jalr	-386(ra) # 80004572 <nameiparent>
    800056fc:	84aa                	mv	s1,a0
    800056fe:	14050b63          	beqz	a0,80005854 <create+0x17e>
    return 0;

  ilock(dp);
    80005702:	ffffe097          	auipc	ra,0xffffe
    80005706:	6ac080e7          	jalr	1708(ra) # 80003dae <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000570a:	4601                	li	a2,0
    8000570c:	fb040593          	addi	a1,s0,-80
    80005710:	8526                	mv	a0,s1
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	b80080e7          	jalr	-1152(ra) # 80004292 <dirlookup>
    8000571a:	8aaa                	mv	s5,a0
    8000571c:	c921                	beqz	a0,8000576c <create+0x96>
    iunlockput(dp);
    8000571e:	8526                	mv	a0,s1
    80005720:	fffff097          	auipc	ra,0xfffff
    80005724:	8f0080e7          	jalr	-1808(ra) # 80004010 <iunlockput>
    ilock(ip);
    80005728:	8556                	mv	a0,s5
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	684080e7          	jalr	1668(ra) # 80003dae <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005732:	4789                	li	a5,2
    80005734:	02fb1563          	bne	s6,a5,8000575e <create+0x88>
    80005738:	044ad783          	lhu	a5,68(s5)
    8000573c:	37f9                	addiw	a5,a5,-2
    8000573e:	17c2                	slli	a5,a5,0x30
    80005740:	93c1                	srli	a5,a5,0x30
    80005742:	4705                	li	a4,1
    80005744:	00f76d63          	bltu	a4,a5,8000575e <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005748:	8556                	mv	a0,s5
    8000574a:	60a6                	ld	ra,72(sp)
    8000574c:	6406                	ld	s0,64(sp)
    8000574e:	74e2                	ld	s1,56(sp)
    80005750:	7942                	ld	s2,48(sp)
    80005752:	79a2                	ld	s3,40(sp)
    80005754:	7a02                	ld	s4,32(sp)
    80005756:	6ae2                	ld	s5,24(sp)
    80005758:	6b42                	ld	s6,16(sp)
    8000575a:	6161                	addi	sp,sp,80
    8000575c:	8082                	ret
    iunlockput(ip);
    8000575e:	8556                	mv	a0,s5
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	8b0080e7          	jalr	-1872(ra) # 80004010 <iunlockput>
    return 0;
    80005768:	4a81                	li	s5,0
    8000576a:	bff9                	j	80005748 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000576c:	85da                	mv	a1,s6
    8000576e:	4088                	lw	a0,0(s1)
    80005770:	ffffe097          	auipc	ra,0xffffe
    80005774:	4a6080e7          	jalr	1190(ra) # 80003c16 <ialloc>
    80005778:	8a2a                	mv	s4,a0
    8000577a:	c529                	beqz	a0,800057c4 <create+0xee>
  ilock(ip);
    8000577c:	ffffe097          	auipc	ra,0xffffe
    80005780:	632080e7          	jalr	1586(ra) # 80003dae <ilock>
  ip->major = major;
    80005784:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005788:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000578c:	4905                	li	s2,1
    8000578e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005792:	8552                	mv	a0,s4
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	54e080e7          	jalr	1358(ra) # 80003ce2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000579c:	032b0b63          	beq	s6,s2,800057d2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800057a0:	004a2603          	lw	a2,4(s4)
    800057a4:	fb040593          	addi	a1,s0,-80
    800057a8:	8526                	mv	a0,s1
    800057aa:	fffff097          	auipc	ra,0xfffff
    800057ae:	cf8080e7          	jalr	-776(ra) # 800044a2 <dirlink>
    800057b2:	06054f63          	bltz	a0,80005830 <create+0x15a>
  iunlockput(dp);
    800057b6:	8526                	mv	a0,s1
    800057b8:	fffff097          	auipc	ra,0xfffff
    800057bc:	858080e7          	jalr	-1960(ra) # 80004010 <iunlockput>
  return ip;
    800057c0:	8ad2                	mv	s5,s4
    800057c2:	b759                	j	80005748 <create+0x72>
    iunlockput(dp);
    800057c4:	8526                	mv	a0,s1
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	84a080e7          	jalr	-1974(ra) # 80004010 <iunlockput>
    return 0;
    800057ce:	8ad2                	mv	s5,s4
    800057d0:	bfa5                	j	80005748 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057d2:	004a2603          	lw	a2,4(s4)
    800057d6:	00003597          	auipc	a1,0x3
    800057da:	10258593          	addi	a1,a1,258 # 800088d8 <syscalls+0x2c8>
    800057de:	8552                	mv	a0,s4
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	cc2080e7          	jalr	-830(ra) # 800044a2 <dirlink>
    800057e8:	04054463          	bltz	a0,80005830 <create+0x15a>
    800057ec:	40d0                	lw	a2,4(s1)
    800057ee:	00003597          	auipc	a1,0x3
    800057f2:	0f258593          	addi	a1,a1,242 # 800088e0 <syscalls+0x2d0>
    800057f6:	8552                	mv	a0,s4
    800057f8:	fffff097          	auipc	ra,0xfffff
    800057fc:	caa080e7          	jalr	-854(ra) # 800044a2 <dirlink>
    80005800:	02054863          	bltz	a0,80005830 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005804:	004a2603          	lw	a2,4(s4)
    80005808:	fb040593          	addi	a1,s0,-80
    8000580c:	8526                	mv	a0,s1
    8000580e:	fffff097          	auipc	ra,0xfffff
    80005812:	c94080e7          	jalr	-876(ra) # 800044a2 <dirlink>
    80005816:	00054d63          	bltz	a0,80005830 <create+0x15a>
    dp->nlink++;  // for ".."
    8000581a:	04a4d783          	lhu	a5,74(s1)
    8000581e:	2785                	addiw	a5,a5,1
    80005820:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005824:	8526                	mv	a0,s1
    80005826:	ffffe097          	auipc	ra,0xffffe
    8000582a:	4bc080e7          	jalr	1212(ra) # 80003ce2 <iupdate>
    8000582e:	b761                	j	800057b6 <create+0xe0>
  ip->nlink = 0;
    80005830:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005834:	8552                	mv	a0,s4
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	4ac080e7          	jalr	1196(ra) # 80003ce2 <iupdate>
  iunlockput(ip);
    8000583e:	8552                	mv	a0,s4
    80005840:	ffffe097          	auipc	ra,0xffffe
    80005844:	7d0080e7          	jalr	2000(ra) # 80004010 <iunlockput>
  iunlockput(dp);
    80005848:	8526                	mv	a0,s1
    8000584a:	ffffe097          	auipc	ra,0xffffe
    8000584e:	7c6080e7          	jalr	1990(ra) # 80004010 <iunlockput>
  return 0;
    80005852:	bddd                	j	80005748 <create+0x72>
    return 0;
    80005854:	8aaa                	mv	s5,a0
    80005856:	bdcd                	j	80005748 <create+0x72>

0000000080005858 <sys_dup>:
{
    80005858:	7179                	addi	sp,sp,-48
    8000585a:	f406                	sd	ra,40(sp)
    8000585c:	f022                	sd	s0,32(sp)
    8000585e:	ec26                	sd	s1,24(sp)
    80005860:	e84a                	sd	s2,16(sp)
    80005862:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005864:	fd840613          	addi	a2,s0,-40
    80005868:	4581                	li	a1,0
    8000586a:	4501                	li	a0,0
    8000586c:	00000097          	auipc	ra,0x0
    80005870:	dc8080e7          	jalr	-568(ra) # 80005634 <argfd>
    return -1;
    80005874:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005876:	02054363          	bltz	a0,8000589c <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000587a:	fd843903          	ld	s2,-40(s0)
    8000587e:	854a                	mv	a0,s2
    80005880:	00000097          	auipc	ra,0x0
    80005884:	e14080e7          	jalr	-492(ra) # 80005694 <fdalloc>
    80005888:	84aa                	mv	s1,a0
    return -1;
    8000588a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000588c:	00054863          	bltz	a0,8000589c <sys_dup+0x44>
  filedup(f);
    80005890:	854a                	mv	a0,s2
    80005892:	fffff097          	auipc	ra,0xfffff
    80005896:	334080e7          	jalr	820(ra) # 80004bc6 <filedup>
  return fd;
    8000589a:	87a6                	mv	a5,s1
}
    8000589c:	853e                	mv	a0,a5
    8000589e:	70a2                	ld	ra,40(sp)
    800058a0:	7402                	ld	s0,32(sp)
    800058a2:	64e2                	ld	s1,24(sp)
    800058a4:	6942                	ld	s2,16(sp)
    800058a6:	6145                	addi	sp,sp,48
    800058a8:	8082                	ret

00000000800058aa <sys_read>:
{
    800058aa:	7179                	addi	sp,sp,-48
    800058ac:	f406                	sd	ra,40(sp)
    800058ae:	f022                	sd	s0,32(sp)
    800058b0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058b2:	fd840593          	addi	a1,s0,-40
    800058b6:	4505                	li	a0,1
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	85a080e7          	jalr	-1958(ra) # 80003112 <argaddr>
  argint(2, &n);
    800058c0:	fe440593          	addi	a1,s0,-28
    800058c4:	4509                	li	a0,2
    800058c6:	ffffe097          	auipc	ra,0xffffe
    800058ca:	82c080e7          	jalr	-2004(ra) # 800030f2 <argint>
  if(argfd(0, 0, &f) < 0)
    800058ce:	fe840613          	addi	a2,s0,-24
    800058d2:	4581                	li	a1,0
    800058d4:	4501                	li	a0,0
    800058d6:	00000097          	auipc	ra,0x0
    800058da:	d5e080e7          	jalr	-674(ra) # 80005634 <argfd>
    800058de:	87aa                	mv	a5,a0
    return -1;
    800058e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058e2:	0007cc63          	bltz	a5,800058fa <sys_read+0x50>
  return fileread(f, p, n);
    800058e6:	fe442603          	lw	a2,-28(s0)
    800058ea:	fd843583          	ld	a1,-40(s0)
    800058ee:	fe843503          	ld	a0,-24(s0)
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	460080e7          	jalr	1120(ra) # 80004d52 <fileread>
}
    800058fa:	70a2                	ld	ra,40(sp)
    800058fc:	7402                	ld	s0,32(sp)
    800058fe:	6145                	addi	sp,sp,48
    80005900:	8082                	ret

0000000080005902 <sys_write>:
{
    80005902:	7179                	addi	sp,sp,-48
    80005904:	f406                	sd	ra,40(sp)
    80005906:	f022                	sd	s0,32(sp)
    80005908:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000590a:	fd840593          	addi	a1,s0,-40
    8000590e:	4505                	li	a0,1
    80005910:	ffffe097          	auipc	ra,0xffffe
    80005914:	802080e7          	jalr	-2046(ra) # 80003112 <argaddr>
  argint(2, &n);
    80005918:	fe440593          	addi	a1,s0,-28
    8000591c:	4509                	li	a0,2
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	7d4080e7          	jalr	2004(ra) # 800030f2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005926:	fe840613          	addi	a2,s0,-24
    8000592a:	4581                	li	a1,0
    8000592c:	4501                	li	a0,0
    8000592e:	00000097          	auipc	ra,0x0
    80005932:	d06080e7          	jalr	-762(ra) # 80005634 <argfd>
    80005936:	87aa                	mv	a5,a0
    return -1;
    80005938:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000593a:	0007cc63          	bltz	a5,80005952 <sys_write+0x50>
  return filewrite(f, p, n);
    8000593e:	fe442603          	lw	a2,-28(s0)
    80005942:	fd843583          	ld	a1,-40(s0)
    80005946:	fe843503          	ld	a0,-24(s0)
    8000594a:	fffff097          	auipc	ra,0xfffff
    8000594e:	4ca080e7          	jalr	1226(ra) # 80004e14 <filewrite>
}
    80005952:	70a2                	ld	ra,40(sp)
    80005954:	7402                	ld	s0,32(sp)
    80005956:	6145                	addi	sp,sp,48
    80005958:	8082                	ret

000000008000595a <sys_close>:
{
    8000595a:	1101                	addi	sp,sp,-32
    8000595c:	ec06                	sd	ra,24(sp)
    8000595e:	e822                	sd	s0,16(sp)
    80005960:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005962:	fe040613          	addi	a2,s0,-32
    80005966:	fec40593          	addi	a1,s0,-20
    8000596a:	4501                	li	a0,0
    8000596c:	00000097          	auipc	ra,0x0
    80005970:	cc8080e7          	jalr	-824(ra) # 80005634 <argfd>
    return -1;
    80005974:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005976:	02054463          	bltz	a0,8000599e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000597a:	ffffc097          	auipc	ra,0xffffc
    8000597e:	3f2080e7          	jalr	1010(ra) # 80001d6c <myproc>
    80005982:	fec42783          	lw	a5,-20(s0)
    80005986:	07e9                	addi	a5,a5,26
    80005988:	078e                	slli	a5,a5,0x3
    8000598a:	953e                	add	a0,a0,a5
    8000598c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005990:	fe043503          	ld	a0,-32(s0)
    80005994:	fffff097          	auipc	ra,0xfffff
    80005998:	284080e7          	jalr	644(ra) # 80004c18 <fileclose>
  return 0;
    8000599c:	4781                	li	a5,0
}
    8000599e:	853e                	mv	a0,a5
    800059a0:	60e2                	ld	ra,24(sp)
    800059a2:	6442                	ld	s0,16(sp)
    800059a4:	6105                	addi	sp,sp,32
    800059a6:	8082                	ret

00000000800059a8 <sys_fstat>:
{
    800059a8:	1101                	addi	sp,sp,-32
    800059aa:	ec06                	sd	ra,24(sp)
    800059ac:	e822                	sd	s0,16(sp)
    800059ae:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059b0:	fe040593          	addi	a1,s0,-32
    800059b4:	4505                	li	a0,1
    800059b6:	ffffd097          	auipc	ra,0xffffd
    800059ba:	75c080e7          	jalr	1884(ra) # 80003112 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059be:	fe840613          	addi	a2,s0,-24
    800059c2:	4581                	li	a1,0
    800059c4:	4501                	li	a0,0
    800059c6:	00000097          	auipc	ra,0x0
    800059ca:	c6e080e7          	jalr	-914(ra) # 80005634 <argfd>
    800059ce:	87aa                	mv	a5,a0
    return -1;
    800059d0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059d2:	0007ca63          	bltz	a5,800059e6 <sys_fstat+0x3e>
  return filestat(f, st);
    800059d6:	fe043583          	ld	a1,-32(s0)
    800059da:	fe843503          	ld	a0,-24(s0)
    800059de:	fffff097          	auipc	ra,0xfffff
    800059e2:	302080e7          	jalr	770(ra) # 80004ce0 <filestat>
}
    800059e6:	60e2                	ld	ra,24(sp)
    800059e8:	6442                	ld	s0,16(sp)
    800059ea:	6105                	addi	sp,sp,32
    800059ec:	8082                	ret

00000000800059ee <sys_link>:
{
    800059ee:	7169                	addi	sp,sp,-304
    800059f0:	f606                	sd	ra,296(sp)
    800059f2:	f222                	sd	s0,288(sp)
    800059f4:	ee26                	sd	s1,280(sp)
    800059f6:	ea4a                	sd	s2,272(sp)
    800059f8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800059fa:	08000613          	li	a2,128
    800059fe:	ed040593          	addi	a1,s0,-304
    80005a02:	4501                	li	a0,0
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	72e080e7          	jalr	1838(ra) # 80003132 <argstr>
    return -1;
    80005a0c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a0e:	10054e63          	bltz	a0,80005b2a <sys_link+0x13c>
    80005a12:	08000613          	li	a2,128
    80005a16:	f5040593          	addi	a1,s0,-176
    80005a1a:	4505                	li	a0,1
    80005a1c:	ffffd097          	auipc	ra,0xffffd
    80005a20:	716080e7          	jalr	1814(ra) # 80003132 <argstr>
    return -1;
    80005a24:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a26:	10054263          	bltz	a0,80005b2a <sys_link+0x13c>
  begin_op();
    80005a2a:	fffff097          	auipc	ra,0xfffff
    80005a2e:	d2a080e7          	jalr	-726(ra) # 80004754 <begin_op>
  if((ip = namei(old)) == 0){
    80005a32:	ed040513          	addi	a0,s0,-304
    80005a36:	fffff097          	auipc	ra,0xfffff
    80005a3a:	b1e080e7          	jalr	-1250(ra) # 80004554 <namei>
    80005a3e:	84aa                	mv	s1,a0
    80005a40:	c551                	beqz	a0,80005acc <sys_link+0xde>
  ilock(ip);
    80005a42:	ffffe097          	auipc	ra,0xffffe
    80005a46:	36c080e7          	jalr	876(ra) # 80003dae <ilock>
  if(ip->type == T_DIR){
    80005a4a:	04449703          	lh	a4,68(s1)
    80005a4e:	4785                	li	a5,1
    80005a50:	08f70463          	beq	a4,a5,80005ad8 <sys_link+0xea>
  ip->nlink++;
    80005a54:	04a4d783          	lhu	a5,74(s1)
    80005a58:	2785                	addiw	a5,a5,1
    80005a5a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a5e:	8526                	mv	a0,s1
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	282080e7          	jalr	642(ra) # 80003ce2 <iupdate>
  iunlock(ip);
    80005a68:	8526                	mv	a0,s1
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	406080e7          	jalr	1030(ra) # 80003e70 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a72:	fd040593          	addi	a1,s0,-48
    80005a76:	f5040513          	addi	a0,s0,-176
    80005a7a:	fffff097          	auipc	ra,0xfffff
    80005a7e:	af8080e7          	jalr	-1288(ra) # 80004572 <nameiparent>
    80005a82:	892a                	mv	s2,a0
    80005a84:	c935                	beqz	a0,80005af8 <sys_link+0x10a>
  ilock(dp);
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	328080e7          	jalr	808(ra) # 80003dae <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a8e:	00092703          	lw	a4,0(s2)
    80005a92:	409c                	lw	a5,0(s1)
    80005a94:	04f71d63          	bne	a4,a5,80005aee <sys_link+0x100>
    80005a98:	40d0                	lw	a2,4(s1)
    80005a9a:	fd040593          	addi	a1,s0,-48
    80005a9e:	854a                	mv	a0,s2
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	a02080e7          	jalr	-1534(ra) # 800044a2 <dirlink>
    80005aa8:	04054363          	bltz	a0,80005aee <sys_link+0x100>
  iunlockput(dp);
    80005aac:	854a                	mv	a0,s2
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	562080e7          	jalr	1378(ra) # 80004010 <iunlockput>
  iput(ip);
    80005ab6:	8526                	mv	a0,s1
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	4b0080e7          	jalr	1200(ra) # 80003f68 <iput>
  end_op();
    80005ac0:	fffff097          	auipc	ra,0xfffff
    80005ac4:	d0e080e7          	jalr	-754(ra) # 800047ce <end_op>
  return 0;
    80005ac8:	4781                	li	a5,0
    80005aca:	a085                	j	80005b2a <sys_link+0x13c>
    end_op();
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	d02080e7          	jalr	-766(ra) # 800047ce <end_op>
    return -1;
    80005ad4:	57fd                	li	a5,-1
    80005ad6:	a891                	j	80005b2a <sys_link+0x13c>
    iunlockput(ip);
    80005ad8:	8526                	mv	a0,s1
    80005ada:	ffffe097          	auipc	ra,0xffffe
    80005ade:	536080e7          	jalr	1334(ra) # 80004010 <iunlockput>
    end_op();
    80005ae2:	fffff097          	auipc	ra,0xfffff
    80005ae6:	cec080e7          	jalr	-788(ra) # 800047ce <end_op>
    return -1;
    80005aea:	57fd                	li	a5,-1
    80005aec:	a83d                	j	80005b2a <sys_link+0x13c>
    iunlockput(dp);
    80005aee:	854a                	mv	a0,s2
    80005af0:	ffffe097          	auipc	ra,0xffffe
    80005af4:	520080e7          	jalr	1312(ra) # 80004010 <iunlockput>
  ilock(ip);
    80005af8:	8526                	mv	a0,s1
    80005afa:	ffffe097          	auipc	ra,0xffffe
    80005afe:	2b4080e7          	jalr	692(ra) # 80003dae <ilock>
  ip->nlink--;
    80005b02:	04a4d783          	lhu	a5,74(s1)
    80005b06:	37fd                	addiw	a5,a5,-1
    80005b08:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b0c:	8526                	mv	a0,s1
    80005b0e:	ffffe097          	auipc	ra,0xffffe
    80005b12:	1d4080e7          	jalr	468(ra) # 80003ce2 <iupdate>
  iunlockput(ip);
    80005b16:	8526                	mv	a0,s1
    80005b18:	ffffe097          	auipc	ra,0xffffe
    80005b1c:	4f8080e7          	jalr	1272(ra) # 80004010 <iunlockput>
  end_op();
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	cae080e7          	jalr	-850(ra) # 800047ce <end_op>
  return -1;
    80005b28:	57fd                	li	a5,-1
}
    80005b2a:	853e                	mv	a0,a5
    80005b2c:	70b2                	ld	ra,296(sp)
    80005b2e:	7412                	ld	s0,288(sp)
    80005b30:	64f2                	ld	s1,280(sp)
    80005b32:	6952                	ld	s2,272(sp)
    80005b34:	6155                	addi	sp,sp,304
    80005b36:	8082                	ret

0000000080005b38 <sys_unlink>:
{
    80005b38:	7151                	addi	sp,sp,-240
    80005b3a:	f586                	sd	ra,232(sp)
    80005b3c:	f1a2                	sd	s0,224(sp)
    80005b3e:	eda6                	sd	s1,216(sp)
    80005b40:	e9ca                	sd	s2,208(sp)
    80005b42:	e5ce                	sd	s3,200(sp)
    80005b44:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b46:	08000613          	li	a2,128
    80005b4a:	f3040593          	addi	a1,s0,-208
    80005b4e:	4501                	li	a0,0
    80005b50:	ffffd097          	auipc	ra,0xffffd
    80005b54:	5e2080e7          	jalr	1506(ra) # 80003132 <argstr>
    80005b58:	18054163          	bltz	a0,80005cda <sys_unlink+0x1a2>
  begin_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	bf8080e7          	jalr	-1032(ra) # 80004754 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b64:	fb040593          	addi	a1,s0,-80
    80005b68:	f3040513          	addi	a0,s0,-208
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	a06080e7          	jalr	-1530(ra) # 80004572 <nameiparent>
    80005b74:	84aa                	mv	s1,a0
    80005b76:	c979                	beqz	a0,80005c4c <sys_unlink+0x114>
  ilock(dp);
    80005b78:	ffffe097          	auipc	ra,0xffffe
    80005b7c:	236080e7          	jalr	566(ra) # 80003dae <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b80:	00003597          	auipc	a1,0x3
    80005b84:	d5858593          	addi	a1,a1,-680 # 800088d8 <syscalls+0x2c8>
    80005b88:	fb040513          	addi	a0,s0,-80
    80005b8c:	ffffe097          	auipc	ra,0xffffe
    80005b90:	6ec080e7          	jalr	1772(ra) # 80004278 <namecmp>
    80005b94:	14050a63          	beqz	a0,80005ce8 <sys_unlink+0x1b0>
    80005b98:	00003597          	auipc	a1,0x3
    80005b9c:	d4858593          	addi	a1,a1,-696 # 800088e0 <syscalls+0x2d0>
    80005ba0:	fb040513          	addi	a0,s0,-80
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	6d4080e7          	jalr	1748(ra) # 80004278 <namecmp>
    80005bac:	12050e63          	beqz	a0,80005ce8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bb0:	f2c40613          	addi	a2,s0,-212
    80005bb4:	fb040593          	addi	a1,s0,-80
    80005bb8:	8526                	mv	a0,s1
    80005bba:	ffffe097          	auipc	ra,0xffffe
    80005bbe:	6d8080e7          	jalr	1752(ra) # 80004292 <dirlookup>
    80005bc2:	892a                	mv	s2,a0
    80005bc4:	12050263          	beqz	a0,80005ce8 <sys_unlink+0x1b0>
  ilock(ip);
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	1e6080e7          	jalr	486(ra) # 80003dae <ilock>
  if(ip->nlink < 1)
    80005bd0:	04a91783          	lh	a5,74(s2)
    80005bd4:	08f05263          	blez	a5,80005c58 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005bd8:	04491703          	lh	a4,68(s2)
    80005bdc:	4785                	li	a5,1
    80005bde:	08f70563          	beq	a4,a5,80005c68 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005be2:	4641                	li	a2,16
    80005be4:	4581                	li	a1,0
    80005be6:	fc040513          	addi	a0,s0,-64
    80005bea:	ffffb097          	auipc	ra,0xffffb
    80005bee:	2ea080e7          	jalr	746(ra) # 80000ed4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005bf2:	4741                	li	a4,16
    80005bf4:	f2c42683          	lw	a3,-212(s0)
    80005bf8:	fc040613          	addi	a2,s0,-64
    80005bfc:	4581                	li	a1,0
    80005bfe:	8526                	mv	a0,s1
    80005c00:	ffffe097          	auipc	ra,0xffffe
    80005c04:	55a080e7          	jalr	1370(ra) # 8000415a <writei>
    80005c08:	47c1                	li	a5,16
    80005c0a:	0af51563          	bne	a0,a5,80005cb4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c0e:	04491703          	lh	a4,68(s2)
    80005c12:	4785                	li	a5,1
    80005c14:	0af70863          	beq	a4,a5,80005cc4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c18:	8526                	mv	a0,s1
    80005c1a:	ffffe097          	auipc	ra,0xffffe
    80005c1e:	3f6080e7          	jalr	1014(ra) # 80004010 <iunlockput>
  ip->nlink--;
    80005c22:	04a95783          	lhu	a5,74(s2)
    80005c26:	37fd                	addiw	a5,a5,-1
    80005c28:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c2c:	854a                	mv	a0,s2
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	0b4080e7          	jalr	180(ra) # 80003ce2 <iupdate>
  iunlockput(ip);
    80005c36:	854a                	mv	a0,s2
    80005c38:	ffffe097          	auipc	ra,0xffffe
    80005c3c:	3d8080e7          	jalr	984(ra) # 80004010 <iunlockput>
  end_op();
    80005c40:	fffff097          	auipc	ra,0xfffff
    80005c44:	b8e080e7          	jalr	-1138(ra) # 800047ce <end_op>
  return 0;
    80005c48:	4501                	li	a0,0
    80005c4a:	a84d                	j	80005cfc <sys_unlink+0x1c4>
    end_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	b82080e7          	jalr	-1150(ra) # 800047ce <end_op>
    return -1;
    80005c54:	557d                	li	a0,-1
    80005c56:	a05d                	j	80005cfc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c58:	00003517          	auipc	a0,0x3
    80005c5c:	c9050513          	addi	a0,a0,-880 # 800088e8 <syscalls+0x2d8>
    80005c60:	ffffb097          	auipc	ra,0xffffb
    80005c64:	8dc080e7          	jalr	-1828(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c68:	04c92703          	lw	a4,76(s2)
    80005c6c:	02000793          	li	a5,32
    80005c70:	f6e7f9e3          	bgeu	a5,a4,80005be2 <sys_unlink+0xaa>
    80005c74:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c78:	4741                	li	a4,16
    80005c7a:	86ce                	mv	a3,s3
    80005c7c:	f1840613          	addi	a2,s0,-232
    80005c80:	4581                	li	a1,0
    80005c82:	854a                	mv	a0,s2
    80005c84:	ffffe097          	auipc	ra,0xffffe
    80005c88:	3de080e7          	jalr	990(ra) # 80004062 <readi>
    80005c8c:	47c1                	li	a5,16
    80005c8e:	00f51b63          	bne	a0,a5,80005ca4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005c92:	f1845783          	lhu	a5,-232(s0)
    80005c96:	e7a1                	bnez	a5,80005cde <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c98:	29c1                	addiw	s3,s3,16
    80005c9a:	04c92783          	lw	a5,76(s2)
    80005c9e:	fcf9ede3          	bltu	s3,a5,80005c78 <sys_unlink+0x140>
    80005ca2:	b781                	j	80005be2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ca4:	00003517          	auipc	a0,0x3
    80005ca8:	c5c50513          	addi	a0,a0,-932 # 80008900 <syscalls+0x2f0>
    80005cac:	ffffb097          	auipc	ra,0xffffb
    80005cb0:	890080e7          	jalr	-1904(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005cb4:	00003517          	auipc	a0,0x3
    80005cb8:	c6450513          	addi	a0,a0,-924 # 80008918 <syscalls+0x308>
    80005cbc:	ffffb097          	auipc	ra,0xffffb
    80005cc0:	880080e7          	jalr	-1920(ra) # 8000053c <panic>
    dp->nlink--;
    80005cc4:	04a4d783          	lhu	a5,74(s1)
    80005cc8:	37fd                	addiw	a5,a5,-1
    80005cca:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cce:	8526                	mv	a0,s1
    80005cd0:	ffffe097          	auipc	ra,0xffffe
    80005cd4:	012080e7          	jalr	18(ra) # 80003ce2 <iupdate>
    80005cd8:	b781                	j	80005c18 <sys_unlink+0xe0>
    return -1;
    80005cda:	557d                	li	a0,-1
    80005cdc:	a005                	j	80005cfc <sys_unlink+0x1c4>
    iunlockput(ip);
    80005cde:	854a                	mv	a0,s2
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	330080e7          	jalr	816(ra) # 80004010 <iunlockput>
  iunlockput(dp);
    80005ce8:	8526                	mv	a0,s1
    80005cea:	ffffe097          	auipc	ra,0xffffe
    80005cee:	326080e7          	jalr	806(ra) # 80004010 <iunlockput>
  end_op();
    80005cf2:	fffff097          	auipc	ra,0xfffff
    80005cf6:	adc080e7          	jalr	-1316(ra) # 800047ce <end_op>
  return -1;
    80005cfa:	557d                	li	a0,-1
}
    80005cfc:	70ae                	ld	ra,232(sp)
    80005cfe:	740e                	ld	s0,224(sp)
    80005d00:	64ee                	ld	s1,216(sp)
    80005d02:	694e                	ld	s2,208(sp)
    80005d04:	69ae                	ld	s3,200(sp)
    80005d06:	616d                	addi	sp,sp,240
    80005d08:	8082                	ret

0000000080005d0a <sys_open>:

uint64
sys_open(void)
{
    80005d0a:	7131                	addi	sp,sp,-192
    80005d0c:	fd06                	sd	ra,184(sp)
    80005d0e:	f922                	sd	s0,176(sp)
    80005d10:	f526                	sd	s1,168(sp)
    80005d12:	f14a                	sd	s2,160(sp)
    80005d14:	ed4e                	sd	s3,152(sp)
    80005d16:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d18:	f4c40593          	addi	a1,s0,-180
    80005d1c:	4505                	li	a0,1
    80005d1e:	ffffd097          	auipc	ra,0xffffd
    80005d22:	3d4080e7          	jalr	980(ra) # 800030f2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d26:	08000613          	li	a2,128
    80005d2a:	f5040593          	addi	a1,s0,-176
    80005d2e:	4501                	li	a0,0
    80005d30:	ffffd097          	auipc	ra,0xffffd
    80005d34:	402080e7          	jalr	1026(ra) # 80003132 <argstr>
    80005d38:	87aa                	mv	a5,a0
    return -1;
    80005d3a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d3c:	0a07c863          	bltz	a5,80005dec <sys_open+0xe2>

  begin_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	a14080e7          	jalr	-1516(ra) # 80004754 <begin_op>

  if(omode & O_CREATE){
    80005d48:	f4c42783          	lw	a5,-180(s0)
    80005d4c:	2007f793          	andi	a5,a5,512
    80005d50:	cbdd                	beqz	a5,80005e06 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005d52:	4681                	li	a3,0
    80005d54:	4601                	li	a2,0
    80005d56:	4589                	li	a1,2
    80005d58:	f5040513          	addi	a0,s0,-176
    80005d5c:	00000097          	auipc	ra,0x0
    80005d60:	97a080e7          	jalr	-1670(ra) # 800056d6 <create>
    80005d64:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d66:	c951                	beqz	a0,80005dfa <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d68:	04449703          	lh	a4,68(s1)
    80005d6c:	478d                	li	a5,3
    80005d6e:	00f71763          	bne	a4,a5,80005d7c <sys_open+0x72>
    80005d72:	0464d703          	lhu	a4,70(s1)
    80005d76:	47a5                	li	a5,9
    80005d78:	0ce7ec63          	bltu	a5,a4,80005e50 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	de0080e7          	jalr	-544(ra) # 80004b5c <filealloc>
    80005d84:	892a                	mv	s2,a0
    80005d86:	c56d                	beqz	a0,80005e70 <sys_open+0x166>
    80005d88:	00000097          	auipc	ra,0x0
    80005d8c:	90c080e7          	jalr	-1780(ra) # 80005694 <fdalloc>
    80005d90:	89aa                	mv	s3,a0
    80005d92:	0c054a63          	bltz	a0,80005e66 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005d96:	04449703          	lh	a4,68(s1)
    80005d9a:	478d                	li	a5,3
    80005d9c:	0ef70563          	beq	a4,a5,80005e86 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005da0:	4789                	li	a5,2
    80005da2:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005da6:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005daa:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005dae:	f4c42783          	lw	a5,-180(s0)
    80005db2:	0017c713          	xori	a4,a5,1
    80005db6:	8b05                	andi	a4,a4,1
    80005db8:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dbc:	0037f713          	andi	a4,a5,3
    80005dc0:	00e03733          	snez	a4,a4
    80005dc4:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005dc8:	4007f793          	andi	a5,a5,1024
    80005dcc:	c791                	beqz	a5,80005dd8 <sys_open+0xce>
    80005dce:	04449703          	lh	a4,68(s1)
    80005dd2:	4789                	li	a5,2
    80005dd4:	0cf70063          	beq	a4,a5,80005e94 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005dd8:	8526                	mv	a0,s1
    80005dda:	ffffe097          	auipc	ra,0xffffe
    80005dde:	096080e7          	jalr	150(ra) # 80003e70 <iunlock>
  end_op();
    80005de2:	fffff097          	auipc	ra,0xfffff
    80005de6:	9ec080e7          	jalr	-1556(ra) # 800047ce <end_op>

  return fd;
    80005dea:	854e                	mv	a0,s3
}
    80005dec:	70ea                	ld	ra,184(sp)
    80005dee:	744a                	ld	s0,176(sp)
    80005df0:	74aa                	ld	s1,168(sp)
    80005df2:	790a                	ld	s2,160(sp)
    80005df4:	69ea                	ld	s3,152(sp)
    80005df6:	6129                	addi	sp,sp,192
    80005df8:	8082                	ret
      end_op();
    80005dfa:	fffff097          	auipc	ra,0xfffff
    80005dfe:	9d4080e7          	jalr	-1580(ra) # 800047ce <end_op>
      return -1;
    80005e02:	557d                	li	a0,-1
    80005e04:	b7e5                	j	80005dec <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005e06:	f5040513          	addi	a0,s0,-176
    80005e0a:	ffffe097          	auipc	ra,0xffffe
    80005e0e:	74a080e7          	jalr	1866(ra) # 80004554 <namei>
    80005e12:	84aa                	mv	s1,a0
    80005e14:	c905                	beqz	a0,80005e44 <sys_open+0x13a>
    ilock(ip);
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	f98080e7          	jalr	-104(ra) # 80003dae <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e1e:	04449703          	lh	a4,68(s1)
    80005e22:	4785                	li	a5,1
    80005e24:	f4f712e3          	bne	a4,a5,80005d68 <sys_open+0x5e>
    80005e28:	f4c42783          	lw	a5,-180(s0)
    80005e2c:	dba1                	beqz	a5,80005d7c <sys_open+0x72>
      iunlockput(ip);
    80005e2e:	8526                	mv	a0,s1
    80005e30:	ffffe097          	auipc	ra,0xffffe
    80005e34:	1e0080e7          	jalr	480(ra) # 80004010 <iunlockput>
      end_op();
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	996080e7          	jalr	-1642(ra) # 800047ce <end_op>
      return -1;
    80005e40:	557d                	li	a0,-1
    80005e42:	b76d                	j	80005dec <sys_open+0xe2>
      end_op();
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	98a080e7          	jalr	-1654(ra) # 800047ce <end_op>
      return -1;
    80005e4c:	557d                	li	a0,-1
    80005e4e:	bf79                	j	80005dec <sys_open+0xe2>
    iunlockput(ip);
    80005e50:	8526                	mv	a0,s1
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	1be080e7          	jalr	446(ra) # 80004010 <iunlockput>
    end_op();
    80005e5a:	fffff097          	auipc	ra,0xfffff
    80005e5e:	974080e7          	jalr	-1676(ra) # 800047ce <end_op>
    return -1;
    80005e62:	557d                	li	a0,-1
    80005e64:	b761                	j	80005dec <sys_open+0xe2>
      fileclose(f);
    80005e66:	854a                	mv	a0,s2
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	db0080e7          	jalr	-592(ra) # 80004c18 <fileclose>
    iunlockput(ip);
    80005e70:	8526                	mv	a0,s1
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	19e080e7          	jalr	414(ra) # 80004010 <iunlockput>
    end_op();
    80005e7a:	fffff097          	auipc	ra,0xfffff
    80005e7e:	954080e7          	jalr	-1708(ra) # 800047ce <end_op>
    return -1;
    80005e82:	557d                	li	a0,-1
    80005e84:	b7a5                	j	80005dec <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005e86:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005e8a:	04649783          	lh	a5,70(s1)
    80005e8e:	02f91223          	sh	a5,36(s2)
    80005e92:	bf21                	j	80005daa <sys_open+0xa0>
    itrunc(ip);
    80005e94:	8526                	mv	a0,s1
    80005e96:	ffffe097          	auipc	ra,0xffffe
    80005e9a:	026080e7          	jalr	38(ra) # 80003ebc <itrunc>
    80005e9e:	bf2d                	j	80005dd8 <sys_open+0xce>

0000000080005ea0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ea0:	7175                	addi	sp,sp,-144
    80005ea2:	e506                	sd	ra,136(sp)
    80005ea4:	e122                	sd	s0,128(sp)
    80005ea6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ea8:	fffff097          	auipc	ra,0xfffff
    80005eac:	8ac080e7          	jalr	-1876(ra) # 80004754 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005eb0:	08000613          	li	a2,128
    80005eb4:	f7040593          	addi	a1,s0,-144
    80005eb8:	4501                	li	a0,0
    80005eba:	ffffd097          	auipc	ra,0xffffd
    80005ebe:	278080e7          	jalr	632(ra) # 80003132 <argstr>
    80005ec2:	02054963          	bltz	a0,80005ef4 <sys_mkdir+0x54>
    80005ec6:	4681                	li	a3,0
    80005ec8:	4601                	li	a2,0
    80005eca:	4585                	li	a1,1
    80005ecc:	f7040513          	addi	a0,s0,-144
    80005ed0:	00000097          	auipc	ra,0x0
    80005ed4:	806080e7          	jalr	-2042(ra) # 800056d6 <create>
    80005ed8:	cd11                	beqz	a0,80005ef4 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005eda:	ffffe097          	auipc	ra,0xffffe
    80005ede:	136080e7          	jalr	310(ra) # 80004010 <iunlockput>
  end_op();
    80005ee2:	fffff097          	auipc	ra,0xfffff
    80005ee6:	8ec080e7          	jalr	-1812(ra) # 800047ce <end_op>
  return 0;
    80005eea:	4501                	li	a0,0
}
    80005eec:	60aa                	ld	ra,136(sp)
    80005eee:	640a                	ld	s0,128(sp)
    80005ef0:	6149                	addi	sp,sp,144
    80005ef2:	8082                	ret
    end_op();
    80005ef4:	fffff097          	auipc	ra,0xfffff
    80005ef8:	8da080e7          	jalr	-1830(ra) # 800047ce <end_op>
    return -1;
    80005efc:	557d                	li	a0,-1
    80005efe:	b7fd                	j	80005eec <sys_mkdir+0x4c>

0000000080005f00 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f00:	7135                	addi	sp,sp,-160
    80005f02:	ed06                	sd	ra,152(sp)
    80005f04:	e922                	sd	s0,144(sp)
    80005f06:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f08:	fffff097          	auipc	ra,0xfffff
    80005f0c:	84c080e7          	jalr	-1972(ra) # 80004754 <begin_op>
  argint(1, &major);
    80005f10:	f6c40593          	addi	a1,s0,-148
    80005f14:	4505                	li	a0,1
    80005f16:	ffffd097          	auipc	ra,0xffffd
    80005f1a:	1dc080e7          	jalr	476(ra) # 800030f2 <argint>
  argint(2, &minor);
    80005f1e:	f6840593          	addi	a1,s0,-152
    80005f22:	4509                	li	a0,2
    80005f24:	ffffd097          	auipc	ra,0xffffd
    80005f28:	1ce080e7          	jalr	462(ra) # 800030f2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f2c:	08000613          	li	a2,128
    80005f30:	f7040593          	addi	a1,s0,-144
    80005f34:	4501                	li	a0,0
    80005f36:	ffffd097          	auipc	ra,0xffffd
    80005f3a:	1fc080e7          	jalr	508(ra) # 80003132 <argstr>
    80005f3e:	02054b63          	bltz	a0,80005f74 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f42:	f6841683          	lh	a3,-152(s0)
    80005f46:	f6c41603          	lh	a2,-148(s0)
    80005f4a:	458d                	li	a1,3
    80005f4c:	f7040513          	addi	a0,s0,-144
    80005f50:	fffff097          	auipc	ra,0xfffff
    80005f54:	786080e7          	jalr	1926(ra) # 800056d6 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f58:	cd11                	beqz	a0,80005f74 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f5a:	ffffe097          	auipc	ra,0xffffe
    80005f5e:	0b6080e7          	jalr	182(ra) # 80004010 <iunlockput>
  end_op();
    80005f62:	fffff097          	auipc	ra,0xfffff
    80005f66:	86c080e7          	jalr	-1940(ra) # 800047ce <end_op>
  return 0;
    80005f6a:	4501                	li	a0,0
}
    80005f6c:	60ea                	ld	ra,152(sp)
    80005f6e:	644a                	ld	s0,144(sp)
    80005f70:	610d                	addi	sp,sp,160
    80005f72:	8082                	ret
    end_op();
    80005f74:	fffff097          	auipc	ra,0xfffff
    80005f78:	85a080e7          	jalr	-1958(ra) # 800047ce <end_op>
    return -1;
    80005f7c:	557d                	li	a0,-1
    80005f7e:	b7fd                	j	80005f6c <sys_mknod+0x6c>

0000000080005f80 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f80:	7135                	addi	sp,sp,-160
    80005f82:	ed06                	sd	ra,152(sp)
    80005f84:	e922                	sd	s0,144(sp)
    80005f86:	e526                	sd	s1,136(sp)
    80005f88:	e14a                	sd	s2,128(sp)
    80005f8a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f8c:	ffffc097          	auipc	ra,0xffffc
    80005f90:	de0080e7          	jalr	-544(ra) # 80001d6c <myproc>
    80005f94:	892a                	mv	s2,a0
  
  begin_op();
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	7be080e7          	jalr	1982(ra) # 80004754 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005f9e:	08000613          	li	a2,128
    80005fa2:	f6040593          	addi	a1,s0,-160
    80005fa6:	4501                	li	a0,0
    80005fa8:	ffffd097          	auipc	ra,0xffffd
    80005fac:	18a080e7          	jalr	394(ra) # 80003132 <argstr>
    80005fb0:	04054b63          	bltz	a0,80006006 <sys_chdir+0x86>
    80005fb4:	f6040513          	addi	a0,s0,-160
    80005fb8:	ffffe097          	auipc	ra,0xffffe
    80005fbc:	59c080e7          	jalr	1436(ra) # 80004554 <namei>
    80005fc0:	84aa                	mv	s1,a0
    80005fc2:	c131                	beqz	a0,80006006 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fc4:	ffffe097          	auipc	ra,0xffffe
    80005fc8:	dea080e7          	jalr	-534(ra) # 80003dae <ilock>
  if(ip->type != T_DIR){
    80005fcc:	04449703          	lh	a4,68(s1)
    80005fd0:	4785                	li	a5,1
    80005fd2:	04f71063          	bne	a4,a5,80006012 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fd6:	8526                	mv	a0,s1
    80005fd8:	ffffe097          	auipc	ra,0xffffe
    80005fdc:	e98080e7          	jalr	-360(ra) # 80003e70 <iunlock>
  iput(p->cwd);
    80005fe0:	15093503          	ld	a0,336(s2)
    80005fe4:	ffffe097          	auipc	ra,0xffffe
    80005fe8:	f84080e7          	jalr	-124(ra) # 80003f68 <iput>
  end_op();
    80005fec:	ffffe097          	auipc	ra,0xffffe
    80005ff0:	7e2080e7          	jalr	2018(ra) # 800047ce <end_op>
  p->cwd = ip;
    80005ff4:	14993823          	sd	s1,336(s2)
  return 0;
    80005ff8:	4501                	li	a0,0
}
    80005ffa:	60ea                	ld	ra,152(sp)
    80005ffc:	644a                	ld	s0,144(sp)
    80005ffe:	64aa                	ld	s1,136(sp)
    80006000:	690a                	ld	s2,128(sp)
    80006002:	610d                	addi	sp,sp,160
    80006004:	8082                	ret
    end_op();
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	7c8080e7          	jalr	1992(ra) # 800047ce <end_op>
    return -1;
    8000600e:	557d                	li	a0,-1
    80006010:	b7ed                	j	80005ffa <sys_chdir+0x7a>
    iunlockput(ip);
    80006012:	8526                	mv	a0,s1
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	ffc080e7          	jalr	-4(ra) # 80004010 <iunlockput>
    end_op();
    8000601c:	ffffe097          	auipc	ra,0xffffe
    80006020:	7b2080e7          	jalr	1970(ra) # 800047ce <end_op>
    return -1;
    80006024:	557d                	li	a0,-1
    80006026:	bfd1                	j	80005ffa <sys_chdir+0x7a>

0000000080006028 <sys_exec>:

uint64
sys_exec(void)
{
    80006028:	7121                	addi	sp,sp,-448
    8000602a:	ff06                	sd	ra,440(sp)
    8000602c:	fb22                	sd	s0,432(sp)
    8000602e:	f726                	sd	s1,424(sp)
    80006030:	f34a                	sd	s2,416(sp)
    80006032:	ef4e                	sd	s3,408(sp)
    80006034:	eb52                	sd	s4,400(sp)
    80006036:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006038:	e4840593          	addi	a1,s0,-440
    8000603c:	4505                	li	a0,1
    8000603e:	ffffd097          	auipc	ra,0xffffd
    80006042:	0d4080e7          	jalr	212(ra) # 80003112 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006046:	08000613          	li	a2,128
    8000604a:	f5040593          	addi	a1,s0,-176
    8000604e:	4501                	li	a0,0
    80006050:	ffffd097          	auipc	ra,0xffffd
    80006054:	0e2080e7          	jalr	226(ra) # 80003132 <argstr>
    80006058:	87aa                	mv	a5,a0
    return -1;
    8000605a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000605c:	0c07c263          	bltz	a5,80006120 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80006060:	10000613          	li	a2,256
    80006064:	4581                	li	a1,0
    80006066:	e5040513          	addi	a0,s0,-432
    8000606a:	ffffb097          	auipc	ra,0xffffb
    8000606e:	e6a080e7          	jalr	-406(ra) # 80000ed4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006072:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006076:	89a6                	mv	s3,s1
    80006078:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000607a:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000607e:	00391513          	slli	a0,s2,0x3
    80006082:	e4040593          	addi	a1,s0,-448
    80006086:	e4843783          	ld	a5,-440(s0)
    8000608a:	953e                	add	a0,a0,a5
    8000608c:	ffffd097          	auipc	ra,0xffffd
    80006090:	fc8080e7          	jalr	-56(ra) # 80003054 <fetchaddr>
    80006094:	02054a63          	bltz	a0,800060c8 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    80006098:	e4043783          	ld	a5,-448(s0)
    8000609c:	c3b9                	beqz	a5,800060e2 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000609e:	ffffb097          	auipc	ra,0xffffb
    800060a2:	bc0080e7          	jalr	-1088(ra) # 80000c5e <kalloc>
    800060a6:	85aa                	mv	a1,a0
    800060a8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060ac:	cd11                	beqz	a0,800060c8 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060ae:	6605                	lui	a2,0x1
    800060b0:	e4043503          	ld	a0,-448(s0)
    800060b4:	ffffd097          	auipc	ra,0xffffd
    800060b8:	ff2080e7          	jalr	-14(ra) # 800030a6 <fetchstr>
    800060bc:	00054663          	bltz	a0,800060c8 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800060c0:	0905                	addi	s2,s2,1
    800060c2:	09a1                	addi	s3,s3,8
    800060c4:	fb491de3          	bne	s2,s4,8000607e <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060c8:	f5040913          	addi	s2,s0,-176
    800060cc:	6088                	ld	a0,0(s1)
    800060ce:	c921                	beqz	a0,8000611e <sys_exec+0xf6>
    kfree(argv[i]);
    800060d0:	ffffb097          	auipc	ra,0xffffb
    800060d4:	9a2080e7          	jalr	-1630(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d8:	04a1                	addi	s1,s1,8
    800060da:	ff2499e3          	bne	s1,s2,800060cc <sys_exec+0xa4>
  return -1;
    800060de:	557d                	li	a0,-1
    800060e0:	a081                	j	80006120 <sys_exec+0xf8>
      argv[i] = 0;
    800060e2:	0009079b          	sext.w	a5,s2
    800060e6:	078e                	slli	a5,a5,0x3
    800060e8:	fd078793          	addi	a5,a5,-48
    800060ec:	97a2                	add	a5,a5,s0
    800060ee:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    800060f2:	e5040593          	addi	a1,s0,-432
    800060f6:	f5040513          	addi	a0,s0,-176
    800060fa:	fffff097          	auipc	ra,0xfffff
    800060fe:	194080e7          	jalr	404(ra) # 8000528e <exec>
    80006102:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006104:	f5040993          	addi	s3,s0,-176
    80006108:	6088                	ld	a0,0(s1)
    8000610a:	c901                	beqz	a0,8000611a <sys_exec+0xf2>
    kfree(argv[i]);
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	966080e7          	jalr	-1690(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006114:	04a1                	addi	s1,s1,8
    80006116:	ff3499e3          	bne	s1,s3,80006108 <sys_exec+0xe0>
  return ret;
    8000611a:	854a                	mv	a0,s2
    8000611c:	a011                	j	80006120 <sys_exec+0xf8>
  return -1;
    8000611e:	557d                	li	a0,-1
}
    80006120:	70fa                	ld	ra,440(sp)
    80006122:	745a                	ld	s0,432(sp)
    80006124:	74ba                	ld	s1,424(sp)
    80006126:	791a                	ld	s2,416(sp)
    80006128:	69fa                	ld	s3,408(sp)
    8000612a:	6a5a                	ld	s4,400(sp)
    8000612c:	6139                	addi	sp,sp,448
    8000612e:	8082                	ret

0000000080006130 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006130:	7139                	addi	sp,sp,-64
    80006132:	fc06                	sd	ra,56(sp)
    80006134:	f822                	sd	s0,48(sp)
    80006136:	f426                	sd	s1,40(sp)
    80006138:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000613a:	ffffc097          	auipc	ra,0xffffc
    8000613e:	c32080e7          	jalr	-974(ra) # 80001d6c <myproc>
    80006142:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006144:	fd840593          	addi	a1,s0,-40
    80006148:	4501                	li	a0,0
    8000614a:	ffffd097          	auipc	ra,0xffffd
    8000614e:	fc8080e7          	jalr	-56(ra) # 80003112 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006152:	fc840593          	addi	a1,s0,-56
    80006156:	fd040513          	addi	a0,s0,-48
    8000615a:	fffff097          	auipc	ra,0xfffff
    8000615e:	dea080e7          	jalr	-534(ra) # 80004f44 <pipealloc>
    return -1;
    80006162:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006164:	0c054463          	bltz	a0,8000622c <sys_pipe+0xfc>
  fd0 = -1;
    80006168:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000616c:	fd043503          	ld	a0,-48(s0)
    80006170:	fffff097          	auipc	ra,0xfffff
    80006174:	524080e7          	jalr	1316(ra) # 80005694 <fdalloc>
    80006178:	fca42223          	sw	a0,-60(s0)
    8000617c:	08054b63          	bltz	a0,80006212 <sys_pipe+0xe2>
    80006180:	fc843503          	ld	a0,-56(s0)
    80006184:	fffff097          	auipc	ra,0xfffff
    80006188:	510080e7          	jalr	1296(ra) # 80005694 <fdalloc>
    8000618c:	fca42023          	sw	a0,-64(s0)
    80006190:	06054863          	bltz	a0,80006200 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006194:	4691                	li	a3,4
    80006196:	fc440613          	addi	a2,s0,-60
    8000619a:	fd843583          	ld	a1,-40(s0)
    8000619e:	68a8                	ld	a0,80(s1)
    800061a0:	ffffb097          	auipc	ra,0xffffb
    800061a4:	784080e7          	jalr	1924(ra) # 80001924 <copyout>
    800061a8:	02054063          	bltz	a0,800061c8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061ac:	4691                	li	a3,4
    800061ae:	fc040613          	addi	a2,s0,-64
    800061b2:	fd843583          	ld	a1,-40(s0)
    800061b6:	0591                	addi	a1,a1,4
    800061b8:	68a8                	ld	a0,80(s1)
    800061ba:	ffffb097          	auipc	ra,0xffffb
    800061be:	76a080e7          	jalr	1898(ra) # 80001924 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061c2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061c4:	06055463          	bgez	a0,8000622c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061c8:	fc442783          	lw	a5,-60(s0)
    800061cc:	07e9                	addi	a5,a5,26
    800061ce:	078e                	slli	a5,a5,0x3
    800061d0:	97a6                	add	a5,a5,s1
    800061d2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061d6:	fc042783          	lw	a5,-64(s0)
    800061da:	07e9                	addi	a5,a5,26
    800061dc:	078e                	slli	a5,a5,0x3
    800061de:	94be                	add	s1,s1,a5
    800061e0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061e4:	fd043503          	ld	a0,-48(s0)
    800061e8:	fffff097          	auipc	ra,0xfffff
    800061ec:	a30080e7          	jalr	-1488(ra) # 80004c18 <fileclose>
    fileclose(wf);
    800061f0:	fc843503          	ld	a0,-56(s0)
    800061f4:	fffff097          	auipc	ra,0xfffff
    800061f8:	a24080e7          	jalr	-1500(ra) # 80004c18 <fileclose>
    return -1;
    800061fc:	57fd                	li	a5,-1
    800061fe:	a03d                	j	8000622c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006200:	fc442783          	lw	a5,-60(s0)
    80006204:	0007c763          	bltz	a5,80006212 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006208:	07e9                	addi	a5,a5,26
    8000620a:	078e                	slli	a5,a5,0x3
    8000620c:	97a6                	add	a5,a5,s1
    8000620e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006212:	fd043503          	ld	a0,-48(s0)
    80006216:	fffff097          	auipc	ra,0xfffff
    8000621a:	a02080e7          	jalr	-1534(ra) # 80004c18 <fileclose>
    fileclose(wf);
    8000621e:	fc843503          	ld	a0,-56(s0)
    80006222:	fffff097          	auipc	ra,0xfffff
    80006226:	9f6080e7          	jalr	-1546(ra) # 80004c18 <fileclose>
    return -1;
    8000622a:	57fd                	li	a5,-1
}
    8000622c:	853e                	mv	a0,a5
    8000622e:	70e2                	ld	ra,56(sp)
    80006230:	7442                	ld	s0,48(sp)
    80006232:	74a2                	ld	s1,40(sp)
    80006234:	6121                	addi	sp,sp,64
    80006236:	8082                	ret
	...

0000000080006240 <kernelvec>:
    80006240:	7111                	addi	sp,sp,-256
    80006242:	e006                	sd	ra,0(sp)
    80006244:	e40a                	sd	sp,8(sp)
    80006246:	e80e                	sd	gp,16(sp)
    80006248:	ec12                	sd	tp,24(sp)
    8000624a:	f016                	sd	t0,32(sp)
    8000624c:	f41a                	sd	t1,40(sp)
    8000624e:	f81e                	sd	t2,48(sp)
    80006250:	fc22                	sd	s0,56(sp)
    80006252:	e0a6                	sd	s1,64(sp)
    80006254:	e4aa                	sd	a0,72(sp)
    80006256:	e8ae                	sd	a1,80(sp)
    80006258:	ecb2                	sd	a2,88(sp)
    8000625a:	f0b6                	sd	a3,96(sp)
    8000625c:	f4ba                	sd	a4,104(sp)
    8000625e:	f8be                	sd	a5,112(sp)
    80006260:	fcc2                	sd	a6,120(sp)
    80006262:	e146                	sd	a7,128(sp)
    80006264:	e54a                	sd	s2,136(sp)
    80006266:	e94e                	sd	s3,144(sp)
    80006268:	ed52                	sd	s4,152(sp)
    8000626a:	f156                	sd	s5,160(sp)
    8000626c:	f55a                	sd	s6,168(sp)
    8000626e:	f95e                	sd	s7,176(sp)
    80006270:	fd62                	sd	s8,184(sp)
    80006272:	e1e6                	sd	s9,192(sp)
    80006274:	e5ea                	sd	s10,200(sp)
    80006276:	e9ee                	sd	s11,208(sp)
    80006278:	edf2                	sd	t3,216(sp)
    8000627a:	f1f6                	sd	t4,224(sp)
    8000627c:	f5fa                	sd	t5,232(sp)
    8000627e:	f9fe                	sd	t6,240(sp)
    80006280:	ac7fc0ef          	jal	ra,80002d46 <kerneltrap>
    80006284:	6082                	ld	ra,0(sp)
    80006286:	6122                	ld	sp,8(sp)
    80006288:	61c2                	ld	gp,16(sp)
    8000628a:	7282                	ld	t0,32(sp)
    8000628c:	7322                	ld	t1,40(sp)
    8000628e:	73c2                	ld	t2,48(sp)
    80006290:	7462                	ld	s0,56(sp)
    80006292:	6486                	ld	s1,64(sp)
    80006294:	6526                	ld	a0,72(sp)
    80006296:	65c6                	ld	a1,80(sp)
    80006298:	6666                	ld	a2,88(sp)
    8000629a:	7686                	ld	a3,96(sp)
    8000629c:	7726                	ld	a4,104(sp)
    8000629e:	77c6                	ld	a5,112(sp)
    800062a0:	7866                	ld	a6,120(sp)
    800062a2:	688a                	ld	a7,128(sp)
    800062a4:	692a                	ld	s2,136(sp)
    800062a6:	69ca                	ld	s3,144(sp)
    800062a8:	6a6a                	ld	s4,152(sp)
    800062aa:	7a8a                	ld	s5,160(sp)
    800062ac:	7b2a                	ld	s6,168(sp)
    800062ae:	7bca                	ld	s7,176(sp)
    800062b0:	7c6a                	ld	s8,184(sp)
    800062b2:	6c8e                	ld	s9,192(sp)
    800062b4:	6d2e                	ld	s10,200(sp)
    800062b6:	6dce                	ld	s11,208(sp)
    800062b8:	6e6e                	ld	t3,216(sp)
    800062ba:	7e8e                	ld	t4,224(sp)
    800062bc:	7f2e                	ld	t5,232(sp)
    800062be:	7fce                	ld	t6,240(sp)
    800062c0:	6111                	addi	sp,sp,256
    800062c2:	10200073          	sret
    800062c6:	00000013          	nop
    800062ca:	00000013          	nop
    800062ce:	0001                	nop

00000000800062d0 <timervec>:
    800062d0:	34051573          	csrrw	a0,mscratch,a0
    800062d4:	e10c                	sd	a1,0(a0)
    800062d6:	e510                	sd	a2,8(a0)
    800062d8:	e914                	sd	a3,16(a0)
    800062da:	6d0c                	ld	a1,24(a0)
    800062dc:	7110                	ld	a2,32(a0)
    800062de:	6194                	ld	a3,0(a1)
    800062e0:	96b2                	add	a3,a3,a2
    800062e2:	e194                	sd	a3,0(a1)
    800062e4:	4589                	li	a1,2
    800062e6:	14459073          	csrw	sip,a1
    800062ea:	6914                	ld	a3,16(a0)
    800062ec:	6510                	ld	a2,8(a0)
    800062ee:	610c                	ld	a1,0(a0)
    800062f0:	34051573          	csrrw	a0,mscratch,a0
    800062f4:	30200073          	mret
	...

00000000800062fa <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800062fa:	1141                	addi	sp,sp,-16
    800062fc:	e422                	sd	s0,8(sp)
    800062fe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006300:	0c0007b7          	lui	a5,0xc000
    80006304:	4705                	li	a4,1
    80006306:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006308:	c3d8                	sw	a4,4(a5)
}
    8000630a:	6422                	ld	s0,8(sp)
    8000630c:	0141                	addi	sp,sp,16
    8000630e:	8082                	ret

0000000080006310 <plicinithart>:

void
plicinithart(void)
{
    80006310:	1141                	addi	sp,sp,-16
    80006312:	e406                	sd	ra,8(sp)
    80006314:	e022                	sd	s0,0(sp)
    80006316:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006318:	ffffc097          	auipc	ra,0xffffc
    8000631c:	a28080e7          	jalr	-1496(ra) # 80001d40 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006320:	0085171b          	slliw	a4,a0,0x8
    80006324:	0c0027b7          	lui	a5,0xc002
    80006328:	97ba                	add	a5,a5,a4
    8000632a:	40200713          	li	a4,1026
    8000632e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006332:	00d5151b          	slliw	a0,a0,0xd
    80006336:	0c2017b7          	lui	a5,0xc201
    8000633a:	97aa                	add	a5,a5,a0
    8000633c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006340:	60a2                	ld	ra,8(sp)
    80006342:	6402                	ld	s0,0(sp)
    80006344:	0141                	addi	sp,sp,16
    80006346:	8082                	ret

0000000080006348 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006348:	1141                	addi	sp,sp,-16
    8000634a:	e406                	sd	ra,8(sp)
    8000634c:	e022                	sd	s0,0(sp)
    8000634e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006350:	ffffc097          	auipc	ra,0xffffc
    80006354:	9f0080e7          	jalr	-1552(ra) # 80001d40 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006358:	00d5151b          	slliw	a0,a0,0xd
    8000635c:	0c2017b7          	lui	a5,0xc201
    80006360:	97aa                	add	a5,a5,a0
  return irq;
}
    80006362:	43c8                	lw	a0,4(a5)
    80006364:	60a2                	ld	ra,8(sp)
    80006366:	6402                	ld	s0,0(sp)
    80006368:	0141                	addi	sp,sp,16
    8000636a:	8082                	ret

000000008000636c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000636c:	1101                	addi	sp,sp,-32
    8000636e:	ec06                	sd	ra,24(sp)
    80006370:	e822                	sd	s0,16(sp)
    80006372:	e426                	sd	s1,8(sp)
    80006374:	1000                	addi	s0,sp,32
    80006376:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006378:	ffffc097          	auipc	ra,0xffffc
    8000637c:	9c8080e7          	jalr	-1592(ra) # 80001d40 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006380:	00d5151b          	slliw	a0,a0,0xd
    80006384:	0c2017b7          	lui	a5,0xc201
    80006388:	97aa                	add	a5,a5,a0
    8000638a:	c3c4                	sw	s1,4(a5)
}
    8000638c:	60e2                	ld	ra,24(sp)
    8000638e:	6442                	ld	s0,16(sp)
    80006390:	64a2                	ld	s1,8(sp)
    80006392:	6105                	addi	sp,sp,32
    80006394:	8082                	ret

0000000080006396 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006396:	1141                	addi	sp,sp,-16
    80006398:	e406                	sd	ra,8(sp)
    8000639a:	e022                	sd	s0,0(sp)
    8000639c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000639e:	479d                	li	a5,7
    800063a0:	04a7cc63          	blt	a5,a0,800063f8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063a4:	0023c797          	auipc	a5,0x23c
    800063a8:	a8c78793          	addi	a5,a5,-1396 # 80241e30 <disk>
    800063ac:	97aa                	add	a5,a5,a0
    800063ae:	0187c783          	lbu	a5,24(a5)
    800063b2:	ebb9                	bnez	a5,80006408 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063b4:	00451693          	slli	a3,a0,0x4
    800063b8:	0023c797          	auipc	a5,0x23c
    800063bc:	a7878793          	addi	a5,a5,-1416 # 80241e30 <disk>
    800063c0:	6398                	ld	a4,0(a5)
    800063c2:	9736                	add	a4,a4,a3
    800063c4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800063c8:	6398                	ld	a4,0(a5)
    800063ca:	9736                	add	a4,a4,a3
    800063cc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063d0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063d4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063d8:	97aa                	add	a5,a5,a0
    800063da:	4705                	li	a4,1
    800063dc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063e0:	0023c517          	auipc	a0,0x23c
    800063e4:	a6850513          	addi	a0,a0,-1432 # 80241e48 <disk+0x18>
    800063e8:	ffffc097          	auipc	ra,0xffffc
    800063ec:	150080e7          	jalr	336(ra) # 80002538 <wakeup>
}
    800063f0:	60a2                	ld	ra,8(sp)
    800063f2:	6402                	ld	s0,0(sp)
    800063f4:	0141                	addi	sp,sp,16
    800063f6:	8082                	ret
    panic("free_desc 1");
    800063f8:	00002517          	auipc	a0,0x2
    800063fc:	53050513          	addi	a0,a0,1328 # 80008928 <syscalls+0x318>
    80006400:	ffffa097          	auipc	ra,0xffffa
    80006404:	13c080e7          	jalr	316(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006408:	00002517          	auipc	a0,0x2
    8000640c:	53050513          	addi	a0,a0,1328 # 80008938 <syscalls+0x328>
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	12c080e7          	jalr	300(ra) # 8000053c <panic>

0000000080006418 <virtio_disk_init>:
{
    80006418:	1101                	addi	sp,sp,-32
    8000641a:	ec06                	sd	ra,24(sp)
    8000641c:	e822                	sd	s0,16(sp)
    8000641e:	e426                	sd	s1,8(sp)
    80006420:	e04a                	sd	s2,0(sp)
    80006422:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006424:	00002597          	auipc	a1,0x2
    80006428:	52458593          	addi	a1,a1,1316 # 80008948 <syscalls+0x338>
    8000642c:	0023c517          	auipc	a0,0x23c
    80006430:	b2c50513          	addi	a0,a0,-1236 # 80241f58 <disk+0x128>
    80006434:	ffffb097          	auipc	ra,0xffffb
    80006438:	914080e7          	jalr	-1772(ra) # 80000d48 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000643c:	100017b7          	lui	a5,0x10001
    80006440:	4398                	lw	a4,0(a5)
    80006442:	2701                	sext.w	a4,a4
    80006444:	747277b7          	lui	a5,0x74727
    80006448:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000644c:	14f71b63          	bne	a4,a5,800065a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006450:	100017b7          	lui	a5,0x10001
    80006454:	43dc                	lw	a5,4(a5)
    80006456:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006458:	4709                	li	a4,2
    8000645a:	14e79463          	bne	a5,a4,800065a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000645e:	100017b7          	lui	a5,0x10001
    80006462:	479c                	lw	a5,8(a5)
    80006464:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006466:	12e79e63          	bne	a5,a4,800065a2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000646a:	100017b7          	lui	a5,0x10001
    8000646e:	47d8                	lw	a4,12(a5)
    80006470:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006472:	554d47b7          	lui	a5,0x554d4
    80006476:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000647a:	12f71463          	bne	a4,a5,800065a2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000647e:	100017b7          	lui	a5,0x10001
    80006482:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006486:	4705                	li	a4,1
    80006488:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000648a:	470d                	li	a4,3
    8000648c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000648e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006490:	c7ffe6b7          	lui	a3,0xc7ffe
    80006494:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc7ef>
    80006498:	8f75                	and	a4,a4,a3
    8000649a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000649c:	472d                	li	a4,11
    8000649e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064a0:	5bbc                	lw	a5,112(a5)
    800064a2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064a6:	8ba1                	andi	a5,a5,8
    800064a8:	10078563          	beqz	a5,800065b2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064ac:	100017b7          	lui	a5,0x10001
    800064b0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064b4:	43fc                	lw	a5,68(a5)
    800064b6:	2781                	sext.w	a5,a5
    800064b8:	10079563          	bnez	a5,800065c2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064bc:	100017b7          	lui	a5,0x10001
    800064c0:	5bdc                	lw	a5,52(a5)
    800064c2:	2781                	sext.w	a5,a5
  if(max == 0)
    800064c4:	10078763          	beqz	a5,800065d2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800064c8:	471d                	li	a4,7
    800064ca:	10f77c63          	bgeu	a4,a5,800065e2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800064ce:	ffffa097          	auipc	ra,0xffffa
    800064d2:	790080e7          	jalr	1936(ra) # 80000c5e <kalloc>
    800064d6:	0023c497          	auipc	s1,0x23c
    800064da:	95a48493          	addi	s1,s1,-1702 # 80241e30 <disk>
    800064de:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064e0:	ffffa097          	auipc	ra,0xffffa
    800064e4:	77e080e7          	jalr	1918(ra) # 80000c5e <kalloc>
    800064e8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064ea:	ffffa097          	auipc	ra,0xffffa
    800064ee:	774080e7          	jalr	1908(ra) # 80000c5e <kalloc>
    800064f2:	87aa                	mv	a5,a0
    800064f4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800064f6:	6088                	ld	a0,0(s1)
    800064f8:	cd6d                	beqz	a0,800065f2 <virtio_disk_init+0x1da>
    800064fa:	0023c717          	auipc	a4,0x23c
    800064fe:	93e73703          	ld	a4,-1730(a4) # 80241e38 <disk+0x8>
    80006502:	cb65                	beqz	a4,800065f2 <virtio_disk_init+0x1da>
    80006504:	c7fd                	beqz	a5,800065f2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006506:	6605                	lui	a2,0x1
    80006508:	4581                	li	a1,0
    8000650a:	ffffb097          	auipc	ra,0xffffb
    8000650e:	9ca080e7          	jalr	-1590(ra) # 80000ed4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006512:	0023c497          	auipc	s1,0x23c
    80006516:	91e48493          	addi	s1,s1,-1762 # 80241e30 <disk>
    8000651a:	6605                	lui	a2,0x1
    8000651c:	4581                	li	a1,0
    8000651e:	6488                	ld	a0,8(s1)
    80006520:	ffffb097          	auipc	ra,0xffffb
    80006524:	9b4080e7          	jalr	-1612(ra) # 80000ed4 <memset>
  memset(disk.used, 0, PGSIZE);
    80006528:	6605                	lui	a2,0x1
    8000652a:	4581                	li	a1,0
    8000652c:	6888                	ld	a0,16(s1)
    8000652e:	ffffb097          	auipc	ra,0xffffb
    80006532:	9a6080e7          	jalr	-1626(ra) # 80000ed4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006536:	100017b7          	lui	a5,0x10001
    8000653a:	4721                	li	a4,8
    8000653c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000653e:	4098                	lw	a4,0(s1)
    80006540:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006544:	40d8                	lw	a4,4(s1)
    80006546:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000654a:	6498                	ld	a4,8(s1)
    8000654c:	0007069b          	sext.w	a3,a4
    80006550:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006554:	9701                	srai	a4,a4,0x20
    80006556:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000655a:	6898                	ld	a4,16(s1)
    8000655c:	0007069b          	sext.w	a3,a4
    80006560:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006564:	9701                	srai	a4,a4,0x20
    80006566:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000656a:	4705                	li	a4,1
    8000656c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000656e:	00e48c23          	sb	a4,24(s1)
    80006572:	00e48ca3          	sb	a4,25(s1)
    80006576:	00e48d23          	sb	a4,26(s1)
    8000657a:	00e48da3          	sb	a4,27(s1)
    8000657e:	00e48e23          	sb	a4,28(s1)
    80006582:	00e48ea3          	sb	a4,29(s1)
    80006586:	00e48f23          	sb	a4,30(s1)
    8000658a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000658e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006592:	0727a823          	sw	s2,112(a5)
}
    80006596:	60e2                	ld	ra,24(sp)
    80006598:	6442                	ld	s0,16(sp)
    8000659a:	64a2                	ld	s1,8(sp)
    8000659c:	6902                	ld	s2,0(sp)
    8000659e:	6105                	addi	sp,sp,32
    800065a0:	8082                	ret
    panic("could not find virtio disk");
    800065a2:	00002517          	auipc	a0,0x2
    800065a6:	3b650513          	addi	a0,a0,950 # 80008958 <syscalls+0x348>
    800065aa:	ffffa097          	auipc	ra,0xffffa
    800065ae:	f92080e7          	jalr	-110(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	3c650513          	addi	a0,a0,966 # 80008978 <syscalls+0x368>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	3d650513          	addi	a0,a0,982 # 80008998 <syscalls+0x388>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f72080e7          	jalr	-142(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800065d2:	00002517          	auipc	a0,0x2
    800065d6:	3e650513          	addi	a0,a0,998 # 800089b8 <syscalls+0x3a8>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f62080e7          	jalr	-158(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	3f650513          	addi	a0,a0,1014 # 800089d8 <syscalls+0x3c8>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f52080e7          	jalr	-174(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	40650513          	addi	a0,a0,1030 # 800089f8 <syscalls+0x3e8>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f42080e7          	jalr	-190(ra) # 8000053c <panic>

0000000080006602 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006602:	7159                	addi	sp,sp,-112
    80006604:	f486                	sd	ra,104(sp)
    80006606:	f0a2                	sd	s0,96(sp)
    80006608:	eca6                	sd	s1,88(sp)
    8000660a:	e8ca                	sd	s2,80(sp)
    8000660c:	e4ce                	sd	s3,72(sp)
    8000660e:	e0d2                	sd	s4,64(sp)
    80006610:	fc56                	sd	s5,56(sp)
    80006612:	f85a                	sd	s6,48(sp)
    80006614:	f45e                	sd	s7,40(sp)
    80006616:	f062                	sd	s8,32(sp)
    80006618:	ec66                	sd	s9,24(sp)
    8000661a:	e86a                	sd	s10,16(sp)
    8000661c:	1880                	addi	s0,sp,112
    8000661e:	8a2a                	mv	s4,a0
    80006620:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006622:	00c52c83          	lw	s9,12(a0)
    80006626:	001c9c9b          	slliw	s9,s9,0x1
    8000662a:	1c82                	slli	s9,s9,0x20
    8000662c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006630:	0023c517          	auipc	a0,0x23c
    80006634:	92850513          	addi	a0,a0,-1752 # 80241f58 <disk+0x128>
    80006638:	ffffa097          	auipc	ra,0xffffa
    8000663c:	7a0080e7          	jalr	1952(ra) # 80000dd8 <acquire>
  for(int i = 0; i < 3; i++){
    80006640:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006642:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006644:	0023bb17          	auipc	s6,0x23b
    80006648:	7ecb0b13          	addi	s6,s6,2028 # 80241e30 <disk>
  for(int i = 0; i < 3; i++){
    8000664c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000664e:	0023cc17          	auipc	s8,0x23c
    80006652:	90ac0c13          	addi	s8,s8,-1782 # 80241f58 <disk+0x128>
    80006656:	a095                	j	800066ba <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006658:	00fb0733          	add	a4,s6,a5
    8000665c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006660:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006662:	0207c563          	bltz	a5,8000668c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006666:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006668:	0591                	addi	a1,a1,4
    8000666a:	05560d63          	beq	a2,s5,800066c4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000666e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006670:	0023b717          	auipc	a4,0x23b
    80006674:	7c070713          	addi	a4,a4,1984 # 80241e30 <disk>
    80006678:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000667a:	01874683          	lbu	a3,24(a4)
    8000667e:	fee9                	bnez	a3,80006658 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006680:	2785                	addiw	a5,a5,1
    80006682:	0705                	addi	a4,a4,1
    80006684:	fe979be3          	bne	a5,s1,8000667a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006688:	57fd                	li	a5,-1
    8000668a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000668c:	00c05e63          	blez	a2,800066a8 <virtio_disk_rw+0xa6>
    80006690:	060a                	slli	a2,a2,0x2
    80006692:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    80006696:	0009a503          	lw	a0,0(s3)
    8000669a:	00000097          	auipc	ra,0x0
    8000669e:	cfc080e7          	jalr	-772(ra) # 80006396 <free_desc>
      for(int j = 0; j < i; j++)
    800066a2:	0991                	addi	s3,s3,4
    800066a4:	ffa999e3          	bne	s3,s10,80006696 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066a8:	85e2                	mv	a1,s8
    800066aa:	0023b517          	auipc	a0,0x23b
    800066ae:	79e50513          	addi	a0,a0,1950 # 80241e48 <disk+0x18>
    800066b2:	ffffc097          	auipc	ra,0xffffc
    800066b6:	e22080e7          	jalr	-478(ra) # 800024d4 <sleep>
  for(int i = 0; i < 3; i++){
    800066ba:	f9040993          	addi	s3,s0,-112
{
    800066be:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800066c0:	864a                	mv	a2,s2
    800066c2:	b775                	j	8000666e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066c4:	f9042503          	lw	a0,-112(s0)
    800066c8:	00a50713          	addi	a4,a0,10
    800066cc:	0712                	slli	a4,a4,0x4

  if(write)
    800066ce:	0023b797          	auipc	a5,0x23b
    800066d2:	76278793          	addi	a5,a5,1890 # 80241e30 <disk>
    800066d6:	00e786b3          	add	a3,a5,a4
    800066da:	01703633          	snez	a2,s7
    800066de:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066e0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066e4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066e8:	f6070613          	addi	a2,a4,-160
    800066ec:	6394                	ld	a3,0(a5)
    800066ee:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066f0:	00870593          	addi	a1,a4,8
    800066f4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800066f6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800066f8:	0007b803          	ld	a6,0(a5)
    800066fc:	9642                	add	a2,a2,a6
    800066fe:	46c1                	li	a3,16
    80006700:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006702:	4585                	li	a1,1
    80006704:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006708:	f9442683          	lw	a3,-108(s0)
    8000670c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006710:	0692                	slli	a3,a3,0x4
    80006712:	9836                	add	a6,a6,a3
    80006714:	058a0613          	addi	a2,s4,88
    80006718:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000671c:	0007b803          	ld	a6,0(a5)
    80006720:	96c2                	add	a3,a3,a6
    80006722:	40000613          	li	a2,1024
    80006726:	c690                	sw	a2,8(a3)
  if(write)
    80006728:	001bb613          	seqz	a2,s7
    8000672c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006730:	00166613          	ori	a2,a2,1
    80006734:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006738:	f9842603          	lw	a2,-104(s0)
    8000673c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006740:	00250693          	addi	a3,a0,2
    80006744:	0692                	slli	a3,a3,0x4
    80006746:	96be                	add	a3,a3,a5
    80006748:	58fd                	li	a7,-1
    8000674a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000674e:	0612                	slli	a2,a2,0x4
    80006750:	9832                	add	a6,a6,a2
    80006752:	f9070713          	addi	a4,a4,-112
    80006756:	973e                	add	a4,a4,a5
    80006758:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000675c:	6398                	ld	a4,0(a5)
    8000675e:	9732                	add	a4,a4,a2
    80006760:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006762:	4609                	li	a2,2
    80006764:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006768:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000676c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006770:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006774:	6794                	ld	a3,8(a5)
    80006776:	0026d703          	lhu	a4,2(a3)
    8000677a:	8b1d                	andi	a4,a4,7
    8000677c:	0706                	slli	a4,a4,0x1
    8000677e:	96ba                	add	a3,a3,a4
    80006780:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006784:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006788:	6798                	ld	a4,8(a5)
    8000678a:	00275783          	lhu	a5,2(a4)
    8000678e:	2785                	addiw	a5,a5,1
    80006790:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006794:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006798:	100017b7          	lui	a5,0x10001
    8000679c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067a0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800067a4:	0023b917          	auipc	s2,0x23b
    800067a8:	7b490913          	addi	s2,s2,1972 # 80241f58 <disk+0x128>
  while(b->disk == 1) {
    800067ac:	4485                	li	s1,1
    800067ae:	00b79c63          	bne	a5,a1,800067c6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067b2:	85ca                	mv	a1,s2
    800067b4:	8552                	mv	a0,s4
    800067b6:	ffffc097          	auipc	ra,0xffffc
    800067ba:	d1e080e7          	jalr	-738(ra) # 800024d4 <sleep>
  while(b->disk == 1) {
    800067be:	004a2783          	lw	a5,4(s4)
    800067c2:	fe9788e3          	beq	a5,s1,800067b2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067c6:	f9042903          	lw	s2,-112(s0)
    800067ca:	00290713          	addi	a4,s2,2
    800067ce:	0712                	slli	a4,a4,0x4
    800067d0:	0023b797          	auipc	a5,0x23b
    800067d4:	66078793          	addi	a5,a5,1632 # 80241e30 <disk>
    800067d8:	97ba                	add	a5,a5,a4
    800067da:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067de:	0023b997          	auipc	s3,0x23b
    800067e2:	65298993          	addi	s3,s3,1618 # 80241e30 <disk>
    800067e6:	00491713          	slli	a4,s2,0x4
    800067ea:	0009b783          	ld	a5,0(s3)
    800067ee:	97ba                	add	a5,a5,a4
    800067f0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800067f4:	854a                	mv	a0,s2
    800067f6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800067fa:	00000097          	auipc	ra,0x0
    800067fe:	b9c080e7          	jalr	-1124(ra) # 80006396 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006802:	8885                	andi	s1,s1,1
    80006804:	f0ed                	bnez	s1,800067e6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006806:	0023b517          	auipc	a0,0x23b
    8000680a:	75250513          	addi	a0,a0,1874 # 80241f58 <disk+0x128>
    8000680e:	ffffa097          	auipc	ra,0xffffa
    80006812:	67e080e7          	jalr	1662(ra) # 80000e8c <release>
}
    80006816:	70a6                	ld	ra,104(sp)
    80006818:	7406                	ld	s0,96(sp)
    8000681a:	64e6                	ld	s1,88(sp)
    8000681c:	6946                	ld	s2,80(sp)
    8000681e:	69a6                	ld	s3,72(sp)
    80006820:	6a06                	ld	s4,64(sp)
    80006822:	7ae2                	ld	s5,56(sp)
    80006824:	7b42                	ld	s6,48(sp)
    80006826:	7ba2                	ld	s7,40(sp)
    80006828:	7c02                	ld	s8,32(sp)
    8000682a:	6ce2                	ld	s9,24(sp)
    8000682c:	6d42                	ld	s10,16(sp)
    8000682e:	6165                	addi	sp,sp,112
    80006830:	8082                	ret

0000000080006832 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006832:	1101                	addi	sp,sp,-32
    80006834:	ec06                	sd	ra,24(sp)
    80006836:	e822                	sd	s0,16(sp)
    80006838:	e426                	sd	s1,8(sp)
    8000683a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000683c:	0023b497          	auipc	s1,0x23b
    80006840:	5f448493          	addi	s1,s1,1524 # 80241e30 <disk>
    80006844:	0023b517          	auipc	a0,0x23b
    80006848:	71450513          	addi	a0,a0,1812 # 80241f58 <disk+0x128>
    8000684c:	ffffa097          	auipc	ra,0xffffa
    80006850:	58c080e7          	jalr	1420(ra) # 80000dd8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006854:	10001737          	lui	a4,0x10001
    80006858:	533c                	lw	a5,96(a4)
    8000685a:	8b8d                	andi	a5,a5,3
    8000685c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000685e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006862:	689c                	ld	a5,16(s1)
    80006864:	0204d703          	lhu	a4,32(s1)
    80006868:	0027d783          	lhu	a5,2(a5)
    8000686c:	04f70863          	beq	a4,a5,800068bc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006870:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006874:	6898                	ld	a4,16(s1)
    80006876:	0204d783          	lhu	a5,32(s1)
    8000687a:	8b9d                	andi	a5,a5,7
    8000687c:	078e                	slli	a5,a5,0x3
    8000687e:	97ba                	add	a5,a5,a4
    80006880:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006882:	00278713          	addi	a4,a5,2
    80006886:	0712                	slli	a4,a4,0x4
    80006888:	9726                	add	a4,a4,s1
    8000688a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000688e:	e721                	bnez	a4,800068d6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006890:	0789                	addi	a5,a5,2
    80006892:	0792                	slli	a5,a5,0x4
    80006894:	97a6                	add	a5,a5,s1
    80006896:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006898:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000689c:	ffffc097          	auipc	ra,0xffffc
    800068a0:	c9c080e7          	jalr	-868(ra) # 80002538 <wakeup>

    disk.used_idx += 1;
    800068a4:	0204d783          	lhu	a5,32(s1)
    800068a8:	2785                	addiw	a5,a5,1
    800068aa:	17c2                	slli	a5,a5,0x30
    800068ac:	93c1                	srli	a5,a5,0x30
    800068ae:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068b2:	6898                	ld	a4,16(s1)
    800068b4:	00275703          	lhu	a4,2(a4)
    800068b8:	faf71ce3          	bne	a4,a5,80006870 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068bc:	0023b517          	auipc	a0,0x23b
    800068c0:	69c50513          	addi	a0,a0,1692 # 80241f58 <disk+0x128>
    800068c4:	ffffa097          	auipc	ra,0xffffa
    800068c8:	5c8080e7          	jalr	1480(ra) # 80000e8c <release>
}
    800068cc:	60e2                	ld	ra,24(sp)
    800068ce:	6442                	ld	s0,16(sp)
    800068d0:	64a2                	ld	s1,8(sp)
    800068d2:	6105                	addi	sp,sp,32
    800068d4:	8082                	ret
      panic("virtio_disk_intr status");
    800068d6:	00002517          	auipc	a0,0x2
    800068da:	13a50513          	addi	a0,a0,314 # 80008a10 <syscalls+0x400>
    800068de:	ffffa097          	auipc	ra,0xffffa
    800068e2:	c5e080e7          	jalr	-930(ra) # 8000053c <panic>
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
