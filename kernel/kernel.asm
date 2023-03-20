
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	be010113          	addi	sp,sp,-1056 # 80008be0 <stack0>
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
    80000054:	a5070713          	addi	a4,a4,-1456 # 80008aa0 <timer_scratch>
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
    80000066:	2ae78793          	addi	a5,a5,686 # 80006310 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc8ef>
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
    8000012e:	848080e7          	jalr	-1976(ra) # 80002972 <either_copyin>
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
    80000188:	a5c50513          	addi	a0,a0,-1444 # 80010be0 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	c4c080e7          	jalr	-948(ra) # 80000dd8 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	a4c48493          	addi	s1,s1,-1460 # 80010be0 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	adc90913          	addi	s2,s2,-1316 # 80010c78 <cons+0x98>
    while (n > 0)
    800001a4:	09305263          	blez	s3,80000228 <consoleread+0xc4>
        while (cons.r == cons.w)
    800001a8:	0984a783          	lw	a5,152(s1)
    800001ac:	09c4a703          	lw	a4,156(s1)
    800001b0:	02f71763          	bne	a4,a5,800001de <consoleread+0x7a>
            if (killed(myproc()))
    800001b4:	00002097          	auipc	ra,0x2
    800001b8:	bf8080e7          	jalr	-1032(ra) # 80001dac <myproc>
    800001bc:	00002097          	auipc	ra,0x2
    800001c0:	600080e7          	jalr	1536(ra) # 800027bc <killed>
    800001c4:	ed2d                	bnez	a0,8000023e <consoleread+0xda>
            sleep(&cons.r, &cons.lock);
    800001c6:	85a6                	mv	a1,s1
    800001c8:	854a                	mv	a0,s2
    800001ca:	00002097          	auipc	ra,0x2
    800001ce:	34a080e7          	jalr	842(ra) # 80002514 <sleep>
        while (cons.r == cons.w)
    800001d2:	0984a783          	lw	a5,152(s1)
    800001d6:	09c4a703          	lw	a4,156(s1)
    800001da:	fcf70de3          	beq	a4,a5,800001b4 <consoleread+0x50>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00011717          	auipc	a4,0x11
    800001e2:	a0270713          	addi	a4,a4,-1534 # 80010be0 <cons>
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
    80000214:	70c080e7          	jalr	1804(ra) # 8000291c <either_copyout>
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
    8000022c:	9b850513          	addi	a0,a0,-1608 # 80010be0 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	c5c080e7          	jalr	-932(ra) # 80000e8c <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	9a250513          	addi	a0,a0,-1630 # 80010be0 <cons>
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
    80000272:	a0f72523          	sw	a5,-1526(a4) # 80010c78 <cons+0x98>
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
    800002cc:	91850513          	addi	a0,a0,-1768 # 80010be0 <cons>
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
    800002f2:	6da080e7          	jalr	1754(ra) # 800029c8 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002f6:	00011517          	auipc	a0,0x11
    800002fa:	8ea50513          	addi	a0,a0,-1814 # 80010be0 <cons>
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
    8000031e:	8c670713          	addi	a4,a4,-1850 # 80010be0 <cons>
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
    80000348:	89c78793          	addi	a5,a5,-1892 # 80010be0 <cons>
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
    80000376:	9067a783          	lw	a5,-1786(a5) # 80010c78 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	85a70713          	addi	a4,a4,-1958 # 80010be0 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	84a48493          	addi	s1,s1,-1974 # 80010be0 <cons>
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
    800003d6:	80e70713          	addi	a4,a4,-2034 # 80010be0 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	88f72c23          	sw	a5,-1896(a4) # 80010c80 <cons+0xa0>
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
    80000412:	7d278793          	addi	a5,a5,2002 # 80010be0 <cons>
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
    80000436:	84c7a523          	sw	a2,-1974(a5) # 80010c7c <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	83e50513          	addi	a0,a0,-1986 # 80010c78 <cons+0x98>
    80000442:	00002097          	auipc	ra,0x2
    80000446:	136080e7          	jalr	310(ra) # 80002578 <wakeup>
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
    80000460:	78450513          	addi	a0,a0,1924 # 80010be0 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	8e4080e7          	jalr	-1820(ra) # 80000d48 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	90478793          	addi	a5,a5,-1788 # 80240d78 <devsw>
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
    8000055e:	7407a323          	sw	zero,1862(a5) # 80010ca0 <pr+0x18>
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
    80000580:	b1450513          	addi	a0,a0,-1260 # 80008090 <digits+0x40>
    80000584:	00000097          	auipc	ra,0x0
    80000588:	014080e7          	jalr	20(ra) # 80000598 <printf>
    panicked = 1; // freeze uart output from other CPUs
    8000058c:	4785                	li	a5,1
    8000058e:	00008717          	auipc	a4,0x8
    80000592:	4cf72123          	sw	a5,1218(a4) # 80008a50 <panicked>
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
    800005ce:	6d6dad83          	lw	s11,1750(s11) # 80010ca0 <pr+0x18>
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
    8000060c:	68050513          	addi	a0,a0,1664 # 80010c88 <pr>
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
    8000076a:	52250513          	addi	a0,a0,1314 # 80010c88 <pr>
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
    80000786:	50648493          	addi	s1,s1,1286 # 80010c88 <pr>
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
    800007e6:	4c650513          	addi	a0,a0,1222 # 80010ca8 <uart_tx_lock>
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
    80000812:	2427a783          	lw	a5,578(a5) # 80008a50 <panicked>
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
    8000084a:	2127b783          	ld	a5,530(a5) # 80008a58 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	21273703          	ld	a4,530(a4) # 80008a60 <uart_tx_w>
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
    80000874:	438a0a13          	addi	s4,s4,1080 # 80010ca8 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	1e048493          	addi	s1,s1,480 # 80008a58 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	1e098993          	addi	s3,s3,480 # 80008a60 <uart_tx_w>
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
    800008a6:	cd6080e7          	jalr	-810(ra) # 80002578 <wakeup>
    
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
    800008e2:	3ca50513          	addi	a0,a0,970 # 80010ca8 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	4f2080e7          	jalr	1266(ra) # 80000dd8 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1627a783          	lw	a5,354(a5) # 80008a50 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	16873703          	ld	a4,360(a4) # 80008a60 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1587b783          	ld	a5,344(a5) # 80008a58 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	39c98993          	addi	s3,s3,924 # 80010ca8 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	14448493          	addi	s1,s1,324 # 80008a58 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	14490913          	addi	s2,s2,324 # 80008a60 <uart_tx_w>
    80000924:	00e79f63          	bne	a5,a4,80000942 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85ce                	mv	a1,s3
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	be8080e7          	jalr	-1048(ra) # 80002514 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093703          	ld	a4,0(s2)
    80000938:	609c                	ld	a5,0(s1)
    8000093a:	02078793          	addi	a5,a5,32
    8000093e:	fee785e3          	beq	a5,a4,80000928 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00010497          	auipc	s1,0x10
    80000946:	36648493          	addi	s1,s1,870 # 80010ca8 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	10e7b523          	sd	a4,266(a5) # 80008a60 <uart_tx_w>
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
    800009cc:	2e048493          	addi	s1,s1,736 # 80010ca8 <uart_tx_lock>
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
    80000a0c:	2d850513          	addi	a0,a0,728 # 80010ce0 <kmem>
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	3c8080e7          	jalr	968(ra) # 80000dd8 <acquire>
    if (pa >= PHYSTOP || reference_count[pn] < 1) {
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f97363          	bgeu	s2,a5,80000a62 <increment_refcount+0x6c>
    80000a20:	2481                	sext.w	s1,s1
    80000a22:	00249713          	slli	a4,s1,0x2
    80000a26:	00010797          	auipc	a5,0x10
    80000a2a:	2da78793          	addi	a5,a5,730 # 80010d00 <reference_count>
    80000a2e:	97ba                	add	a5,a5,a4
    80000a30:	439c                	lw	a5,0(a5)
    80000a32:	02f05863          	blez	a5,80000a62 <increment_refcount+0x6c>
        panic("incref");
    }
    reference_count[pn]++;
    80000a36:	048a                	slli	s1,s1,0x2
    80000a38:	00010717          	auipc	a4,0x10
    80000a3c:	2c870713          	addi	a4,a4,712 # 80010d00 <reference_count>
    80000a40:	9726                	add	a4,a4,s1
    80000a42:	2785                	addiw	a5,a5,1
    80000a44:	c31c                	sw	a5,0(a4)
    release(&kmem.lock);
    80000a46:	00010517          	auipc	a0,0x10
    80000a4a:	29a50513          	addi	a0,a0,666 # 80010ce0 <kmem>
    80000a4e:	00000097          	auipc	ra,0x0
    80000a52:	43e080e7          	jalr	1086(ra) # 80000e8c <release>
}
    80000a56:	60e2                	ld	ra,24(sp)
    80000a58:	6442                	ld	s0,16(sp)
    80000a5a:	64a2                	ld	s1,8(sp)
    80000a5c:	6902                	ld	s2,0(sp)
    80000a5e:	6105                	addi	sp,sp,32
    80000a60:	8082                	ret
        panic("incref");
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
    80000a84:	ff07b783          	ld	a5,-16(a5) # 80008a70 <MAX_PAGES>
    80000a88:	c799                	beqz	a5,80000a96 <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a8a:	00008717          	auipc	a4,0x8
    80000a8e:	fde73703          	ld	a4,-34(a4) # 80008a68 <FREE_PAGES>
    80000a92:	06f77e63          	bgeu	a4,a5,80000b0e <kfree+0x9c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) {
    80000a96:	03449793          	slli	a5,s1,0x34
    80000a9a:	e7c5                	bnez	a5,80000b42 <kfree+0xd0>
    80000a9c:	00241797          	auipc	a5,0x241
    80000aa0:	47478793          	addi	a5,a5,1140 # 80241f10 <end>
    80000aa4:	08f4ef63          	bltu	s1,a5,80000b42 <kfree+0xd0>
    80000aa8:	47c5                	li	a5,17
    80000aaa:	07ee                	slli	a5,a5,0x1b
    80000aac:	08f4fb63          	bgeu	s1,a5,80000b42 <kfree+0xd0>
        panic("kfree");
    }

    acquire(&kmem.lock);
    80000ab0:	00010517          	auipc	a0,0x10
    80000ab4:	23050513          	addi	a0,a0,560 # 80010ce0 <kmem>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	320080e7          	jalr	800(ra) # 80000dd8 <acquire>
    int pn = (uint64) pa / PGSIZE;
    80000ac0:	00c4d793          	srli	a5,s1,0xc
    80000ac4:	2781                	sext.w	a5,a5
    if (1 > reference_count[pn]) {
    80000ac6:	00279693          	slli	a3,a5,0x2
    80000aca:	00010717          	auipc	a4,0x10
    80000ace:	23670713          	addi	a4,a4,566 # 80010d00 <reference_count>
    80000ad2:	9736                	add	a4,a4,a3
    80000ad4:	4318                	lw	a4,0(a4)
    80000ad6:	06e05e63          	blez	a4,80000b52 <kfree+0xe0>
        panic("kfree: ref");
    }
    reference_count[pn]--;
    80000ada:	377d                	addiw	a4,a4,-1
    80000adc:	0007091b          	sext.w	s2,a4
    80000ae0:	078a                	slli	a5,a5,0x2
    80000ae2:	00010697          	auipc	a3,0x10
    80000ae6:	21e68693          	addi	a3,a3,542 # 80010d00 <reference_count>
    80000aea:	97b6                	add	a5,a5,a3
    80000aec:	c398                	sw	a4,0(a5)
    int tmp = reference_count[pn];
    release(&kmem.lock);
    80000aee:	00010517          	auipc	a0,0x10
    80000af2:	1f250513          	addi	a0,a0,498 # 80010ce0 <kmem>
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	396080e7          	jalr	918(ra) # 80000e8c <release>

    if (0 < tmp) {
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
    80000b0e:	04500693          	li	a3,69
    80000b12:	00007617          	auipc	a2,0x7
    80000b16:	4f660613          	addi	a2,a2,1270 # 80008008 <__func__.1>
    80000b1a:	00007597          	auipc	a1,0x7
    80000b1e:	55e58593          	addi	a1,a1,1374 # 80008078 <digits+0x28>
    80000b22:	00007517          	auipc	a0,0x7
    80000b26:	56650513          	addi	a0,a0,1382 # 80008088 <digits+0x38>
    80000b2a:	00000097          	auipc	ra,0x0
    80000b2e:	a6e080e7          	jalr	-1426(ra) # 80000598 <printf>
    80000b32:	00007517          	auipc	a0,0x7
    80000b36:	56650513          	addi	a0,a0,1382 # 80008098 <digits+0x48>
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	a02080e7          	jalr	-1534(ra) # 8000053c <panic>
        panic("kfree");
    80000b42:	00007517          	auipc	a0,0x7
    80000b46:	56650513          	addi	a0,a0,1382 # 800080a8 <digits+0x58>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	9f2080e7          	jalr	-1550(ra) # 8000053c <panic>
        panic("kfree: ref");
    80000b52:	00007517          	auipc	a0,0x7
    80000b56:	55e50513          	addi	a0,a0,1374 # 800080b0 <digits+0x60>
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
    80000b74:	17090913          	addi	s2,s2,368 # 80010ce0 <kmem>
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
    80000b90:	edc70713          	addi	a4,a4,-292 # 80008a68 <FREE_PAGES>
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
    80000bd4:	130b0b13          	addi	s6,s6,304 # 80010d00 <reference_count>
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
    80000c26:	0be50513          	addi	a0,a0,190 # 80010ce0 <kmem>
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	11e080e7          	jalr	286(ra) # 80000d48 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000c32:	45c5                	li	a1,17
    80000c34:	05ee                	slli	a1,a1,0x1b
    80000c36:	00241517          	auipc	a0,0x241
    80000c3a:	2da50513          	addi	a0,a0,730 # 80241f10 <end>
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	f68080e7          	jalr	-152(ra) # 80000ba6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000c46:	00008797          	auipc	a5,0x8
    80000c4a:	e227b783          	ld	a5,-478(a5) # 80008a68 <FREE_PAGES>
    80000c4e:	00008717          	auipc	a4,0x8
    80000c52:	e2f73123          	sd	a5,-478(a4) # 80008a70 <MAX_PAGES>
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
    80000c6c:	e007b783          	ld	a5,-512(a5) # 80008a68 <FREE_PAGES>
    80000c70:	c3c9                	beqz	a5,80000cf2 <kalloc+0x94>
    struct run *r;

    acquire(&kmem.lock);
    80000c72:	00010497          	auipc	s1,0x10
    80000c76:	06e48493          	addi	s1,s1,110 # 80010ce0 <kmem>
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
    80000c8e:	06f73723          	sd	a5,110(a4) # 80010cf8 <kmem+0x18>
    int pn = (uint64) r / PGSIZE;
    80000c92:	00c4d793          	srli	a5,s1,0xc
    80000c96:	2781                	sext.w	a5,a5
    if (0 != reference_count[pn]) {
    80000c98:	00279693          	slli	a3,a5,0x2
    80000c9c:	00010717          	auipc	a4,0x10
    80000ca0:	06470713          	addi	a4,a4,100 # 80010d00 <reference_count>
    80000ca4:	9736                	add	a4,a4,a3
    80000ca6:	4318                	lw	a4,0(a4)
    80000ca8:	ef3d                	bnez	a4,80000d26 <kalloc+0xc8>
        panic("kalloc: ref");
    }
        reference_count[pn] = 1;
    80000caa:	078a                	slli	a5,a5,0x2
    80000cac:	00010717          	auipc	a4,0x10
    80000cb0:	05470713          	addi	a4,a4,84 # 80010d00 <reference_count>
    80000cb4:	97ba                	add	a5,a5,a4
    80000cb6:	4705                	li	a4,1
    80000cb8:	c398                	sw	a4,0(a5)
    } 
    release(&kmem.lock);
    80000cba:	00010517          	auipc	a0,0x10
    80000cbe:	02650513          	addi	a0,a0,38 # 80010ce0 <kmem>
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
    80000cdc:	d9070713          	addi	a4,a4,-624 # 80008a68 <FREE_PAGES>
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
    80000cf2:	06b00693          	li	a3,107
    80000cf6:	00007617          	auipc	a2,0x7
    80000cfa:	30a60613          	addi	a2,a2,778 # 80008000 <etext>
    80000cfe:	00007597          	auipc	a1,0x7
    80000d02:	37a58593          	addi	a1,a1,890 # 80008078 <digits+0x28>
    80000d06:	00007517          	auipc	a0,0x7
    80000d0a:	38250513          	addi	a0,a0,898 # 80008088 <digits+0x38>
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	88a080e7          	jalr	-1910(ra) # 80000598 <printf>
    80000d16:	00007517          	auipc	a0,0x7
    80000d1a:	38250513          	addi	a0,a0,898 # 80008098 <digits+0x48>
    80000d1e:	00000097          	auipc	ra,0x0
    80000d22:	81e080e7          	jalr	-2018(ra) # 8000053c <panic>
        panic("kalloc: ref");
    80000d26:	00007517          	auipc	a0,0x7
    80000d2a:	3a250513          	addi	a0,a0,930 # 800080c8 <digits+0x78>
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	80e080e7          	jalr	-2034(ra) # 8000053c <panic>
    release(&kmem.lock);
    80000d36:	00010517          	auipc	a0,0x10
    80000d3a:	faa50513          	addi	a0,a0,-86 # 80010ce0 <kmem>
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
    80000d76:	01e080e7          	jalr	30(ra) # 80001d90 <mycpu>
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
    80000da8:	fec080e7          	jalr	-20(ra) # 80001d90 <mycpu>
    80000dac:	5d3c                	lw	a5,120(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000db0:	00001097          	auipc	ra,0x1
    80000db4:	fe0080e7          	jalr	-32(ra) # 80001d90 <mycpu>
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
    80000dcc:	fc8080e7          	jalr	-56(ra) # 80001d90 <mycpu>
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
    80000e0c:	f88080e7          	jalr	-120(ra) # 80001d90 <mycpu>
    80000e10:	e888                	sd	a0,16(s1)
}
    80000e12:	60e2                	ld	ra,24(sp)
    80000e14:	6442                	ld	s0,16(sp)
    80000e16:	64a2                	ld	s1,8(sp)
    80000e18:	6105                	addi	sp,sp,32
    80000e1a:	8082                	ret
    panic("acquire");
    80000e1c:	00007517          	auipc	a0,0x7
    80000e20:	2bc50513          	addi	a0,a0,700 # 800080d8 <digits+0x88>
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
    80000e38:	f5c080e7          	jalr	-164(ra) # 80001d90 <mycpu>
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
    80000e70:	27450513          	addi	a0,a0,628 # 800080e0 <digits+0x90>
    80000e74:	fffff097          	auipc	ra,0xfffff
    80000e78:	6c8080e7          	jalr	1736(ra) # 8000053c <panic>
    panic("pop_off");
    80000e7c:	00007517          	auipc	a0,0x7
    80000e80:	27c50513          	addi	a0,a0,636 # 800080f8 <digits+0xa8>
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
    80000ec8:	23c50513          	addi	a0,a0,572 # 80008100 <digits+0xb0>
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
    80001084:	d00080e7          	jalr	-768(ra) # 80001d80 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001088:	00008717          	auipc	a4,0x8
    8000108c:	9f070713          	addi	a4,a4,-1552 # 80008a78 <started>
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
    800010a0:	ce4080e7          	jalr	-796(ra) # 80001d80 <cpuid>
    800010a4:	85aa                	mv	a1,a0
    800010a6:	00007517          	auipc	a0,0x7
    800010aa:	07a50513          	addi	a0,a0,122 # 80008120 <digits+0xd0>
    800010ae:	fffff097          	auipc	ra,0xfffff
    800010b2:	4ea080e7          	jalr	1258(ra) # 80000598 <printf>
    kvminithart();    // turn on paging
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	0d8080e7          	jalr	216(ra) # 8000118e <kvminithart>
    trapinithart();   // install kernel trap vector
    800010be:	00002097          	auipc	ra,0x2
    800010c2:	b2e080e7          	jalr	-1234(ra) # 80002bec <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800010c6:	00005097          	auipc	ra,0x5
    800010ca:	28a080e7          	jalr	650(ra) # 80006350 <plicinithart>
  }

  scheduler();        
    800010ce:	00001097          	auipc	ra,0x1
    800010d2:	324080e7          	jalr	804(ra) # 800023f2 <scheduler>
    consoleinit();
    800010d6:	fffff097          	auipc	ra,0xfffff
    800010da:	376080e7          	jalr	886(ra) # 8000044c <consoleinit>
    printfinit();
    800010de:	fffff097          	auipc	ra,0xfffff
    800010e2:	69a080e7          	jalr	1690(ra) # 80000778 <printfinit>
    printf("\n");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	faa50513          	addi	a0,a0,-86 # 80008090 <digits+0x40>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	4aa080e7          	jalr	1194(ra) # 80000598 <printf>
    printf("xv6 kernel is booting\n");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	01250513          	addi	a0,a0,18 # 80008108 <digits+0xb8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	49a080e7          	jalr	1178(ra) # 80000598 <printf>
    printf("\n");
    80001106:	00007517          	auipc	a0,0x7
    8000110a:	f8a50513          	addi	a0,a0,-118 # 80008090 <digits+0x40>
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
    80001132:	b7a080e7          	jalr	-1158(ra) # 80001ca8 <procinit>
    trapinit();      // trap vectors
    80001136:	00002097          	auipc	ra,0x2
    8000113a:	a8e080e7          	jalr	-1394(ra) # 80002bc4 <trapinit>
    trapinithart();  // install kernel trap vector
    8000113e:	00002097          	auipc	ra,0x2
    80001142:	aae080e7          	jalr	-1362(ra) # 80002bec <trapinithart>
    plicinit();      // set up interrupt controller
    80001146:	00005097          	auipc	ra,0x5
    8000114a:	1f4080e7          	jalr	500(ra) # 8000633a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000114e:	00005097          	auipc	ra,0x5
    80001152:	202080e7          	jalr	514(ra) # 80006350 <plicinithart>
    binit();         // buffer cache
    80001156:	00002097          	auipc	ra,0x2
    8000115a:	3f6080e7          	jalr	1014(ra) # 8000354c <binit>
    iinit();         // inode table
    8000115e:	00003097          	auipc	ra,0x3
    80001162:	a94080e7          	jalr	-1388(ra) # 80003bf2 <iinit>
    fileinit();      // file table
    80001166:	00004097          	auipc	ra,0x4
    8000116a:	a0a080e7          	jalr	-1526(ra) # 80004b70 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000116e:	00005097          	auipc	ra,0x5
    80001172:	2ea080e7          	jalr	746(ra) # 80006458 <virtio_disk_init>
    userinit();      // first user process
    80001176:	00001097          	auipc	ra,0x1
    8000117a:	f0e080e7          	jalr	-242(ra) # 80002084 <userinit>
    __sync_synchronize();
    8000117e:	0ff0000f          	fence
    started = 1;
    80001182:	4785                	li	a5,1
    80001184:	00008717          	auipc	a4,0x8
    80001188:	8ef72a23          	sw	a5,-1804(a4) # 80008a78 <started>
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
    8000119c:	8e87b783          	ld	a5,-1816(a5) # 80008a80 <kernel_pagetable>
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
    800011e0:	f5c50513          	addi	a0,a0,-164 # 80008138 <digits+0xe8>
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
    80001306:	e3e50513          	addi	a0,a0,-450 # 80008140 <digits+0xf0>
    8000130a:	fffff097          	auipc	ra,0xfffff
    8000130e:	232080e7          	jalr	562(ra) # 8000053c <panic>
      panic("mappages: remap");
    80001312:	00007517          	auipc	a0,0x7
    80001316:	e3e50513          	addi	a0,a0,-450 # 80008150 <digits+0x100>
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
    80001362:	e0250513          	addi	a0,a0,-510 # 80008160 <digits+0x110>
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
    80001432:	7e4080e7          	jalr	2020(ra) # 80001c12 <proc_mapstacks>
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
    80001458:	62a7b623          	sd	a0,1580(a5) # 80008a80 <kernel_pagetable>
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
    800014ae:	cbe50513          	addi	a0,a0,-834 # 80008168 <digits+0x118>
    800014b2:	fffff097          	auipc	ra,0xfffff
    800014b6:	08a080e7          	jalr	138(ra) # 8000053c <panic>
      panic("uvmunmap: walk");
    800014ba:	00007517          	auipc	a0,0x7
    800014be:	cc650513          	addi	a0,a0,-826 # 80008180 <digits+0x130>
    800014c2:	fffff097          	auipc	ra,0xfffff
    800014c6:	07a080e7          	jalr	122(ra) # 8000053c <panic>
      panic("uvmunmap: not mapped");
    800014ca:	00007517          	auipc	a0,0x7
    800014ce:	cc650513          	addi	a0,a0,-826 # 80008190 <digits+0x140>
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	06a080e7          	jalr	106(ra) # 8000053c <panic>
      panic("uvmunmap: not a leaf");
    800014da:	00007517          	auipc	a0,0x7
    800014de:	cce50513          	addi	a0,a0,-818 # 800081a8 <digits+0x158>
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
    800015bc:	c0850513          	addi	a0,a0,-1016 # 800081c0 <digits+0x170>
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
    80001708:	adc50513          	addi	a0,a0,-1316 # 800081e0 <digits+0x190>
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
    800017e6:	a0e50513          	addi	a0,a0,-1522 # 800081f0 <digits+0x1a0>
    800017ea:	fffff097          	auipc	ra,0xfffff
    800017ee:	d52080e7          	jalr	-686(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800017f2:	00007517          	auipc	a0,0x7
    800017f6:	a1e50513          	addi	a0,a0,-1506 # 80008210 <digits+0x1c0>
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
    *pte &= ~PTE_W;
    80001876:	ffb77493          	andi	s1,a4,-5
    8000187a:	e104                	sd	s1,0(a0)
    flags = PTE_FLAGS(*pte);
    increment_refcount(pa);
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
    800018aa:	94a50513          	addi	a0,a0,-1718 # 800081f0 <digits+0x1a0>
    800018ae:	fffff097          	auipc	ra,0xfffff
    800018b2:	c8e080e7          	jalr	-882(ra) # 8000053c <panic>
      panic("uvmcopy: page not present");
    800018b6:	00007517          	auipc	a0,0x7
    800018ba:	95a50513          	addi	a0,a0,-1702 # 80008210 <digits+0x1c0>
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
    80001918:	91c50513          	addi	a0,a0,-1764 # 80008230 <digits+0x1e0>
    8000191c:	fffff097          	auipc	ra,0xfffff
    80001920:	c20080e7          	jalr	-992(ra) # 8000053c <panic>

0000000080001924 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001924:	cac5                	beqz	a3,800019d4 <copyout+0xb0>
{
    80001926:	7159                	addi	sp,sp,-112
    80001928:	f486                	sd	ra,104(sp)
    8000192a:	f0a2                	sd	s0,96(sp)
    8000192c:	eca6                	sd	s1,88(sp)
    8000192e:	e8ca                	sd	s2,80(sp)
    80001930:	e4ce                	sd	s3,72(sp)
    80001932:	e0d2                	sd	s4,64(sp)
    80001934:	fc56                	sd	s5,56(sp)
    80001936:	f85a                	sd	s6,48(sp)
    80001938:	f45e                	sd	s7,40(sp)
    8000193a:	f062                	sd	s8,32(sp)
    8000193c:	ec66                	sd	s9,24(sp)
    8000193e:	e86a                	sd	s10,16(sp)
    80001940:	e46e                	sd	s11,8(sp)
    80001942:	1880                	addi	s0,sp,112
    80001944:	8c2a                	mv	s8,a0
    80001946:	8b2e                	mv	s6,a1
    80001948:	8bb2                	mv	s7,a2
    8000194a:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    8000194c:	74fd                	lui	s1,0xfffff
    8000194e:	8ced                	and	s1,s1,a1
    if(va0 >= MAXVA)
    80001950:	57fd                	li	a5,-1
    80001952:	83e9                	srli	a5,a5,0x1a
    80001954:	0897e263          	bltu	a5,s1,800019d8 <copyout+0xb4>
      return -1;
    
    pte_t* pte = walk(pagetable, va0, 0);
    if (0 == pte || 0 == (*pte & PTE_V) || 0 == (*pte & PTE_U)) {
    80001958:	4d45                	li	s10,17
    8000195a:	6d85                	lui	s11,0x1
    if(va0 >= MAXVA)
    8000195c:	8cbe                	mv	s9,a5
    8000195e:	a83d                	j	8000199c <copyout+0x78>
        return -1;
      }
    }
    pa0 = PTE2PA(*pte);

    n = PGSIZE - (dstva - va0);
    80001960:	01b48ab3          	add	s5,s1,s11
    80001964:	416a89b3          	sub	s3,s5,s6
    80001968:	013a7363          	bgeu	s4,s3,8000196e <copyout+0x4a>
    8000196c:	89d2                	mv	s3,s4
    pa0 = PTE2PA(*pte);
    8000196e:	00093783          	ld	a5,0(s2) # 1000 <_entry-0x7ffff000>
    80001972:	83a9                	srli	a5,a5,0xa
    80001974:	07b2                	slli	a5,a5,0xc
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001976:	409b0533          	sub	a0,s6,s1
    8000197a:	0009861b          	sext.w	a2,s3
    8000197e:	85de                	mv	a1,s7
    80001980:	953e                	add	a0,a0,a5
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	5ae080e7          	jalr	1454(ra) # 80000f30 <memmove>

    len -= n;
    8000198a:	413a0a33          	sub	s4,s4,s3
    src += n;
    8000198e:	9bce                	add	s7,s7,s3
  while(len > 0){
    80001990:	040a0063          	beqz	s4,800019d0 <copyout+0xac>
    if(va0 >= MAXVA)
    80001994:	055ce463          	bltu	s9,s5,800019dc <copyout+0xb8>
    va0 = PGROUNDDOWN(dstva);
    80001998:	84d6                	mv	s1,s5
    dstva = va0 + PGSIZE;
    8000199a:	8b56                	mv	s6,s5
    pte_t* pte = walk(pagetable, va0, 0);
    8000199c:	4601                	li	a2,0
    8000199e:	85a6                	mv	a1,s1
    800019a0:	8562                	mv	a0,s8
    800019a2:	00000097          	auipc	ra,0x0
    800019a6:	814080e7          	jalr	-2028(ra) # 800011b6 <walk>
    800019aa:	892a                	mv	s2,a0
    if (0 == pte || 0 == (*pte & PTE_V) || 0 == (*pte & PTE_U)) {
    800019ac:	c915                	beqz	a0,800019e0 <copyout+0xbc>
    800019ae:	611c                	ld	a5,0(a0)
    800019b0:	0117f713          	andi	a4,a5,17
    800019b4:	05a71663          	bne	a4,s10,80001a00 <copyout+0xdc>
    if (0 == (*pte & PTE_W)) {
    800019b8:	8b91                	andi	a5,a5,4
    800019ba:	f3dd                	bnez	a5,80001960 <copyout+0x3c>
      if (0 > cowfault(pagetable, va0)) {
    800019bc:	85a6                	mv	a1,s1
    800019be:	8562                	mv	a0,s8
    800019c0:	00001097          	auipc	ra,0x1
    800019c4:	492080e7          	jalr	1170(ra) # 80002e52 <cowfault>
    800019c8:	f8055ce3          	bgez	a0,80001960 <copyout+0x3c>
        return -1;
    800019cc:	557d                	li	a0,-1
    800019ce:	a811                	j	800019e2 <copyout+0xbe>
  }
  return 0;
    800019d0:	4501                	li	a0,0
    800019d2:	a801                	j	800019e2 <copyout+0xbe>
    800019d4:	4501                	li	a0,0
}
    800019d6:	8082                	ret
      return -1;
    800019d8:	557d                	li	a0,-1
    800019da:	a021                	j	800019e2 <copyout+0xbe>
    800019dc:	557d                	li	a0,-1
    800019de:	a011                	j	800019e2 <copyout+0xbe>
      return -1;
    800019e0:	557d                	li	a0,-1
}
    800019e2:	70a6                	ld	ra,104(sp)
    800019e4:	7406                	ld	s0,96(sp)
    800019e6:	64e6                	ld	s1,88(sp)
    800019e8:	6946                	ld	s2,80(sp)
    800019ea:	69a6                	ld	s3,72(sp)
    800019ec:	6a06                	ld	s4,64(sp)
    800019ee:	7ae2                	ld	s5,56(sp)
    800019f0:	7b42                	ld	s6,48(sp)
    800019f2:	7ba2                	ld	s7,40(sp)
    800019f4:	7c02                	ld	s8,32(sp)
    800019f6:	6ce2                	ld	s9,24(sp)
    800019f8:	6d42                	ld	s10,16(sp)
    800019fa:	6da2                	ld	s11,8(sp)
    800019fc:	6165                	addi	sp,sp,112
    800019fe:	8082                	ret
      return -1;
    80001a00:	557d                	li	a0,-1
    80001a02:	b7c5                	j	800019e2 <copyout+0xbe>

0000000080001a04 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a04:	caa5                	beqz	a3,80001a74 <copyin+0x70>
{
    80001a06:	715d                	addi	sp,sp,-80
    80001a08:	e486                	sd	ra,72(sp)
    80001a0a:	e0a2                	sd	s0,64(sp)
    80001a0c:	fc26                	sd	s1,56(sp)
    80001a0e:	f84a                	sd	s2,48(sp)
    80001a10:	f44e                	sd	s3,40(sp)
    80001a12:	f052                	sd	s4,32(sp)
    80001a14:	ec56                	sd	s5,24(sp)
    80001a16:	e85a                	sd	s6,16(sp)
    80001a18:	e45e                	sd	s7,8(sp)
    80001a1a:	e062                	sd	s8,0(sp)
    80001a1c:	0880                	addi	s0,sp,80
    80001a1e:	8b2a                	mv	s6,a0
    80001a20:	8a2e                	mv	s4,a1
    80001a22:	8c32                	mv	s8,a2
    80001a24:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001a26:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a28:	6a85                	lui	s5,0x1
    80001a2a:	a01d                	j	80001a50 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001a2c:	018505b3          	add	a1,a0,s8
    80001a30:	0004861b          	sext.w	a2,s1
    80001a34:	412585b3          	sub	a1,a1,s2
    80001a38:	8552                	mv	a0,s4
    80001a3a:	fffff097          	auipc	ra,0xfffff
    80001a3e:	4f6080e7          	jalr	1270(ra) # 80000f30 <memmove>

    len -= n;
    80001a42:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001a46:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001a48:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001a4c:	02098263          	beqz	s3,80001a70 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001a50:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a54:	85ca                	mv	a1,s2
    80001a56:	855a                	mv	a0,s6
    80001a58:	00000097          	auipc	ra,0x0
    80001a5c:	804080e7          	jalr	-2044(ra) # 8000125c <walkaddr>
    if(pa0 == 0)
    80001a60:	cd01                	beqz	a0,80001a78 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001a62:	418904b3          	sub	s1,s2,s8
    80001a66:	94d6                	add	s1,s1,s5
    80001a68:	fc99f2e3          	bgeu	s3,s1,80001a2c <copyin+0x28>
    80001a6c:	84ce                	mv	s1,s3
    80001a6e:	bf7d                	j	80001a2c <copyin+0x28>
  }
  return 0;
    80001a70:	4501                	li	a0,0
    80001a72:	a021                	j	80001a7a <copyin+0x76>
    80001a74:	4501                	li	a0,0
}
    80001a76:	8082                	ret
      return -1;
    80001a78:	557d                	li	a0,-1
}
    80001a7a:	60a6                	ld	ra,72(sp)
    80001a7c:	6406                	ld	s0,64(sp)
    80001a7e:	74e2                	ld	s1,56(sp)
    80001a80:	7942                	ld	s2,48(sp)
    80001a82:	79a2                	ld	s3,40(sp)
    80001a84:	7a02                	ld	s4,32(sp)
    80001a86:	6ae2                	ld	s5,24(sp)
    80001a88:	6b42                	ld	s6,16(sp)
    80001a8a:	6ba2                	ld	s7,8(sp)
    80001a8c:	6c02                	ld	s8,0(sp)
    80001a8e:	6161                	addi	sp,sp,80
    80001a90:	8082                	ret

0000000080001a92 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001a92:	c2dd                	beqz	a3,80001b38 <copyinstr+0xa6>
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
    80001aa8:	0880                	addi	s0,sp,80
    80001aaa:	8a2a                	mv	s4,a0
    80001aac:	8b2e                	mv	s6,a1
    80001aae:	8bb2                	mv	s7,a2
    80001ab0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001ab2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001ab4:	6985                	lui	s3,0x1
    80001ab6:	a02d                	j	80001ae0 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001ab8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001abc:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001abe:	37fd                	addiw	a5,a5,-1
    80001ac0:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001ac4:	60a6                	ld	ra,72(sp)
    80001ac6:	6406                	ld	s0,64(sp)
    80001ac8:	74e2                	ld	s1,56(sp)
    80001aca:	7942                	ld	s2,48(sp)
    80001acc:	79a2                	ld	s3,40(sp)
    80001ace:	7a02                	ld	s4,32(sp)
    80001ad0:	6ae2                	ld	s5,24(sp)
    80001ad2:	6b42                	ld	s6,16(sp)
    80001ad4:	6ba2                	ld	s7,8(sp)
    80001ad6:	6161                	addi	sp,sp,80
    80001ad8:	8082                	ret
    srcva = va0 + PGSIZE;
    80001ada:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001ade:	c8a9                	beqz	s1,80001b30 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    80001ae0:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001ae4:	85ca                	mv	a1,s2
    80001ae6:	8552                	mv	a0,s4
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	774080e7          	jalr	1908(ra) # 8000125c <walkaddr>
    if(pa0 == 0)
    80001af0:	c131                	beqz	a0,80001b34 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001af2:	417906b3          	sub	a3,s2,s7
    80001af6:	96ce                	add	a3,a3,s3
    80001af8:	00d4f363          	bgeu	s1,a3,80001afe <copyinstr+0x6c>
    80001afc:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001afe:	955e                	add	a0,a0,s7
    80001b00:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001b04:	daf9                	beqz	a3,80001ada <copyinstr+0x48>
    80001b06:	87da                	mv	a5,s6
    80001b08:	885a                	mv	a6,s6
      if(*p == '\0'){
    80001b0a:	41650633          	sub	a2,a0,s6
    while(n > 0){
    80001b0e:	96da                	add	a3,a3,s6
    80001b10:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001b12:	00f60733          	add	a4,a2,a5
    80001b16:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbd0f0>
    80001b1a:	df59                	beqz	a4,80001ab8 <copyinstr+0x26>
        *dst = *p;
    80001b1c:	00e78023          	sb	a4,0(a5)
      dst++;
    80001b20:	0785                	addi	a5,a5,1
    while(n > 0){
    80001b22:	fed797e3          	bne	a5,a3,80001b10 <copyinstr+0x7e>
    80001b26:	14fd                	addi	s1,s1,-1 # ffffffffffffefff <end+0xffffffff7fdbd0ef>
    80001b28:	94c2                	add	s1,s1,a6
      --max;
    80001b2a:	8c8d                	sub	s1,s1,a1
      dst++;
    80001b2c:	8b3e                	mv	s6,a5
    80001b2e:	b775                	j	80001ada <copyinstr+0x48>
    80001b30:	4781                	li	a5,0
    80001b32:	b771                	j	80001abe <copyinstr+0x2c>
      return -1;
    80001b34:	557d                	li	a0,-1
    80001b36:	b779                	j	80001ac4 <copyinstr+0x32>
  int got_null = 0;
    80001b38:	4781                	li	a5,0
  if(got_null){
    80001b3a:	37fd                	addiw	a5,a5,-1
    80001b3c:	0007851b          	sext.w	a0,a5
}
    80001b40:	8082                	ret

0000000080001b42 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001b42:	715d                	addi	sp,sp,-80
    80001b44:	e486                	sd	ra,72(sp)
    80001b46:	e0a2                	sd	s0,64(sp)
    80001b48:	fc26                	sd	s1,56(sp)
    80001b4a:	f84a                	sd	s2,48(sp)
    80001b4c:	f44e                	sd	s3,40(sp)
    80001b4e:	f052                	sd	s4,32(sp)
    80001b50:	ec56                	sd	s5,24(sp)
    80001b52:	e85a                	sd	s6,16(sp)
    80001b54:	e45e                	sd	s7,8(sp)
    80001b56:	e062                	sd	s8,0(sp)
    80001b58:	0880                	addi	s0,sp,80
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b5a:	8792                	mv	a5,tp
    int id = r_tp();
    80001b5c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    80001b5e:	0022fa97          	auipc	s5,0x22f
    80001b62:	1a2a8a93          	addi	s5,s5,418 # 80230d00 <cpus>
    80001b66:	00779713          	slli	a4,a5,0x7
    80001b6a:	00ea86b3          	add	a3,s5,a4
    80001b6e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fdbd0f0>
                // Switch to chosen process.  It is the process's job
                // to release its lock and then reacquire it
                // before jumping back to us.
                p->state = RUNNING;
                c->proc = p;
                swtch(&c->context, &p->context);
    80001b72:	0721                	addi	a4,a4,8
    80001b74:	9aba                	add	s5,s5,a4
                c->proc = p;
    80001b76:	8936                	mv	s2,a3
                // check if we are still the right scheduler (or if schedset changed)
                if (sched_pointer != &rr_scheduler)
    80001b78:	00007c17          	auipc	s8,0x7
    80001b7c:	e60c0c13          	addi	s8,s8,-416 # 800089d8 <sched_pointer>
    80001b80:	00000b97          	auipc	s7,0x0
    80001b84:	fc2b8b93          	addi	s7,s7,-62 # 80001b42 <rr_scheduler>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001b88:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001b8c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001b90:	10079073          	csrw	sstatus,a5
        for (p = proc; p < &proc[NPROC]; p++)
    80001b94:	0022f497          	auipc	s1,0x22f
    80001b98:	59c48493          	addi	s1,s1,1436 # 80231130 <proc>
            if (p->state == RUNNABLE)
    80001b9c:	498d                	li	s3,3
                p->state = RUNNING;
    80001b9e:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001ba0:	00235a17          	auipc	s4,0x235
    80001ba4:	f90a0a13          	addi	s4,s4,-112 # 80236b30 <tickslock>
    80001ba8:	a81d                	j	80001bde <rr_scheduler+0x9c>
                {
                    release(&p->lock);
    80001baa:	8526                	mv	a0,s1
    80001bac:	fffff097          	auipc	ra,0xfffff
    80001bb0:	2e0080e7          	jalr	736(ra) # 80000e8c <release>
                c->proc = 0;
            }
            release(&p->lock);
        }
    }
}
    80001bb4:	60a6                	ld	ra,72(sp)
    80001bb6:	6406                	ld	s0,64(sp)
    80001bb8:	74e2                	ld	s1,56(sp)
    80001bba:	7942                	ld	s2,48(sp)
    80001bbc:	79a2                	ld	s3,40(sp)
    80001bbe:	7a02                	ld	s4,32(sp)
    80001bc0:	6ae2                	ld	s5,24(sp)
    80001bc2:	6b42                	ld	s6,16(sp)
    80001bc4:	6ba2                	ld	s7,8(sp)
    80001bc6:	6c02                	ld	s8,0(sp)
    80001bc8:	6161                	addi	sp,sp,80
    80001bca:	8082                	ret
            release(&p->lock);
    80001bcc:	8526                	mv	a0,s1
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	2be080e7          	jalr	702(ra) # 80000e8c <release>
        for (p = proc; p < &proc[NPROC]; p++)
    80001bd6:	16848493          	addi	s1,s1,360
    80001bda:	fb4487e3          	beq	s1,s4,80001b88 <rr_scheduler+0x46>
            acquire(&p->lock);
    80001bde:	8526                	mv	a0,s1
    80001be0:	fffff097          	auipc	ra,0xfffff
    80001be4:	1f8080e7          	jalr	504(ra) # 80000dd8 <acquire>
            if (p->state == RUNNABLE)
    80001be8:	4c9c                	lw	a5,24(s1)
    80001bea:	ff3791e3          	bne	a5,s3,80001bcc <rr_scheduler+0x8a>
                p->state = RUNNING;
    80001bee:	0164ac23          	sw	s6,24(s1)
                c->proc = p;
    80001bf2:	00993023          	sd	s1,0(s2)
                swtch(&c->context, &p->context);
    80001bf6:	06048593          	addi	a1,s1,96
    80001bfa:	8556                	mv	a0,s5
    80001bfc:	00001097          	auipc	ra,0x1
    80001c00:	f5e080e7          	jalr	-162(ra) # 80002b5a <swtch>
                if (sched_pointer != &rr_scheduler)
    80001c04:	000c3783          	ld	a5,0(s8)
    80001c08:	fb7791e3          	bne	a5,s7,80001baa <rr_scheduler+0x68>
                c->proc = 0;
    80001c0c:	00093023          	sd	zero,0(s2)
    80001c10:	bf75                	j	80001bcc <rr_scheduler+0x8a>

0000000080001c12 <proc_mapstacks>:
{
    80001c12:	7139                	addi	sp,sp,-64
    80001c14:	fc06                	sd	ra,56(sp)
    80001c16:	f822                	sd	s0,48(sp)
    80001c18:	f426                	sd	s1,40(sp)
    80001c1a:	f04a                	sd	s2,32(sp)
    80001c1c:	ec4e                	sd	s3,24(sp)
    80001c1e:	e852                	sd	s4,16(sp)
    80001c20:	e456                	sd	s5,8(sp)
    80001c22:	e05a                	sd	s6,0(sp)
    80001c24:	0080                	addi	s0,sp,64
    80001c26:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    80001c28:	0022f497          	auipc	s1,0x22f
    80001c2c:	50848493          	addi	s1,s1,1288 # 80231130 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001c30:	8b26                	mv	s6,s1
    80001c32:	00006a97          	auipc	s5,0x6
    80001c36:	3dea8a93          	addi	s5,s5,990 # 80008010 <__func__.1+0x8>
    80001c3a:	04000937          	lui	s2,0x4000
    80001c3e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c40:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c42:	00235a17          	auipc	s4,0x235
    80001c46:	eeea0a13          	addi	s4,s4,-274 # 80236b30 <tickslock>
        char *pa = kalloc();
    80001c4a:	fffff097          	auipc	ra,0xfffff
    80001c4e:	014080e7          	jalr	20(ra) # 80000c5e <kalloc>
    80001c52:	862a                	mv	a2,a0
        if (pa == 0)
    80001c54:	c131                	beqz	a0,80001c98 <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    80001c56:	416485b3          	sub	a1,s1,s6
    80001c5a:	858d                	srai	a1,a1,0x3
    80001c5c:	000ab783          	ld	a5,0(s5)
    80001c60:	02f585b3          	mul	a1,a1,a5
    80001c64:	2585                	addiw	a1,a1,1
    80001c66:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001c6a:	4719                	li	a4,6
    80001c6c:	6685                	lui	a3,0x1
    80001c6e:	40b905b3          	sub	a1,s2,a1
    80001c72:	854e                	mv	a0,s3
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	6ca080e7          	jalr	1738(ra) # 8000133e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001c7c:	16848493          	addi	s1,s1,360
    80001c80:	fd4495e3          	bne	s1,s4,80001c4a <proc_mapstacks+0x38>
}
    80001c84:	70e2                	ld	ra,56(sp)
    80001c86:	7442                	ld	s0,48(sp)
    80001c88:	74a2                	ld	s1,40(sp)
    80001c8a:	7902                	ld	s2,32(sp)
    80001c8c:	69e2                	ld	s3,24(sp)
    80001c8e:	6a42                	ld	s4,16(sp)
    80001c90:	6aa2                	ld	s5,8(sp)
    80001c92:	6b02                	ld	s6,0(sp)
    80001c94:	6121                	addi	sp,sp,64
    80001c96:	8082                	ret
            panic("kalloc");
    80001c98:	00006517          	auipc	a0,0x6
    80001c9c:	5a850513          	addi	a0,a0,1448 # 80008240 <digits+0x1f0>
    80001ca0:	fffff097          	auipc	ra,0xfffff
    80001ca4:	89c080e7          	jalr	-1892(ra) # 8000053c <panic>

0000000080001ca8 <procinit>:
{
    80001ca8:	7139                	addi	sp,sp,-64
    80001caa:	fc06                	sd	ra,56(sp)
    80001cac:	f822                	sd	s0,48(sp)
    80001cae:	f426                	sd	s1,40(sp)
    80001cb0:	f04a                	sd	s2,32(sp)
    80001cb2:	ec4e                	sd	s3,24(sp)
    80001cb4:	e852                	sd	s4,16(sp)
    80001cb6:	e456                	sd	s5,8(sp)
    80001cb8:	e05a                	sd	s6,0(sp)
    80001cba:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001cbc:	00006597          	auipc	a1,0x6
    80001cc0:	58c58593          	addi	a1,a1,1420 # 80008248 <digits+0x1f8>
    80001cc4:	0022f517          	auipc	a0,0x22f
    80001cc8:	43c50513          	addi	a0,a0,1084 # 80231100 <pid_lock>
    80001ccc:	fffff097          	auipc	ra,0xfffff
    80001cd0:	07c080e7          	jalr	124(ra) # 80000d48 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001cd4:	00006597          	auipc	a1,0x6
    80001cd8:	57c58593          	addi	a1,a1,1404 # 80008250 <digits+0x200>
    80001cdc:	0022f517          	auipc	a0,0x22f
    80001ce0:	43c50513          	addi	a0,a0,1084 # 80231118 <wait_lock>
    80001ce4:	fffff097          	auipc	ra,0xfffff
    80001ce8:	064080e7          	jalr	100(ra) # 80000d48 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001cec:	0022f497          	auipc	s1,0x22f
    80001cf0:	44448493          	addi	s1,s1,1092 # 80231130 <proc>
        initlock(&p->lock, "proc");
    80001cf4:	00006b17          	auipc	s6,0x6
    80001cf8:	56cb0b13          	addi	s6,s6,1388 # 80008260 <digits+0x210>
        p->kstack = KSTACK((int)(p - proc));
    80001cfc:	8aa6                	mv	s5,s1
    80001cfe:	00006a17          	auipc	s4,0x6
    80001d02:	312a0a13          	addi	s4,s4,786 # 80008010 <__func__.1+0x8>
    80001d06:	04000937          	lui	s2,0x4000
    80001d0a:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001d0c:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001d0e:	00235997          	auipc	s3,0x235
    80001d12:	e2298993          	addi	s3,s3,-478 # 80236b30 <tickslock>
        initlock(&p->lock, "proc");
    80001d16:	85da                	mv	a1,s6
    80001d18:	8526                	mv	a0,s1
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	02e080e7          	jalr	46(ra) # 80000d48 <initlock>
        p->state = UNUSED;
    80001d22:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    80001d26:	415487b3          	sub	a5,s1,s5
    80001d2a:	878d                	srai	a5,a5,0x3
    80001d2c:	000a3703          	ld	a4,0(s4)
    80001d30:	02e787b3          	mul	a5,a5,a4
    80001d34:	2785                	addiw	a5,a5,1
    80001d36:	00d7979b          	slliw	a5,a5,0xd
    80001d3a:	40f907b3          	sub	a5,s2,a5
    80001d3e:	e0bc                	sd	a5,64(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001d40:	16848493          	addi	s1,s1,360
    80001d44:	fd3499e3          	bne	s1,s3,80001d16 <procinit+0x6e>
}
    80001d48:	70e2                	ld	ra,56(sp)
    80001d4a:	7442                	ld	s0,48(sp)
    80001d4c:	74a2                	ld	s1,40(sp)
    80001d4e:	7902                	ld	s2,32(sp)
    80001d50:	69e2                	ld	s3,24(sp)
    80001d52:	6a42                	ld	s4,16(sp)
    80001d54:	6aa2                	ld	s5,8(sp)
    80001d56:	6b02                	ld	s6,0(sp)
    80001d58:	6121                	addi	sp,sp,64
    80001d5a:	8082                	ret

0000000080001d5c <copy_array>:
{
    80001d5c:	1141                	addi	sp,sp,-16
    80001d5e:	e422                	sd	s0,8(sp)
    80001d60:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001d62:	00c05c63          	blez	a2,80001d7a <copy_array+0x1e>
    80001d66:	87aa                	mv	a5,a0
    80001d68:	9532                	add	a0,a0,a2
        dst[i] = src[i];
    80001d6a:	0007c703          	lbu	a4,0(a5)
    80001d6e:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001d72:	0785                	addi	a5,a5,1
    80001d74:	0585                	addi	a1,a1,1
    80001d76:	fea79ae3          	bne	a5,a0,80001d6a <copy_array+0xe>
}
    80001d7a:	6422                	ld	s0,8(sp)
    80001d7c:	0141                	addi	sp,sp,16
    80001d7e:	8082                	ret

0000000080001d80 <cpuid>:
{
    80001d80:	1141                	addi	sp,sp,-16
    80001d82:	e422                	sd	s0,8(sp)
    80001d84:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d86:	8512                	mv	a0,tp
}
    80001d88:	2501                	sext.w	a0,a0
    80001d8a:	6422                	ld	s0,8(sp)
    80001d8c:	0141                	addi	sp,sp,16
    80001d8e:	8082                	ret

0000000080001d90 <mycpu>:
{
    80001d90:	1141                	addi	sp,sp,-16
    80001d92:	e422                	sd	s0,8(sp)
    80001d94:	0800                	addi	s0,sp,16
    80001d96:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001d98:	2781                	sext.w	a5,a5
    80001d9a:	079e                	slli	a5,a5,0x7
}
    80001d9c:	0022f517          	auipc	a0,0x22f
    80001da0:	f6450513          	addi	a0,a0,-156 # 80230d00 <cpus>
    80001da4:	953e                	add	a0,a0,a5
    80001da6:	6422                	ld	s0,8(sp)
    80001da8:	0141                	addi	sp,sp,16
    80001daa:	8082                	ret

0000000080001dac <myproc>:
{
    80001dac:	1101                	addi	sp,sp,-32
    80001dae:	ec06                	sd	ra,24(sp)
    80001db0:	e822                	sd	s0,16(sp)
    80001db2:	e426                	sd	s1,8(sp)
    80001db4:	1000                	addi	s0,sp,32
    push_off();
    80001db6:	fffff097          	auipc	ra,0xfffff
    80001dba:	fd6080e7          	jalr	-42(ra) # 80000d8c <push_off>
    80001dbe:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001dc0:	2781                	sext.w	a5,a5
    80001dc2:	079e                	slli	a5,a5,0x7
    80001dc4:	0022f717          	auipc	a4,0x22f
    80001dc8:	f3c70713          	addi	a4,a4,-196 # 80230d00 <cpus>
    80001dcc:	97ba                	add	a5,a5,a4
    80001dce:	6384                	ld	s1,0(a5)
    pop_off();
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	05c080e7          	jalr	92(ra) # 80000e2c <pop_off>
}
    80001dd8:	8526                	mv	a0,s1
    80001dda:	60e2                	ld	ra,24(sp)
    80001ddc:	6442                	ld	s0,16(sp)
    80001dde:	64a2                	ld	s1,8(sp)
    80001de0:	6105                	addi	sp,sp,32
    80001de2:	8082                	ret

0000000080001de4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001de4:	1141                	addi	sp,sp,-16
    80001de6:	e406                	sd	ra,8(sp)
    80001de8:	e022                	sd	s0,0(sp)
    80001dea:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001dec:	00000097          	auipc	ra,0x0
    80001df0:	fc0080e7          	jalr	-64(ra) # 80001dac <myproc>
    80001df4:	fffff097          	auipc	ra,0xfffff
    80001df8:	098080e7          	jalr	152(ra) # 80000e8c <release>

    if (first)
    80001dfc:	00007797          	auipc	a5,0x7
    80001e00:	bd47a783          	lw	a5,-1068(a5) # 800089d0 <first.1>
    80001e04:	eb89                	bnez	a5,80001e16 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001e06:	00001097          	auipc	ra,0x1
    80001e0a:	dfe080e7          	jalr	-514(ra) # 80002c04 <usertrapret>
}
    80001e0e:	60a2                	ld	ra,8(sp)
    80001e10:	6402                	ld	s0,0(sp)
    80001e12:	0141                	addi	sp,sp,16
    80001e14:	8082                	ret
        first = 0;
    80001e16:	00007797          	auipc	a5,0x7
    80001e1a:	ba07ad23          	sw	zero,-1094(a5) # 800089d0 <first.1>
        fsinit(ROOTDEV);
    80001e1e:	4505                	li	a0,1
    80001e20:	00002097          	auipc	ra,0x2
    80001e24:	d52080e7          	jalr	-686(ra) # 80003b72 <fsinit>
    80001e28:	bff9                	j	80001e06 <forkret+0x22>

0000000080001e2a <allocpid>:
{
    80001e2a:	1101                	addi	sp,sp,-32
    80001e2c:	ec06                	sd	ra,24(sp)
    80001e2e:	e822                	sd	s0,16(sp)
    80001e30:	e426                	sd	s1,8(sp)
    80001e32:	e04a                	sd	s2,0(sp)
    80001e34:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001e36:	0022f917          	auipc	s2,0x22f
    80001e3a:	2ca90913          	addi	s2,s2,714 # 80231100 <pid_lock>
    80001e3e:	854a                	mv	a0,s2
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	f98080e7          	jalr	-104(ra) # 80000dd8 <acquire>
    pid = nextpid;
    80001e48:	00007797          	auipc	a5,0x7
    80001e4c:	b9878793          	addi	a5,a5,-1128 # 800089e0 <nextpid>
    80001e50:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001e52:	0014871b          	addiw	a4,s1,1
    80001e56:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001e58:	854a                	mv	a0,s2
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	032080e7          	jalr	50(ra) # 80000e8c <release>
}
    80001e62:	8526                	mv	a0,s1
    80001e64:	60e2                	ld	ra,24(sp)
    80001e66:	6442                	ld	s0,16(sp)
    80001e68:	64a2                	ld	s1,8(sp)
    80001e6a:	6902                	ld	s2,0(sp)
    80001e6c:	6105                	addi	sp,sp,32
    80001e6e:	8082                	ret

0000000080001e70 <proc_pagetable>:
{
    80001e70:	1101                	addi	sp,sp,-32
    80001e72:	ec06                	sd	ra,24(sp)
    80001e74:	e822                	sd	s0,16(sp)
    80001e76:	e426                	sd	s1,8(sp)
    80001e78:	e04a                	sd	s2,0(sp)
    80001e7a:	1000                	addi	s0,sp,32
    80001e7c:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	6aa080e7          	jalr	1706(ra) # 80001528 <uvmcreate>
    80001e86:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001e88:	c121                	beqz	a0,80001ec8 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e8a:	4729                	li	a4,10
    80001e8c:	00005697          	auipc	a3,0x5
    80001e90:	17468693          	addi	a3,a3,372 # 80007000 <_trampoline>
    80001e94:	6605                	lui	a2,0x1
    80001e96:	040005b7          	lui	a1,0x4000
    80001e9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001e9c:	05b2                	slli	a1,a1,0xc
    80001e9e:	fffff097          	auipc	ra,0xfffff
    80001ea2:	400080e7          	jalr	1024(ra) # 8000129e <mappages>
    80001ea6:	02054863          	bltz	a0,80001ed6 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001eaa:	4719                	li	a4,6
    80001eac:	05893683          	ld	a3,88(s2)
    80001eb0:	6605                	lui	a2,0x1
    80001eb2:	020005b7          	lui	a1,0x2000
    80001eb6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001eb8:	05b6                	slli	a1,a1,0xd
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	3e2080e7          	jalr	994(ra) # 8000129e <mappages>
    80001ec4:	02054163          	bltz	a0,80001ee6 <proc_pagetable+0x76>
}
    80001ec8:	8526                	mv	a0,s1
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6902                	ld	s2,0(sp)
    80001ed2:	6105                	addi	sp,sp,32
    80001ed4:	8082                	ret
        uvmfree(pagetable, 0);
    80001ed6:	4581                	li	a1,0
    80001ed8:	8526                	mv	a0,s1
    80001eda:	00000097          	auipc	ra,0x0
    80001ede:	854080e7          	jalr	-1964(ra) # 8000172e <uvmfree>
        return 0;
    80001ee2:	4481                	li	s1,0
    80001ee4:	b7d5                	j	80001ec8 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ee6:	4681                	li	a3,0
    80001ee8:	4605                	li	a2,1
    80001eea:	040005b7          	lui	a1,0x4000
    80001eee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ef0:	05b2                	slli	a1,a1,0xc
    80001ef2:	8526                	mv	a0,s1
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	570080e7          	jalr	1392(ra) # 80001464 <uvmunmap>
        uvmfree(pagetable, 0);
    80001efc:	4581                	li	a1,0
    80001efe:	8526                	mv	a0,s1
    80001f00:	00000097          	auipc	ra,0x0
    80001f04:	82e080e7          	jalr	-2002(ra) # 8000172e <uvmfree>
        return 0;
    80001f08:	4481                	li	s1,0
    80001f0a:	bf7d                	j	80001ec8 <proc_pagetable+0x58>

0000000080001f0c <proc_freepagetable>:
{
    80001f0c:	1101                	addi	sp,sp,-32
    80001f0e:	ec06                	sd	ra,24(sp)
    80001f10:	e822                	sd	s0,16(sp)
    80001f12:	e426                	sd	s1,8(sp)
    80001f14:	e04a                	sd	s2,0(sp)
    80001f16:	1000                	addi	s0,sp,32
    80001f18:	84aa                	mv	s1,a0
    80001f1a:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f1c:	4681                	li	a3,0
    80001f1e:	4605                	li	a2,1
    80001f20:	040005b7          	lui	a1,0x4000
    80001f24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001f26:	05b2                	slli	a1,a1,0xc
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	53c080e7          	jalr	1340(ra) # 80001464 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f30:	4681                	li	a3,0
    80001f32:	4605                	li	a2,1
    80001f34:	020005b7          	lui	a1,0x2000
    80001f38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001f3a:	05b6                	slli	a1,a1,0xd
    80001f3c:	8526                	mv	a0,s1
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	526080e7          	jalr	1318(ra) # 80001464 <uvmunmap>
    uvmfree(pagetable, sz);
    80001f46:	85ca                	mv	a1,s2
    80001f48:	8526                	mv	a0,s1
    80001f4a:	fffff097          	auipc	ra,0xfffff
    80001f4e:	7e4080e7          	jalr	2020(ra) # 8000172e <uvmfree>
}
    80001f52:	60e2                	ld	ra,24(sp)
    80001f54:	6442                	ld	s0,16(sp)
    80001f56:	64a2                	ld	s1,8(sp)
    80001f58:	6902                	ld	s2,0(sp)
    80001f5a:	6105                	addi	sp,sp,32
    80001f5c:	8082                	ret

0000000080001f5e <freeproc>:
{
    80001f5e:	1101                	addi	sp,sp,-32
    80001f60:	ec06                	sd	ra,24(sp)
    80001f62:	e822                	sd	s0,16(sp)
    80001f64:	e426                	sd	s1,8(sp)
    80001f66:	1000                	addi	s0,sp,32
    80001f68:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001f6a:	6d28                	ld	a0,88(a0)
    80001f6c:	c509                	beqz	a0,80001f76 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001f6e:	fffff097          	auipc	ra,0xfffff
    80001f72:	b04080e7          	jalr	-1276(ra) # 80000a72 <kfree>
    p->trapframe = 0;
    80001f76:	0404bc23          	sd	zero,88(s1)
    if (p->pagetable)
    80001f7a:	68a8                	ld	a0,80(s1)
    80001f7c:	c511                	beqz	a0,80001f88 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001f7e:	64ac                	ld	a1,72(s1)
    80001f80:	00000097          	auipc	ra,0x0
    80001f84:	f8c080e7          	jalr	-116(ra) # 80001f0c <proc_freepagetable>
    p->pagetable = 0;
    80001f88:	0404b823          	sd	zero,80(s1)
    p->sz = 0;
    80001f8c:	0404b423          	sd	zero,72(s1)
    p->pid = 0;
    80001f90:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001f94:	0204bc23          	sd	zero,56(s1)
    p->name[0] = 0;
    80001f98:	14048c23          	sb	zero,344(s1)
    p->chan = 0;
    80001f9c:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001fa0:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001fa4:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001fa8:	0004ac23          	sw	zero,24(s1)
}
    80001fac:	60e2                	ld	ra,24(sp)
    80001fae:	6442                	ld	s0,16(sp)
    80001fb0:	64a2                	ld	s1,8(sp)
    80001fb2:	6105                	addi	sp,sp,32
    80001fb4:	8082                	ret

0000000080001fb6 <allocproc>:
{
    80001fb6:	1101                	addi	sp,sp,-32
    80001fb8:	ec06                	sd	ra,24(sp)
    80001fba:	e822                	sd	s0,16(sp)
    80001fbc:	e426                	sd	s1,8(sp)
    80001fbe:	e04a                	sd	s2,0(sp)
    80001fc0:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001fc2:	0022f497          	auipc	s1,0x22f
    80001fc6:	16e48493          	addi	s1,s1,366 # 80231130 <proc>
    80001fca:	00235917          	auipc	s2,0x235
    80001fce:	b6690913          	addi	s2,s2,-1178 # 80236b30 <tickslock>
        acquire(&p->lock);
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	e04080e7          	jalr	-508(ra) # 80000dd8 <acquire>
        if (p->state == UNUSED)
    80001fdc:	4c9c                	lw	a5,24(s1)
    80001fde:	cf81                	beqz	a5,80001ff6 <allocproc+0x40>
            release(&p->lock);
    80001fe0:	8526                	mv	a0,s1
    80001fe2:	fffff097          	auipc	ra,0xfffff
    80001fe6:	eaa080e7          	jalr	-342(ra) # 80000e8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001fea:	16848493          	addi	s1,s1,360
    80001fee:	ff2492e3          	bne	s1,s2,80001fd2 <allocproc+0x1c>
    return 0;
    80001ff2:	4481                	li	s1,0
    80001ff4:	a889                	j	80002046 <allocproc+0x90>
    p->pid = allocpid();
    80001ff6:	00000097          	auipc	ra,0x0
    80001ffa:	e34080e7          	jalr	-460(ra) # 80001e2a <allocpid>
    80001ffe:	d888                	sw	a0,48(s1)
    p->state = USED;
    80002000:	4785                	li	a5,1
    80002002:	cc9c                	sw	a5,24(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80002004:	fffff097          	auipc	ra,0xfffff
    80002008:	c5a080e7          	jalr	-934(ra) # 80000c5e <kalloc>
    8000200c:	892a                	mv	s2,a0
    8000200e:	eca8                	sd	a0,88(s1)
    80002010:	c131                	beqz	a0,80002054 <allocproc+0x9e>
    p->pagetable = proc_pagetable(p);
    80002012:	8526                	mv	a0,s1
    80002014:	00000097          	auipc	ra,0x0
    80002018:	e5c080e7          	jalr	-420(ra) # 80001e70 <proc_pagetable>
    8000201c:	892a                	mv	s2,a0
    8000201e:	e8a8                	sd	a0,80(s1)
    if (p->pagetable == 0)
    80002020:	c531                	beqz	a0,8000206c <allocproc+0xb6>
    memset(&p->context, 0, sizeof(p->context));
    80002022:	07000613          	li	a2,112
    80002026:	4581                	li	a1,0
    80002028:	06048513          	addi	a0,s1,96
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	ea8080e7          	jalr	-344(ra) # 80000ed4 <memset>
    p->context.ra = (uint64)forkret;
    80002034:	00000797          	auipc	a5,0x0
    80002038:	db078793          	addi	a5,a5,-592 # 80001de4 <forkret>
    8000203c:	f0bc                	sd	a5,96(s1)
    p->context.sp = p->kstack + PGSIZE;
    8000203e:	60bc                	ld	a5,64(s1)
    80002040:	6705                	lui	a4,0x1
    80002042:	97ba                	add	a5,a5,a4
    80002044:	f4bc                	sd	a5,104(s1)
}
    80002046:	8526                	mv	a0,s1
    80002048:	60e2                	ld	ra,24(sp)
    8000204a:	6442                	ld	s0,16(sp)
    8000204c:	64a2                	ld	s1,8(sp)
    8000204e:	6902                	ld	s2,0(sp)
    80002050:	6105                	addi	sp,sp,32
    80002052:	8082                	ret
        freeproc(p);
    80002054:	8526                	mv	a0,s1
    80002056:	00000097          	auipc	ra,0x0
    8000205a:	f08080e7          	jalr	-248(ra) # 80001f5e <freeproc>
        release(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	e2c080e7          	jalr	-468(ra) # 80000e8c <release>
        return 0;
    80002068:	84ca                	mv	s1,s2
    8000206a:	bff1                	j	80002046 <allocproc+0x90>
        freeproc(p);
    8000206c:	8526                	mv	a0,s1
    8000206e:	00000097          	auipc	ra,0x0
    80002072:	ef0080e7          	jalr	-272(ra) # 80001f5e <freeproc>
        release(&p->lock);
    80002076:	8526                	mv	a0,s1
    80002078:	fffff097          	auipc	ra,0xfffff
    8000207c:	e14080e7          	jalr	-492(ra) # 80000e8c <release>
        return 0;
    80002080:	84ca                	mv	s1,s2
    80002082:	b7d1                	j	80002046 <allocproc+0x90>

0000000080002084 <userinit>:
{
    80002084:	1101                	addi	sp,sp,-32
    80002086:	ec06                	sd	ra,24(sp)
    80002088:	e822                	sd	s0,16(sp)
    8000208a:	e426                	sd	s1,8(sp)
    8000208c:	1000                	addi	s0,sp,32
    p = allocproc();
    8000208e:	00000097          	auipc	ra,0x0
    80002092:	f28080e7          	jalr	-216(ra) # 80001fb6 <allocproc>
    80002096:	84aa                	mv	s1,a0
    initproc = p;
    80002098:	00007797          	auipc	a5,0x7
    8000209c:	9ea7b823          	sd	a0,-1552(a5) # 80008a88 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    800020a0:	03400613          	li	a2,52
    800020a4:	00007597          	auipc	a1,0x7
    800020a8:	94c58593          	addi	a1,a1,-1716 # 800089f0 <initcode>
    800020ac:	6928                	ld	a0,80(a0)
    800020ae:	fffff097          	auipc	ra,0xfffff
    800020b2:	4a8080e7          	jalr	1192(ra) # 80001556 <uvmfirst>
    p->sz = PGSIZE;
    800020b6:	6785                	lui	a5,0x1
    800020b8:	e4bc                	sd	a5,72(s1)
    p->trapframe->epc = 0;     // user program counter
    800020ba:	6cb8                	ld	a4,88(s1)
    800020bc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    800020c0:	6cb8                	ld	a4,88(s1)
    800020c2:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    800020c4:	4641                	li	a2,16
    800020c6:	00006597          	auipc	a1,0x6
    800020ca:	1a258593          	addi	a1,a1,418 # 80008268 <digits+0x218>
    800020ce:	15848513          	addi	a0,s1,344
    800020d2:	fffff097          	auipc	ra,0xfffff
    800020d6:	f4a080e7          	jalr	-182(ra) # 8000101c <safestrcpy>
    p->cwd = namei("/");
    800020da:	00006517          	auipc	a0,0x6
    800020de:	19e50513          	addi	a0,a0,414 # 80008278 <digits+0x228>
    800020e2:	00002097          	auipc	ra,0x2
    800020e6:	4ae080e7          	jalr	1198(ra) # 80004590 <namei>
    800020ea:	14a4b823          	sd	a0,336(s1)
    p->state = RUNNABLE;
    800020ee:	478d                	li	a5,3
    800020f0:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    800020f2:	8526                	mv	a0,s1
    800020f4:	fffff097          	auipc	ra,0xfffff
    800020f8:	d98080e7          	jalr	-616(ra) # 80000e8c <release>
}
    800020fc:	60e2                	ld	ra,24(sp)
    800020fe:	6442                	ld	s0,16(sp)
    80002100:	64a2                	ld	s1,8(sp)
    80002102:	6105                	addi	sp,sp,32
    80002104:	8082                	ret

0000000080002106 <growproc>:
{
    80002106:	1101                	addi	sp,sp,-32
    80002108:	ec06                	sd	ra,24(sp)
    8000210a:	e822                	sd	s0,16(sp)
    8000210c:	e426                	sd	s1,8(sp)
    8000210e:	e04a                	sd	s2,0(sp)
    80002110:	1000                	addi	s0,sp,32
    80002112:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80002114:	00000097          	auipc	ra,0x0
    80002118:	c98080e7          	jalr	-872(ra) # 80001dac <myproc>
    8000211c:	84aa                	mv	s1,a0
    sz = p->sz;
    8000211e:	652c                	ld	a1,72(a0)
    if (n > 0)
    80002120:	01204c63          	bgtz	s2,80002138 <growproc+0x32>
    else if (n < 0)
    80002124:	02094663          	bltz	s2,80002150 <growproc+0x4a>
    p->sz = sz;
    80002128:	e4ac                	sd	a1,72(s1)
    return 0;
    8000212a:	4501                	li	a0,0
}
    8000212c:	60e2                	ld	ra,24(sp)
    8000212e:	6442                	ld	s0,16(sp)
    80002130:	64a2                	ld	s1,8(sp)
    80002132:	6902                	ld	s2,0(sp)
    80002134:	6105                	addi	sp,sp,32
    80002136:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002138:	4691                	li	a3,4
    8000213a:	00b90633          	add	a2,s2,a1
    8000213e:	6928                	ld	a0,80(a0)
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	4d0080e7          	jalr	1232(ra) # 80001610 <uvmalloc>
    80002148:	85aa                	mv	a1,a0
    8000214a:	fd79                	bnez	a0,80002128 <growproc+0x22>
            return -1;
    8000214c:	557d                	li	a0,-1
    8000214e:	bff9                	j	8000212c <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002150:	00b90633          	add	a2,s2,a1
    80002154:	6928                	ld	a0,80(a0)
    80002156:	fffff097          	auipc	ra,0xfffff
    8000215a:	472080e7          	jalr	1138(ra) # 800015c8 <uvmdealloc>
    8000215e:	85aa                	mv	a1,a0
    80002160:	b7e1                	j	80002128 <growproc+0x22>

0000000080002162 <ps>:
{
    80002162:	715d                	addi	sp,sp,-80
    80002164:	e486                	sd	ra,72(sp)
    80002166:	e0a2                	sd	s0,64(sp)
    80002168:	fc26                	sd	s1,56(sp)
    8000216a:	f84a                	sd	s2,48(sp)
    8000216c:	f44e                	sd	s3,40(sp)
    8000216e:	f052                	sd	s4,32(sp)
    80002170:	ec56                	sd	s5,24(sp)
    80002172:	e85a                	sd	s6,16(sp)
    80002174:	e45e                	sd	s7,8(sp)
    80002176:	e062                	sd	s8,0(sp)
    80002178:	0880                	addi	s0,sp,80
    8000217a:	84aa                	mv	s1,a0
    8000217c:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    8000217e:	00000097          	auipc	ra,0x0
    80002182:	c2e080e7          	jalr	-978(ra) # 80001dac <myproc>
    if (count == 0)
    80002186:	120b8063          	beqz	s7,800022a6 <ps+0x144>
    void *result = (void *)myproc()->sz;
    8000218a:	04853b03          	ld	s6,72(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    8000218e:	003b951b          	slliw	a0,s7,0x3
    80002192:	0175053b          	addw	a0,a0,s7
    80002196:	0025151b          	slliw	a0,a0,0x2
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	f6c080e7          	jalr	-148(ra) # 80002106 <growproc>
    800021a2:	10054463          	bltz	a0,800022aa <ps+0x148>
    struct user_proc loc_result[count];
    800021a6:	003b9a13          	slli	s4,s7,0x3
    800021aa:	9a5e                	add	s4,s4,s7
    800021ac:	0a0a                	slli	s4,s4,0x2
    800021ae:	00fa0793          	addi	a5,s4,15
    800021b2:	8391                	srli	a5,a5,0x4
    800021b4:	0792                	slli	a5,a5,0x4
    800021b6:	40f10133          	sub	sp,sp,a5
    800021ba:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    800021bc:	007e97b7          	lui	a5,0x7e9
    800021c0:	02f484b3          	mul	s1,s1,a5
    800021c4:	0022f797          	auipc	a5,0x22f
    800021c8:	f6c78793          	addi	a5,a5,-148 # 80231130 <proc>
    800021cc:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    800021ce:	00235797          	auipc	a5,0x235
    800021d2:	96278793          	addi	a5,a5,-1694 # 80236b30 <tickslock>
    800021d6:	0cf4fc63          	bgeu	s1,a5,800022ae <ps+0x14c>
        if (localCount == count)
    800021da:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    800021de:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    800021e0:	8c3e                	mv	s8,a5
    800021e2:	a069                	j	8000226c <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    800021e4:	00399793          	slli	a5,s3,0x3
    800021e8:	97ce                	add	a5,a5,s3
    800021ea:	078a                	slli	a5,a5,0x2
    800021ec:	97d6                	add	a5,a5,s5
    800021ee:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    800021f2:	8526                	mv	a0,s1
    800021f4:	fffff097          	auipc	ra,0xfffff
    800021f8:	c98080e7          	jalr	-872(ra) # 80000e8c <release>
    if (localCount < count)
    800021fc:	0179f963          	bgeu	s3,s7,8000220e <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80002200:	00399793          	slli	a5,s3,0x3
    80002204:	97ce                	add	a5,a5,s3
    80002206:	078a                	slli	a5,a5,0x2
    80002208:	97d6                	add	a5,a5,s5
    8000220a:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    8000220e:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80002210:	00000097          	auipc	ra,0x0
    80002214:	b9c080e7          	jalr	-1124(ra) # 80001dac <myproc>
    80002218:	86d2                	mv	a3,s4
    8000221a:	8656                	mv	a2,s5
    8000221c:	85da                	mv	a1,s6
    8000221e:	6928                	ld	a0,80(a0)
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	704080e7          	jalr	1796(ra) # 80001924 <copyout>
}
    80002228:	8526                	mv	a0,s1
    8000222a:	fb040113          	addi	sp,s0,-80
    8000222e:	60a6                	ld	ra,72(sp)
    80002230:	6406                	ld	s0,64(sp)
    80002232:	74e2                	ld	s1,56(sp)
    80002234:	7942                	ld	s2,48(sp)
    80002236:	79a2                	ld	s3,40(sp)
    80002238:	7a02                	ld	s4,32(sp)
    8000223a:	6ae2                	ld	s5,24(sp)
    8000223c:	6b42                	ld	s6,16(sp)
    8000223e:	6ba2                	ld	s7,8(sp)
    80002240:	6c02                	ld	s8,0(sp)
    80002242:	6161                	addi	sp,sp,80
    80002244:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80002246:	5b9c                	lw	a5,48(a5)
    80002248:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    8000224c:	8526                	mv	a0,s1
    8000224e:	fffff097          	auipc	ra,0xfffff
    80002252:	c3e080e7          	jalr	-962(ra) # 80000e8c <release>
        localCount++;
    80002256:	2985                	addiw	s3,s3,1
    80002258:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    8000225c:	16848493          	addi	s1,s1,360
    80002260:	f984fee3          	bgeu	s1,s8,800021fc <ps+0x9a>
        if (localCount == count)
    80002264:	02490913          	addi	s2,s2,36
    80002268:	fb3b83e3          	beq	s7,s3,8000220e <ps+0xac>
        acquire(&p->lock);
    8000226c:	8526                	mv	a0,s1
    8000226e:	fffff097          	auipc	ra,0xfffff
    80002272:	b6a080e7          	jalr	-1174(ra) # 80000dd8 <acquire>
        if (p->state == UNUSED)
    80002276:	4c9c                	lw	a5,24(s1)
    80002278:	d7b5                	beqz	a5,800021e4 <ps+0x82>
        loc_result[localCount].state = p->state;
    8000227a:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    8000227e:	549c                	lw	a5,40(s1)
    80002280:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80002284:	54dc                	lw	a5,44(s1)
    80002286:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    8000228a:	589c                	lw	a5,48(s1)
    8000228c:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80002290:	4641                	li	a2,16
    80002292:	85ca                	mv	a1,s2
    80002294:	15848513          	addi	a0,s1,344
    80002298:	00000097          	auipc	ra,0x0
    8000229c:	ac4080e7          	jalr	-1340(ra) # 80001d5c <copy_array>
        if (p->parent != 0) // init
    800022a0:	7c9c                	ld	a5,56(s1)
    800022a2:	f3d5                	bnez	a5,80002246 <ps+0xe4>
    800022a4:	b765                	j	8000224c <ps+0xea>
        return result;
    800022a6:	4481                	li	s1,0
    800022a8:	b741                	j	80002228 <ps+0xc6>
        return result;
    800022aa:	4481                	li	s1,0
    800022ac:	bfb5                	j	80002228 <ps+0xc6>
        return result;
    800022ae:	4481                	li	s1,0
    800022b0:	bfa5                	j	80002228 <ps+0xc6>

00000000800022b2 <fork>:
{
    800022b2:	7139                	addi	sp,sp,-64
    800022b4:	fc06                	sd	ra,56(sp)
    800022b6:	f822                	sd	s0,48(sp)
    800022b8:	f426                	sd	s1,40(sp)
    800022ba:	f04a                	sd	s2,32(sp)
    800022bc:	ec4e                	sd	s3,24(sp)
    800022be:	e852                	sd	s4,16(sp)
    800022c0:	e456                	sd	s5,8(sp)
    800022c2:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    800022c4:	00000097          	auipc	ra,0x0
    800022c8:	ae8080e7          	jalr	-1304(ra) # 80001dac <myproc>
    800022cc:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    800022ce:	00000097          	auipc	ra,0x0
    800022d2:	ce8080e7          	jalr	-792(ra) # 80001fb6 <allocproc>
    800022d6:	10050c63          	beqz	a0,800023ee <fork+0x13c>
    800022da:	8a2a                	mv	s4,a0
    if (uvmshare(p->pagetable, np->pagetable, p->sz) < 0)
    800022dc:	048ab603          	ld	a2,72(s5)
    800022e0:	692c                	ld	a1,80(a0)
    800022e2:	050ab503          	ld	a0,80(s5)
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	554080e7          	jalr	1364(ra) # 8000183a <uvmshare>
    800022ee:	04054863          	bltz	a0,8000233e <fork+0x8c>
    np->sz = p->sz;
    800022f2:	048ab783          	ld	a5,72(s5)
    800022f6:	04fa3423          	sd	a5,72(s4)
    *(np->trapframe) = *(p->trapframe);
    800022fa:	058ab683          	ld	a3,88(s5)
    800022fe:	87b6                	mv	a5,a3
    80002300:	058a3703          	ld	a4,88(s4)
    80002304:	12068693          	addi	a3,a3,288
    80002308:	0007b803          	ld	a6,0(a5)
    8000230c:	6788                	ld	a0,8(a5)
    8000230e:	6b8c                	ld	a1,16(a5)
    80002310:	6f90                	ld	a2,24(a5)
    80002312:	01073023          	sd	a6,0(a4)
    80002316:	e708                	sd	a0,8(a4)
    80002318:	eb0c                	sd	a1,16(a4)
    8000231a:	ef10                	sd	a2,24(a4)
    8000231c:	02078793          	addi	a5,a5,32
    80002320:	02070713          	addi	a4,a4,32
    80002324:	fed792e3          	bne	a5,a3,80002308 <fork+0x56>
    np->trapframe->a0 = 0;
    80002328:	058a3783          	ld	a5,88(s4)
    8000232c:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002330:	0d0a8493          	addi	s1,s5,208
    80002334:	0d0a0913          	addi	s2,s4,208
    80002338:	150a8993          	addi	s3,s5,336
    8000233c:	a00d                	j	8000235e <fork+0xac>
        freeproc(np);
    8000233e:	8552                	mv	a0,s4
    80002340:	00000097          	auipc	ra,0x0
    80002344:	c1e080e7          	jalr	-994(ra) # 80001f5e <freeproc>
        release(&np->lock);
    80002348:	8552                	mv	a0,s4
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	b42080e7          	jalr	-1214(ra) # 80000e8c <release>
        return -1;
    80002352:	597d                	li	s2,-1
    80002354:	a059                	j	800023da <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002356:	04a1                	addi	s1,s1,8
    80002358:	0921                	addi	s2,s2,8
    8000235a:	01348b63          	beq	s1,s3,80002370 <fork+0xbe>
        if (p->ofile[i])
    8000235e:	6088                	ld	a0,0(s1)
    80002360:	d97d                	beqz	a0,80002356 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002362:	00003097          	auipc	ra,0x3
    80002366:	8a0080e7          	jalr	-1888(ra) # 80004c02 <filedup>
    8000236a:	00a93023          	sd	a0,0(s2)
    8000236e:	b7e5                	j	80002356 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002370:	150ab503          	ld	a0,336(s5)
    80002374:	00002097          	auipc	ra,0x2
    80002378:	a38080e7          	jalr	-1480(ra) # 80003dac <idup>
    8000237c:	14aa3823          	sd	a0,336(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002380:	4641                	li	a2,16
    80002382:	158a8593          	addi	a1,s5,344
    80002386:	158a0513          	addi	a0,s4,344
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	c92080e7          	jalr	-878(ra) # 8000101c <safestrcpy>
    pid = np->pid;
    80002392:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002396:	8552                	mv	a0,s4
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	af4080e7          	jalr	-1292(ra) # 80000e8c <release>
    acquire(&wait_lock);
    800023a0:	0022f497          	auipc	s1,0x22f
    800023a4:	d7848493          	addi	s1,s1,-648 # 80231118 <wait_lock>
    800023a8:	8526                	mv	a0,s1
    800023aa:	fffff097          	auipc	ra,0xfffff
    800023ae:	a2e080e7          	jalr	-1490(ra) # 80000dd8 <acquire>
    np->parent = p;
    800023b2:	035a3c23          	sd	s5,56(s4)
    release(&wait_lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	ad4080e7          	jalr	-1324(ra) # 80000e8c <release>
    acquire(&np->lock);
    800023c0:	8552                	mv	a0,s4
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	a16080e7          	jalr	-1514(ra) # 80000dd8 <acquire>
    np->state = RUNNABLE;
    800023ca:	478d                	li	a5,3
    800023cc:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800023d0:	8552                	mv	a0,s4
    800023d2:	fffff097          	auipc	ra,0xfffff
    800023d6:	aba080e7          	jalr	-1350(ra) # 80000e8c <release>
}
    800023da:	854a                	mv	a0,s2
    800023dc:	70e2                	ld	ra,56(sp)
    800023de:	7442                	ld	s0,48(sp)
    800023e0:	74a2                	ld	s1,40(sp)
    800023e2:	7902                	ld	s2,32(sp)
    800023e4:	69e2                	ld	s3,24(sp)
    800023e6:	6a42                	ld	s4,16(sp)
    800023e8:	6aa2                	ld	s5,8(sp)
    800023ea:	6121                	addi	sp,sp,64
    800023ec:	8082                	ret
        return -1;
    800023ee:	597d                	li	s2,-1
    800023f0:	b7ed                	j	800023da <fork+0x128>

00000000800023f2 <scheduler>:
{
    800023f2:	1101                	addi	sp,sp,-32
    800023f4:	ec06                	sd	ra,24(sp)
    800023f6:	e822                	sd	s0,16(sp)
    800023f8:	e426                	sd	s1,8(sp)
    800023fa:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800023fc:	00006497          	auipc	s1,0x6
    80002400:	5dc48493          	addi	s1,s1,1500 # 800089d8 <sched_pointer>
    80002404:	609c                	ld	a5,0(s1)
    80002406:	9782                	jalr	a5
    while (1)
    80002408:	bff5                	j	80002404 <scheduler+0x12>

000000008000240a <sched>:
{
    8000240a:	7179                	addi	sp,sp,-48
    8000240c:	f406                	sd	ra,40(sp)
    8000240e:	f022                	sd	s0,32(sp)
    80002410:	ec26                	sd	s1,24(sp)
    80002412:	e84a                	sd	s2,16(sp)
    80002414:	e44e                	sd	s3,8(sp)
    80002416:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002418:	00000097          	auipc	ra,0x0
    8000241c:	994080e7          	jalr	-1644(ra) # 80001dac <myproc>
    80002420:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	93c080e7          	jalr	-1732(ra) # 80000d5e <holding>
    8000242a:	c53d                	beqz	a0,80002498 <sched+0x8e>
    8000242c:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    8000242e:	2781                	sext.w	a5,a5
    80002430:	079e                	slli	a5,a5,0x7
    80002432:	0022f717          	auipc	a4,0x22f
    80002436:	8ce70713          	addi	a4,a4,-1842 # 80230d00 <cpus>
    8000243a:	97ba                	add	a5,a5,a4
    8000243c:	5fb8                	lw	a4,120(a5)
    8000243e:	4785                	li	a5,1
    80002440:	06f71463          	bne	a4,a5,800024a8 <sched+0x9e>
    if (p->state == RUNNING)
    80002444:	4c98                	lw	a4,24(s1)
    80002446:	4791                	li	a5,4
    80002448:	06f70863          	beq	a4,a5,800024b8 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000244c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002450:	8b89                	andi	a5,a5,2
    if (intr_get())
    80002452:	ebbd                	bnez	a5,800024c8 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002454:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    80002456:	0022f917          	auipc	s2,0x22f
    8000245a:	8aa90913          	addi	s2,s2,-1878 # 80230d00 <cpus>
    8000245e:	2781                	sext.w	a5,a5
    80002460:	079e                	slli	a5,a5,0x7
    80002462:	97ca                	add	a5,a5,s2
    80002464:	07c7a983          	lw	s3,124(a5)
    80002468:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    8000246a:	2581                	sext.w	a1,a1
    8000246c:	059e                	slli	a1,a1,0x7
    8000246e:	05a1                	addi	a1,a1,8
    80002470:	95ca                	add	a1,a1,s2
    80002472:	06048513          	addi	a0,s1,96
    80002476:	00000097          	auipc	ra,0x0
    8000247a:	6e4080e7          	jalr	1764(ra) # 80002b5a <swtch>
    8000247e:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    80002480:	2781                	sext.w	a5,a5
    80002482:	079e                	slli	a5,a5,0x7
    80002484:	993e                	add	s2,s2,a5
    80002486:	07392e23          	sw	s3,124(s2)
}
    8000248a:	70a2                	ld	ra,40(sp)
    8000248c:	7402                	ld	s0,32(sp)
    8000248e:	64e2                	ld	s1,24(sp)
    80002490:	6942                	ld	s2,16(sp)
    80002492:	69a2                	ld	s3,8(sp)
    80002494:	6145                	addi	sp,sp,48
    80002496:	8082                	ret
        panic("sched p->lock");
    80002498:	00006517          	auipc	a0,0x6
    8000249c:	de850513          	addi	a0,a0,-536 # 80008280 <digits+0x230>
    800024a0:	ffffe097          	auipc	ra,0xffffe
    800024a4:	09c080e7          	jalr	156(ra) # 8000053c <panic>
        panic("sched locks");
    800024a8:	00006517          	auipc	a0,0x6
    800024ac:	de850513          	addi	a0,a0,-536 # 80008290 <digits+0x240>
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	08c080e7          	jalr	140(ra) # 8000053c <panic>
        panic("sched running");
    800024b8:	00006517          	auipc	a0,0x6
    800024bc:	de850513          	addi	a0,a0,-536 # 800082a0 <digits+0x250>
    800024c0:	ffffe097          	auipc	ra,0xffffe
    800024c4:	07c080e7          	jalr	124(ra) # 8000053c <panic>
        panic("sched interruptible");
    800024c8:	00006517          	auipc	a0,0x6
    800024cc:	de850513          	addi	a0,a0,-536 # 800082b0 <digits+0x260>
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	06c080e7          	jalr	108(ra) # 8000053c <panic>

00000000800024d8 <yield>:
{
    800024d8:	1101                	addi	sp,sp,-32
    800024da:	ec06                	sd	ra,24(sp)
    800024dc:	e822                	sd	s0,16(sp)
    800024de:	e426                	sd	s1,8(sp)
    800024e0:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    800024e2:	00000097          	auipc	ra,0x0
    800024e6:	8ca080e7          	jalr	-1846(ra) # 80001dac <myproc>
    800024ea:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800024ec:	fffff097          	auipc	ra,0xfffff
    800024f0:	8ec080e7          	jalr	-1812(ra) # 80000dd8 <acquire>
    p->state = RUNNABLE;
    800024f4:	478d                	li	a5,3
    800024f6:	cc9c                	sw	a5,24(s1)
    sched();
    800024f8:	00000097          	auipc	ra,0x0
    800024fc:	f12080e7          	jalr	-238(ra) # 8000240a <sched>
    release(&p->lock);
    80002500:	8526                	mv	a0,s1
    80002502:	fffff097          	auipc	ra,0xfffff
    80002506:	98a080e7          	jalr	-1654(ra) # 80000e8c <release>
}
    8000250a:	60e2                	ld	ra,24(sp)
    8000250c:	6442                	ld	s0,16(sp)
    8000250e:	64a2                	ld	s1,8(sp)
    80002510:	6105                	addi	sp,sp,32
    80002512:	8082                	ret

0000000080002514 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002514:	7179                	addi	sp,sp,-48
    80002516:	f406                	sd	ra,40(sp)
    80002518:	f022                	sd	s0,32(sp)
    8000251a:	ec26                	sd	s1,24(sp)
    8000251c:	e84a                	sd	s2,16(sp)
    8000251e:	e44e                	sd	s3,8(sp)
    80002520:	1800                	addi	s0,sp,48
    80002522:	89aa                	mv	s3,a0
    80002524:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002526:	00000097          	auipc	ra,0x0
    8000252a:	886080e7          	jalr	-1914(ra) # 80001dac <myproc>
    8000252e:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	8a8080e7          	jalr	-1880(ra) # 80000dd8 <acquire>
    release(lk);
    80002538:	854a                	mv	a0,s2
    8000253a:	fffff097          	auipc	ra,0xfffff
    8000253e:	952080e7          	jalr	-1710(ra) # 80000e8c <release>

    // Go to sleep.
    p->chan = chan;
    80002542:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    80002546:	4789                	li	a5,2
    80002548:	cc9c                	sw	a5,24(s1)

    sched();
    8000254a:	00000097          	auipc	ra,0x0
    8000254e:	ec0080e7          	jalr	-320(ra) # 8000240a <sched>

    // Tidy up.
    p->chan = 0;
    80002552:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    80002556:	8526                	mv	a0,s1
    80002558:	fffff097          	auipc	ra,0xfffff
    8000255c:	934080e7          	jalr	-1740(ra) # 80000e8c <release>
    acquire(lk);
    80002560:	854a                	mv	a0,s2
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	876080e7          	jalr	-1930(ra) # 80000dd8 <acquire>
}
    8000256a:	70a2                	ld	ra,40(sp)
    8000256c:	7402                	ld	s0,32(sp)
    8000256e:	64e2                	ld	s1,24(sp)
    80002570:	6942                	ld	s2,16(sp)
    80002572:	69a2                	ld	s3,8(sp)
    80002574:	6145                	addi	sp,sp,48
    80002576:	8082                	ret

0000000080002578 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002578:	7139                	addi	sp,sp,-64
    8000257a:	fc06                	sd	ra,56(sp)
    8000257c:	f822                	sd	s0,48(sp)
    8000257e:	f426                	sd	s1,40(sp)
    80002580:	f04a                	sd	s2,32(sp)
    80002582:	ec4e                	sd	s3,24(sp)
    80002584:	e852                	sd	s4,16(sp)
    80002586:	e456                	sd	s5,8(sp)
    80002588:	0080                	addi	s0,sp,64
    8000258a:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000258c:	0022f497          	auipc	s1,0x22f
    80002590:	ba448493          	addi	s1,s1,-1116 # 80231130 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    80002594:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    80002596:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    80002598:	00234917          	auipc	s2,0x234
    8000259c:	59890913          	addi	s2,s2,1432 # 80236b30 <tickslock>
    800025a0:	a811                	j	800025b4 <wakeup+0x3c>
            }
            release(&p->lock);
    800025a2:	8526                	mv	a0,s1
    800025a4:	fffff097          	auipc	ra,0xfffff
    800025a8:	8e8080e7          	jalr	-1816(ra) # 80000e8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800025ac:	16848493          	addi	s1,s1,360
    800025b0:	03248663          	beq	s1,s2,800025dc <wakeup+0x64>
        if (p != myproc())
    800025b4:	fffff097          	auipc	ra,0xfffff
    800025b8:	7f8080e7          	jalr	2040(ra) # 80001dac <myproc>
    800025bc:	fea488e3          	beq	s1,a0,800025ac <wakeup+0x34>
            acquire(&p->lock);
    800025c0:	8526                	mv	a0,s1
    800025c2:	fffff097          	auipc	ra,0xfffff
    800025c6:	816080e7          	jalr	-2026(ra) # 80000dd8 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    800025ca:	4c9c                	lw	a5,24(s1)
    800025cc:	fd379be3          	bne	a5,s3,800025a2 <wakeup+0x2a>
    800025d0:	709c                	ld	a5,32(s1)
    800025d2:	fd4798e3          	bne	a5,s4,800025a2 <wakeup+0x2a>
                p->state = RUNNABLE;
    800025d6:	0154ac23          	sw	s5,24(s1)
    800025da:	b7e1                	j	800025a2 <wakeup+0x2a>
        }
    }
}
    800025dc:	70e2                	ld	ra,56(sp)
    800025de:	7442                	ld	s0,48(sp)
    800025e0:	74a2                	ld	s1,40(sp)
    800025e2:	7902                	ld	s2,32(sp)
    800025e4:	69e2                	ld	s3,24(sp)
    800025e6:	6a42                	ld	s4,16(sp)
    800025e8:	6aa2                	ld	s5,8(sp)
    800025ea:	6121                	addi	sp,sp,64
    800025ec:	8082                	ret

00000000800025ee <reparent>:
{
    800025ee:	7179                	addi	sp,sp,-48
    800025f0:	f406                	sd	ra,40(sp)
    800025f2:	f022                	sd	s0,32(sp)
    800025f4:	ec26                	sd	s1,24(sp)
    800025f6:	e84a                	sd	s2,16(sp)
    800025f8:	e44e                	sd	s3,8(sp)
    800025fa:	e052                	sd	s4,0(sp)
    800025fc:	1800                	addi	s0,sp,48
    800025fe:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002600:	0022f497          	auipc	s1,0x22f
    80002604:	b3048493          	addi	s1,s1,-1232 # 80231130 <proc>
            pp->parent = initproc;
    80002608:	00006a17          	auipc	s4,0x6
    8000260c:	480a0a13          	addi	s4,s4,1152 # 80008a88 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002610:	00234997          	auipc	s3,0x234
    80002614:	52098993          	addi	s3,s3,1312 # 80236b30 <tickslock>
    80002618:	a029                	j	80002622 <reparent+0x34>
    8000261a:	16848493          	addi	s1,s1,360
    8000261e:	01348d63          	beq	s1,s3,80002638 <reparent+0x4a>
        if (pp->parent == p)
    80002622:	7c9c                	ld	a5,56(s1)
    80002624:	ff279be3          	bne	a5,s2,8000261a <reparent+0x2c>
            pp->parent = initproc;
    80002628:	000a3503          	ld	a0,0(s4)
    8000262c:	fc88                	sd	a0,56(s1)
            wakeup(initproc);
    8000262e:	00000097          	auipc	ra,0x0
    80002632:	f4a080e7          	jalr	-182(ra) # 80002578 <wakeup>
    80002636:	b7d5                	j	8000261a <reparent+0x2c>
}
    80002638:	70a2                	ld	ra,40(sp)
    8000263a:	7402                	ld	s0,32(sp)
    8000263c:	64e2                	ld	s1,24(sp)
    8000263e:	6942                	ld	s2,16(sp)
    80002640:	69a2                	ld	s3,8(sp)
    80002642:	6a02                	ld	s4,0(sp)
    80002644:	6145                	addi	sp,sp,48
    80002646:	8082                	ret

0000000080002648 <exit>:
{
    80002648:	7179                	addi	sp,sp,-48
    8000264a:	f406                	sd	ra,40(sp)
    8000264c:	f022                	sd	s0,32(sp)
    8000264e:	ec26                	sd	s1,24(sp)
    80002650:	e84a                	sd	s2,16(sp)
    80002652:	e44e                	sd	s3,8(sp)
    80002654:	e052                	sd	s4,0(sp)
    80002656:	1800                	addi	s0,sp,48
    80002658:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    8000265a:	fffff097          	auipc	ra,0xfffff
    8000265e:	752080e7          	jalr	1874(ra) # 80001dac <myproc>
    80002662:	89aa                	mv	s3,a0
    if (p == initproc)
    80002664:	00006797          	auipc	a5,0x6
    80002668:	4247b783          	ld	a5,1060(a5) # 80008a88 <initproc>
    8000266c:	0d050493          	addi	s1,a0,208
    80002670:	15050913          	addi	s2,a0,336
    80002674:	02a79363          	bne	a5,a0,8000269a <exit+0x52>
        panic("init exiting");
    80002678:	00006517          	auipc	a0,0x6
    8000267c:	c5050513          	addi	a0,a0,-944 # 800082c8 <digits+0x278>
    80002680:	ffffe097          	auipc	ra,0xffffe
    80002684:	ebc080e7          	jalr	-324(ra) # 8000053c <panic>
            fileclose(f);
    80002688:	00002097          	auipc	ra,0x2
    8000268c:	5cc080e7          	jalr	1484(ra) # 80004c54 <fileclose>
            p->ofile[fd] = 0;
    80002690:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    80002694:	04a1                	addi	s1,s1,8
    80002696:	01248563          	beq	s1,s2,800026a0 <exit+0x58>
        if (p->ofile[fd])
    8000269a:	6088                	ld	a0,0(s1)
    8000269c:	f575                	bnez	a0,80002688 <exit+0x40>
    8000269e:	bfdd                	j	80002694 <exit+0x4c>
    begin_op();
    800026a0:	00002097          	auipc	ra,0x2
    800026a4:	0f0080e7          	jalr	240(ra) # 80004790 <begin_op>
    iput(p->cwd);
    800026a8:	1509b503          	ld	a0,336(s3)
    800026ac:	00002097          	auipc	ra,0x2
    800026b0:	8f8080e7          	jalr	-1800(ra) # 80003fa4 <iput>
    end_op();
    800026b4:	00002097          	auipc	ra,0x2
    800026b8:	156080e7          	jalr	342(ra) # 8000480a <end_op>
    p->cwd = 0;
    800026bc:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    800026c0:	0022f497          	auipc	s1,0x22f
    800026c4:	a5848493          	addi	s1,s1,-1448 # 80231118 <wait_lock>
    800026c8:	8526                	mv	a0,s1
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	70e080e7          	jalr	1806(ra) # 80000dd8 <acquire>
    reparent(p);
    800026d2:	854e                	mv	a0,s3
    800026d4:	00000097          	auipc	ra,0x0
    800026d8:	f1a080e7          	jalr	-230(ra) # 800025ee <reparent>
    wakeup(p->parent);
    800026dc:	0389b503          	ld	a0,56(s3)
    800026e0:	00000097          	auipc	ra,0x0
    800026e4:	e98080e7          	jalr	-360(ra) # 80002578 <wakeup>
    acquire(&p->lock);
    800026e8:	854e                	mv	a0,s3
    800026ea:	ffffe097          	auipc	ra,0xffffe
    800026ee:	6ee080e7          	jalr	1774(ra) # 80000dd8 <acquire>
    p->xstate = status;
    800026f2:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    800026f6:	4795                	li	a5,5
    800026f8:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    800026fc:	8526                	mv	a0,s1
    800026fe:	ffffe097          	auipc	ra,0xffffe
    80002702:	78e080e7          	jalr	1934(ra) # 80000e8c <release>
    sched();
    80002706:	00000097          	auipc	ra,0x0
    8000270a:	d04080e7          	jalr	-764(ra) # 8000240a <sched>
    panic("zombie exit");
    8000270e:	00006517          	auipc	a0,0x6
    80002712:	bca50513          	addi	a0,a0,-1078 # 800082d8 <digits+0x288>
    80002716:	ffffe097          	auipc	ra,0xffffe
    8000271a:	e26080e7          	jalr	-474(ra) # 8000053c <panic>

000000008000271e <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    8000271e:	7179                	addi	sp,sp,-48
    80002720:	f406                	sd	ra,40(sp)
    80002722:	f022                	sd	s0,32(sp)
    80002724:	ec26                	sd	s1,24(sp)
    80002726:	e84a                	sd	s2,16(sp)
    80002728:	e44e                	sd	s3,8(sp)
    8000272a:	1800                	addi	s0,sp,48
    8000272c:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    8000272e:	0022f497          	auipc	s1,0x22f
    80002732:	a0248493          	addi	s1,s1,-1534 # 80231130 <proc>
    80002736:	00234997          	auipc	s3,0x234
    8000273a:	3fa98993          	addi	s3,s3,1018 # 80236b30 <tickslock>
    {
        acquire(&p->lock);
    8000273e:	8526                	mv	a0,s1
    80002740:	ffffe097          	auipc	ra,0xffffe
    80002744:	698080e7          	jalr	1688(ra) # 80000dd8 <acquire>
        if (p->pid == pid)
    80002748:	589c                	lw	a5,48(s1)
    8000274a:	01278d63          	beq	a5,s2,80002764 <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    8000274e:	8526                	mv	a0,s1
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	73c080e7          	jalr	1852(ra) # 80000e8c <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002758:	16848493          	addi	s1,s1,360
    8000275c:	ff3491e3          	bne	s1,s3,8000273e <kill+0x20>
    }
    return -1;
    80002760:	557d                	li	a0,-1
    80002762:	a829                	j	8000277c <kill+0x5e>
            p->killed = 1;
    80002764:	4785                	li	a5,1
    80002766:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    80002768:	4c98                	lw	a4,24(s1)
    8000276a:	4789                	li	a5,2
    8000276c:	00f70f63          	beq	a4,a5,8000278a <kill+0x6c>
            release(&p->lock);
    80002770:	8526                	mv	a0,s1
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	71a080e7          	jalr	1818(ra) # 80000e8c <release>
            return 0;
    8000277a:	4501                	li	a0,0
}
    8000277c:	70a2                	ld	ra,40(sp)
    8000277e:	7402                	ld	s0,32(sp)
    80002780:	64e2                	ld	s1,24(sp)
    80002782:	6942                	ld	s2,16(sp)
    80002784:	69a2                	ld	s3,8(sp)
    80002786:	6145                	addi	sp,sp,48
    80002788:	8082                	ret
                p->state = RUNNABLE;
    8000278a:	478d                	li	a5,3
    8000278c:	cc9c                	sw	a5,24(s1)
    8000278e:	b7cd                	j	80002770 <kill+0x52>

0000000080002790 <setkilled>:

void setkilled(struct proc *p)
{
    80002790:	1101                	addi	sp,sp,-32
    80002792:	ec06                	sd	ra,24(sp)
    80002794:	e822                	sd	s0,16(sp)
    80002796:	e426                	sd	s1,8(sp)
    80002798:	1000                	addi	s0,sp,32
    8000279a:	84aa                	mv	s1,a0
    acquire(&p->lock);
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	63c080e7          	jalr	1596(ra) # 80000dd8 <acquire>
    p->killed = 1;
    800027a4:	4785                	li	a5,1
    800027a6:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	6e2080e7          	jalr	1762(ra) # 80000e8c <release>
}
    800027b2:	60e2                	ld	ra,24(sp)
    800027b4:	6442                	ld	s0,16(sp)
    800027b6:	64a2                	ld	s1,8(sp)
    800027b8:	6105                	addi	sp,sp,32
    800027ba:	8082                	ret

00000000800027bc <killed>:

int killed(struct proc *p)
{
    800027bc:	1101                	addi	sp,sp,-32
    800027be:	ec06                	sd	ra,24(sp)
    800027c0:	e822                	sd	s0,16(sp)
    800027c2:	e426                	sd	s1,8(sp)
    800027c4:	e04a                	sd	s2,0(sp)
    800027c6:	1000                	addi	s0,sp,32
    800027c8:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	60e080e7          	jalr	1550(ra) # 80000dd8 <acquire>
    k = p->killed;
    800027d2:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    800027d6:	8526                	mv	a0,s1
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	6b4080e7          	jalr	1716(ra) # 80000e8c <release>
    return k;
}
    800027e0:	854a                	mv	a0,s2
    800027e2:	60e2                	ld	ra,24(sp)
    800027e4:	6442                	ld	s0,16(sp)
    800027e6:	64a2                	ld	s1,8(sp)
    800027e8:	6902                	ld	s2,0(sp)
    800027ea:	6105                	addi	sp,sp,32
    800027ec:	8082                	ret

00000000800027ee <wait>:
{
    800027ee:	715d                	addi	sp,sp,-80
    800027f0:	e486                	sd	ra,72(sp)
    800027f2:	e0a2                	sd	s0,64(sp)
    800027f4:	fc26                	sd	s1,56(sp)
    800027f6:	f84a                	sd	s2,48(sp)
    800027f8:	f44e                	sd	s3,40(sp)
    800027fa:	f052                	sd	s4,32(sp)
    800027fc:	ec56                	sd	s5,24(sp)
    800027fe:	e85a                	sd	s6,16(sp)
    80002800:	e45e                	sd	s7,8(sp)
    80002802:	e062                	sd	s8,0(sp)
    80002804:	0880                	addi	s0,sp,80
    80002806:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002808:	fffff097          	auipc	ra,0xfffff
    8000280c:	5a4080e7          	jalr	1444(ra) # 80001dac <myproc>
    80002810:	892a                	mv	s2,a0
    acquire(&wait_lock);
    80002812:	0022f517          	auipc	a0,0x22f
    80002816:	90650513          	addi	a0,a0,-1786 # 80231118 <wait_lock>
    8000281a:	ffffe097          	auipc	ra,0xffffe
    8000281e:	5be080e7          	jalr	1470(ra) # 80000dd8 <acquire>
        havekids = 0;
    80002822:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    80002824:	4a15                	li	s4,5
                havekids = 1;
    80002826:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002828:	00234997          	auipc	s3,0x234
    8000282c:	30898993          	addi	s3,s3,776 # 80236b30 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002830:	0022fc17          	auipc	s8,0x22f
    80002834:	8e8c0c13          	addi	s8,s8,-1816 # 80231118 <wait_lock>
    80002838:	a0d1                	j	800028fc <wait+0x10e>
                    pid = pp->pid;
    8000283a:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000283e:	000b0e63          	beqz	s6,8000285a <wait+0x6c>
    80002842:	4691                	li	a3,4
    80002844:	02c48613          	addi	a2,s1,44
    80002848:	85da                	mv	a1,s6
    8000284a:	05093503          	ld	a0,80(s2)
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	0d6080e7          	jalr	214(ra) # 80001924 <copyout>
    80002856:	04054163          	bltz	a0,80002898 <wait+0xaa>
                    freeproc(pp);
    8000285a:	8526                	mv	a0,s1
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	702080e7          	jalr	1794(ra) # 80001f5e <freeproc>
                    release(&pp->lock);
    80002864:	8526                	mv	a0,s1
    80002866:	ffffe097          	auipc	ra,0xffffe
    8000286a:	626080e7          	jalr	1574(ra) # 80000e8c <release>
                    release(&wait_lock);
    8000286e:	0022f517          	auipc	a0,0x22f
    80002872:	8aa50513          	addi	a0,a0,-1878 # 80231118 <wait_lock>
    80002876:	ffffe097          	auipc	ra,0xffffe
    8000287a:	616080e7          	jalr	1558(ra) # 80000e8c <release>
}
    8000287e:	854e                	mv	a0,s3
    80002880:	60a6                	ld	ra,72(sp)
    80002882:	6406                	ld	s0,64(sp)
    80002884:	74e2                	ld	s1,56(sp)
    80002886:	7942                	ld	s2,48(sp)
    80002888:	79a2                	ld	s3,40(sp)
    8000288a:	7a02                	ld	s4,32(sp)
    8000288c:	6ae2                	ld	s5,24(sp)
    8000288e:	6b42                	ld	s6,16(sp)
    80002890:	6ba2                	ld	s7,8(sp)
    80002892:	6c02                	ld	s8,0(sp)
    80002894:	6161                	addi	sp,sp,80
    80002896:	8082                	ret
                        release(&pp->lock);
    80002898:	8526                	mv	a0,s1
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	5f2080e7          	jalr	1522(ra) # 80000e8c <release>
                        release(&wait_lock);
    800028a2:	0022f517          	auipc	a0,0x22f
    800028a6:	87650513          	addi	a0,a0,-1930 # 80231118 <wait_lock>
    800028aa:	ffffe097          	auipc	ra,0xffffe
    800028ae:	5e2080e7          	jalr	1506(ra) # 80000e8c <release>
                        return -1;
    800028b2:	59fd                	li	s3,-1
    800028b4:	b7e9                	j	8000287e <wait+0x90>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800028b6:	16848493          	addi	s1,s1,360
    800028ba:	03348463          	beq	s1,s3,800028e2 <wait+0xf4>
            if (pp->parent == p)
    800028be:	7c9c                	ld	a5,56(s1)
    800028c0:	ff279be3          	bne	a5,s2,800028b6 <wait+0xc8>
                acquire(&pp->lock);
    800028c4:	8526                	mv	a0,s1
    800028c6:	ffffe097          	auipc	ra,0xffffe
    800028ca:	512080e7          	jalr	1298(ra) # 80000dd8 <acquire>
                if (pp->state == ZOMBIE)
    800028ce:	4c9c                	lw	a5,24(s1)
    800028d0:	f74785e3          	beq	a5,s4,8000283a <wait+0x4c>
                release(&pp->lock);
    800028d4:	8526                	mv	a0,s1
    800028d6:	ffffe097          	auipc	ra,0xffffe
    800028da:	5b6080e7          	jalr	1462(ra) # 80000e8c <release>
                havekids = 1;
    800028de:	8756                	mv	a4,s5
    800028e0:	bfd9                	j	800028b6 <wait+0xc8>
        if (!havekids || killed(p))
    800028e2:	c31d                	beqz	a4,80002908 <wait+0x11a>
    800028e4:	854a                	mv	a0,s2
    800028e6:	00000097          	auipc	ra,0x0
    800028ea:	ed6080e7          	jalr	-298(ra) # 800027bc <killed>
    800028ee:	ed09                	bnez	a0,80002908 <wait+0x11a>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800028f0:	85e2                	mv	a1,s8
    800028f2:	854a                	mv	a0,s2
    800028f4:	00000097          	auipc	ra,0x0
    800028f8:	c20080e7          	jalr	-992(ra) # 80002514 <sleep>
        havekids = 0;
    800028fc:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    800028fe:	0022f497          	auipc	s1,0x22f
    80002902:	83248493          	addi	s1,s1,-1998 # 80231130 <proc>
    80002906:	bf65                	j	800028be <wait+0xd0>
            release(&wait_lock);
    80002908:	0022f517          	auipc	a0,0x22f
    8000290c:	81050513          	addi	a0,a0,-2032 # 80231118 <wait_lock>
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	57c080e7          	jalr	1404(ra) # 80000e8c <release>
            return -1;
    80002918:	59fd                	li	s3,-1
    8000291a:	b795                	j	8000287e <wait+0x90>

000000008000291c <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000291c:	7179                	addi	sp,sp,-48
    8000291e:	f406                	sd	ra,40(sp)
    80002920:	f022                	sd	s0,32(sp)
    80002922:	ec26                	sd	s1,24(sp)
    80002924:	e84a                	sd	s2,16(sp)
    80002926:	e44e                	sd	s3,8(sp)
    80002928:	e052                	sd	s4,0(sp)
    8000292a:	1800                	addi	s0,sp,48
    8000292c:	84aa                	mv	s1,a0
    8000292e:	892e                	mv	s2,a1
    80002930:	89b2                	mv	s3,a2
    80002932:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    80002934:	fffff097          	auipc	ra,0xfffff
    80002938:	478080e7          	jalr	1144(ra) # 80001dac <myproc>
    if (user_dst)
    8000293c:	c08d                	beqz	s1,8000295e <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    8000293e:	86d2                	mv	a3,s4
    80002940:	864e                	mv	a2,s3
    80002942:	85ca                	mv	a1,s2
    80002944:	6928                	ld	a0,80(a0)
    80002946:	fffff097          	auipc	ra,0xfffff
    8000294a:	fde080e7          	jalr	-34(ra) # 80001924 <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    8000294e:	70a2                	ld	ra,40(sp)
    80002950:	7402                	ld	s0,32(sp)
    80002952:	64e2                	ld	s1,24(sp)
    80002954:	6942                	ld	s2,16(sp)
    80002956:	69a2                	ld	s3,8(sp)
    80002958:	6a02                	ld	s4,0(sp)
    8000295a:	6145                	addi	sp,sp,48
    8000295c:	8082                	ret
        memmove((char *)dst, src, len);
    8000295e:	000a061b          	sext.w	a2,s4
    80002962:	85ce                	mv	a1,s3
    80002964:	854a                	mv	a0,s2
    80002966:	ffffe097          	auipc	ra,0xffffe
    8000296a:	5ca080e7          	jalr	1482(ra) # 80000f30 <memmove>
        return 0;
    8000296e:	8526                	mv	a0,s1
    80002970:	bff9                	j	8000294e <either_copyout+0x32>

0000000080002972 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002972:	7179                	addi	sp,sp,-48
    80002974:	f406                	sd	ra,40(sp)
    80002976:	f022                	sd	s0,32(sp)
    80002978:	ec26                	sd	s1,24(sp)
    8000297a:	e84a                	sd	s2,16(sp)
    8000297c:	e44e                	sd	s3,8(sp)
    8000297e:	e052                	sd	s4,0(sp)
    80002980:	1800                	addi	s0,sp,48
    80002982:	892a                	mv	s2,a0
    80002984:	84ae                	mv	s1,a1
    80002986:	89b2                	mv	s3,a2
    80002988:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	422080e7          	jalr	1058(ra) # 80001dac <myproc>
    if (user_src)
    80002992:	c08d                	beqz	s1,800029b4 <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    80002994:	86d2                	mv	a3,s4
    80002996:	864e                	mv	a2,s3
    80002998:	85ca                	mv	a1,s2
    8000299a:	6928                	ld	a0,80(a0)
    8000299c:	fffff097          	auipc	ra,0xfffff
    800029a0:	068080e7          	jalr	104(ra) # 80001a04 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800029a4:	70a2                	ld	ra,40(sp)
    800029a6:	7402                	ld	s0,32(sp)
    800029a8:	64e2                	ld	s1,24(sp)
    800029aa:	6942                	ld	s2,16(sp)
    800029ac:	69a2                	ld	s3,8(sp)
    800029ae:	6a02                	ld	s4,0(sp)
    800029b0:	6145                	addi	sp,sp,48
    800029b2:	8082                	ret
        memmove(dst, (char *)src, len);
    800029b4:	000a061b          	sext.w	a2,s4
    800029b8:	85ce                	mv	a1,s3
    800029ba:	854a                	mv	a0,s2
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	574080e7          	jalr	1396(ra) # 80000f30 <memmove>
        return 0;
    800029c4:	8526                	mv	a0,s1
    800029c6:	bff9                	j	800029a4 <either_copyin+0x32>

00000000800029c8 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    800029c8:	715d                	addi	sp,sp,-80
    800029ca:	e486                	sd	ra,72(sp)
    800029cc:	e0a2                	sd	s0,64(sp)
    800029ce:	fc26                	sd	s1,56(sp)
    800029d0:	f84a                	sd	s2,48(sp)
    800029d2:	f44e                	sd	s3,40(sp)
    800029d4:	f052                	sd	s4,32(sp)
    800029d6:	ec56                	sd	s5,24(sp)
    800029d8:	e85a                	sd	s6,16(sp)
    800029da:	e45e                	sd	s7,8(sp)
    800029dc:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    800029de:	00005517          	auipc	a0,0x5
    800029e2:	6b250513          	addi	a0,a0,1714 # 80008090 <digits+0x40>
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	bb2080e7          	jalr	-1102(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    800029ee:	0022f497          	auipc	s1,0x22f
    800029f2:	89a48493          	addi	s1,s1,-1894 # 80231288 <proc+0x158>
    800029f6:	00234917          	auipc	s2,0x234
    800029fa:	29290913          	addi	s2,s2,658 # 80236c88 <bcache+0x140>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029fe:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002a00:	00006997          	auipc	s3,0x6
    80002a04:	8e898993          	addi	s3,s3,-1816 # 800082e8 <digits+0x298>
        printf("%d <%s %s", p->pid, state, p->name);
    80002a08:	00006a97          	auipc	s5,0x6
    80002a0c:	8e8a8a93          	addi	s5,s5,-1816 # 800082f0 <digits+0x2a0>
        printf("\n");
    80002a10:	00005a17          	auipc	s4,0x5
    80002a14:	680a0a13          	addi	s4,s4,1664 # 80008090 <digits+0x40>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a18:	00006b97          	auipc	s7,0x6
    80002a1c:	9e8b8b93          	addi	s7,s7,-1560 # 80008400 <states.0>
    80002a20:	a00d                	j	80002a42 <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    80002a22:	ed86a583          	lw	a1,-296(a3)
    80002a26:	8556                	mv	a0,s5
    80002a28:	ffffe097          	auipc	ra,0xffffe
    80002a2c:	b70080e7          	jalr	-1168(ra) # 80000598 <printf>
        printf("\n");
    80002a30:	8552                	mv	a0,s4
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	b66080e7          	jalr	-1178(ra) # 80000598 <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002a3a:	16848493          	addi	s1,s1,360
    80002a3e:	03248263          	beq	s1,s2,80002a62 <procdump+0x9a>
        if (p->state == UNUSED)
    80002a42:	86a6                	mv	a3,s1
    80002a44:	ec04a783          	lw	a5,-320(s1)
    80002a48:	dbed                	beqz	a5,80002a3a <procdump+0x72>
            state = "???";
    80002a4a:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002a4c:	fcfb6be3          	bltu	s6,a5,80002a22 <procdump+0x5a>
    80002a50:	02079713          	slli	a4,a5,0x20
    80002a54:	01d75793          	srli	a5,a4,0x1d
    80002a58:	97de                	add	a5,a5,s7
    80002a5a:	6390                	ld	a2,0(a5)
    80002a5c:	f279                	bnez	a2,80002a22 <procdump+0x5a>
            state = "???";
    80002a5e:	864e                	mv	a2,s3
    80002a60:	b7c9                	j	80002a22 <procdump+0x5a>
    }
}
    80002a62:	60a6                	ld	ra,72(sp)
    80002a64:	6406                	ld	s0,64(sp)
    80002a66:	74e2                	ld	s1,56(sp)
    80002a68:	7942                	ld	s2,48(sp)
    80002a6a:	79a2                	ld	s3,40(sp)
    80002a6c:	7a02                	ld	s4,32(sp)
    80002a6e:	6ae2                	ld	s5,24(sp)
    80002a70:	6b42                	ld	s6,16(sp)
    80002a72:	6ba2                	ld	s7,8(sp)
    80002a74:	6161                	addi	sp,sp,80
    80002a76:	8082                	ret

0000000080002a78 <schedls>:

void schedls()
{
    80002a78:	1141                	addi	sp,sp,-16
    80002a7a:	e406                	sd	ra,8(sp)
    80002a7c:	e022                	sd	s0,0(sp)
    80002a7e:	0800                	addi	s0,sp,16
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    80002a80:	00006517          	auipc	a0,0x6
    80002a84:	88050513          	addi	a0,a0,-1920 # 80008300 <digits+0x2b0>
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	b10080e7          	jalr	-1264(ra) # 80000598 <printf>
    printf("====================================\n");
    80002a90:	00006517          	auipc	a0,0x6
    80002a94:	89850513          	addi	a0,a0,-1896 # 80008328 <digits+0x2d8>
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	b00080e7          	jalr	-1280(ra) # 80000598 <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    80002aa0:	00006717          	auipc	a4,0x6
    80002aa4:	f9873703          	ld	a4,-104(a4) # 80008a38 <available_schedulers+0x10>
    80002aa8:	00006797          	auipc	a5,0x6
    80002aac:	f307b783          	ld	a5,-208(a5) # 800089d8 <sched_pointer>
    80002ab0:	04f70663          	beq	a4,a5,80002afc <schedls+0x84>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002ab4:	00006517          	auipc	a0,0x6
    80002ab8:	8a450513          	addi	a0,a0,-1884 # 80008358 <digits+0x308>
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	adc080e7          	jalr	-1316(ra) # 80000598 <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002ac4:	00006617          	auipc	a2,0x6
    80002ac8:	f7c62603          	lw	a2,-132(a2) # 80008a40 <available_schedulers+0x18>
    80002acc:	00006597          	auipc	a1,0x6
    80002ad0:	f5c58593          	addi	a1,a1,-164 # 80008a28 <available_schedulers>
    80002ad4:	00006517          	auipc	a0,0x6
    80002ad8:	88c50513          	addi	a0,a0,-1908 # 80008360 <digits+0x310>
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	abc080e7          	jalr	-1348(ra) # 80000598 <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002ae4:	00006517          	auipc	a0,0x6
    80002ae8:	88450513          	addi	a0,a0,-1916 # 80008368 <digits+0x318>
    80002aec:	ffffe097          	auipc	ra,0xffffe
    80002af0:	aac080e7          	jalr	-1364(ra) # 80000598 <printf>
}
    80002af4:	60a2                	ld	ra,8(sp)
    80002af6:	6402                	ld	s0,0(sp)
    80002af8:	0141                	addi	sp,sp,16
    80002afa:	8082                	ret
            printf("[*]\t");
    80002afc:	00006517          	auipc	a0,0x6
    80002b00:	85450513          	addi	a0,a0,-1964 # 80008350 <digits+0x300>
    80002b04:	ffffe097          	auipc	ra,0xffffe
    80002b08:	a94080e7          	jalr	-1388(ra) # 80000598 <printf>
    80002b0c:	bf65                	j	80002ac4 <schedls+0x4c>

0000000080002b0e <schedset>:

void schedset(int id)
{
    80002b0e:	1141                	addi	sp,sp,-16
    80002b10:	e406                	sd	ra,8(sp)
    80002b12:	e022                	sd	s0,0(sp)
    80002b14:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002b16:	e90d                	bnez	a0,80002b48 <schedset+0x3a>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002b18:	00006797          	auipc	a5,0x6
    80002b1c:	f207b783          	ld	a5,-224(a5) # 80008a38 <available_schedulers+0x10>
    80002b20:	00006717          	auipc	a4,0x6
    80002b24:	eaf73c23          	sd	a5,-328(a4) # 800089d8 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002b28:	00006597          	auipc	a1,0x6
    80002b2c:	f0058593          	addi	a1,a1,-256 # 80008a28 <available_schedulers>
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	87850513          	addi	a0,a0,-1928 # 800083a8 <digits+0x358>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a60080e7          	jalr	-1440(ra) # 80000598 <printf>
    80002b40:	60a2                	ld	ra,8(sp)
    80002b42:	6402                	ld	s0,0(sp)
    80002b44:	0141                	addi	sp,sp,16
    80002b46:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002b48:	00006517          	auipc	a0,0x6
    80002b4c:	83850513          	addi	a0,a0,-1992 # 80008380 <digits+0x330>
    80002b50:	ffffe097          	auipc	ra,0xffffe
    80002b54:	a48080e7          	jalr	-1464(ra) # 80000598 <printf>
        return;
    80002b58:	b7e5                	j	80002b40 <schedset+0x32>

0000000080002b5a <swtch>:
    80002b5a:	00153023          	sd	ra,0(a0)
    80002b5e:	00253423          	sd	sp,8(a0)
    80002b62:	e900                	sd	s0,16(a0)
    80002b64:	ed04                	sd	s1,24(a0)
    80002b66:	03253023          	sd	s2,32(a0)
    80002b6a:	03353423          	sd	s3,40(a0)
    80002b6e:	03453823          	sd	s4,48(a0)
    80002b72:	03553c23          	sd	s5,56(a0)
    80002b76:	05653023          	sd	s6,64(a0)
    80002b7a:	05753423          	sd	s7,72(a0)
    80002b7e:	05853823          	sd	s8,80(a0)
    80002b82:	05953c23          	sd	s9,88(a0)
    80002b86:	07a53023          	sd	s10,96(a0)
    80002b8a:	07b53423          	sd	s11,104(a0)
    80002b8e:	0005b083          	ld	ra,0(a1)
    80002b92:	0085b103          	ld	sp,8(a1)
    80002b96:	6980                	ld	s0,16(a1)
    80002b98:	6d84                	ld	s1,24(a1)
    80002b9a:	0205b903          	ld	s2,32(a1)
    80002b9e:	0285b983          	ld	s3,40(a1)
    80002ba2:	0305ba03          	ld	s4,48(a1)
    80002ba6:	0385ba83          	ld	s5,56(a1)
    80002baa:	0405bb03          	ld	s6,64(a1)
    80002bae:	0485bb83          	ld	s7,72(a1)
    80002bb2:	0505bc03          	ld	s8,80(a1)
    80002bb6:	0585bc83          	ld	s9,88(a1)
    80002bba:	0605bd03          	ld	s10,96(a1)
    80002bbe:	0685bd83          	ld	s11,104(a1)
    80002bc2:	8082                	ret

0000000080002bc4 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002bc4:	1141                	addi	sp,sp,-16
    80002bc6:	e406                	sd	ra,8(sp)
    80002bc8:	e022                	sd	s0,0(sp)
    80002bca:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002bcc:	00006597          	auipc	a1,0x6
    80002bd0:	86458593          	addi	a1,a1,-1948 # 80008430 <states.0+0x30>
    80002bd4:	00234517          	auipc	a0,0x234
    80002bd8:	f5c50513          	addi	a0,a0,-164 # 80236b30 <tickslock>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	16c080e7          	jalr	364(ra) # 80000d48 <initlock>
}
    80002be4:	60a2                	ld	ra,8(sp)
    80002be6:	6402                	ld	s0,0(sp)
    80002be8:	0141                	addi	sp,sp,16
    80002bea:	8082                	ret

0000000080002bec <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002bec:	1141                	addi	sp,sp,-16
    80002bee:	e422                	sd	s0,8(sp)
    80002bf0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf2:	00003797          	auipc	a5,0x3
    80002bf6:	68e78793          	addi	a5,a5,1678 # 80006280 <kernelvec>
    80002bfa:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bfe:	6422                	ld	s0,8(sp)
    80002c00:	0141                	addi	sp,sp,16
    80002c02:	8082                	ret

0000000080002c04 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002c04:	1141                	addi	sp,sp,-16
    80002c06:	e406                	sd	ra,8(sp)
    80002c08:	e022                	sd	s0,0(sp)
    80002c0a:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002c0c:	fffff097          	auipc	ra,0xfffff
    80002c10:	1a0080e7          	jalr	416(ra) # 80001dac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c14:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002c18:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c1a:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002c1e:	00004697          	auipc	a3,0x4
    80002c22:	3e268693          	addi	a3,a3,994 # 80007000 <_trampoline>
    80002c26:	00004717          	auipc	a4,0x4
    80002c2a:	3da70713          	addi	a4,a4,986 # 80007000 <_trampoline>
    80002c2e:	8f15                	sub	a4,a4,a3
    80002c30:	040007b7          	lui	a5,0x4000
    80002c34:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002c36:	07b2                	slli	a5,a5,0xc
    80002c38:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002c3a:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002c3e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002c40:	18002673          	csrr	a2,satp
    80002c44:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c46:	6d30                	ld	a2,88(a0)
    80002c48:	6138                	ld	a4,64(a0)
    80002c4a:	6585                	lui	a1,0x1
    80002c4c:	972e                	add	a4,a4,a1
    80002c4e:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c50:	6d38                	ld	a4,88(a0)
    80002c52:	00000617          	auipc	a2,0x0
    80002c56:	29460613          	addi	a2,a2,660 # 80002ee6 <usertrap>
    80002c5a:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c5c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c5e:	8612                	mv	a2,tp
    80002c60:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c62:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c66:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c6a:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c6e:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c72:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c74:	6f18                	ld	a4,24(a4)
    80002c76:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c7a:	6928                	ld	a0,80(a0)
    80002c7c:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c7e:	00004717          	auipc	a4,0x4
    80002c82:	41e70713          	addi	a4,a4,1054 # 8000709c <userret>
    80002c86:	8f15                	sub	a4,a4,a3
    80002c88:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c8a:	577d                	li	a4,-1
    80002c8c:	177e                	slli	a4,a4,0x3f
    80002c8e:	8d59                	or	a0,a0,a4
    80002c90:	9782                	jalr	a5
}
    80002c92:	60a2                	ld	ra,8(sp)
    80002c94:	6402                	ld	s0,0(sp)
    80002c96:	0141                	addi	sp,sp,16
    80002c98:	8082                	ret

0000000080002c9a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c9a:	1101                	addi	sp,sp,-32
    80002c9c:	ec06                	sd	ra,24(sp)
    80002c9e:	e822                	sd	s0,16(sp)
    80002ca0:	e426                	sd	s1,8(sp)
    80002ca2:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ca4:	00234497          	auipc	s1,0x234
    80002ca8:	e8c48493          	addi	s1,s1,-372 # 80236b30 <tickslock>
    80002cac:	8526                	mv	a0,s1
    80002cae:	ffffe097          	auipc	ra,0xffffe
    80002cb2:	12a080e7          	jalr	298(ra) # 80000dd8 <acquire>
  ticks++;
    80002cb6:	00006517          	auipc	a0,0x6
    80002cba:	dda50513          	addi	a0,a0,-550 # 80008a90 <ticks>
    80002cbe:	411c                	lw	a5,0(a0)
    80002cc0:	2785                	addiw	a5,a5,1
    80002cc2:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002cc4:	00000097          	auipc	ra,0x0
    80002cc8:	8b4080e7          	jalr	-1868(ra) # 80002578 <wakeup>
  release(&tickslock);
    80002ccc:	8526                	mv	a0,s1
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	1be080e7          	jalr	446(ra) # 80000e8c <release>
}
    80002cd6:	60e2                	ld	ra,24(sp)
    80002cd8:	6442                	ld	s0,16(sp)
    80002cda:	64a2                	ld	s1,8(sp)
    80002cdc:	6105                	addi	sp,sp,32
    80002cde:	8082                	ret

0000000080002ce0 <devintr>:
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ce0:	142027f3          	csrr	a5,scause
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002ce4:	4501                	li	a0,0
  if((scause & 0x8000000000000000L) &&
    80002ce6:	0807df63          	bgez	a5,80002d84 <devintr+0xa4>
{
    80002cea:	1101                	addi	sp,sp,-32
    80002cec:	ec06                	sd	ra,24(sp)
    80002cee:	e822                	sd	s0,16(sp)
    80002cf0:	e426                	sd	s1,8(sp)
    80002cf2:	1000                	addi	s0,sp,32
     (scause & 0xff) == 9){
    80002cf4:	0ff7f713          	zext.b	a4,a5
  if((scause & 0x8000000000000000L) &&
    80002cf8:	46a5                	li	a3,9
    80002cfa:	00d70d63          	beq	a4,a3,80002d14 <devintr+0x34>
  } else if(scause == 0x8000000000000001L){
    80002cfe:	577d                	li	a4,-1
    80002d00:	177e                	slli	a4,a4,0x3f
    80002d02:	0705                	addi	a4,a4,1
    return 0;
    80002d04:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002d06:	04e78e63          	beq	a5,a4,80002d62 <devintr+0x82>
  }
}
    80002d0a:	60e2                	ld	ra,24(sp)
    80002d0c:	6442                	ld	s0,16(sp)
    80002d0e:	64a2                	ld	s1,8(sp)
    80002d10:	6105                	addi	sp,sp,32
    80002d12:	8082                	ret
    int irq = plic_claim();
    80002d14:	00003097          	auipc	ra,0x3
    80002d18:	674080e7          	jalr	1652(ra) # 80006388 <plic_claim>
    80002d1c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002d1e:	47a9                	li	a5,10
    80002d20:	02f50763          	beq	a0,a5,80002d4e <devintr+0x6e>
    } else if(irq == VIRTIO0_IRQ){
    80002d24:	4785                	li	a5,1
    80002d26:	02f50963          	beq	a0,a5,80002d58 <devintr+0x78>
    return 1;
    80002d2a:	4505                	li	a0,1
    } else if(irq){
    80002d2c:	dcf9                	beqz	s1,80002d0a <devintr+0x2a>
      printf("unexpected interrupt irq=%d\n", irq);
    80002d2e:	85a6                	mv	a1,s1
    80002d30:	00005517          	auipc	a0,0x5
    80002d34:	70850513          	addi	a0,a0,1800 # 80008438 <states.0+0x38>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	860080e7          	jalr	-1952(ra) # 80000598 <printf>
      plic_complete(irq);
    80002d40:	8526                	mv	a0,s1
    80002d42:	00003097          	auipc	ra,0x3
    80002d46:	66a080e7          	jalr	1642(ra) # 800063ac <plic_complete>
    return 1;
    80002d4a:	4505                	li	a0,1
    80002d4c:	bf7d                	j	80002d0a <devintr+0x2a>
      uartintr();
    80002d4e:	ffffe097          	auipc	ra,0xffffe
    80002d52:	c58080e7          	jalr	-936(ra) # 800009a6 <uartintr>
    if(irq)
    80002d56:	b7ed                	j	80002d40 <devintr+0x60>
      virtio_disk_intr();
    80002d58:	00004097          	auipc	ra,0x4
    80002d5c:	b1a080e7          	jalr	-1254(ra) # 80006872 <virtio_disk_intr>
    if(irq)
    80002d60:	b7c5                	j	80002d40 <devintr+0x60>
    if(cpuid() == 0){
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	01e080e7          	jalr	30(ra) # 80001d80 <cpuid>
    80002d6a:	c901                	beqz	a0,80002d7a <devintr+0x9a>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d6c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d70:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d72:	14479073          	csrw	sip,a5
    return 2;
    80002d76:	4509                	li	a0,2
    80002d78:	bf49                	j	80002d0a <devintr+0x2a>
      clockintr();
    80002d7a:	00000097          	auipc	ra,0x0
    80002d7e:	f20080e7          	jalr	-224(ra) # 80002c9a <clockintr>
    80002d82:	b7ed                	j	80002d6c <devintr+0x8c>
}
    80002d84:	8082                	ret

0000000080002d86 <kerneltrap>:
{
    80002d86:	7179                	addi	sp,sp,-48
    80002d88:	f406                	sd	ra,40(sp)
    80002d8a:	f022                	sd	s0,32(sp)
    80002d8c:	ec26                	sd	s1,24(sp)
    80002d8e:	e84a                	sd	s2,16(sp)
    80002d90:	e44e                	sd	s3,8(sp)
    80002d92:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d94:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d98:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d9c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002da0:	1004f793          	andi	a5,s1,256
    80002da4:	cb85                	beqz	a5,80002dd4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002da6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002daa:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002dac:	ef85                	bnez	a5,80002de4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	f32080e7          	jalr	-206(ra) # 80002ce0 <devintr>
    80002db6:	cd1d                	beqz	a0,80002df4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002db8:	4789                	li	a5,2
    80002dba:	06f50a63          	beq	a0,a5,80002e2e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002dbe:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc2:	10049073          	csrw	sstatus,s1
}
    80002dc6:	70a2                	ld	ra,40(sp)
    80002dc8:	7402                	ld	s0,32(sp)
    80002dca:	64e2                	ld	s1,24(sp)
    80002dcc:	6942                	ld	s2,16(sp)
    80002dce:	69a2                	ld	s3,8(sp)
    80002dd0:	6145                	addi	sp,sp,48
    80002dd2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002dd4:	00005517          	auipc	a0,0x5
    80002dd8:	68450513          	addi	a0,a0,1668 # 80008458 <states.0+0x58>
    80002ddc:	ffffd097          	auipc	ra,0xffffd
    80002de0:	760080e7          	jalr	1888(ra) # 8000053c <panic>
    panic("kerneltrap: interrupts enabled");
    80002de4:	00005517          	auipc	a0,0x5
    80002de8:	69c50513          	addi	a0,a0,1692 # 80008480 <states.0+0x80>
    80002dec:	ffffd097          	auipc	ra,0xffffd
    80002df0:	750080e7          	jalr	1872(ra) # 8000053c <panic>
    printf("scause %p\n", scause);
    80002df4:	85ce                	mv	a1,s3
    80002df6:	00005517          	auipc	a0,0x5
    80002dfa:	6aa50513          	addi	a0,a0,1706 # 800084a0 <states.0+0xa0>
    80002dfe:	ffffd097          	auipc	ra,0xffffd
    80002e02:	79a080e7          	jalr	1946(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e06:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e0a:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e0e:	00005517          	auipc	a0,0x5
    80002e12:	6a250513          	addi	a0,a0,1698 # 800084b0 <states.0+0xb0>
    80002e16:	ffffd097          	auipc	ra,0xffffd
    80002e1a:	782080e7          	jalr	1922(ra) # 80000598 <printf>
    panic("kerneltrap");
    80002e1e:	00005517          	auipc	a0,0x5
    80002e22:	6aa50513          	addi	a0,a0,1706 # 800084c8 <states.0+0xc8>
    80002e26:	ffffd097          	auipc	ra,0xffffd
    80002e2a:	716080e7          	jalr	1814(ra) # 8000053c <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e2e:	fffff097          	auipc	ra,0xfffff
    80002e32:	f7e080e7          	jalr	-130(ra) # 80001dac <myproc>
    80002e36:	d541                	beqz	a0,80002dbe <kerneltrap+0x38>
    80002e38:	fffff097          	auipc	ra,0xfffff
    80002e3c:	f74080e7          	jalr	-140(ra) # 80001dac <myproc>
    80002e40:	4d18                	lw	a4,24(a0)
    80002e42:	4791                	li	a5,4
    80002e44:	f6f71de3          	bne	a4,a5,80002dbe <kerneltrap+0x38>
    yield();
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	690080e7          	jalr	1680(ra) # 800024d8 <yield>
    80002e50:	b7bd                	j	80002dbe <kerneltrap+0x38>

0000000080002e52 <cowfault>:

int
 cowfault(pagetable_t pagetable, uint64 va)
 {
   if (va >= MAXVA) {
    80002e52:	57fd                	li	a5,-1
    80002e54:	83e9                	srli	a5,a5,0x1a
    80002e56:	08b7e263          	bltu	a5,a1,80002eda <cowfault+0x88>
 {
    80002e5a:	7179                	addi	sp,sp,-48
    80002e5c:	f406                	sd	ra,40(sp)
    80002e5e:	f022                	sd	s0,32(sp)
    80002e60:	ec26                	sd	s1,24(sp)
    80002e62:	e84a                	sd	s2,16(sp)
    80002e64:	e44e                	sd	s3,8(sp)
    80002e66:	1800                	addi	s0,sp,48
     return -1;
   }

   pte_t* pte = walk(pagetable, va, 0);
    80002e68:	4601                	li	a2,0
    80002e6a:	ffffe097          	auipc	ra,0xffffe
    80002e6e:	34c080e7          	jalr	844(ra) # 800011b6 <walk>
    80002e72:	89aa                	mv	s3,a0
   if (0 == pte) {
    80002e74:	c52d                	beqz	a0,80002ede <cowfault+0x8c>
     return -1;
   }

   if (0 == (*pte & PTE_U) || 0 == (*pte & PTE_V)) {
    80002e76:	610c                	ld	a1,0(a0)
    80002e78:	0115f713          	andi	a4,a1,17
    80002e7c:	47c5                	li	a5,17
    80002e7e:	06f71263          	bne	a4,a5,80002ee2 <cowfault+0x90>
     return -1;
   }

   uint64 pa1 = PTE2PA(*pte);
    80002e82:	81a9                	srli	a1,a1,0xa
    80002e84:	00c59913          	slli	s2,a1,0xc
   uint64 pa2 = (uint64) kalloc();
    80002e88:	ffffe097          	auipc	ra,0xffffe
    80002e8c:	dd6080e7          	jalr	-554(ra) # 80000c5e <kalloc>
    80002e90:	84aa                	mv	s1,a0
   if (0 == pa2) {
    80002e92:	c915                	beqz	a0,80002ec6 <cowfault+0x74>
     printf("cow kalloc failed\n");
     return -1;
   }

   memmove((void*) pa2, (void*) pa1, PGSIZE);
    80002e94:	6605                	lui	a2,0x1
    80002e96:	85ca                	mv	a1,s2
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	098080e7          	jalr	152(ra) # 80000f30 <memmove>

   kfree((void*) pa1);
    80002ea0:	854a                	mv	a0,s2
    80002ea2:	ffffe097          	auipc	ra,0xffffe
    80002ea6:	bd0080e7          	jalr	-1072(ra) # 80000a72 <kfree>

   *pte = PA2PTE(pa2) | PTE_V | PTE_U | PTE_R | PTE_W | PTE_X;
    80002eaa:	80b1                	srli	s1,s1,0xc
    80002eac:	04aa                	slli	s1,s1,0xa
    80002eae:	01f4e493          	ori	s1,s1,31
    80002eb2:	0099b023          	sd	s1,0(s3)

   return 0;
    80002eb6:	4501                	li	a0,0
 }
    80002eb8:	70a2                	ld	ra,40(sp)
    80002eba:	7402                	ld	s0,32(sp)
    80002ebc:	64e2                	ld	s1,24(sp)
    80002ebe:	6942                	ld	s2,16(sp)
    80002ec0:	69a2                	ld	s3,8(sp)
    80002ec2:	6145                	addi	sp,sp,48
    80002ec4:	8082                	ret
     printf("cow kalloc failed\n");
    80002ec6:	00005517          	auipc	a0,0x5
    80002eca:	61250513          	addi	a0,a0,1554 # 800084d8 <states.0+0xd8>
    80002ece:	ffffd097          	auipc	ra,0xffffd
    80002ed2:	6ca080e7          	jalr	1738(ra) # 80000598 <printf>
     return -1;
    80002ed6:	557d                	li	a0,-1
    80002ed8:	b7c5                	j	80002eb8 <cowfault+0x66>
     return -1;
    80002eda:	557d                	li	a0,-1
 }
    80002edc:	8082                	ret
     return -1;
    80002ede:	557d                	li	a0,-1
    80002ee0:	bfe1                	j	80002eb8 <cowfault+0x66>
     return -1;
    80002ee2:	557d                	li	a0,-1
    80002ee4:	bfd1                	j	80002eb8 <cowfault+0x66>

0000000080002ee6 <usertrap>:
{
    80002ee6:	1101                	addi	sp,sp,-32
    80002ee8:	ec06                	sd	ra,24(sp)
    80002eea:	e822                	sd	s0,16(sp)
    80002eec:	e426                	sd	s1,8(sp)
    80002eee:	e04a                	sd	s2,0(sp)
    80002ef0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ef2:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002ef6:	1007f793          	andi	a5,a5,256
    80002efa:	efad                	bnez	a5,80002f74 <usertrap+0x8e>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002efc:	00003797          	auipc	a5,0x3
    80002f00:	38478793          	addi	a5,a5,900 # 80006280 <kernelvec>
    80002f04:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002f08:	fffff097          	auipc	ra,0xfffff
    80002f0c:	ea4080e7          	jalr	-348(ra) # 80001dac <myproc>
    80002f10:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002f12:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f14:	14102773          	csrr	a4,sepc
    80002f18:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f1a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002f1e:	47a1                	li	a5,8
    80002f20:	06f70263          	beq	a4,a5,80002f84 <usertrap+0x9e>
  } else if((which_dev = devintr()) != 0){
    80002f24:	00000097          	auipc	ra,0x0
    80002f28:	dbc080e7          	jalr	-580(ra) # 80002ce0 <devintr>
    80002f2c:	892a                	mv	s2,a0
    80002f2e:	e161                	bnez	a0,80002fee <usertrap+0x108>
    80002f30:	14202773          	csrr	a4,scause
  } else if (0xf == r_scause()) {
    80002f34:	47bd                	li	a5,15
    80002f36:	0af70063          	beq	a4,a5,80002fd6 <usertrap+0xf0>
    80002f3a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002f3e:	5890                	lw	a2,48(s1)
    80002f40:	00005517          	auipc	a0,0x5
    80002f44:	5d050513          	addi	a0,a0,1488 # 80008510 <states.0+0x110>
    80002f48:	ffffd097          	auipc	ra,0xffffd
    80002f4c:	650080e7          	jalr	1616(ra) # 80000598 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002f50:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002f54:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002f58:	00005517          	auipc	a0,0x5
    80002f5c:	5e850513          	addi	a0,a0,1512 # 80008540 <states.0+0x140>
    80002f60:	ffffd097          	auipc	ra,0xffffd
    80002f64:	638080e7          	jalr	1592(ra) # 80000598 <printf>
    setkilled(p);
    80002f68:	8526                	mv	a0,s1
    80002f6a:	00000097          	auipc	ra,0x0
    80002f6e:	826080e7          	jalr	-2010(ra) # 80002790 <setkilled>
    80002f72:	a825                	j	80002faa <usertrap+0xc4>
    panic("usertrap: not from user mode");
    80002f74:	00005517          	auipc	a0,0x5
    80002f78:	57c50513          	addi	a0,a0,1404 # 800084f0 <states.0+0xf0>
    80002f7c:	ffffd097          	auipc	ra,0xffffd
    80002f80:	5c0080e7          	jalr	1472(ra) # 8000053c <panic>
    if(killed(p))
    80002f84:	00000097          	auipc	ra,0x0
    80002f88:	838080e7          	jalr	-1992(ra) # 800027bc <killed>
    80002f8c:	ed1d                	bnez	a0,80002fca <usertrap+0xe4>
    p->trapframe->epc += 4;
    80002f8e:	6cb8                	ld	a4,88(s1)
    80002f90:	6f1c                	ld	a5,24(a4)
    80002f92:	0791                	addi	a5,a5,4
    80002f94:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002f96:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002f9a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002f9e:	10079073          	csrw	sstatus,a5
    syscall();
    80002fa2:	00000097          	auipc	ra,0x0
    80002fa6:	1f4080e7          	jalr	500(ra) # 80003196 <syscall>
  if(killed(p))
    80002faa:	8526                	mv	a0,s1
    80002fac:	00000097          	auipc	ra,0x0
    80002fb0:	810080e7          	jalr	-2032(ra) # 800027bc <killed>
    80002fb4:	e521                	bnez	a0,80002ffc <usertrap+0x116>
  usertrapret();
    80002fb6:	00000097          	auipc	ra,0x0
    80002fba:	c4e080e7          	jalr	-946(ra) # 80002c04 <usertrapret>
}
    80002fbe:	60e2                	ld	ra,24(sp)
    80002fc0:	6442                	ld	s0,16(sp)
    80002fc2:	64a2                	ld	s1,8(sp)
    80002fc4:	6902                	ld	s2,0(sp)
    80002fc6:	6105                	addi	sp,sp,32
    80002fc8:	8082                	ret
      exit(-1);
    80002fca:	557d                	li	a0,-1
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	67c080e7          	jalr	1660(ra) # 80002648 <exit>
    80002fd4:	bf6d                	j	80002f8e <usertrap+0xa8>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002fd6:	143025f3          	csrr	a1,stval
     if (0 > cowfault(p->pagetable, r_stval())) {
    80002fda:	68a8                	ld	a0,80(s1)
    80002fdc:	00000097          	auipc	ra,0x0
    80002fe0:	e76080e7          	jalr	-394(ra) # 80002e52 <cowfault>
    80002fe4:	fc0553e3          	bgez	a0,80002faa <usertrap+0xc4>
       p->killed = 1;
    80002fe8:	4785                	li	a5,1
    80002fea:	d49c                	sw	a5,40(s1)
    80002fec:	bf7d                	j	80002faa <usertrap+0xc4>
  if(killed(p))
    80002fee:	8526                	mv	a0,s1
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	7cc080e7          	jalr	1996(ra) # 800027bc <killed>
    80002ff8:	c901                	beqz	a0,80003008 <usertrap+0x122>
    80002ffa:	a011                	j	80002ffe <usertrap+0x118>
    80002ffc:	4901                	li	s2,0
    exit(-1);
    80002ffe:	557d                	li	a0,-1
    80003000:	fffff097          	auipc	ra,0xfffff
    80003004:	648080e7          	jalr	1608(ra) # 80002648 <exit>
  if(which_dev == 2)
    80003008:	4789                	li	a5,2
    8000300a:	faf916e3          	bne	s2,a5,80002fb6 <usertrap+0xd0>
    yield();
    8000300e:	fffff097          	auipc	ra,0xfffff
    80003012:	4ca080e7          	jalr	1226(ra) # 800024d8 <yield>
    80003016:	b745                	j	80002fb6 <usertrap+0xd0>

0000000080003018 <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80003018:	1101                	addi	sp,sp,-32
    8000301a:	ec06                	sd	ra,24(sp)
    8000301c:	e822                	sd	s0,16(sp)
    8000301e:	e426                	sd	s1,8(sp)
    80003020:	1000                	addi	s0,sp,32
    80003022:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80003024:	fffff097          	auipc	ra,0xfffff
    80003028:	d88080e7          	jalr	-632(ra) # 80001dac <myproc>
    switch (n)
    8000302c:	4795                	li	a5,5
    8000302e:	0497e163          	bltu	a5,s1,80003070 <argraw+0x58>
    80003032:	048a                	slli	s1,s1,0x2
    80003034:	00005717          	auipc	a4,0x5
    80003038:	55470713          	addi	a4,a4,1364 # 80008588 <states.0+0x188>
    8000303c:	94ba                	add	s1,s1,a4
    8000303e:	409c                	lw	a5,0(s1)
    80003040:	97ba                	add	a5,a5,a4
    80003042:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80003044:	6d3c                	ld	a5,88(a0)
    80003046:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80003048:	60e2                	ld	ra,24(sp)
    8000304a:	6442                	ld	s0,16(sp)
    8000304c:	64a2                	ld	s1,8(sp)
    8000304e:	6105                	addi	sp,sp,32
    80003050:	8082                	ret
        return p->trapframe->a1;
    80003052:	6d3c                	ld	a5,88(a0)
    80003054:	7fa8                	ld	a0,120(a5)
    80003056:	bfcd                	j	80003048 <argraw+0x30>
        return p->trapframe->a2;
    80003058:	6d3c                	ld	a5,88(a0)
    8000305a:	63c8                	ld	a0,128(a5)
    8000305c:	b7f5                	j	80003048 <argraw+0x30>
        return p->trapframe->a3;
    8000305e:	6d3c                	ld	a5,88(a0)
    80003060:	67c8                	ld	a0,136(a5)
    80003062:	b7dd                	j	80003048 <argraw+0x30>
        return p->trapframe->a4;
    80003064:	6d3c                	ld	a5,88(a0)
    80003066:	6bc8                	ld	a0,144(a5)
    80003068:	b7c5                	j	80003048 <argraw+0x30>
        return p->trapframe->a5;
    8000306a:	6d3c                	ld	a5,88(a0)
    8000306c:	6fc8                	ld	a0,152(a5)
    8000306e:	bfe9                	j	80003048 <argraw+0x30>
    panic("argraw");
    80003070:	00005517          	auipc	a0,0x5
    80003074:	4f050513          	addi	a0,a0,1264 # 80008560 <states.0+0x160>
    80003078:	ffffd097          	auipc	ra,0xffffd
    8000307c:	4c4080e7          	jalr	1220(ra) # 8000053c <panic>

0000000080003080 <fetchaddr>:
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	e426                	sd	s1,8(sp)
    80003088:	e04a                	sd	s2,0(sp)
    8000308a:	1000                	addi	s0,sp,32
    8000308c:	84aa                	mv	s1,a0
    8000308e:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80003090:	fffff097          	auipc	ra,0xfffff
    80003094:	d1c080e7          	jalr	-740(ra) # 80001dac <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80003098:	653c                	ld	a5,72(a0)
    8000309a:	02f4f863          	bgeu	s1,a5,800030ca <fetchaddr+0x4a>
    8000309e:	00848713          	addi	a4,s1,8
    800030a2:	02e7e663          	bltu	a5,a4,800030ce <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800030a6:	46a1                	li	a3,8
    800030a8:	8626                	mv	a2,s1
    800030aa:	85ca                	mv	a1,s2
    800030ac:	6928                	ld	a0,80(a0)
    800030ae:	fffff097          	auipc	ra,0xfffff
    800030b2:	956080e7          	jalr	-1706(ra) # 80001a04 <copyin>
    800030b6:	00a03533          	snez	a0,a0
    800030ba:	40a00533          	neg	a0,a0
}
    800030be:	60e2                	ld	ra,24(sp)
    800030c0:	6442                	ld	s0,16(sp)
    800030c2:	64a2                	ld	s1,8(sp)
    800030c4:	6902                	ld	s2,0(sp)
    800030c6:	6105                	addi	sp,sp,32
    800030c8:	8082                	ret
        return -1;
    800030ca:	557d                	li	a0,-1
    800030cc:	bfcd                	j	800030be <fetchaddr+0x3e>
    800030ce:	557d                	li	a0,-1
    800030d0:	b7fd                	j	800030be <fetchaddr+0x3e>

00000000800030d2 <fetchstr>:
{
    800030d2:	7179                	addi	sp,sp,-48
    800030d4:	f406                	sd	ra,40(sp)
    800030d6:	f022                	sd	s0,32(sp)
    800030d8:	ec26                	sd	s1,24(sp)
    800030da:	e84a                	sd	s2,16(sp)
    800030dc:	e44e                	sd	s3,8(sp)
    800030de:	1800                	addi	s0,sp,48
    800030e0:	892a                	mv	s2,a0
    800030e2:	84ae                	mv	s1,a1
    800030e4:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    800030e6:	fffff097          	auipc	ra,0xfffff
    800030ea:	cc6080e7          	jalr	-826(ra) # 80001dac <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    800030ee:	86ce                	mv	a3,s3
    800030f0:	864a                	mv	a2,s2
    800030f2:	85a6                	mv	a1,s1
    800030f4:	6928                	ld	a0,80(a0)
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	99c080e7          	jalr	-1636(ra) # 80001a92 <copyinstr>
    800030fe:	00054e63          	bltz	a0,8000311a <fetchstr+0x48>
    return strlen(buf);
    80003102:	8526                	mv	a0,s1
    80003104:	ffffe097          	auipc	ra,0xffffe
    80003108:	f4a080e7          	jalr	-182(ra) # 8000104e <strlen>
}
    8000310c:	70a2                	ld	ra,40(sp)
    8000310e:	7402                	ld	s0,32(sp)
    80003110:	64e2                	ld	s1,24(sp)
    80003112:	6942                	ld	s2,16(sp)
    80003114:	69a2                	ld	s3,8(sp)
    80003116:	6145                	addi	sp,sp,48
    80003118:	8082                	ret
        return -1;
    8000311a:	557d                	li	a0,-1
    8000311c:	bfc5                	j	8000310c <fetchstr+0x3a>

000000008000311e <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    8000311e:	1101                	addi	sp,sp,-32
    80003120:	ec06                	sd	ra,24(sp)
    80003122:	e822                	sd	s0,16(sp)
    80003124:	e426                	sd	s1,8(sp)
    80003126:	1000                	addi	s0,sp,32
    80003128:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000312a:	00000097          	auipc	ra,0x0
    8000312e:	eee080e7          	jalr	-274(ra) # 80003018 <argraw>
    80003132:	c088                	sw	a0,0(s1)
}
    80003134:	60e2                	ld	ra,24(sp)
    80003136:	6442                	ld	s0,16(sp)
    80003138:	64a2                	ld	s1,8(sp)
    8000313a:	6105                	addi	sp,sp,32
    8000313c:	8082                	ret

000000008000313e <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    8000313e:	1101                	addi	sp,sp,-32
    80003140:	ec06                	sd	ra,24(sp)
    80003142:	e822                	sd	s0,16(sp)
    80003144:	e426                	sd	s1,8(sp)
    80003146:	1000                	addi	s0,sp,32
    80003148:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000314a:	00000097          	auipc	ra,0x0
    8000314e:	ece080e7          	jalr	-306(ra) # 80003018 <argraw>
    80003152:	e088                	sd	a0,0(s1)
}
    80003154:	60e2                	ld	ra,24(sp)
    80003156:	6442                	ld	s0,16(sp)
    80003158:	64a2                	ld	s1,8(sp)
    8000315a:	6105                	addi	sp,sp,32
    8000315c:	8082                	ret

000000008000315e <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    8000315e:	7179                	addi	sp,sp,-48
    80003160:	f406                	sd	ra,40(sp)
    80003162:	f022                	sd	s0,32(sp)
    80003164:	ec26                	sd	s1,24(sp)
    80003166:	e84a                	sd	s2,16(sp)
    80003168:	1800                	addi	s0,sp,48
    8000316a:	84ae                	mv	s1,a1
    8000316c:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    8000316e:	fd840593          	addi	a1,s0,-40
    80003172:	00000097          	auipc	ra,0x0
    80003176:	fcc080e7          	jalr	-52(ra) # 8000313e <argaddr>
    return fetchstr(addr, buf, max);
    8000317a:	864a                	mv	a2,s2
    8000317c:	85a6                	mv	a1,s1
    8000317e:	fd843503          	ld	a0,-40(s0)
    80003182:	00000097          	auipc	ra,0x0
    80003186:	f50080e7          	jalr	-176(ra) # 800030d2 <fetchstr>
}
    8000318a:	70a2                	ld	ra,40(sp)
    8000318c:	7402                	ld	s0,32(sp)
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6942                	ld	s2,16(sp)
    80003192:	6145                	addi	sp,sp,48
    80003194:	8082                	ret

0000000080003196 <syscall>:
    [SYS_pfreepages] sys_pfreepages,
    [SYS_va2pa] sys_va2pa,
};

void syscall(void)
{
    80003196:	1101                	addi	sp,sp,-32
    80003198:	ec06                	sd	ra,24(sp)
    8000319a:	e822                	sd	s0,16(sp)
    8000319c:	e426                	sd	s1,8(sp)
    8000319e:	e04a                	sd	s2,0(sp)
    800031a0:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800031a2:	fffff097          	auipc	ra,0xfffff
    800031a6:	c0a080e7          	jalr	-1014(ra) # 80001dac <myproc>
    800031aa:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800031ac:	05853903          	ld	s2,88(a0)
    800031b0:	0a893783          	ld	a5,168(s2)
    800031b4:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800031b8:	37fd                	addiw	a5,a5,-1
    800031ba:	4765                	li	a4,25
    800031bc:	00f76f63          	bltu	a4,a5,800031da <syscall+0x44>
    800031c0:	00369713          	slli	a4,a3,0x3
    800031c4:	00005797          	auipc	a5,0x5
    800031c8:	3dc78793          	addi	a5,a5,988 # 800085a0 <syscalls>
    800031cc:	97ba                	add	a5,a5,a4
    800031ce:	639c                	ld	a5,0(a5)
    800031d0:	c789                	beqz	a5,800031da <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800031d2:	9782                	jalr	a5
    800031d4:	06a93823          	sd	a0,112(s2)
    800031d8:	a839                	j	800031f6 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800031da:	15848613          	addi	a2,s1,344
    800031de:	588c                	lw	a1,48(s1)
    800031e0:	00005517          	auipc	a0,0x5
    800031e4:	38850513          	addi	a0,a0,904 # 80008568 <states.0+0x168>
    800031e8:	ffffd097          	auipc	ra,0xffffd
    800031ec:	3b0080e7          	jalr	944(ra) # 80000598 <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800031f0:	6cbc                	ld	a5,88(s1)
    800031f2:	577d                	li	a4,-1
    800031f4:	fbb8                	sd	a4,112(a5)
    }
}
    800031f6:	60e2                	ld	ra,24(sp)
    800031f8:	6442                	ld	s0,16(sp)
    800031fa:	64a2                	ld	s1,8(sp)
    800031fc:	6902                	ld	s2,0(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <sys_exit>:
extern uint64 FREE_PAGES; // kalloc.c keeps track of those
extern struct proc proc[];

uint64
sys_exit(void)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000320a:	fec40593          	addi	a1,s0,-20
    8000320e:	4501                	li	a0,0
    80003210:	00000097          	auipc	ra,0x0
    80003214:	f0e080e7          	jalr	-242(ra) # 8000311e <argint>
    exit(n);
    80003218:	fec42503          	lw	a0,-20(s0)
    8000321c:	fffff097          	auipc	ra,0xfffff
    80003220:	42c080e7          	jalr	1068(ra) # 80002648 <exit>
    return 0; // not reached
}
    80003224:	4501                	li	a0,0
    80003226:	60e2                	ld	ra,24(sp)
    80003228:	6442                	ld	s0,16(sp)
    8000322a:	6105                	addi	sp,sp,32
    8000322c:	8082                	ret

000000008000322e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000322e:	1141                	addi	sp,sp,-16
    80003230:	e406                	sd	ra,8(sp)
    80003232:	e022                	sd	s0,0(sp)
    80003234:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003236:	fffff097          	auipc	ra,0xfffff
    8000323a:	b76080e7          	jalr	-1162(ra) # 80001dac <myproc>
}
    8000323e:	5908                	lw	a0,48(a0)
    80003240:	60a2                	ld	ra,8(sp)
    80003242:	6402                	ld	s0,0(sp)
    80003244:	0141                	addi	sp,sp,16
    80003246:	8082                	ret

0000000080003248 <sys_fork>:

uint64
sys_fork(void)
{
    80003248:	1141                	addi	sp,sp,-16
    8000324a:	e406                	sd	ra,8(sp)
    8000324c:	e022                	sd	s0,0(sp)
    8000324e:	0800                	addi	s0,sp,16
    return fork();
    80003250:	fffff097          	auipc	ra,0xfffff
    80003254:	062080e7          	jalr	98(ra) # 800022b2 <fork>
}
    80003258:	60a2                	ld	ra,8(sp)
    8000325a:	6402                	ld	s0,0(sp)
    8000325c:	0141                	addi	sp,sp,16
    8000325e:	8082                	ret

0000000080003260 <sys_wait>:

uint64
sys_wait(void)
{
    80003260:	1101                	addi	sp,sp,-32
    80003262:	ec06                	sd	ra,24(sp)
    80003264:	e822                	sd	s0,16(sp)
    80003266:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    80003268:	fe840593          	addi	a1,s0,-24
    8000326c:	4501                	li	a0,0
    8000326e:	00000097          	auipc	ra,0x0
    80003272:	ed0080e7          	jalr	-304(ra) # 8000313e <argaddr>
    return wait(p);
    80003276:	fe843503          	ld	a0,-24(s0)
    8000327a:	fffff097          	auipc	ra,0xfffff
    8000327e:	574080e7          	jalr	1396(ra) # 800027ee <wait>
}
    80003282:	60e2                	ld	ra,24(sp)
    80003284:	6442                	ld	s0,16(sp)
    80003286:	6105                	addi	sp,sp,32
    80003288:	8082                	ret

000000008000328a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000328a:	7179                	addi	sp,sp,-48
    8000328c:	f406                	sd	ra,40(sp)
    8000328e:	f022                	sd	s0,32(sp)
    80003290:	ec26                	sd	s1,24(sp)
    80003292:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003294:	fdc40593          	addi	a1,s0,-36
    80003298:	4501                	li	a0,0
    8000329a:	00000097          	auipc	ra,0x0
    8000329e:	e84080e7          	jalr	-380(ra) # 8000311e <argint>
    addr = myproc()->sz;
    800032a2:	fffff097          	auipc	ra,0xfffff
    800032a6:	b0a080e7          	jalr	-1270(ra) # 80001dac <myproc>
    800032aa:	6524                	ld	s1,72(a0)
    if (growproc(n) < 0)
    800032ac:	fdc42503          	lw	a0,-36(s0)
    800032b0:	fffff097          	auipc	ra,0xfffff
    800032b4:	e56080e7          	jalr	-426(ra) # 80002106 <growproc>
    800032b8:	00054863          	bltz	a0,800032c8 <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800032bc:	8526                	mv	a0,s1
    800032be:	70a2                	ld	ra,40(sp)
    800032c0:	7402                	ld	s0,32(sp)
    800032c2:	64e2                	ld	s1,24(sp)
    800032c4:	6145                	addi	sp,sp,48
    800032c6:	8082                	ret
        return -1;
    800032c8:	54fd                	li	s1,-1
    800032ca:	bfcd                	j	800032bc <sys_sbrk+0x32>

00000000800032cc <sys_sleep>:

uint64
sys_sleep(void)
{
    800032cc:	7139                	addi	sp,sp,-64
    800032ce:	fc06                	sd	ra,56(sp)
    800032d0:	f822                	sd	s0,48(sp)
    800032d2:	f426                	sd	s1,40(sp)
    800032d4:	f04a                	sd	s2,32(sp)
    800032d6:	ec4e                	sd	s3,24(sp)
    800032d8:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800032da:	fcc40593          	addi	a1,s0,-52
    800032de:	4501                	li	a0,0
    800032e0:	00000097          	auipc	ra,0x0
    800032e4:	e3e080e7          	jalr	-450(ra) # 8000311e <argint>
    acquire(&tickslock);
    800032e8:	00234517          	auipc	a0,0x234
    800032ec:	84850513          	addi	a0,a0,-1976 # 80236b30 <tickslock>
    800032f0:	ffffe097          	auipc	ra,0xffffe
    800032f4:	ae8080e7          	jalr	-1304(ra) # 80000dd8 <acquire>
    ticks0 = ticks;
    800032f8:	00005917          	auipc	s2,0x5
    800032fc:	79892903          	lw	s2,1944(s2) # 80008a90 <ticks>
    while (ticks - ticks0 < n)
    80003300:	fcc42783          	lw	a5,-52(s0)
    80003304:	cf9d                	beqz	a5,80003342 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003306:	00234997          	auipc	s3,0x234
    8000330a:	82a98993          	addi	s3,s3,-2006 # 80236b30 <tickslock>
    8000330e:	00005497          	auipc	s1,0x5
    80003312:	78248493          	addi	s1,s1,1922 # 80008a90 <ticks>
        if (killed(myproc()))
    80003316:	fffff097          	auipc	ra,0xfffff
    8000331a:	a96080e7          	jalr	-1386(ra) # 80001dac <myproc>
    8000331e:	fffff097          	auipc	ra,0xfffff
    80003322:	49e080e7          	jalr	1182(ra) # 800027bc <killed>
    80003326:	ed15                	bnez	a0,80003362 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    80003328:	85ce                	mv	a1,s3
    8000332a:	8526                	mv	a0,s1
    8000332c:	fffff097          	auipc	ra,0xfffff
    80003330:	1e8080e7          	jalr	488(ra) # 80002514 <sleep>
    while (ticks - ticks0 < n)
    80003334:	409c                	lw	a5,0(s1)
    80003336:	412787bb          	subw	a5,a5,s2
    8000333a:	fcc42703          	lw	a4,-52(s0)
    8000333e:	fce7ece3          	bltu	a5,a4,80003316 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003342:	00233517          	auipc	a0,0x233
    80003346:	7ee50513          	addi	a0,a0,2030 # 80236b30 <tickslock>
    8000334a:	ffffe097          	auipc	ra,0xffffe
    8000334e:	b42080e7          	jalr	-1214(ra) # 80000e8c <release>
    return 0;
    80003352:	4501                	li	a0,0
}
    80003354:	70e2                	ld	ra,56(sp)
    80003356:	7442                	ld	s0,48(sp)
    80003358:	74a2                	ld	s1,40(sp)
    8000335a:	7902                	ld	s2,32(sp)
    8000335c:	69e2                	ld	s3,24(sp)
    8000335e:	6121                	addi	sp,sp,64
    80003360:	8082                	ret
            release(&tickslock);
    80003362:	00233517          	auipc	a0,0x233
    80003366:	7ce50513          	addi	a0,a0,1998 # 80236b30 <tickslock>
    8000336a:	ffffe097          	auipc	ra,0xffffe
    8000336e:	b22080e7          	jalr	-1246(ra) # 80000e8c <release>
            return -1;
    80003372:	557d                	li	a0,-1
    80003374:	b7c5                	j	80003354 <sys_sleep+0x88>

0000000080003376 <sys_kill>:

uint64
sys_kill(void)
{
    80003376:	1101                	addi	sp,sp,-32
    80003378:	ec06                	sd	ra,24(sp)
    8000337a:	e822                	sd	s0,16(sp)
    8000337c:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    8000337e:	fec40593          	addi	a1,s0,-20
    80003382:	4501                	li	a0,0
    80003384:	00000097          	auipc	ra,0x0
    80003388:	d9a080e7          	jalr	-614(ra) # 8000311e <argint>
    return kill(pid);
    8000338c:	fec42503          	lw	a0,-20(s0)
    80003390:	fffff097          	auipc	ra,0xfffff
    80003394:	38e080e7          	jalr	910(ra) # 8000271e <kill>
}
    80003398:	60e2                	ld	ra,24(sp)
    8000339a:	6442                	ld	s0,16(sp)
    8000339c:	6105                	addi	sp,sp,32
    8000339e:	8082                	ret

00000000800033a0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800033a0:	1101                	addi	sp,sp,-32
    800033a2:	ec06                	sd	ra,24(sp)
    800033a4:	e822                	sd	s0,16(sp)
    800033a6:	e426                	sd	s1,8(sp)
    800033a8:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800033aa:	00233517          	auipc	a0,0x233
    800033ae:	78650513          	addi	a0,a0,1926 # 80236b30 <tickslock>
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	a26080e7          	jalr	-1498(ra) # 80000dd8 <acquire>
    xticks = ticks;
    800033ba:	00005497          	auipc	s1,0x5
    800033be:	6d64a483          	lw	s1,1750(s1) # 80008a90 <ticks>
    release(&tickslock);
    800033c2:	00233517          	auipc	a0,0x233
    800033c6:	76e50513          	addi	a0,a0,1902 # 80236b30 <tickslock>
    800033ca:	ffffe097          	auipc	ra,0xffffe
    800033ce:	ac2080e7          	jalr	-1342(ra) # 80000e8c <release>
    return xticks;
}
    800033d2:	02049513          	slli	a0,s1,0x20
    800033d6:	9101                	srli	a0,a0,0x20
    800033d8:	60e2                	ld	ra,24(sp)
    800033da:	6442                	ld	s0,16(sp)
    800033dc:	64a2                	ld	s1,8(sp)
    800033de:	6105                	addi	sp,sp,32
    800033e0:	8082                	ret

00000000800033e2 <sys_ps>:

void *
sys_ps(void)
{
    800033e2:	1101                	addi	sp,sp,-32
    800033e4:	ec06                	sd	ra,24(sp)
    800033e6:	e822                	sd	s0,16(sp)
    800033e8:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800033ea:	fe042623          	sw	zero,-20(s0)
    800033ee:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800033f2:	fec40593          	addi	a1,s0,-20
    800033f6:	4501                	li	a0,0
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	d26080e7          	jalr	-730(ra) # 8000311e <argint>
    argint(1, &count);
    80003400:	fe840593          	addi	a1,s0,-24
    80003404:	4505                	li	a0,1
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	d18080e7          	jalr	-744(ra) # 8000311e <argint>
    return ps((uint8)start, (uint8)count);
    8000340e:	fe844583          	lbu	a1,-24(s0)
    80003412:	fec44503          	lbu	a0,-20(s0)
    80003416:	fffff097          	auipc	ra,0xfffff
    8000341a:	d4c080e7          	jalr	-692(ra) # 80002162 <ps>
}
    8000341e:	60e2                	ld	ra,24(sp)
    80003420:	6442                	ld	s0,16(sp)
    80003422:	6105                	addi	sp,sp,32
    80003424:	8082                	ret

0000000080003426 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003426:	1141                	addi	sp,sp,-16
    80003428:	e406                	sd	ra,8(sp)
    8000342a:	e022                	sd	s0,0(sp)
    8000342c:	0800                	addi	s0,sp,16
    schedls();
    8000342e:	fffff097          	auipc	ra,0xfffff
    80003432:	64a080e7          	jalr	1610(ra) # 80002a78 <schedls>
    return 0;
}
    80003436:	4501                	li	a0,0
    80003438:	60a2                	ld	ra,8(sp)
    8000343a:	6402                	ld	s0,0(sp)
    8000343c:	0141                	addi	sp,sp,16
    8000343e:	8082                	ret

0000000080003440 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003440:	1101                	addi	sp,sp,-32
    80003442:	ec06                	sd	ra,24(sp)
    80003444:	e822                	sd	s0,16(sp)
    80003446:	1000                	addi	s0,sp,32
    int id = 0;
    80003448:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000344c:	fec40593          	addi	a1,s0,-20
    80003450:	4501                	li	a0,0
    80003452:	00000097          	auipc	ra,0x0
    80003456:	ccc080e7          	jalr	-820(ra) # 8000311e <argint>
    schedset(id - 1);
    8000345a:	fec42503          	lw	a0,-20(s0)
    8000345e:	357d                	addiw	a0,a0,-1
    80003460:	fffff097          	auipc	ra,0xfffff
    80003464:	6ae080e7          	jalr	1710(ra) # 80002b0e <schedset>
    return 0;
}
    80003468:	4501                	li	a0,0
    8000346a:	60e2                	ld	ra,24(sp)
    8000346c:	6442                	ld	s0,16(sp)
    8000346e:	6105                	addi	sp,sp,32
    80003470:	8082                	ret

0000000080003472 <sys_va2pa>:

uint64 sys_va2pa(void)
{
    80003472:	7179                	addi	sp,sp,-48
    80003474:	f406                	sd	ra,40(sp)
    80003476:	f022                	sd	s0,32(sp)
    80003478:	ec26                	sd	s1,24(sp)
    8000347a:	e84a                	sd	s2,16(sp)
    8000347c:	1800                	addi	s0,sp,48
    int pid = 0;
    8000347e:	fc042e23          	sw	zero,-36(s0)
    uint64 va = 0;
    80003482:	fc043823          	sd	zero,-48(s0)
    
    argint(0, &pid);
    80003486:	fdc40593          	addi	a1,s0,-36
    8000348a:	4501                	li	a0,0
    8000348c:	00000097          	auipc	ra,0x0
    80003490:	c92080e7          	jalr	-878(ra) # 8000311e <argint>
    argaddr(1, &va);
    80003494:	fd040593          	addi	a1,s0,-48
    80003498:	4505                	li	a0,1
    8000349a:	00000097          	auipc	ra,0x0
    8000349e:	ca4080e7          	jalr	-860(ra) # 8000313e <argaddr>

    struct proc *p;
    int pidExists = 0;

    if (pid != 0) {
    800034a2:	fdc42783          	lw	a5,-36(s0)
    800034a6:	c3a5                	beqz	a5,80003506 <sys_va2pa+0x94>
        for (p = proc; p < &proc[NPROC]; p++) {
    800034a8:	0022e497          	auipc	s1,0x22e
    800034ac:	c8848493          	addi	s1,s1,-888 # 80231130 <proc>
    800034b0:	00233917          	auipc	s2,0x233
    800034b4:	68090913          	addi	s2,s2,1664 # 80236b30 <tickslock>
            acquire(&p->lock);
    800034b8:	8526                	mv	a0,s1
    800034ba:	ffffe097          	auipc	ra,0xffffe
    800034be:	91e080e7          	jalr	-1762(ra) # 80000dd8 <acquire>
            if (p->pid == pid) {
    800034c2:	5898                	lw	a4,48(s1)
    800034c4:	fdc42783          	lw	a5,-36(s0)
    800034c8:	00f70d63          	beq	a4,a5,800034e2 <sys_va2pa+0x70>
                release(&p->lock);
                pidExists = 1;
                break;
            }
            release(&p->lock);
    800034cc:	8526                	mv	a0,s1
    800034ce:	ffffe097          	auipc	ra,0xffffe
    800034d2:	9be080e7          	jalr	-1602(ra) # 80000e8c <release>
        for (p = proc; p < &proc[NPROC]; p++) {
    800034d6:	16848493          	addi	s1,s1,360
    800034da:	fd249fe3          	bne	s1,s2,800034b8 <sys_va2pa+0x46>
        }
        if (pidExists == 0) {
            return 0;
    800034de:	4501                	li	a0,0
    800034e0:	a829                	j	800034fa <sys_va2pa+0x88>
                release(&p->lock);
    800034e2:	8526                	mv	a0,s1
    800034e4:	ffffe097          	auipc	ra,0xffffe
    800034e8:	9a8080e7          	jalr	-1624(ra) # 80000e8c <release>
        p = myproc();
    }


    pagetable_t pagetable = p->pagetable;
    uint64 pa = walkaddr(pagetable, va);
    800034ec:	fd043583          	ld	a1,-48(s0)
    800034f0:	68a8                	ld	a0,80(s1)
    800034f2:	ffffe097          	auipc	ra,0xffffe
    800034f6:	d6a080e7          	jalr	-662(ra) # 8000125c <walkaddr>
    } else {
        return pa;
    }

    return 0;
}
    800034fa:	70a2                	ld	ra,40(sp)
    800034fc:	7402                	ld	s0,32(sp)
    800034fe:	64e2                	ld	s1,24(sp)
    80003500:	6942                	ld	s2,16(sp)
    80003502:	6145                	addi	sp,sp,48
    80003504:	8082                	ret
        printf("No pid supplied pid\n");
    80003506:	00005517          	auipc	a0,0x5
    8000350a:	17250513          	addi	a0,a0,370 # 80008678 <syscalls+0xd8>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	08a080e7          	jalr	138(ra) # 80000598 <printf>
        p = myproc();
    80003516:	fffff097          	auipc	ra,0xfffff
    8000351a:	896080e7          	jalr	-1898(ra) # 80001dac <myproc>
    8000351e:	84aa                	mv	s1,a0
    80003520:	b7f1                	j	800034ec <sys_va2pa+0x7a>

0000000080003522 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    80003522:	1141                	addi	sp,sp,-16
    80003524:	e406                	sd	ra,8(sp)
    80003526:	e022                	sd	s0,0(sp)
    80003528:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    8000352a:	00005597          	auipc	a1,0x5
    8000352e:	53e5b583          	ld	a1,1342(a1) # 80008a68 <FREE_PAGES>
    80003532:	00005517          	auipc	a0,0x5
    80003536:	04e50513          	addi	a0,a0,78 # 80008580 <states.0+0x180>
    8000353a:	ffffd097          	auipc	ra,0xffffd
    8000353e:	05e080e7          	jalr	94(ra) # 80000598 <printf>
    return 0;
    80003542:	4501                	li	a0,0
    80003544:	60a2                	ld	ra,8(sp)
    80003546:	6402                	ld	s0,0(sp)
    80003548:	0141                	addi	sp,sp,16
    8000354a:	8082                	ret

000000008000354c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000354c:	7179                	addi	sp,sp,-48
    8000354e:	f406                	sd	ra,40(sp)
    80003550:	f022                	sd	s0,32(sp)
    80003552:	ec26                	sd	s1,24(sp)
    80003554:	e84a                	sd	s2,16(sp)
    80003556:	e44e                	sd	s3,8(sp)
    80003558:	e052                	sd	s4,0(sp)
    8000355a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000355c:	00005597          	auipc	a1,0x5
    80003560:	13458593          	addi	a1,a1,308 # 80008690 <syscalls+0xf0>
    80003564:	00233517          	auipc	a0,0x233
    80003568:	5e450513          	addi	a0,a0,1508 # 80236b48 <bcache>
    8000356c:	ffffd097          	auipc	ra,0xffffd
    80003570:	7dc080e7          	jalr	2012(ra) # 80000d48 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003574:	0023b797          	auipc	a5,0x23b
    80003578:	5d478793          	addi	a5,a5,1492 # 8023eb48 <bcache+0x8000>
    8000357c:	0023c717          	auipc	a4,0x23c
    80003580:	83470713          	addi	a4,a4,-1996 # 8023edb0 <bcache+0x8268>
    80003584:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003588:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000358c:	00233497          	auipc	s1,0x233
    80003590:	5d448493          	addi	s1,s1,1492 # 80236b60 <bcache+0x18>
    b->next = bcache.head.next;
    80003594:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003596:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003598:	00005a17          	auipc	s4,0x5
    8000359c:	100a0a13          	addi	s4,s4,256 # 80008698 <syscalls+0xf8>
    b->next = bcache.head.next;
    800035a0:	2b893783          	ld	a5,696(s2)
    800035a4:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800035a6:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800035aa:	85d2                	mv	a1,s4
    800035ac:	01048513          	addi	a0,s1,16
    800035b0:	00001097          	auipc	ra,0x1
    800035b4:	496080e7          	jalr	1174(ra) # 80004a46 <initsleeplock>
    bcache.head.next->prev = b;
    800035b8:	2b893783          	ld	a5,696(s2)
    800035bc:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800035be:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800035c2:	45848493          	addi	s1,s1,1112
    800035c6:	fd349de3          	bne	s1,s3,800035a0 <binit+0x54>
  }
}
    800035ca:	70a2                	ld	ra,40(sp)
    800035cc:	7402                	ld	s0,32(sp)
    800035ce:	64e2                	ld	s1,24(sp)
    800035d0:	6942                	ld	s2,16(sp)
    800035d2:	69a2                	ld	s3,8(sp)
    800035d4:	6a02                	ld	s4,0(sp)
    800035d6:	6145                	addi	sp,sp,48
    800035d8:	8082                	ret

00000000800035da <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035da:	7179                	addi	sp,sp,-48
    800035dc:	f406                	sd	ra,40(sp)
    800035de:	f022                	sd	s0,32(sp)
    800035e0:	ec26                	sd	s1,24(sp)
    800035e2:	e84a                	sd	s2,16(sp)
    800035e4:	e44e                	sd	s3,8(sp)
    800035e6:	1800                	addi	s0,sp,48
    800035e8:	892a                	mv	s2,a0
    800035ea:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035ec:	00233517          	auipc	a0,0x233
    800035f0:	55c50513          	addi	a0,a0,1372 # 80236b48 <bcache>
    800035f4:	ffffd097          	auipc	ra,0xffffd
    800035f8:	7e4080e7          	jalr	2020(ra) # 80000dd8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035fc:	0023c497          	auipc	s1,0x23c
    80003600:	8044b483          	ld	s1,-2044(s1) # 8023ee00 <bcache+0x82b8>
    80003604:	0023b797          	auipc	a5,0x23b
    80003608:	7ac78793          	addi	a5,a5,1964 # 8023edb0 <bcache+0x8268>
    8000360c:	02f48f63          	beq	s1,a5,8000364a <bread+0x70>
    80003610:	873e                	mv	a4,a5
    80003612:	a021                	j	8000361a <bread+0x40>
    80003614:	68a4                	ld	s1,80(s1)
    80003616:	02e48a63          	beq	s1,a4,8000364a <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000361a:	449c                	lw	a5,8(s1)
    8000361c:	ff279ce3          	bne	a5,s2,80003614 <bread+0x3a>
    80003620:	44dc                	lw	a5,12(s1)
    80003622:	ff3799e3          	bne	a5,s3,80003614 <bread+0x3a>
      b->refcnt++;
    80003626:	40bc                	lw	a5,64(s1)
    80003628:	2785                	addiw	a5,a5,1
    8000362a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000362c:	00233517          	auipc	a0,0x233
    80003630:	51c50513          	addi	a0,a0,1308 # 80236b48 <bcache>
    80003634:	ffffe097          	auipc	ra,0xffffe
    80003638:	858080e7          	jalr	-1960(ra) # 80000e8c <release>
      acquiresleep(&b->lock);
    8000363c:	01048513          	addi	a0,s1,16
    80003640:	00001097          	auipc	ra,0x1
    80003644:	440080e7          	jalr	1088(ra) # 80004a80 <acquiresleep>
      return b;
    80003648:	a8b9                	j	800036a6 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000364a:	0023b497          	auipc	s1,0x23b
    8000364e:	7ae4b483          	ld	s1,1966(s1) # 8023edf8 <bcache+0x82b0>
    80003652:	0023b797          	auipc	a5,0x23b
    80003656:	75e78793          	addi	a5,a5,1886 # 8023edb0 <bcache+0x8268>
    8000365a:	00f48863          	beq	s1,a5,8000366a <bread+0x90>
    8000365e:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003660:	40bc                	lw	a5,64(s1)
    80003662:	cf81                	beqz	a5,8000367a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003664:	64a4                	ld	s1,72(s1)
    80003666:	fee49de3          	bne	s1,a4,80003660 <bread+0x86>
  panic("bget: no buffers");
    8000366a:	00005517          	auipc	a0,0x5
    8000366e:	03650513          	addi	a0,a0,54 # 800086a0 <syscalls+0x100>
    80003672:	ffffd097          	auipc	ra,0xffffd
    80003676:	eca080e7          	jalr	-310(ra) # 8000053c <panic>
      b->dev = dev;
    8000367a:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000367e:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003682:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003686:	4785                	li	a5,1
    80003688:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000368a:	00233517          	auipc	a0,0x233
    8000368e:	4be50513          	addi	a0,a0,1214 # 80236b48 <bcache>
    80003692:	ffffd097          	auipc	ra,0xffffd
    80003696:	7fa080e7          	jalr	2042(ra) # 80000e8c <release>
      acquiresleep(&b->lock);
    8000369a:	01048513          	addi	a0,s1,16
    8000369e:	00001097          	auipc	ra,0x1
    800036a2:	3e2080e7          	jalr	994(ra) # 80004a80 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800036a6:	409c                	lw	a5,0(s1)
    800036a8:	cb89                	beqz	a5,800036ba <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800036aa:	8526                	mv	a0,s1
    800036ac:	70a2                	ld	ra,40(sp)
    800036ae:	7402                	ld	s0,32(sp)
    800036b0:	64e2                	ld	s1,24(sp)
    800036b2:	6942                	ld	s2,16(sp)
    800036b4:	69a2                	ld	s3,8(sp)
    800036b6:	6145                	addi	sp,sp,48
    800036b8:	8082                	ret
    virtio_disk_rw(b, 0);
    800036ba:	4581                	li	a1,0
    800036bc:	8526                	mv	a0,s1
    800036be:	00003097          	auipc	ra,0x3
    800036c2:	f84080e7          	jalr	-124(ra) # 80006642 <virtio_disk_rw>
    b->valid = 1;
    800036c6:	4785                	li	a5,1
    800036c8:	c09c                	sw	a5,0(s1)
  return b;
    800036ca:	b7c5                	j	800036aa <bread+0xd0>

00000000800036cc <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036d8:	0541                	addi	a0,a0,16
    800036da:	00001097          	auipc	ra,0x1
    800036de:	440080e7          	jalr	1088(ra) # 80004b1a <holdingsleep>
    800036e2:	cd01                	beqz	a0,800036fa <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036e4:	4585                	li	a1,1
    800036e6:	8526                	mv	a0,s1
    800036e8:	00003097          	auipc	ra,0x3
    800036ec:	f5a080e7          	jalr	-166(ra) # 80006642 <virtio_disk_rw>
}
    800036f0:	60e2                	ld	ra,24(sp)
    800036f2:	6442                	ld	s0,16(sp)
    800036f4:	64a2                	ld	s1,8(sp)
    800036f6:	6105                	addi	sp,sp,32
    800036f8:	8082                	ret
    panic("bwrite");
    800036fa:	00005517          	auipc	a0,0x5
    800036fe:	fbe50513          	addi	a0,a0,-66 # 800086b8 <syscalls+0x118>
    80003702:	ffffd097          	auipc	ra,0xffffd
    80003706:	e3a080e7          	jalr	-454(ra) # 8000053c <panic>

000000008000370a <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000370a:	1101                	addi	sp,sp,-32
    8000370c:	ec06                	sd	ra,24(sp)
    8000370e:	e822                	sd	s0,16(sp)
    80003710:	e426                	sd	s1,8(sp)
    80003712:	e04a                	sd	s2,0(sp)
    80003714:	1000                	addi	s0,sp,32
    80003716:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003718:	01050913          	addi	s2,a0,16
    8000371c:	854a                	mv	a0,s2
    8000371e:	00001097          	auipc	ra,0x1
    80003722:	3fc080e7          	jalr	1020(ra) # 80004b1a <holdingsleep>
    80003726:	c925                	beqz	a0,80003796 <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    80003728:	854a                	mv	a0,s2
    8000372a:	00001097          	auipc	ra,0x1
    8000372e:	3ac080e7          	jalr	940(ra) # 80004ad6 <releasesleep>

  acquire(&bcache.lock);
    80003732:	00233517          	auipc	a0,0x233
    80003736:	41650513          	addi	a0,a0,1046 # 80236b48 <bcache>
    8000373a:	ffffd097          	auipc	ra,0xffffd
    8000373e:	69e080e7          	jalr	1694(ra) # 80000dd8 <acquire>
  b->refcnt--;
    80003742:	40bc                	lw	a5,64(s1)
    80003744:	37fd                	addiw	a5,a5,-1
    80003746:	0007871b          	sext.w	a4,a5
    8000374a:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000374c:	e71d                	bnez	a4,8000377a <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000374e:	68b8                	ld	a4,80(s1)
    80003750:	64bc                	ld	a5,72(s1)
    80003752:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003754:	68b8                	ld	a4,80(s1)
    80003756:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003758:	0023b797          	auipc	a5,0x23b
    8000375c:	3f078793          	addi	a5,a5,1008 # 8023eb48 <bcache+0x8000>
    80003760:	2b87b703          	ld	a4,696(a5)
    80003764:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003766:	0023b717          	auipc	a4,0x23b
    8000376a:	64a70713          	addi	a4,a4,1610 # 8023edb0 <bcache+0x8268>
    8000376e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003770:	2b87b703          	ld	a4,696(a5)
    80003774:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003776:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000377a:	00233517          	auipc	a0,0x233
    8000377e:	3ce50513          	addi	a0,a0,974 # 80236b48 <bcache>
    80003782:	ffffd097          	auipc	ra,0xffffd
    80003786:	70a080e7          	jalr	1802(ra) # 80000e8c <release>
}
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6902                	ld	s2,0(sp)
    80003792:	6105                	addi	sp,sp,32
    80003794:	8082                	ret
    panic("brelse");
    80003796:	00005517          	auipc	a0,0x5
    8000379a:	f2a50513          	addi	a0,a0,-214 # 800086c0 <syscalls+0x120>
    8000379e:	ffffd097          	auipc	ra,0xffffd
    800037a2:	d9e080e7          	jalr	-610(ra) # 8000053c <panic>

00000000800037a6 <bpin>:

void
bpin(struct buf *b) {
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b2:	00233517          	auipc	a0,0x233
    800037b6:	39650513          	addi	a0,a0,918 # 80236b48 <bcache>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	61e080e7          	jalr	1566(ra) # 80000dd8 <acquire>
  b->refcnt++;
    800037c2:	40bc                	lw	a5,64(s1)
    800037c4:	2785                	addiw	a5,a5,1
    800037c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037c8:	00233517          	auipc	a0,0x233
    800037cc:	38050513          	addi	a0,a0,896 # 80236b48 <bcache>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	6bc080e7          	jalr	1724(ra) # 80000e8c <release>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret

00000000800037e2 <bunpin>:

void
bunpin(struct buf *b) {
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	1000                	addi	s0,sp,32
    800037ec:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037ee:	00233517          	auipc	a0,0x233
    800037f2:	35a50513          	addi	a0,a0,858 # 80236b48 <bcache>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	5e2080e7          	jalr	1506(ra) # 80000dd8 <acquire>
  b->refcnt--;
    800037fe:	40bc                	lw	a5,64(s1)
    80003800:	37fd                	addiw	a5,a5,-1
    80003802:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003804:	00233517          	auipc	a0,0x233
    80003808:	34450513          	addi	a0,a0,836 # 80236b48 <bcache>
    8000380c:	ffffd097          	auipc	ra,0xffffd
    80003810:	680080e7          	jalr	1664(ra) # 80000e8c <release>
}
    80003814:	60e2                	ld	ra,24(sp)
    80003816:	6442                	ld	s0,16(sp)
    80003818:	64a2                	ld	s1,8(sp)
    8000381a:	6105                	addi	sp,sp,32
    8000381c:	8082                	ret

000000008000381e <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    8000381e:	1101                	addi	sp,sp,-32
    80003820:	ec06                	sd	ra,24(sp)
    80003822:	e822                	sd	s0,16(sp)
    80003824:	e426                	sd	s1,8(sp)
    80003826:	e04a                	sd	s2,0(sp)
    80003828:	1000                	addi	s0,sp,32
    8000382a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000382c:	00d5d59b          	srliw	a1,a1,0xd
    80003830:	0023c797          	auipc	a5,0x23c
    80003834:	9f47a783          	lw	a5,-1548(a5) # 8023f224 <sb+0x1c>
    80003838:	9dbd                	addw	a1,a1,a5
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	da0080e7          	jalr	-608(ra) # 800035da <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003842:	0074f713          	andi	a4,s1,7
    80003846:	4785                	li	a5,1
    80003848:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000384c:	14ce                	slli	s1,s1,0x33
    8000384e:	90d9                	srli	s1,s1,0x36
    80003850:	00950733          	add	a4,a0,s1
    80003854:	05874703          	lbu	a4,88(a4)
    80003858:	00e7f6b3          	and	a3,a5,a4
    8000385c:	c69d                	beqz	a3,8000388a <bfree+0x6c>
    8000385e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003860:	94aa                	add	s1,s1,a0
    80003862:	fff7c793          	not	a5,a5
    80003866:	8f7d                	and	a4,a4,a5
    80003868:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	0f6080e7          	jalr	246(ra) # 80004962 <log_write>
  brelse(bp);
    80003874:	854a                	mv	a0,s2
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	e94080e7          	jalr	-364(ra) # 8000370a <brelse>
}
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6902                	ld	s2,0(sp)
    80003886:	6105                	addi	sp,sp,32
    80003888:	8082                	ret
    panic("freeing free block");
    8000388a:	00005517          	auipc	a0,0x5
    8000388e:	e3e50513          	addi	a0,a0,-450 # 800086c8 <syscalls+0x128>
    80003892:	ffffd097          	auipc	ra,0xffffd
    80003896:	caa080e7          	jalr	-854(ra) # 8000053c <panic>

000000008000389a <balloc>:
{
    8000389a:	711d                	addi	sp,sp,-96
    8000389c:	ec86                	sd	ra,88(sp)
    8000389e:	e8a2                	sd	s0,80(sp)
    800038a0:	e4a6                	sd	s1,72(sp)
    800038a2:	e0ca                	sd	s2,64(sp)
    800038a4:	fc4e                	sd	s3,56(sp)
    800038a6:	f852                	sd	s4,48(sp)
    800038a8:	f456                	sd	s5,40(sp)
    800038aa:	f05a                	sd	s6,32(sp)
    800038ac:	ec5e                	sd	s7,24(sp)
    800038ae:	e862                	sd	s8,16(sp)
    800038b0:	e466                	sd	s9,8(sp)
    800038b2:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800038b4:	0023c797          	auipc	a5,0x23c
    800038b8:	9587a783          	lw	a5,-1704(a5) # 8023f20c <sb+0x4>
    800038bc:	cff5                	beqz	a5,800039b8 <balloc+0x11e>
    800038be:	8baa                	mv	s7,a0
    800038c0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800038c2:	0023cb17          	auipc	s6,0x23c
    800038c6:	946b0b13          	addi	s6,s6,-1722 # 8023f208 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ca:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038cc:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038ce:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038d0:	6c89                	lui	s9,0x2
    800038d2:	a061                	j	8000395a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038d4:	97ca                	add	a5,a5,s2
    800038d6:	8e55                	or	a2,a2,a3
    800038d8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800038dc:	854a                	mv	a0,s2
    800038de:	00001097          	auipc	ra,0x1
    800038e2:	084080e7          	jalr	132(ra) # 80004962 <log_write>
        brelse(bp);
    800038e6:	854a                	mv	a0,s2
    800038e8:	00000097          	auipc	ra,0x0
    800038ec:	e22080e7          	jalr	-478(ra) # 8000370a <brelse>
  bp = bread(dev, bno);
    800038f0:	85a6                	mv	a1,s1
    800038f2:	855e                	mv	a0,s7
    800038f4:	00000097          	auipc	ra,0x0
    800038f8:	ce6080e7          	jalr	-794(ra) # 800035da <bread>
    800038fc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038fe:	40000613          	li	a2,1024
    80003902:	4581                	li	a1,0
    80003904:	05850513          	addi	a0,a0,88
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	5cc080e7          	jalr	1484(ra) # 80000ed4 <memset>
  log_write(bp);
    80003910:	854a                	mv	a0,s2
    80003912:	00001097          	auipc	ra,0x1
    80003916:	050080e7          	jalr	80(ra) # 80004962 <log_write>
  brelse(bp);
    8000391a:	854a                	mv	a0,s2
    8000391c:	00000097          	auipc	ra,0x0
    80003920:	dee080e7          	jalr	-530(ra) # 8000370a <brelse>
}
    80003924:	8526                	mv	a0,s1
    80003926:	60e6                	ld	ra,88(sp)
    80003928:	6446                	ld	s0,80(sp)
    8000392a:	64a6                	ld	s1,72(sp)
    8000392c:	6906                	ld	s2,64(sp)
    8000392e:	79e2                	ld	s3,56(sp)
    80003930:	7a42                	ld	s4,48(sp)
    80003932:	7aa2                	ld	s5,40(sp)
    80003934:	7b02                	ld	s6,32(sp)
    80003936:	6be2                	ld	s7,24(sp)
    80003938:	6c42                	ld	s8,16(sp)
    8000393a:	6ca2                	ld	s9,8(sp)
    8000393c:	6125                	addi	sp,sp,96
    8000393e:	8082                	ret
    brelse(bp);
    80003940:	854a                	mv	a0,s2
    80003942:	00000097          	auipc	ra,0x0
    80003946:	dc8080e7          	jalr	-568(ra) # 8000370a <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000394a:	015c87bb          	addw	a5,s9,s5
    8000394e:	00078a9b          	sext.w	s5,a5
    80003952:	004b2703          	lw	a4,4(s6)
    80003956:	06eaf163          	bgeu	s5,a4,800039b8 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000395a:	41fad79b          	sraiw	a5,s5,0x1f
    8000395e:	0137d79b          	srliw	a5,a5,0x13
    80003962:	015787bb          	addw	a5,a5,s5
    80003966:	40d7d79b          	sraiw	a5,a5,0xd
    8000396a:	01cb2583          	lw	a1,28(s6)
    8000396e:	9dbd                	addw	a1,a1,a5
    80003970:	855e                	mv	a0,s7
    80003972:	00000097          	auipc	ra,0x0
    80003976:	c68080e7          	jalr	-920(ra) # 800035da <bread>
    8000397a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000397c:	004b2503          	lw	a0,4(s6)
    80003980:	000a849b          	sext.w	s1,s5
    80003984:	8762                	mv	a4,s8
    80003986:	faa4fde3          	bgeu	s1,a0,80003940 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000398a:	00777693          	andi	a3,a4,7
    8000398e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003992:	41f7579b          	sraiw	a5,a4,0x1f
    80003996:	01d7d79b          	srliw	a5,a5,0x1d
    8000399a:	9fb9                	addw	a5,a5,a4
    8000399c:	4037d79b          	sraiw	a5,a5,0x3
    800039a0:	00f90633          	add	a2,s2,a5
    800039a4:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800039a8:	00c6f5b3          	and	a1,a3,a2
    800039ac:	d585                	beqz	a1,800038d4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800039ae:	2705                	addiw	a4,a4,1
    800039b0:	2485                	addiw	s1,s1,1
    800039b2:	fd471ae3          	bne	a4,s4,80003986 <balloc+0xec>
    800039b6:	b769                	j	80003940 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800039b8:	00005517          	auipc	a0,0x5
    800039bc:	d2850513          	addi	a0,a0,-728 # 800086e0 <syscalls+0x140>
    800039c0:	ffffd097          	auipc	ra,0xffffd
    800039c4:	bd8080e7          	jalr	-1064(ra) # 80000598 <printf>
  return 0;
    800039c8:	4481                	li	s1,0
    800039ca:	bfa9                	j	80003924 <balloc+0x8a>

00000000800039cc <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800039cc:	7179                	addi	sp,sp,-48
    800039ce:	f406                	sd	ra,40(sp)
    800039d0:	f022                	sd	s0,32(sp)
    800039d2:	ec26                	sd	s1,24(sp)
    800039d4:	e84a                	sd	s2,16(sp)
    800039d6:	e44e                	sd	s3,8(sp)
    800039d8:	e052                	sd	s4,0(sp)
    800039da:	1800                	addi	s0,sp,48
    800039dc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039de:	47ad                	li	a5,11
    800039e0:	02b7e863          	bltu	a5,a1,80003a10 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800039e4:	02059793          	slli	a5,a1,0x20
    800039e8:	01e7d593          	srli	a1,a5,0x1e
    800039ec:	00b504b3          	add	s1,a0,a1
    800039f0:	0504a903          	lw	s2,80(s1)
    800039f4:	06091e63          	bnez	s2,80003a70 <bmap+0xa4>
      addr = balloc(ip->dev);
    800039f8:	4108                	lw	a0,0(a0)
    800039fa:	00000097          	auipc	ra,0x0
    800039fe:	ea0080e7          	jalr	-352(ra) # 8000389a <balloc>
    80003a02:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a06:	06090563          	beqz	s2,80003a70 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003a0a:	0524a823          	sw	s2,80(s1)
    80003a0e:	a08d                	j	80003a70 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003a10:	ff45849b          	addiw	s1,a1,-12
    80003a14:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003a18:	0ff00793          	li	a5,255
    80003a1c:	08e7e563          	bltu	a5,a4,80003aa6 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003a20:	08052903          	lw	s2,128(a0)
    80003a24:	00091d63          	bnez	s2,80003a3e <bmap+0x72>
      addr = balloc(ip->dev);
    80003a28:	4108                	lw	a0,0(a0)
    80003a2a:	00000097          	auipc	ra,0x0
    80003a2e:	e70080e7          	jalr	-400(ra) # 8000389a <balloc>
    80003a32:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a36:	02090d63          	beqz	s2,80003a70 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a3a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a3e:	85ca                	mv	a1,s2
    80003a40:	0009a503          	lw	a0,0(s3)
    80003a44:	00000097          	auipc	ra,0x0
    80003a48:	b96080e7          	jalr	-1130(ra) # 800035da <bread>
    80003a4c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a4e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a52:	02049713          	slli	a4,s1,0x20
    80003a56:	01e75593          	srli	a1,a4,0x1e
    80003a5a:	00b784b3          	add	s1,a5,a1
    80003a5e:	0004a903          	lw	s2,0(s1)
    80003a62:	02090063          	beqz	s2,80003a82 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a66:	8552                	mv	a0,s4
    80003a68:	00000097          	auipc	ra,0x0
    80003a6c:	ca2080e7          	jalr	-862(ra) # 8000370a <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a70:	854a                	mv	a0,s2
    80003a72:	70a2                	ld	ra,40(sp)
    80003a74:	7402                	ld	s0,32(sp)
    80003a76:	64e2                	ld	s1,24(sp)
    80003a78:	6942                	ld	s2,16(sp)
    80003a7a:	69a2                	ld	s3,8(sp)
    80003a7c:	6a02                	ld	s4,0(sp)
    80003a7e:	6145                	addi	sp,sp,48
    80003a80:	8082                	ret
      addr = balloc(ip->dev);
    80003a82:	0009a503          	lw	a0,0(s3)
    80003a86:	00000097          	auipc	ra,0x0
    80003a8a:	e14080e7          	jalr	-492(ra) # 8000389a <balloc>
    80003a8e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a92:	fc090ae3          	beqz	s2,80003a66 <bmap+0x9a>
        a[bn] = addr;
    80003a96:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a9a:	8552                	mv	a0,s4
    80003a9c:	00001097          	auipc	ra,0x1
    80003aa0:	ec6080e7          	jalr	-314(ra) # 80004962 <log_write>
    80003aa4:	b7c9                	j	80003a66 <bmap+0x9a>
  panic("bmap: out of range");
    80003aa6:	00005517          	auipc	a0,0x5
    80003aaa:	c5250513          	addi	a0,a0,-942 # 800086f8 <syscalls+0x158>
    80003aae:	ffffd097          	auipc	ra,0xffffd
    80003ab2:	a8e080e7          	jalr	-1394(ra) # 8000053c <panic>

0000000080003ab6 <iget>:
{
    80003ab6:	7179                	addi	sp,sp,-48
    80003ab8:	f406                	sd	ra,40(sp)
    80003aba:	f022                	sd	s0,32(sp)
    80003abc:	ec26                	sd	s1,24(sp)
    80003abe:	e84a                	sd	s2,16(sp)
    80003ac0:	e44e                	sd	s3,8(sp)
    80003ac2:	e052                	sd	s4,0(sp)
    80003ac4:	1800                	addi	s0,sp,48
    80003ac6:	89aa                	mv	s3,a0
    80003ac8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003aca:	0023b517          	auipc	a0,0x23b
    80003ace:	75e50513          	addi	a0,a0,1886 # 8023f228 <itable>
    80003ad2:	ffffd097          	auipc	ra,0xffffd
    80003ad6:	306080e7          	jalr	774(ra) # 80000dd8 <acquire>
  empty = 0;
    80003ada:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003adc:	0023b497          	auipc	s1,0x23b
    80003ae0:	76448493          	addi	s1,s1,1892 # 8023f240 <itable+0x18>
    80003ae4:	0023d697          	auipc	a3,0x23d
    80003ae8:	1ec68693          	addi	a3,a3,492 # 80240cd0 <log>
    80003aec:	a039                	j	80003afa <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aee:	02090b63          	beqz	s2,80003b24 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003af2:	08848493          	addi	s1,s1,136
    80003af6:	02d48a63          	beq	s1,a3,80003b2a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003afa:	449c                	lw	a5,8(s1)
    80003afc:	fef059e3          	blez	a5,80003aee <iget+0x38>
    80003b00:	4098                	lw	a4,0(s1)
    80003b02:	ff3716e3          	bne	a4,s3,80003aee <iget+0x38>
    80003b06:	40d8                	lw	a4,4(s1)
    80003b08:	ff4713e3          	bne	a4,s4,80003aee <iget+0x38>
      ip->ref++;
    80003b0c:	2785                	addiw	a5,a5,1
    80003b0e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003b10:	0023b517          	auipc	a0,0x23b
    80003b14:	71850513          	addi	a0,a0,1816 # 8023f228 <itable>
    80003b18:	ffffd097          	auipc	ra,0xffffd
    80003b1c:	374080e7          	jalr	884(ra) # 80000e8c <release>
      return ip;
    80003b20:	8926                	mv	s2,s1
    80003b22:	a03d                	j	80003b50 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003b24:	f7f9                	bnez	a5,80003af2 <iget+0x3c>
    80003b26:	8926                	mv	s2,s1
    80003b28:	b7e9                	j	80003af2 <iget+0x3c>
  if(empty == 0)
    80003b2a:	02090c63          	beqz	s2,80003b62 <iget+0xac>
  ip->dev = dev;
    80003b2e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b32:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b36:	4785                	li	a5,1
    80003b38:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b3c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b40:	0023b517          	auipc	a0,0x23b
    80003b44:	6e850513          	addi	a0,a0,1768 # 8023f228 <itable>
    80003b48:	ffffd097          	auipc	ra,0xffffd
    80003b4c:	344080e7          	jalr	836(ra) # 80000e8c <release>
}
    80003b50:	854a                	mv	a0,s2
    80003b52:	70a2                	ld	ra,40(sp)
    80003b54:	7402                	ld	s0,32(sp)
    80003b56:	64e2                	ld	s1,24(sp)
    80003b58:	6942                	ld	s2,16(sp)
    80003b5a:	69a2                	ld	s3,8(sp)
    80003b5c:	6a02                	ld	s4,0(sp)
    80003b5e:	6145                	addi	sp,sp,48
    80003b60:	8082                	ret
    panic("iget: no inodes");
    80003b62:	00005517          	auipc	a0,0x5
    80003b66:	bae50513          	addi	a0,a0,-1106 # 80008710 <syscalls+0x170>
    80003b6a:	ffffd097          	auipc	ra,0xffffd
    80003b6e:	9d2080e7          	jalr	-1582(ra) # 8000053c <panic>

0000000080003b72 <fsinit>:
fsinit(int dev) {
    80003b72:	7179                	addi	sp,sp,-48
    80003b74:	f406                	sd	ra,40(sp)
    80003b76:	f022                	sd	s0,32(sp)
    80003b78:	ec26                	sd	s1,24(sp)
    80003b7a:	e84a                	sd	s2,16(sp)
    80003b7c:	e44e                	sd	s3,8(sp)
    80003b7e:	1800                	addi	s0,sp,48
    80003b80:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b82:	4585                	li	a1,1
    80003b84:	00000097          	auipc	ra,0x0
    80003b88:	a56080e7          	jalr	-1450(ra) # 800035da <bread>
    80003b8c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b8e:	0023b997          	auipc	s3,0x23b
    80003b92:	67a98993          	addi	s3,s3,1658 # 8023f208 <sb>
    80003b96:	02000613          	li	a2,32
    80003b9a:	05850593          	addi	a1,a0,88
    80003b9e:	854e                	mv	a0,s3
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	390080e7          	jalr	912(ra) # 80000f30 <memmove>
  brelse(bp);
    80003ba8:	8526                	mv	a0,s1
    80003baa:	00000097          	auipc	ra,0x0
    80003bae:	b60080e7          	jalr	-1184(ra) # 8000370a <brelse>
  if(sb.magic != FSMAGIC)
    80003bb2:	0009a703          	lw	a4,0(s3)
    80003bb6:	102037b7          	lui	a5,0x10203
    80003bba:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003bbe:	02f71263          	bne	a4,a5,80003be2 <fsinit+0x70>
  initlog(dev, &sb);
    80003bc2:	0023b597          	auipc	a1,0x23b
    80003bc6:	64658593          	addi	a1,a1,1606 # 8023f208 <sb>
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	b2c080e7          	jalr	-1236(ra) # 800046f8 <initlog>
}
    80003bd4:	70a2                	ld	ra,40(sp)
    80003bd6:	7402                	ld	s0,32(sp)
    80003bd8:	64e2                	ld	s1,24(sp)
    80003bda:	6942                	ld	s2,16(sp)
    80003bdc:	69a2                	ld	s3,8(sp)
    80003bde:	6145                	addi	sp,sp,48
    80003be0:	8082                	ret
    panic("invalid file system");
    80003be2:	00005517          	auipc	a0,0x5
    80003be6:	b3e50513          	addi	a0,a0,-1218 # 80008720 <syscalls+0x180>
    80003bea:	ffffd097          	auipc	ra,0xffffd
    80003bee:	952080e7          	jalr	-1710(ra) # 8000053c <panic>

0000000080003bf2 <iinit>:
{
    80003bf2:	7179                	addi	sp,sp,-48
    80003bf4:	f406                	sd	ra,40(sp)
    80003bf6:	f022                	sd	s0,32(sp)
    80003bf8:	ec26                	sd	s1,24(sp)
    80003bfa:	e84a                	sd	s2,16(sp)
    80003bfc:	e44e                	sd	s3,8(sp)
    80003bfe:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003c00:	00005597          	auipc	a1,0x5
    80003c04:	b3858593          	addi	a1,a1,-1224 # 80008738 <syscalls+0x198>
    80003c08:	0023b517          	auipc	a0,0x23b
    80003c0c:	62050513          	addi	a0,a0,1568 # 8023f228 <itable>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	138080e7          	jalr	312(ra) # 80000d48 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003c18:	0023b497          	auipc	s1,0x23b
    80003c1c:	63848493          	addi	s1,s1,1592 # 8023f250 <itable+0x28>
    80003c20:	0023d997          	auipc	s3,0x23d
    80003c24:	0c098993          	addi	s3,s3,192 # 80240ce0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003c28:	00005917          	auipc	s2,0x5
    80003c2c:	b1890913          	addi	s2,s2,-1256 # 80008740 <syscalls+0x1a0>
    80003c30:	85ca                	mv	a1,s2
    80003c32:	8526                	mv	a0,s1
    80003c34:	00001097          	auipc	ra,0x1
    80003c38:	e12080e7          	jalr	-494(ra) # 80004a46 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c3c:	08848493          	addi	s1,s1,136
    80003c40:	ff3498e3          	bne	s1,s3,80003c30 <iinit+0x3e>
}
    80003c44:	70a2                	ld	ra,40(sp)
    80003c46:	7402                	ld	s0,32(sp)
    80003c48:	64e2                	ld	s1,24(sp)
    80003c4a:	6942                	ld	s2,16(sp)
    80003c4c:	69a2                	ld	s3,8(sp)
    80003c4e:	6145                	addi	sp,sp,48
    80003c50:	8082                	ret

0000000080003c52 <ialloc>:
{
    80003c52:	7139                	addi	sp,sp,-64
    80003c54:	fc06                	sd	ra,56(sp)
    80003c56:	f822                	sd	s0,48(sp)
    80003c58:	f426                	sd	s1,40(sp)
    80003c5a:	f04a                	sd	s2,32(sp)
    80003c5c:	ec4e                	sd	s3,24(sp)
    80003c5e:	e852                	sd	s4,16(sp)
    80003c60:	e456                	sd	s5,8(sp)
    80003c62:	e05a                	sd	s6,0(sp)
    80003c64:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c66:	0023b717          	auipc	a4,0x23b
    80003c6a:	5ae72703          	lw	a4,1454(a4) # 8023f214 <sb+0xc>
    80003c6e:	4785                	li	a5,1
    80003c70:	04e7f863          	bgeu	a5,a4,80003cc0 <ialloc+0x6e>
    80003c74:	8aaa                	mv	s5,a0
    80003c76:	8b2e                	mv	s6,a1
    80003c78:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c7a:	0023ba17          	auipc	s4,0x23b
    80003c7e:	58ea0a13          	addi	s4,s4,1422 # 8023f208 <sb>
    80003c82:	00495593          	srli	a1,s2,0x4
    80003c86:	018a2783          	lw	a5,24(s4)
    80003c8a:	9dbd                	addw	a1,a1,a5
    80003c8c:	8556                	mv	a0,s5
    80003c8e:	00000097          	auipc	ra,0x0
    80003c92:	94c080e7          	jalr	-1716(ra) # 800035da <bread>
    80003c96:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c98:	05850993          	addi	s3,a0,88
    80003c9c:	00f97793          	andi	a5,s2,15
    80003ca0:	079a                	slli	a5,a5,0x6
    80003ca2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ca4:	00099783          	lh	a5,0(s3)
    80003ca8:	cf9d                	beqz	a5,80003ce6 <ialloc+0x94>
    brelse(bp);
    80003caa:	00000097          	auipc	ra,0x0
    80003cae:	a60080e7          	jalr	-1440(ra) # 8000370a <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003cb2:	0905                	addi	s2,s2,1
    80003cb4:	00ca2703          	lw	a4,12(s4)
    80003cb8:	0009079b          	sext.w	a5,s2
    80003cbc:	fce7e3e3          	bltu	a5,a4,80003c82 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003cc0:	00005517          	auipc	a0,0x5
    80003cc4:	a8850513          	addi	a0,a0,-1400 # 80008748 <syscalls+0x1a8>
    80003cc8:	ffffd097          	auipc	ra,0xffffd
    80003ccc:	8d0080e7          	jalr	-1840(ra) # 80000598 <printf>
  return 0;
    80003cd0:	4501                	li	a0,0
}
    80003cd2:	70e2                	ld	ra,56(sp)
    80003cd4:	7442                	ld	s0,48(sp)
    80003cd6:	74a2                	ld	s1,40(sp)
    80003cd8:	7902                	ld	s2,32(sp)
    80003cda:	69e2                	ld	s3,24(sp)
    80003cdc:	6a42                	ld	s4,16(sp)
    80003cde:	6aa2                	ld	s5,8(sp)
    80003ce0:	6b02                	ld	s6,0(sp)
    80003ce2:	6121                	addi	sp,sp,64
    80003ce4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003ce6:	04000613          	li	a2,64
    80003cea:	4581                	li	a1,0
    80003cec:	854e                	mv	a0,s3
    80003cee:	ffffd097          	auipc	ra,0xffffd
    80003cf2:	1e6080e7          	jalr	486(ra) # 80000ed4 <memset>
      dip->type = type;
    80003cf6:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cfa:	8526                	mv	a0,s1
    80003cfc:	00001097          	auipc	ra,0x1
    80003d00:	c66080e7          	jalr	-922(ra) # 80004962 <log_write>
      brelse(bp);
    80003d04:	8526                	mv	a0,s1
    80003d06:	00000097          	auipc	ra,0x0
    80003d0a:	a04080e7          	jalr	-1532(ra) # 8000370a <brelse>
      return iget(dev, inum);
    80003d0e:	0009059b          	sext.w	a1,s2
    80003d12:	8556                	mv	a0,s5
    80003d14:	00000097          	auipc	ra,0x0
    80003d18:	da2080e7          	jalr	-606(ra) # 80003ab6 <iget>
    80003d1c:	bf5d                	j	80003cd2 <ialloc+0x80>

0000000080003d1e <iupdate>:
{
    80003d1e:	1101                	addi	sp,sp,-32
    80003d20:	ec06                	sd	ra,24(sp)
    80003d22:	e822                	sd	s0,16(sp)
    80003d24:	e426                	sd	s1,8(sp)
    80003d26:	e04a                	sd	s2,0(sp)
    80003d28:	1000                	addi	s0,sp,32
    80003d2a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d2c:	415c                	lw	a5,4(a0)
    80003d2e:	0047d79b          	srliw	a5,a5,0x4
    80003d32:	0023b597          	auipc	a1,0x23b
    80003d36:	4ee5a583          	lw	a1,1262(a1) # 8023f220 <sb+0x18>
    80003d3a:	9dbd                	addw	a1,a1,a5
    80003d3c:	4108                	lw	a0,0(a0)
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	89c080e7          	jalr	-1892(ra) # 800035da <bread>
    80003d46:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d48:	05850793          	addi	a5,a0,88
    80003d4c:	40d8                	lw	a4,4(s1)
    80003d4e:	8b3d                	andi	a4,a4,15
    80003d50:	071a                	slli	a4,a4,0x6
    80003d52:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d54:	04449703          	lh	a4,68(s1)
    80003d58:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d5c:	04649703          	lh	a4,70(s1)
    80003d60:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d64:	04849703          	lh	a4,72(s1)
    80003d68:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d6c:	04a49703          	lh	a4,74(s1)
    80003d70:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d74:	44f8                	lw	a4,76(s1)
    80003d76:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d78:	03400613          	li	a2,52
    80003d7c:	05048593          	addi	a1,s1,80
    80003d80:	00c78513          	addi	a0,a5,12
    80003d84:	ffffd097          	auipc	ra,0xffffd
    80003d88:	1ac080e7          	jalr	428(ra) # 80000f30 <memmove>
  log_write(bp);
    80003d8c:	854a                	mv	a0,s2
    80003d8e:	00001097          	auipc	ra,0x1
    80003d92:	bd4080e7          	jalr	-1068(ra) # 80004962 <log_write>
  brelse(bp);
    80003d96:	854a                	mv	a0,s2
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	972080e7          	jalr	-1678(ra) # 8000370a <brelse>
}
    80003da0:	60e2                	ld	ra,24(sp)
    80003da2:	6442                	ld	s0,16(sp)
    80003da4:	64a2                	ld	s1,8(sp)
    80003da6:	6902                	ld	s2,0(sp)
    80003da8:	6105                	addi	sp,sp,32
    80003daa:	8082                	ret

0000000080003dac <idup>:
{
    80003dac:	1101                	addi	sp,sp,-32
    80003dae:	ec06                	sd	ra,24(sp)
    80003db0:	e822                	sd	s0,16(sp)
    80003db2:	e426                	sd	s1,8(sp)
    80003db4:	1000                	addi	s0,sp,32
    80003db6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003db8:	0023b517          	auipc	a0,0x23b
    80003dbc:	47050513          	addi	a0,a0,1136 # 8023f228 <itable>
    80003dc0:	ffffd097          	auipc	ra,0xffffd
    80003dc4:	018080e7          	jalr	24(ra) # 80000dd8 <acquire>
  ip->ref++;
    80003dc8:	449c                	lw	a5,8(s1)
    80003dca:	2785                	addiw	a5,a5,1
    80003dcc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003dce:	0023b517          	auipc	a0,0x23b
    80003dd2:	45a50513          	addi	a0,a0,1114 # 8023f228 <itable>
    80003dd6:	ffffd097          	auipc	ra,0xffffd
    80003dda:	0b6080e7          	jalr	182(ra) # 80000e8c <release>
}
    80003dde:	8526                	mv	a0,s1
    80003de0:	60e2                	ld	ra,24(sp)
    80003de2:	6442                	ld	s0,16(sp)
    80003de4:	64a2                	ld	s1,8(sp)
    80003de6:	6105                	addi	sp,sp,32
    80003de8:	8082                	ret

0000000080003dea <ilock>:
{
    80003dea:	1101                	addi	sp,sp,-32
    80003dec:	ec06                	sd	ra,24(sp)
    80003dee:	e822                	sd	s0,16(sp)
    80003df0:	e426                	sd	s1,8(sp)
    80003df2:	e04a                	sd	s2,0(sp)
    80003df4:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003df6:	c115                	beqz	a0,80003e1a <ilock+0x30>
    80003df8:	84aa                	mv	s1,a0
    80003dfa:	451c                	lw	a5,8(a0)
    80003dfc:	00f05f63          	blez	a5,80003e1a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003e00:	0541                	addi	a0,a0,16
    80003e02:	00001097          	auipc	ra,0x1
    80003e06:	c7e080e7          	jalr	-898(ra) # 80004a80 <acquiresleep>
  if(ip->valid == 0){
    80003e0a:	40bc                	lw	a5,64(s1)
    80003e0c:	cf99                	beqz	a5,80003e2a <ilock+0x40>
}
    80003e0e:	60e2                	ld	ra,24(sp)
    80003e10:	6442                	ld	s0,16(sp)
    80003e12:	64a2                	ld	s1,8(sp)
    80003e14:	6902                	ld	s2,0(sp)
    80003e16:	6105                	addi	sp,sp,32
    80003e18:	8082                	ret
    panic("ilock");
    80003e1a:	00005517          	auipc	a0,0x5
    80003e1e:	94650513          	addi	a0,a0,-1722 # 80008760 <syscalls+0x1c0>
    80003e22:	ffffc097          	auipc	ra,0xffffc
    80003e26:	71a080e7          	jalr	1818(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003e2a:	40dc                	lw	a5,4(s1)
    80003e2c:	0047d79b          	srliw	a5,a5,0x4
    80003e30:	0023b597          	auipc	a1,0x23b
    80003e34:	3f05a583          	lw	a1,1008(a1) # 8023f220 <sb+0x18>
    80003e38:	9dbd                	addw	a1,a1,a5
    80003e3a:	4088                	lw	a0,0(s1)
    80003e3c:	fffff097          	auipc	ra,0xfffff
    80003e40:	79e080e7          	jalr	1950(ra) # 800035da <bread>
    80003e44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e46:	05850593          	addi	a1,a0,88
    80003e4a:	40dc                	lw	a5,4(s1)
    80003e4c:	8bbd                	andi	a5,a5,15
    80003e4e:	079a                	slli	a5,a5,0x6
    80003e50:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e52:	00059783          	lh	a5,0(a1)
    80003e56:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e5a:	00259783          	lh	a5,2(a1)
    80003e5e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e62:	00459783          	lh	a5,4(a1)
    80003e66:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e6a:	00659783          	lh	a5,6(a1)
    80003e6e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e72:	459c                	lw	a5,8(a1)
    80003e74:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e76:	03400613          	li	a2,52
    80003e7a:	05b1                	addi	a1,a1,12
    80003e7c:	05048513          	addi	a0,s1,80
    80003e80:	ffffd097          	auipc	ra,0xffffd
    80003e84:	0b0080e7          	jalr	176(ra) # 80000f30 <memmove>
    brelse(bp);
    80003e88:	854a                	mv	a0,s2
    80003e8a:	00000097          	auipc	ra,0x0
    80003e8e:	880080e7          	jalr	-1920(ra) # 8000370a <brelse>
    ip->valid = 1;
    80003e92:	4785                	li	a5,1
    80003e94:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e96:	04449783          	lh	a5,68(s1)
    80003e9a:	fbb5                	bnez	a5,80003e0e <ilock+0x24>
      panic("ilock: no type");
    80003e9c:	00005517          	auipc	a0,0x5
    80003ea0:	8cc50513          	addi	a0,a0,-1844 # 80008768 <syscalls+0x1c8>
    80003ea4:	ffffc097          	auipc	ra,0xffffc
    80003ea8:	698080e7          	jalr	1688(ra) # 8000053c <panic>

0000000080003eac <iunlock>:
{
    80003eac:	1101                	addi	sp,sp,-32
    80003eae:	ec06                	sd	ra,24(sp)
    80003eb0:	e822                	sd	s0,16(sp)
    80003eb2:	e426                	sd	s1,8(sp)
    80003eb4:	e04a                	sd	s2,0(sp)
    80003eb6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003eb8:	c905                	beqz	a0,80003ee8 <iunlock+0x3c>
    80003eba:	84aa                	mv	s1,a0
    80003ebc:	01050913          	addi	s2,a0,16
    80003ec0:	854a                	mv	a0,s2
    80003ec2:	00001097          	auipc	ra,0x1
    80003ec6:	c58080e7          	jalr	-936(ra) # 80004b1a <holdingsleep>
    80003eca:	cd19                	beqz	a0,80003ee8 <iunlock+0x3c>
    80003ecc:	449c                	lw	a5,8(s1)
    80003ece:	00f05d63          	blez	a5,80003ee8 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ed2:	854a                	mv	a0,s2
    80003ed4:	00001097          	auipc	ra,0x1
    80003ed8:	c02080e7          	jalr	-1022(ra) # 80004ad6 <releasesleep>
}
    80003edc:	60e2                	ld	ra,24(sp)
    80003ede:	6442                	ld	s0,16(sp)
    80003ee0:	64a2                	ld	s1,8(sp)
    80003ee2:	6902                	ld	s2,0(sp)
    80003ee4:	6105                	addi	sp,sp,32
    80003ee6:	8082                	ret
    panic("iunlock");
    80003ee8:	00005517          	auipc	a0,0x5
    80003eec:	89050513          	addi	a0,a0,-1904 # 80008778 <syscalls+0x1d8>
    80003ef0:	ffffc097          	auipc	ra,0xffffc
    80003ef4:	64c080e7          	jalr	1612(ra) # 8000053c <panic>

0000000080003ef8 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ef8:	7179                	addi	sp,sp,-48
    80003efa:	f406                	sd	ra,40(sp)
    80003efc:	f022                	sd	s0,32(sp)
    80003efe:	ec26                	sd	s1,24(sp)
    80003f00:	e84a                	sd	s2,16(sp)
    80003f02:	e44e                	sd	s3,8(sp)
    80003f04:	e052                	sd	s4,0(sp)
    80003f06:	1800                	addi	s0,sp,48
    80003f08:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003f0a:	05050493          	addi	s1,a0,80
    80003f0e:	08050913          	addi	s2,a0,128
    80003f12:	a021                	j	80003f1a <itrunc+0x22>
    80003f14:	0491                	addi	s1,s1,4
    80003f16:	01248d63          	beq	s1,s2,80003f30 <itrunc+0x38>
    if(ip->addrs[i]){
    80003f1a:	408c                	lw	a1,0(s1)
    80003f1c:	dde5                	beqz	a1,80003f14 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003f1e:	0009a503          	lw	a0,0(s3)
    80003f22:	00000097          	auipc	ra,0x0
    80003f26:	8fc080e7          	jalr	-1796(ra) # 8000381e <bfree>
      ip->addrs[i] = 0;
    80003f2a:	0004a023          	sw	zero,0(s1)
    80003f2e:	b7dd                	j	80003f14 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f30:	0809a583          	lw	a1,128(s3)
    80003f34:	e185                	bnez	a1,80003f54 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f36:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f3a:	854e                	mv	a0,s3
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	de2080e7          	jalr	-542(ra) # 80003d1e <iupdate>
}
    80003f44:	70a2                	ld	ra,40(sp)
    80003f46:	7402                	ld	s0,32(sp)
    80003f48:	64e2                	ld	s1,24(sp)
    80003f4a:	6942                	ld	s2,16(sp)
    80003f4c:	69a2                	ld	s3,8(sp)
    80003f4e:	6a02                	ld	s4,0(sp)
    80003f50:	6145                	addi	sp,sp,48
    80003f52:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f54:	0009a503          	lw	a0,0(s3)
    80003f58:	fffff097          	auipc	ra,0xfffff
    80003f5c:	682080e7          	jalr	1666(ra) # 800035da <bread>
    80003f60:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f62:	05850493          	addi	s1,a0,88
    80003f66:	45850913          	addi	s2,a0,1112
    80003f6a:	a021                	j	80003f72 <itrunc+0x7a>
    80003f6c:	0491                	addi	s1,s1,4
    80003f6e:	01248b63          	beq	s1,s2,80003f84 <itrunc+0x8c>
      if(a[j])
    80003f72:	408c                	lw	a1,0(s1)
    80003f74:	dde5                	beqz	a1,80003f6c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f76:	0009a503          	lw	a0,0(s3)
    80003f7a:	00000097          	auipc	ra,0x0
    80003f7e:	8a4080e7          	jalr	-1884(ra) # 8000381e <bfree>
    80003f82:	b7ed                	j	80003f6c <itrunc+0x74>
    brelse(bp);
    80003f84:	8552                	mv	a0,s4
    80003f86:	fffff097          	auipc	ra,0xfffff
    80003f8a:	784080e7          	jalr	1924(ra) # 8000370a <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f8e:	0809a583          	lw	a1,128(s3)
    80003f92:	0009a503          	lw	a0,0(s3)
    80003f96:	00000097          	auipc	ra,0x0
    80003f9a:	888080e7          	jalr	-1912(ra) # 8000381e <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f9e:	0809a023          	sw	zero,128(s3)
    80003fa2:	bf51                	j	80003f36 <itrunc+0x3e>

0000000080003fa4 <iput>:
{
    80003fa4:	1101                	addi	sp,sp,-32
    80003fa6:	ec06                	sd	ra,24(sp)
    80003fa8:	e822                	sd	s0,16(sp)
    80003faa:	e426                	sd	s1,8(sp)
    80003fac:	e04a                	sd	s2,0(sp)
    80003fae:	1000                	addi	s0,sp,32
    80003fb0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003fb2:	0023b517          	auipc	a0,0x23b
    80003fb6:	27650513          	addi	a0,a0,630 # 8023f228 <itable>
    80003fba:	ffffd097          	auipc	ra,0xffffd
    80003fbe:	e1e080e7          	jalr	-482(ra) # 80000dd8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fc2:	4498                	lw	a4,8(s1)
    80003fc4:	4785                	li	a5,1
    80003fc6:	02f70363          	beq	a4,a5,80003fec <iput+0x48>
  ip->ref--;
    80003fca:	449c                	lw	a5,8(s1)
    80003fcc:	37fd                	addiw	a5,a5,-1
    80003fce:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fd0:	0023b517          	auipc	a0,0x23b
    80003fd4:	25850513          	addi	a0,a0,600 # 8023f228 <itable>
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	eb4080e7          	jalr	-332(ra) # 80000e8c <release>
}
    80003fe0:	60e2                	ld	ra,24(sp)
    80003fe2:	6442                	ld	s0,16(sp)
    80003fe4:	64a2                	ld	s1,8(sp)
    80003fe6:	6902                	ld	s2,0(sp)
    80003fe8:	6105                	addi	sp,sp,32
    80003fea:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fec:	40bc                	lw	a5,64(s1)
    80003fee:	dff1                	beqz	a5,80003fca <iput+0x26>
    80003ff0:	04a49783          	lh	a5,74(s1)
    80003ff4:	fbf9                	bnez	a5,80003fca <iput+0x26>
    acquiresleep(&ip->lock);
    80003ff6:	01048913          	addi	s2,s1,16
    80003ffa:	854a                	mv	a0,s2
    80003ffc:	00001097          	auipc	ra,0x1
    80004000:	a84080e7          	jalr	-1404(ra) # 80004a80 <acquiresleep>
    release(&itable.lock);
    80004004:	0023b517          	auipc	a0,0x23b
    80004008:	22450513          	addi	a0,a0,548 # 8023f228 <itable>
    8000400c:	ffffd097          	auipc	ra,0xffffd
    80004010:	e80080e7          	jalr	-384(ra) # 80000e8c <release>
    itrunc(ip);
    80004014:	8526                	mv	a0,s1
    80004016:	00000097          	auipc	ra,0x0
    8000401a:	ee2080e7          	jalr	-286(ra) # 80003ef8 <itrunc>
    ip->type = 0;
    8000401e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004022:	8526                	mv	a0,s1
    80004024:	00000097          	auipc	ra,0x0
    80004028:	cfa080e7          	jalr	-774(ra) # 80003d1e <iupdate>
    ip->valid = 0;
    8000402c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004030:	854a                	mv	a0,s2
    80004032:	00001097          	auipc	ra,0x1
    80004036:	aa4080e7          	jalr	-1372(ra) # 80004ad6 <releasesleep>
    acquire(&itable.lock);
    8000403a:	0023b517          	auipc	a0,0x23b
    8000403e:	1ee50513          	addi	a0,a0,494 # 8023f228 <itable>
    80004042:	ffffd097          	auipc	ra,0xffffd
    80004046:	d96080e7          	jalr	-618(ra) # 80000dd8 <acquire>
    8000404a:	b741                	j	80003fca <iput+0x26>

000000008000404c <iunlockput>:
{
    8000404c:	1101                	addi	sp,sp,-32
    8000404e:	ec06                	sd	ra,24(sp)
    80004050:	e822                	sd	s0,16(sp)
    80004052:	e426                	sd	s1,8(sp)
    80004054:	1000                	addi	s0,sp,32
    80004056:	84aa                	mv	s1,a0
  iunlock(ip);
    80004058:	00000097          	auipc	ra,0x0
    8000405c:	e54080e7          	jalr	-428(ra) # 80003eac <iunlock>
  iput(ip);
    80004060:	8526                	mv	a0,s1
    80004062:	00000097          	auipc	ra,0x0
    80004066:	f42080e7          	jalr	-190(ra) # 80003fa4 <iput>
}
    8000406a:	60e2                	ld	ra,24(sp)
    8000406c:	6442                	ld	s0,16(sp)
    8000406e:	64a2                	ld	s1,8(sp)
    80004070:	6105                	addi	sp,sp,32
    80004072:	8082                	ret

0000000080004074 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004074:	1141                	addi	sp,sp,-16
    80004076:	e422                	sd	s0,8(sp)
    80004078:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000407a:	411c                	lw	a5,0(a0)
    8000407c:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000407e:	415c                	lw	a5,4(a0)
    80004080:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004082:	04451783          	lh	a5,68(a0)
    80004086:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000408a:	04a51783          	lh	a5,74(a0)
    8000408e:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004092:	04c56783          	lwu	a5,76(a0)
    80004096:	e99c                	sd	a5,16(a1)
}
    80004098:	6422                	ld	s0,8(sp)
    8000409a:	0141                	addi	sp,sp,16
    8000409c:	8082                	ret

000000008000409e <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000409e:	457c                	lw	a5,76(a0)
    800040a0:	0ed7e963          	bltu	a5,a3,80004192 <readi+0xf4>
{
    800040a4:	7159                	addi	sp,sp,-112
    800040a6:	f486                	sd	ra,104(sp)
    800040a8:	f0a2                	sd	s0,96(sp)
    800040aa:	eca6                	sd	s1,88(sp)
    800040ac:	e8ca                	sd	s2,80(sp)
    800040ae:	e4ce                	sd	s3,72(sp)
    800040b0:	e0d2                	sd	s4,64(sp)
    800040b2:	fc56                	sd	s5,56(sp)
    800040b4:	f85a                	sd	s6,48(sp)
    800040b6:	f45e                	sd	s7,40(sp)
    800040b8:	f062                	sd	s8,32(sp)
    800040ba:	ec66                	sd	s9,24(sp)
    800040bc:	e86a                	sd	s10,16(sp)
    800040be:	e46e                	sd	s11,8(sp)
    800040c0:	1880                	addi	s0,sp,112
    800040c2:	8b2a                	mv	s6,a0
    800040c4:	8bae                	mv	s7,a1
    800040c6:	8a32                	mv	s4,a2
    800040c8:	84b6                	mv	s1,a3
    800040ca:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800040cc:	9f35                	addw	a4,a4,a3
    return 0;
    800040ce:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040d0:	0ad76063          	bltu	a4,a3,80004170 <readi+0xd2>
  if(off + n > ip->size)
    800040d4:	00e7f463          	bgeu	a5,a4,800040dc <readi+0x3e>
    n = ip->size - off;
    800040d8:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040dc:	0a0a8963          	beqz	s5,8000418e <readi+0xf0>
    800040e0:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040e2:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040e6:	5c7d                	li	s8,-1
    800040e8:	a82d                	j	80004122 <readi+0x84>
    800040ea:	020d1d93          	slli	s11,s10,0x20
    800040ee:	020ddd93          	srli	s11,s11,0x20
    800040f2:	05890613          	addi	a2,s2,88
    800040f6:	86ee                	mv	a3,s11
    800040f8:	963a                	add	a2,a2,a4
    800040fa:	85d2                	mv	a1,s4
    800040fc:	855e                	mv	a0,s7
    800040fe:	fffff097          	auipc	ra,0xfffff
    80004102:	81e080e7          	jalr	-2018(ra) # 8000291c <either_copyout>
    80004106:	05850d63          	beq	a0,s8,80004160 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    8000410a:	854a                	mv	a0,s2
    8000410c:	fffff097          	auipc	ra,0xfffff
    80004110:	5fe080e7          	jalr	1534(ra) # 8000370a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004114:	013d09bb          	addw	s3,s10,s3
    80004118:	009d04bb          	addw	s1,s10,s1
    8000411c:	9a6e                	add	s4,s4,s11
    8000411e:	0559f763          	bgeu	s3,s5,8000416c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004122:	00a4d59b          	srliw	a1,s1,0xa
    80004126:	855a                	mv	a0,s6
    80004128:	00000097          	auipc	ra,0x0
    8000412c:	8a4080e7          	jalr	-1884(ra) # 800039cc <bmap>
    80004130:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004134:	cd85                	beqz	a1,8000416c <readi+0xce>
    bp = bread(ip->dev, addr);
    80004136:	000b2503          	lw	a0,0(s6)
    8000413a:	fffff097          	auipc	ra,0xfffff
    8000413e:	4a0080e7          	jalr	1184(ra) # 800035da <bread>
    80004142:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004144:	3ff4f713          	andi	a4,s1,1023
    80004148:	40ec87bb          	subw	a5,s9,a4
    8000414c:	413a86bb          	subw	a3,s5,s3
    80004150:	8d3e                	mv	s10,a5
    80004152:	2781                	sext.w	a5,a5
    80004154:	0006861b          	sext.w	a2,a3
    80004158:	f8f679e3          	bgeu	a2,a5,800040ea <readi+0x4c>
    8000415c:	8d36                	mv	s10,a3
    8000415e:	b771                	j	800040ea <readi+0x4c>
      brelse(bp);
    80004160:	854a                	mv	a0,s2
    80004162:	fffff097          	auipc	ra,0xfffff
    80004166:	5a8080e7          	jalr	1448(ra) # 8000370a <brelse>
      tot = -1;
    8000416a:	59fd                	li	s3,-1
  }
  return tot;
    8000416c:	0009851b          	sext.w	a0,s3
}
    80004170:	70a6                	ld	ra,104(sp)
    80004172:	7406                	ld	s0,96(sp)
    80004174:	64e6                	ld	s1,88(sp)
    80004176:	6946                	ld	s2,80(sp)
    80004178:	69a6                	ld	s3,72(sp)
    8000417a:	6a06                	ld	s4,64(sp)
    8000417c:	7ae2                	ld	s5,56(sp)
    8000417e:	7b42                	ld	s6,48(sp)
    80004180:	7ba2                	ld	s7,40(sp)
    80004182:	7c02                	ld	s8,32(sp)
    80004184:	6ce2                	ld	s9,24(sp)
    80004186:	6d42                	ld	s10,16(sp)
    80004188:	6da2                	ld	s11,8(sp)
    8000418a:	6165                	addi	sp,sp,112
    8000418c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000418e:	89d6                	mv	s3,s5
    80004190:	bff1                	j	8000416c <readi+0xce>
    return 0;
    80004192:	4501                	li	a0,0
}
    80004194:	8082                	ret

0000000080004196 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004196:	457c                	lw	a5,76(a0)
    80004198:	10d7e863          	bltu	a5,a3,800042a8 <writei+0x112>
{
    8000419c:	7159                	addi	sp,sp,-112
    8000419e:	f486                	sd	ra,104(sp)
    800041a0:	f0a2                	sd	s0,96(sp)
    800041a2:	eca6                	sd	s1,88(sp)
    800041a4:	e8ca                	sd	s2,80(sp)
    800041a6:	e4ce                	sd	s3,72(sp)
    800041a8:	e0d2                	sd	s4,64(sp)
    800041aa:	fc56                	sd	s5,56(sp)
    800041ac:	f85a                	sd	s6,48(sp)
    800041ae:	f45e                	sd	s7,40(sp)
    800041b0:	f062                	sd	s8,32(sp)
    800041b2:	ec66                	sd	s9,24(sp)
    800041b4:	e86a                	sd	s10,16(sp)
    800041b6:	e46e                	sd	s11,8(sp)
    800041b8:	1880                	addi	s0,sp,112
    800041ba:	8aaa                	mv	s5,a0
    800041bc:	8bae                	mv	s7,a1
    800041be:	8a32                	mv	s4,a2
    800041c0:	8936                	mv	s2,a3
    800041c2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800041c4:	00e687bb          	addw	a5,a3,a4
    800041c8:	0ed7e263          	bltu	a5,a3,800042ac <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041cc:	00043737          	lui	a4,0x43
    800041d0:	0ef76063          	bltu	a4,a5,800042b0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041d4:	0c0b0863          	beqz	s6,800042a4 <writei+0x10e>
    800041d8:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041da:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041de:	5c7d                	li	s8,-1
    800041e0:	a091                	j	80004224 <writei+0x8e>
    800041e2:	020d1d93          	slli	s11,s10,0x20
    800041e6:	020ddd93          	srli	s11,s11,0x20
    800041ea:	05848513          	addi	a0,s1,88
    800041ee:	86ee                	mv	a3,s11
    800041f0:	8652                	mv	a2,s4
    800041f2:	85de                	mv	a1,s7
    800041f4:	953a                	add	a0,a0,a4
    800041f6:	ffffe097          	auipc	ra,0xffffe
    800041fa:	77c080e7          	jalr	1916(ra) # 80002972 <either_copyin>
    800041fe:	07850263          	beq	a0,s8,80004262 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004202:	8526                	mv	a0,s1
    80004204:	00000097          	auipc	ra,0x0
    80004208:	75e080e7          	jalr	1886(ra) # 80004962 <log_write>
    brelse(bp);
    8000420c:	8526                	mv	a0,s1
    8000420e:	fffff097          	auipc	ra,0xfffff
    80004212:	4fc080e7          	jalr	1276(ra) # 8000370a <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004216:	013d09bb          	addw	s3,s10,s3
    8000421a:	012d093b          	addw	s2,s10,s2
    8000421e:	9a6e                	add	s4,s4,s11
    80004220:	0569f663          	bgeu	s3,s6,8000426c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004224:	00a9559b          	srliw	a1,s2,0xa
    80004228:	8556                	mv	a0,s5
    8000422a:	fffff097          	auipc	ra,0xfffff
    8000422e:	7a2080e7          	jalr	1954(ra) # 800039cc <bmap>
    80004232:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004236:	c99d                	beqz	a1,8000426c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004238:	000aa503          	lw	a0,0(s5)
    8000423c:	fffff097          	auipc	ra,0xfffff
    80004240:	39e080e7          	jalr	926(ra) # 800035da <bread>
    80004244:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004246:	3ff97713          	andi	a4,s2,1023
    8000424a:	40ec87bb          	subw	a5,s9,a4
    8000424e:	413b06bb          	subw	a3,s6,s3
    80004252:	8d3e                	mv	s10,a5
    80004254:	2781                	sext.w	a5,a5
    80004256:	0006861b          	sext.w	a2,a3
    8000425a:	f8f674e3          	bgeu	a2,a5,800041e2 <writei+0x4c>
    8000425e:	8d36                	mv	s10,a3
    80004260:	b749                	j	800041e2 <writei+0x4c>
      brelse(bp);
    80004262:	8526                	mv	a0,s1
    80004264:	fffff097          	auipc	ra,0xfffff
    80004268:	4a6080e7          	jalr	1190(ra) # 8000370a <brelse>
  }

  if(off > ip->size)
    8000426c:	04caa783          	lw	a5,76(s5)
    80004270:	0127f463          	bgeu	a5,s2,80004278 <writei+0xe2>
    ip->size = off;
    80004274:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004278:	8556                	mv	a0,s5
    8000427a:	00000097          	auipc	ra,0x0
    8000427e:	aa4080e7          	jalr	-1372(ra) # 80003d1e <iupdate>

  return tot;
    80004282:	0009851b          	sext.w	a0,s3
}
    80004286:	70a6                	ld	ra,104(sp)
    80004288:	7406                	ld	s0,96(sp)
    8000428a:	64e6                	ld	s1,88(sp)
    8000428c:	6946                	ld	s2,80(sp)
    8000428e:	69a6                	ld	s3,72(sp)
    80004290:	6a06                	ld	s4,64(sp)
    80004292:	7ae2                	ld	s5,56(sp)
    80004294:	7b42                	ld	s6,48(sp)
    80004296:	7ba2                	ld	s7,40(sp)
    80004298:	7c02                	ld	s8,32(sp)
    8000429a:	6ce2                	ld	s9,24(sp)
    8000429c:	6d42                	ld	s10,16(sp)
    8000429e:	6da2                	ld	s11,8(sp)
    800042a0:	6165                	addi	sp,sp,112
    800042a2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800042a4:	89da                	mv	s3,s6
    800042a6:	bfc9                	j	80004278 <writei+0xe2>
    return -1;
    800042a8:	557d                	li	a0,-1
}
    800042aa:	8082                	ret
    return -1;
    800042ac:	557d                	li	a0,-1
    800042ae:	bfe1                	j	80004286 <writei+0xf0>
    return -1;
    800042b0:	557d                	li	a0,-1
    800042b2:	bfd1                	j	80004286 <writei+0xf0>

00000000800042b4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800042b4:	1141                	addi	sp,sp,-16
    800042b6:	e406                	sd	ra,8(sp)
    800042b8:	e022                	sd	s0,0(sp)
    800042ba:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800042bc:	4639                	li	a2,14
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	ce6080e7          	jalr	-794(ra) # 80000fa4 <strncmp>
}
    800042c6:	60a2                	ld	ra,8(sp)
    800042c8:	6402                	ld	s0,0(sp)
    800042ca:	0141                	addi	sp,sp,16
    800042cc:	8082                	ret

00000000800042ce <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042ce:	7139                	addi	sp,sp,-64
    800042d0:	fc06                	sd	ra,56(sp)
    800042d2:	f822                	sd	s0,48(sp)
    800042d4:	f426                	sd	s1,40(sp)
    800042d6:	f04a                	sd	s2,32(sp)
    800042d8:	ec4e                	sd	s3,24(sp)
    800042da:	e852                	sd	s4,16(sp)
    800042dc:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042de:	04451703          	lh	a4,68(a0)
    800042e2:	4785                	li	a5,1
    800042e4:	00f71a63          	bne	a4,a5,800042f8 <dirlookup+0x2a>
    800042e8:	892a                	mv	s2,a0
    800042ea:	89ae                	mv	s3,a1
    800042ec:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ee:	457c                	lw	a5,76(a0)
    800042f0:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042f2:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042f4:	e79d                	bnez	a5,80004322 <dirlookup+0x54>
    800042f6:	a8a5                	j	8000436e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042f8:	00004517          	auipc	a0,0x4
    800042fc:	48850513          	addi	a0,a0,1160 # 80008780 <syscalls+0x1e0>
    80004300:	ffffc097          	auipc	ra,0xffffc
    80004304:	23c080e7          	jalr	572(ra) # 8000053c <panic>
      panic("dirlookup read");
    80004308:	00004517          	auipc	a0,0x4
    8000430c:	49050513          	addi	a0,a0,1168 # 80008798 <syscalls+0x1f8>
    80004310:	ffffc097          	auipc	ra,0xffffc
    80004314:	22c080e7          	jalr	556(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004318:	24c1                	addiw	s1,s1,16
    8000431a:	04c92783          	lw	a5,76(s2)
    8000431e:	04f4f763          	bgeu	s1,a5,8000436c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004322:	4741                	li	a4,16
    80004324:	86a6                	mv	a3,s1
    80004326:	fc040613          	addi	a2,s0,-64
    8000432a:	4581                	li	a1,0
    8000432c:	854a                	mv	a0,s2
    8000432e:	00000097          	auipc	ra,0x0
    80004332:	d70080e7          	jalr	-656(ra) # 8000409e <readi>
    80004336:	47c1                	li	a5,16
    80004338:	fcf518e3          	bne	a0,a5,80004308 <dirlookup+0x3a>
    if(de.inum == 0)
    8000433c:	fc045783          	lhu	a5,-64(s0)
    80004340:	dfe1                	beqz	a5,80004318 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004342:	fc240593          	addi	a1,s0,-62
    80004346:	854e                	mv	a0,s3
    80004348:	00000097          	auipc	ra,0x0
    8000434c:	f6c080e7          	jalr	-148(ra) # 800042b4 <namecmp>
    80004350:	f561                	bnez	a0,80004318 <dirlookup+0x4a>
      if(poff)
    80004352:	000a0463          	beqz	s4,8000435a <dirlookup+0x8c>
        *poff = off;
    80004356:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000435a:	fc045583          	lhu	a1,-64(s0)
    8000435e:	00092503          	lw	a0,0(s2)
    80004362:	fffff097          	auipc	ra,0xfffff
    80004366:	754080e7          	jalr	1876(ra) # 80003ab6 <iget>
    8000436a:	a011                	j	8000436e <dirlookup+0xa0>
  return 0;
    8000436c:	4501                	li	a0,0
}
    8000436e:	70e2                	ld	ra,56(sp)
    80004370:	7442                	ld	s0,48(sp)
    80004372:	74a2                	ld	s1,40(sp)
    80004374:	7902                	ld	s2,32(sp)
    80004376:	69e2                	ld	s3,24(sp)
    80004378:	6a42                	ld	s4,16(sp)
    8000437a:	6121                	addi	sp,sp,64
    8000437c:	8082                	ret

000000008000437e <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000437e:	711d                	addi	sp,sp,-96
    80004380:	ec86                	sd	ra,88(sp)
    80004382:	e8a2                	sd	s0,80(sp)
    80004384:	e4a6                	sd	s1,72(sp)
    80004386:	e0ca                	sd	s2,64(sp)
    80004388:	fc4e                	sd	s3,56(sp)
    8000438a:	f852                	sd	s4,48(sp)
    8000438c:	f456                	sd	s5,40(sp)
    8000438e:	f05a                	sd	s6,32(sp)
    80004390:	ec5e                	sd	s7,24(sp)
    80004392:	e862                	sd	s8,16(sp)
    80004394:	e466                	sd	s9,8(sp)
    80004396:	1080                	addi	s0,sp,96
    80004398:	84aa                	mv	s1,a0
    8000439a:	8b2e                	mv	s6,a1
    8000439c:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000439e:	00054703          	lbu	a4,0(a0)
    800043a2:	02f00793          	li	a5,47
    800043a6:	02f70263          	beq	a4,a5,800043ca <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800043aa:	ffffe097          	auipc	ra,0xffffe
    800043ae:	a02080e7          	jalr	-1534(ra) # 80001dac <myproc>
    800043b2:	15053503          	ld	a0,336(a0)
    800043b6:	00000097          	auipc	ra,0x0
    800043ba:	9f6080e7          	jalr	-1546(ra) # 80003dac <idup>
    800043be:	8a2a                	mv	s4,a0
  while(*path == '/')
    800043c0:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800043c4:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800043c6:	4b85                	li	s7,1
    800043c8:	a875                	j	80004484 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    800043ca:	4585                	li	a1,1
    800043cc:	4505                	li	a0,1
    800043ce:	fffff097          	auipc	ra,0xfffff
    800043d2:	6e8080e7          	jalr	1768(ra) # 80003ab6 <iget>
    800043d6:	8a2a                	mv	s4,a0
    800043d8:	b7e5                	j	800043c0 <namex+0x42>
      iunlockput(ip);
    800043da:	8552                	mv	a0,s4
    800043dc:	00000097          	auipc	ra,0x0
    800043e0:	c70080e7          	jalr	-912(ra) # 8000404c <iunlockput>
      return 0;
    800043e4:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043e6:	8552                	mv	a0,s4
    800043e8:	60e6                	ld	ra,88(sp)
    800043ea:	6446                	ld	s0,80(sp)
    800043ec:	64a6                	ld	s1,72(sp)
    800043ee:	6906                	ld	s2,64(sp)
    800043f0:	79e2                	ld	s3,56(sp)
    800043f2:	7a42                	ld	s4,48(sp)
    800043f4:	7aa2                	ld	s5,40(sp)
    800043f6:	7b02                	ld	s6,32(sp)
    800043f8:	6be2                	ld	s7,24(sp)
    800043fa:	6c42                	ld	s8,16(sp)
    800043fc:	6ca2                	ld	s9,8(sp)
    800043fe:	6125                	addi	sp,sp,96
    80004400:	8082                	ret
      iunlock(ip);
    80004402:	8552                	mv	a0,s4
    80004404:	00000097          	auipc	ra,0x0
    80004408:	aa8080e7          	jalr	-1368(ra) # 80003eac <iunlock>
      return ip;
    8000440c:	bfe9                	j	800043e6 <namex+0x68>
      iunlockput(ip);
    8000440e:	8552                	mv	a0,s4
    80004410:	00000097          	auipc	ra,0x0
    80004414:	c3c080e7          	jalr	-964(ra) # 8000404c <iunlockput>
      return 0;
    80004418:	8a4e                	mv	s4,s3
    8000441a:	b7f1                	j	800043e6 <namex+0x68>
  len = path - s;
    8000441c:	40998633          	sub	a2,s3,s1
    80004420:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    80004424:	099c5863          	bge	s8,s9,800044b4 <namex+0x136>
    memmove(name, s, DIRSIZ);
    80004428:	4639                	li	a2,14
    8000442a:	85a6                	mv	a1,s1
    8000442c:	8556                	mv	a0,s5
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	b02080e7          	jalr	-1278(ra) # 80000f30 <memmove>
    80004436:	84ce                	mv	s1,s3
  while(*path == '/')
    80004438:	0004c783          	lbu	a5,0(s1)
    8000443c:	01279763          	bne	a5,s2,8000444a <namex+0xcc>
    path++;
    80004440:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004442:	0004c783          	lbu	a5,0(s1)
    80004446:	ff278de3          	beq	a5,s2,80004440 <namex+0xc2>
    ilock(ip);
    8000444a:	8552                	mv	a0,s4
    8000444c:	00000097          	auipc	ra,0x0
    80004450:	99e080e7          	jalr	-1634(ra) # 80003dea <ilock>
    if(ip->type != T_DIR){
    80004454:	044a1783          	lh	a5,68(s4)
    80004458:	f97791e3          	bne	a5,s7,800043da <namex+0x5c>
    if(nameiparent && *path == '\0'){
    8000445c:	000b0563          	beqz	s6,80004466 <namex+0xe8>
    80004460:	0004c783          	lbu	a5,0(s1)
    80004464:	dfd9                	beqz	a5,80004402 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004466:	4601                	li	a2,0
    80004468:	85d6                	mv	a1,s5
    8000446a:	8552                	mv	a0,s4
    8000446c:	00000097          	auipc	ra,0x0
    80004470:	e62080e7          	jalr	-414(ra) # 800042ce <dirlookup>
    80004474:	89aa                	mv	s3,a0
    80004476:	dd41                	beqz	a0,8000440e <namex+0x90>
    iunlockput(ip);
    80004478:	8552                	mv	a0,s4
    8000447a:	00000097          	auipc	ra,0x0
    8000447e:	bd2080e7          	jalr	-1070(ra) # 8000404c <iunlockput>
    ip = next;
    80004482:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004484:	0004c783          	lbu	a5,0(s1)
    80004488:	01279763          	bne	a5,s2,80004496 <namex+0x118>
    path++;
    8000448c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000448e:	0004c783          	lbu	a5,0(s1)
    80004492:	ff278de3          	beq	a5,s2,8000448c <namex+0x10e>
  if(*path == 0)
    80004496:	cb9d                	beqz	a5,800044cc <namex+0x14e>
  while(*path != '/' && *path != 0)
    80004498:	0004c783          	lbu	a5,0(s1)
    8000449c:	89a6                	mv	s3,s1
  len = path - s;
    8000449e:	4c81                	li	s9,0
    800044a0:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800044a2:	01278963          	beq	a5,s2,800044b4 <namex+0x136>
    800044a6:	dbbd                	beqz	a5,8000441c <namex+0x9e>
    path++;
    800044a8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800044aa:	0009c783          	lbu	a5,0(s3)
    800044ae:	ff279ce3          	bne	a5,s2,800044a6 <namex+0x128>
    800044b2:	b7ad                	j	8000441c <namex+0x9e>
    memmove(name, s, len);
    800044b4:	2601                	sext.w	a2,a2
    800044b6:	85a6                	mv	a1,s1
    800044b8:	8556                	mv	a0,s5
    800044ba:	ffffd097          	auipc	ra,0xffffd
    800044be:	a76080e7          	jalr	-1418(ra) # 80000f30 <memmove>
    name[len] = 0;
    800044c2:	9cd6                	add	s9,s9,s5
    800044c4:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    800044c8:	84ce                	mv	s1,s3
    800044ca:	b7bd                	j	80004438 <namex+0xba>
  if(nameiparent){
    800044cc:	f00b0de3          	beqz	s6,800043e6 <namex+0x68>
    iput(ip);
    800044d0:	8552                	mv	a0,s4
    800044d2:	00000097          	auipc	ra,0x0
    800044d6:	ad2080e7          	jalr	-1326(ra) # 80003fa4 <iput>
    return 0;
    800044da:	4a01                	li	s4,0
    800044dc:	b729                	j	800043e6 <namex+0x68>

00000000800044de <dirlink>:
{
    800044de:	7139                	addi	sp,sp,-64
    800044e0:	fc06                	sd	ra,56(sp)
    800044e2:	f822                	sd	s0,48(sp)
    800044e4:	f426                	sd	s1,40(sp)
    800044e6:	f04a                	sd	s2,32(sp)
    800044e8:	ec4e                	sd	s3,24(sp)
    800044ea:	e852                	sd	s4,16(sp)
    800044ec:	0080                	addi	s0,sp,64
    800044ee:	892a                	mv	s2,a0
    800044f0:	8a2e                	mv	s4,a1
    800044f2:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044f4:	4601                	li	a2,0
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	dd8080e7          	jalr	-552(ra) # 800042ce <dirlookup>
    800044fe:	e93d                	bnez	a0,80004574 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004500:	04c92483          	lw	s1,76(s2)
    80004504:	c49d                	beqz	s1,80004532 <dirlink+0x54>
    80004506:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004508:	4741                	li	a4,16
    8000450a:	86a6                	mv	a3,s1
    8000450c:	fc040613          	addi	a2,s0,-64
    80004510:	4581                	li	a1,0
    80004512:	854a                	mv	a0,s2
    80004514:	00000097          	auipc	ra,0x0
    80004518:	b8a080e7          	jalr	-1142(ra) # 8000409e <readi>
    8000451c:	47c1                	li	a5,16
    8000451e:	06f51163          	bne	a0,a5,80004580 <dirlink+0xa2>
    if(de.inum == 0)
    80004522:	fc045783          	lhu	a5,-64(s0)
    80004526:	c791                	beqz	a5,80004532 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004528:	24c1                	addiw	s1,s1,16
    8000452a:	04c92783          	lw	a5,76(s2)
    8000452e:	fcf4ede3          	bltu	s1,a5,80004508 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004532:	4639                	li	a2,14
    80004534:	85d2                	mv	a1,s4
    80004536:	fc240513          	addi	a0,s0,-62
    8000453a:	ffffd097          	auipc	ra,0xffffd
    8000453e:	aa6080e7          	jalr	-1370(ra) # 80000fe0 <strncpy>
  de.inum = inum;
    80004542:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004546:	4741                	li	a4,16
    80004548:	86a6                	mv	a3,s1
    8000454a:	fc040613          	addi	a2,s0,-64
    8000454e:	4581                	li	a1,0
    80004550:	854a                	mv	a0,s2
    80004552:	00000097          	auipc	ra,0x0
    80004556:	c44080e7          	jalr	-956(ra) # 80004196 <writei>
    8000455a:	1541                	addi	a0,a0,-16
    8000455c:	00a03533          	snez	a0,a0
    80004560:	40a00533          	neg	a0,a0
}
    80004564:	70e2                	ld	ra,56(sp)
    80004566:	7442                	ld	s0,48(sp)
    80004568:	74a2                	ld	s1,40(sp)
    8000456a:	7902                	ld	s2,32(sp)
    8000456c:	69e2                	ld	s3,24(sp)
    8000456e:	6a42                	ld	s4,16(sp)
    80004570:	6121                	addi	sp,sp,64
    80004572:	8082                	ret
    iput(ip);
    80004574:	00000097          	auipc	ra,0x0
    80004578:	a30080e7          	jalr	-1488(ra) # 80003fa4 <iput>
    return -1;
    8000457c:	557d                	li	a0,-1
    8000457e:	b7dd                	j	80004564 <dirlink+0x86>
      panic("dirlink read");
    80004580:	00004517          	auipc	a0,0x4
    80004584:	22850513          	addi	a0,a0,552 # 800087a8 <syscalls+0x208>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	fb4080e7          	jalr	-76(ra) # 8000053c <panic>

0000000080004590 <namei>:

struct inode*
namei(char *path)
{
    80004590:	1101                	addi	sp,sp,-32
    80004592:	ec06                	sd	ra,24(sp)
    80004594:	e822                	sd	s0,16(sp)
    80004596:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004598:	fe040613          	addi	a2,s0,-32
    8000459c:	4581                	li	a1,0
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	de0080e7          	jalr	-544(ra) # 8000437e <namex>
}
    800045a6:	60e2                	ld	ra,24(sp)
    800045a8:	6442                	ld	s0,16(sp)
    800045aa:	6105                	addi	sp,sp,32
    800045ac:	8082                	ret

00000000800045ae <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800045ae:	1141                	addi	sp,sp,-16
    800045b0:	e406                	sd	ra,8(sp)
    800045b2:	e022                	sd	s0,0(sp)
    800045b4:	0800                	addi	s0,sp,16
    800045b6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800045b8:	4585                	li	a1,1
    800045ba:	00000097          	auipc	ra,0x0
    800045be:	dc4080e7          	jalr	-572(ra) # 8000437e <namex>
}
    800045c2:	60a2                	ld	ra,8(sp)
    800045c4:	6402                	ld	s0,0(sp)
    800045c6:	0141                	addi	sp,sp,16
    800045c8:	8082                	ret

00000000800045ca <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800045ca:	1101                	addi	sp,sp,-32
    800045cc:	ec06                	sd	ra,24(sp)
    800045ce:	e822                	sd	s0,16(sp)
    800045d0:	e426                	sd	s1,8(sp)
    800045d2:	e04a                	sd	s2,0(sp)
    800045d4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045d6:	0023c917          	auipc	s2,0x23c
    800045da:	6fa90913          	addi	s2,s2,1786 # 80240cd0 <log>
    800045de:	01892583          	lw	a1,24(s2)
    800045e2:	02892503          	lw	a0,40(s2)
    800045e6:	fffff097          	auipc	ra,0xfffff
    800045ea:	ff4080e7          	jalr	-12(ra) # 800035da <bread>
    800045ee:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045f0:	02c92603          	lw	a2,44(s2)
    800045f4:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045f6:	00c05f63          	blez	a2,80004614 <write_head+0x4a>
    800045fa:	0023c717          	auipc	a4,0x23c
    800045fe:	70670713          	addi	a4,a4,1798 # 80240d00 <log+0x30>
    80004602:	87aa                	mv	a5,a0
    80004604:	060a                	slli	a2,a2,0x2
    80004606:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80004608:	4314                	lw	a3,0(a4)
    8000460a:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    8000460c:	0711                	addi	a4,a4,4
    8000460e:	0791                	addi	a5,a5,4
    80004610:	fec79ce3          	bne	a5,a2,80004608 <write_head+0x3e>
  }
  bwrite(buf);
    80004614:	8526                	mv	a0,s1
    80004616:	fffff097          	auipc	ra,0xfffff
    8000461a:	0b6080e7          	jalr	182(ra) # 800036cc <bwrite>
  brelse(buf);
    8000461e:	8526                	mv	a0,s1
    80004620:	fffff097          	auipc	ra,0xfffff
    80004624:	0ea080e7          	jalr	234(ra) # 8000370a <brelse>
}
    80004628:	60e2                	ld	ra,24(sp)
    8000462a:	6442                	ld	s0,16(sp)
    8000462c:	64a2                	ld	s1,8(sp)
    8000462e:	6902                	ld	s2,0(sp)
    80004630:	6105                	addi	sp,sp,32
    80004632:	8082                	ret

0000000080004634 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004634:	0023c797          	auipc	a5,0x23c
    80004638:	6c87a783          	lw	a5,1736(a5) # 80240cfc <log+0x2c>
    8000463c:	0af05d63          	blez	a5,800046f6 <install_trans+0xc2>
{
    80004640:	7139                	addi	sp,sp,-64
    80004642:	fc06                	sd	ra,56(sp)
    80004644:	f822                	sd	s0,48(sp)
    80004646:	f426                	sd	s1,40(sp)
    80004648:	f04a                	sd	s2,32(sp)
    8000464a:	ec4e                	sd	s3,24(sp)
    8000464c:	e852                	sd	s4,16(sp)
    8000464e:	e456                	sd	s5,8(sp)
    80004650:	e05a                	sd	s6,0(sp)
    80004652:	0080                	addi	s0,sp,64
    80004654:	8b2a                	mv	s6,a0
    80004656:	0023ca97          	auipc	s5,0x23c
    8000465a:	6aaa8a93          	addi	s5,s5,1706 # 80240d00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000465e:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004660:	0023c997          	auipc	s3,0x23c
    80004664:	67098993          	addi	s3,s3,1648 # 80240cd0 <log>
    80004668:	a00d                	j	8000468a <install_trans+0x56>
    brelse(lbuf);
    8000466a:	854a                	mv	a0,s2
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	09e080e7          	jalr	158(ra) # 8000370a <brelse>
    brelse(dbuf);
    80004674:	8526                	mv	a0,s1
    80004676:	fffff097          	auipc	ra,0xfffff
    8000467a:	094080e7          	jalr	148(ra) # 8000370a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000467e:	2a05                	addiw	s4,s4,1
    80004680:	0a91                	addi	s5,s5,4
    80004682:	02c9a783          	lw	a5,44(s3)
    80004686:	04fa5e63          	bge	s4,a5,800046e2 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000468a:	0189a583          	lw	a1,24(s3)
    8000468e:	014585bb          	addw	a1,a1,s4
    80004692:	2585                	addiw	a1,a1,1
    80004694:	0289a503          	lw	a0,40(s3)
    80004698:	fffff097          	auipc	ra,0xfffff
    8000469c:	f42080e7          	jalr	-190(ra) # 800035da <bread>
    800046a0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800046a2:	000aa583          	lw	a1,0(s5)
    800046a6:	0289a503          	lw	a0,40(s3)
    800046aa:	fffff097          	auipc	ra,0xfffff
    800046ae:	f30080e7          	jalr	-208(ra) # 800035da <bread>
    800046b2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800046b4:	40000613          	li	a2,1024
    800046b8:	05890593          	addi	a1,s2,88
    800046bc:	05850513          	addi	a0,a0,88
    800046c0:	ffffd097          	auipc	ra,0xffffd
    800046c4:	870080e7          	jalr	-1936(ra) # 80000f30 <memmove>
    bwrite(dbuf);  // write dst to disk
    800046c8:	8526                	mv	a0,s1
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	002080e7          	jalr	2(ra) # 800036cc <bwrite>
    if(recovering == 0)
    800046d2:	f80b1ce3          	bnez	s6,8000466a <install_trans+0x36>
      bunpin(dbuf);
    800046d6:	8526                	mv	a0,s1
    800046d8:	fffff097          	auipc	ra,0xfffff
    800046dc:	10a080e7          	jalr	266(ra) # 800037e2 <bunpin>
    800046e0:	b769                	j	8000466a <install_trans+0x36>
}
    800046e2:	70e2                	ld	ra,56(sp)
    800046e4:	7442                	ld	s0,48(sp)
    800046e6:	74a2                	ld	s1,40(sp)
    800046e8:	7902                	ld	s2,32(sp)
    800046ea:	69e2                	ld	s3,24(sp)
    800046ec:	6a42                	ld	s4,16(sp)
    800046ee:	6aa2                	ld	s5,8(sp)
    800046f0:	6b02                	ld	s6,0(sp)
    800046f2:	6121                	addi	sp,sp,64
    800046f4:	8082                	ret
    800046f6:	8082                	ret

00000000800046f8 <initlog>:
{
    800046f8:	7179                	addi	sp,sp,-48
    800046fa:	f406                	sd	ra,40(sp)
    800046fc:	f022                	sd	s0,32(sp)
    800046fe:	ec26                	sd	s1,24(sp)
    80004700:	e84a                	sd	s2,16(sp)
    80004702:	e44e                	sd	s3,8(sp)
    80004704:	1800                	addi	s0,sp,48
    80004706:	892a                	mv	s2,a0
    80004708:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000470a:	0023c497          	auipc	s1,0x23c
    8000470e:	5c648493          	addi	s1,s1,1478 # 80240cd0 <log>
    80004712:	00004597          	auipc	a1,0x4
    80004716:	0a658593          	addi	a1,a1,166 # 800087b8 <syscalls+0x218>
    8000471a:	8526                	mv	a0,s1
    8000471c:	ffffc097          	auipc	ra,0xffffc
    80004720:	62c080e7          	jalr	1580(ra) # 80000d48 <initlock>
  log.start = sb->logstart;
    80004724:	0149a583          	lw	a1,20(s3)
    80004728:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000472a:	0109a783          	lw	a5,16(s3)
    8000472e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004730:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004734:	854a                	mv	a0,s2
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	ea4080e7          	jalr	-348(ra) # 800035da <bread>
  log.lh.n = lh->n;
    8000473e:	4d30                	lw	a2,88(a0)
    80004740:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004742:	00c05f63          	blez	a2,80004760 <initlog+0x68>
    80004746:	87aa                	mv	a5,a0
    80004748:	0023c717          	auipc	a4,0x23c
    8000474c:	5b870713          	addi	a4,a4,1464 # 80240d00 <log+0x30>
    80004750:	060a                	slli	a2,a2,0x2
    80004752:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004754:	4ff4                	lw	a3,92(a5)
    80004756:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004758:	0791                	addi	a5,a5,4
    8000475a:	0711                	addi	a4,a4,4
    8000475c:	fec79ce3          	bne	a5,a2,80004754 <initlog+0x5c>
  brelse(buf);
    80004760:	fffff097          	auipc	ra,0xfffff
    80004764:	faa080e7          	jalr	-86(ra) # 8000370a <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004768:	4505                	li	a0,1
    8000476a:	00000097          	auipc	ra,0x0
    8000476e:	eca080e7          	jalr	-310(ra) # 80004634 <install_trans>
  log.lh.n = 0;
    80004772:	0023c797          	auipc	a5,0x23c
    80004776:	5807a523          	sw	zero,1418(a5) # 80240cfc <log+0x2c>
  write_head(); // clear the log
    8000477a:	00000097          	auipc	ra,0x0
    8000477e:	e50080e7          	jalr	-432(ra) # 800045ca <write_head>
}
    80004782:	70a2                	ld	ra,40(sp)
    80004784:	7402                	ld	s0,32(sp)
    80004786:	64e2                	ld	s1,24(sp)
    80004788:	6942                	ld	s2,16(sp)
    8000478a:	69a2                	ld	s3,8(sp)
    8000478c:	6145                	addi	sp,sp,48
    8000478e:	8082                	ret

0000000080004790 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004790:	1101                	addi	sp,sp,-32
    80004792:	ec06                	sd	ra,24(sp)
    80004794:	e822                	sd	s0,16(sp)
    80004796:	e426                	sd	s1,8(sp)
    80004798:	e04a                	sd	s2,0(sp)
    8000479a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000479c:	0023c517          	auipc	a0,0x23c
    800047a0:	53450513          	addi	a0,a0,1332 # 80240cd0 <log>
    800047a4:	ffffc097          	auipc	ra,0xffffc
    800047a8:	634080e7          	jalr	1588(ra) # 80000dd8 <acquire>
  while(1){
    if(log.committing){
    800047ac:	0023c497          	auipc	s1,0x23c
    800047b0:	52448493          	addi	s1,s1,1316 # 80240cd0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047b4:	4979                	li	s2,30
    800047b6:	a039                	j	800047c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800047b8:	85a6                	mv	a1,s1
    800047ba:	8526                	mv	a0,s1
    800047bc:	ffffe097          	auipc	ra,0xffffe
    800047c0:	d58080e7          	jalr	-680(ra) # 80002514 <sleep>
    if(log.committing){
    800047c4:	50dc                	lw	a5,36(s1)
    800047c6:	fbed                	bnez	a5,800047b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047c8:	5098                	lw	a4,32(s1)
    800047ca:	2705                	addiw	a4,a4,1
    800047cc:	0027179b          	slliw	a5,a4,0x2
    800047d0:	9fb9                	addw	a5,a5,a4
    800047d2:	0017979b          	slliw	a5,a5,0x1
    800047d6:	54d4                	lw	a3,44(s1)
    800047d8:	9fb5                	addw	a5,a5,a3
    800047da:	00f95963          	bge	s2,a5,800047ec <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047de:	85a6                	mv	a1,s1
    800047e0:	8526                	mv	a0,s1
    800047e2:	ffffe097          	auipc	ra,0xffffe
    800047e6:	d32080e7          	jalr	-718(ra) # 80002514 <sleep>
    800047ea:	bfe9                	j	800047c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047ec:	0023c517          	auipc	a0,0x23c
    800047f0:	4e450513          	addi	a0,a0,1252 # 80240cd0 <log>
    800047f4:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	696080e7          	jalr	1686(ra) # 80000e8c <release>
      break;
    }
  }
}
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	64a2                	ld	s1,8(sp)
    80004804:	6902                	ld	s2,0(sp)
    80004806:	6105                	addi	sp,sp,32
    80004808:	8082                	ret

000000008000480a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000480a:	7139                	addi	sp,sp,-64
    8000480c:	fc06                	sd	ra,56(sp)
    8000480e:	f822                	sd	s0,48(sp)
    80004810:	f426                	sd	s1,40(sp)
    80004812:	f04a                	sd	s2,32(sp)
    80004814:	ec4e                	sd	s3,24(sp)
    80004816:	e852                	sd	s4,16(sp)
    80004818:	e456                	sd	s5,8(sp)
    8000481a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000481c:	0023c497          	auipc	s1,0x23c
    80004820:	4b448493          	addi	s1,s1,1204 # 80240cd0 <log>
    80004824:	8526                	mv	a0,s1
    80004826:	ffffc097          	auipc	ra,0xffffc
    8000482a:	5b2080e7          	jalr	1458(ra) # 80000dd8 <acquire>
  log.outstanding -= 1;
    8000482e:	509c                	lw	a5,32(s1)
    80004830:	37fd                	addiw	a5,a5,-1
    80004832:	0007891b          	sext.w	s2,a5
    80004836:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004838:	50dc                	lw	a5,36(s1)
    8000483a:	e7b9                	bnez	a5,80004888 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000483c:	04091e63          	bnez	s2,80004898 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004840:	0023c497          	auipc	s1,0x23c
    80004844:	49048493          	addi	s1,s1,1168 # 80240cd0 <log>
    80004848:	4785                	li	a5,1
    8000484a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000484c:	8526                	mv	a0,s1
    8000484e:	ffffc097          	auipc	ra,0xffffc
    80004852:	63e080e7          	jalr	1598(ra) # 80000e8c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004856:	54dc                	lw	a5,44(s1)
    80004858:	06f04763          	bgtz	a5,800048c6 <end_op+0xbc>
    acquire(&log.lock);
    8000485c:	0023c497          	auipc	s1,0x23c
    80004860:	47448493          	addi	s1,s1,1140 # 80240cd0 <log>
    80004864:	8526                	mv	a0,s1
    80004866:	ffffc097          	auipc	ra,0xffffc
    8000486a:	572080e7          	jalr	1394(ra) # 80000dd8 <acquire>
    log.committing = 0;
    8000486e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004872:	8526                	mv	a0,s1
    80004874:	ffffe097          	auipc	ra,0xffffe
    80004878:	d04080e7          	jalr	-764(ra) # 80002578 <wakeup>
    release(&log.lock);
    8000487c:	8526                	mv	a0,s1
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	60e080e7          	jalr	1550(ra) # 80000e8c <release>
}
    80004886:	a03d                	j	800048b4 <end_op+0xaa>
    panic("log.committing");
    80004888:	00004517          	auipc	a0,0x4
    8000488c:	f3850513          	addi	a0,a0,-200 # 800087c0 <syscalls+0x220>
    80004890:	ffffc097          	auipc	ra,0xffffc
    80004894:	cac080e7          	jalr	-852(ra) # 8000053c <panic>
    wakeup(&log);
    80004898:	0023c497          	auipc	s1,0x23c
    8000489c:	43848493          	addi	s1,s1,1080 # 80240cd0 <log>
    800048a0:	8526                	mv	a0,s1
    800048a2:	ffffe097          	auipc	ra,0xffffe
    800048a6:	cd6080e7          	jalr	-810(ra) # 80002578 <wakeup>
  release(&log.lock);
    800048aa:	8526                	mv	a0,s1
    800048ac:	ffffc097          	auipc	ra,0xffffc
    800048b0:	5e0080e7          	jalr	1504(ra) # 80000e8c <release>
}
    800048b4:	70e2                	ld	ra,56(sp)
    800048b6:	7442                	ld	s0,48(sp)
    800048b8:	74a2                	ld	s1,40(sp)
    800048ba:	7902                	ld	s2,32(sp)
    800048bc:	69e2                	ld	s3,24(sp)
    800048be:	6a42                	ld	s4,16(sp)
    800048c0:	6aa2                	ld	s5,8(sp)
    800048c2:	6121                	addi	sp,sp,64
    800048c4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800048c6:	0023ca97          	auipc	s5,0x23c
    800048ca:	43aa8a93          	addi	s5,s5,1082 # 80240d00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048ce:	0023ca17          	auipc	s4,0x23c
    800048d2:	402a0a13          	addi	s4,s4,1026 # 80240cd0 <log>
    800048d6:	018a2583          	lw	a1,24(s4)
    800048da:	012585bb          	addw	a1,a1,s2
    800048de:	2585                	addiw	a1,a1,1
    800048e0:	028a2503          	lw	a0,40(s4)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	cf6080e7          	jalr	-778(ra) # 800035da <bread>
    800048ec:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048ee:	000aa583          	lw	a1,0(s5)
    800048f2:	028a2503          	lw	a0,40(s4)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	ce4080e7          	jalr	-796(ra) # 800035da <bread>
    800048fe:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004900:	40000613          	li	a2,1024
    80004904:	05850593          	addi	a1,a0,88
    80004908:	05848513          	addi	a0,s1,88
    8000490c:	ffffc097          	auipc	ra,0xffffc
    80004910:	624080e7          	jalr	1572(ra) # 80000f30 <memmove>
    bwrite(to);  // write the log
    80004914:	8526                	mv	a0,s1
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	db6080e7          	jalr	-586(ra) # 800036cc <bwrite>
    brelse(from);
    8000491e:	854e                	mv	a0,s3
    80004920:	fffff097          	auipc	ra,0xfffff
    80004924:	dea080e7          	jalr	-534(ra) # 8000370a <brelse>
    brelse(to);
    80004928:	8526                	mv	a0,s1
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	de0080e7          	jalr	-544(ra) # 8000370a <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004932:	2905                	addiw	s2,s2,1
    80004934:	0a91                	addi	s5,s5,4
    80004936:	02ca2783          	lw	a5,44(s4)
    8000493a:	f8f94ee3          	blt	s2,a5,800048d6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	c8c080e7          	jalr	-884(ra) # 800045ca <write_head>
    install_trans(0); // Now install writes to home locations
    80004946:	4501                	li	a0,0
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	cec080e7          	jalr	-788(ra) # 80004634 <install_trans>
    log.lh.n = 0;
    80004950:	0023c797          	auipc	a5,0x23c
    80004954:	3a07a623          	sw	zero,940(a5) # 80240cfc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	c72080e7          	jalr	-910(ra) # 800045ca <write_head>
    80004960:	bdf5                	j	8000485c <end_op+0x52>

0000000080004962 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004962:	1101                	addi	sp,sp,-32
    80004964:	ec06                	sd	ra,24(sp)
    80004966:	e822                	sd	s0,16(sp)
    80004968:	e426                	sd	s1,8(sp)
    8000496a:	e04a                	sd	s2,0(sp)
    8000496c:	1000                	addi	s0,sp,32
    8000496e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004970:	0023c917          	auipc	s2,0x23c
    80004974:	36090913          	addi	s2,s2,864 # 80240cd0 <log>
    80004978:	854a                	mv	a0,s2
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	45e080e7          	jalr	1118(ra) # 80000dd8 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004982:	02c92603          	lw	a2,44(s2)
    80004986:	47f5                	li	a5,29
    80004988:	06c7c563          	blt	a5,a2,800049f2 <log_write+0x90>
    8000498c:	0023c797          	auipc	a5,0x23c
    80004990:	3607a783          	lw	a5,864(a5) # 80240cec <log+0x1c>
    80004994:	37fd                	addiw	a5,a5,-1
    80004996:	04f65e63          	bge	a2,a5,800049f2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000499a:	0023c797          	auipc	a5,0x23c
    8000499e:	3567a783          	lw	a5,854(a5) # 80240cf0 <log+0x20>
    800049a2:	06f05063          	blez	a5,80004a02 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800049a6:	4781                	li	a5,0
    800049a8:	06c05563          	blez	a2,80004a12 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049ac:	44cc                	lw	a1,12(s1)
    800049ae:	0023c717          	auipc	a4,0x23c
    800049b2:	35270713          	addi	a4,a4,850 # 80240d00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049b6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049b8:	4314                	lw	a3,0(a4)
    800049ba:	04b68c63          	beq	a3,a1,80004a12 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049be:	2785                	addiw	a5,a5,1
    800049c0:	0711                	addi	a4,a4,4
    800049c2:	fef61be3          	bne	a2,a5,800049b8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049c6:	0621                	addi	a2,a2,8
    800049c8:	060a                	slli	a2,a2,0x2
    800049ca:	0023c797          	auipc	a5,0x23c
    800049ce:	30678793          	addi	a5,a5,774 # 80240cd0 <log>
    800049d2:	97b2                	add	a5,a5,a2
    800049d4:	44d8                	lw	a4,12(s1)
    800049d6:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049d8:	8526                	mv	a0,s1
    800049da:	fffff097          	auipc	ra,0xfffff
    800049de:	dcc080e7          	jalr	-564(ra) # 800037a6 <bpin>
    log.lh.n++;
    800049e2:	0023c717          	auipc	a4,0x23c
    800049e6:	2ee70713          	addi	a4,a4,750 # 80240cd0 <log>
    800049ea:	575c                	lw	a5,44(a4)
    800049ec:	2785                	addiw	a5,a5,1
    800049ee:	d75c                	sw	a5,44(a4)
    800049f0:	a82d                	j	80004a2a <log_write+0xc8>
    panic("too big a transaction");
    800049f2:	00004517          	auipc	a0,0x4
    800049f6:	dde50513          	addi	a0,a0,-546 # 800087d0 <syscalls+0x230>
    800049fa:	ffffc097          	auipc	ra,0xffffc
    800049fe:	b42080e7          	jalr	-1214(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    80004a02:	00004517          	auipc	a0,0x4
    80004a06:	de650513          	addi	a0,a0,-538 # 800087e8 <syscalls+0x248>
    80004a0a:	ffffc097          	auipc	ra,0xffffc
    80004a0e:	b32080e7          	jalr	-1230(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    80004a12:	00878693          	addi	a3,a5,8
    80004a16:	068a                	slli	a3,a3,0x2
    80004a18:	0023c717          	auipc	a4,0x23c
    80004a1c:	2b870713          	addi	a4,a4,696 # 80240cd0 <log>
    80004a20:	9736                	add	a4,a4,a3
    80004a22:	44d4                	lw	a3,12(s1)
    80004a24:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a26:	faf609e3          	beq	a2,a5,800049d8 <log_write+0x76>
  }
  release(&log.lock);
    80004a2a:	0023c517          	auipc	a0,0x23c
    80004a2e:	2a650513          	addi	a0,a0,678 # 80240cd0 <log>
    80004a32:	ffffc097          	auipc	ra,0xffffc
    80004a36:	45a080e7          	jalr	1114(ra) # 80000e8c <release>
}
    80004a3a:	60e2                	ld	ra,24(sp)
    80004a3c:	6442                	ld	s0,16(sp)
    80004a3e:	64a2                	ld	s1,8(sp)
    80004a40:	6902                	ld	s2,0(sp)
    80004a42:	6105                	addi	sp,sp,32
    80004a44:	8082                	ret

0000000080004a46 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a46:	1101                	addi	sp,sp,-32
    80004a48:	ec06                	sd	ra,24(sp)
    80004a4a:	e822                	sd	s0,16(sp)
    80004a4c:	e426                	sd	s1,8(sp)
    80004a4e:	e04a                	sd	s2,0(sp)
    80004a50:	1000                	addi	s0,sp,32
    80004a52:	84aa                	mv	s1,a0
    80004a54:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a56:	00004597          	auipc	a1,0x4
    80004a5a:	db258593          	addi	a1,a1,-590 # 80008808 <syscalls+0x268>
    80004a5e:	0521                	addi	a0,a0,8
    80004a60:	ffffc097          	auipc	ra,0xffffc
    80004a64:	2e8080e7          	jalr	744(ra) # 80000d48 <initlock>
  lk->name = name;
    80004a68:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a6c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a70:	0204a423          	sw	zero,40(s1)
}
    80004a74:	60e2                	ld	ra,24(sp)
    80004a76:	6442                	ld	s0,16(sp)
    80004a78:	64a2                	ld	s1,8(sp)
    80004a7a:	6902                	ld	s2,0(sp)
    80004a7c:	6105                	addi	sp,sp,32
    80004a7e:	8082                	ret

0000000080004a80 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a80:	1101                	addi	sp,sp,-32
    80004a82:	ec06                	sd	ra,24(sp)
    80004a84:	e822                	sd	s0,16(sp)
    80004a86:	e426                	sd	s1,8(sp)
    80004a88:	e04a                	sd	s2,0(sp)
    80004a8a:	1000                	addi	s0,sp,32
    80004a8c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a8e:	00850913          	addi	s2,a0,8
    80004a92:	854a                	mv	a0,s2
    80004a94:	ffffc097          	auipc	ra,0xffffc
    80004a98:	344080e7          	jalr	836(ra) # 80000dd8 <acquire>
  while (lk->locked) {
    80004a9c:	409c                	lw	a5,0(s1)
    80004a9e:	cb89                	beqz	a5,80004ab0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004aa0:	85ca                	mv	a1,s2
    80004aa2:	8526                	mv	a0,s1
    80004aa4:	ffffe097          	auipc	ra,0xffffe
    80004aa8:	a70080e7          	jalr	-1424(ra) # 80002514 <sleep>
  while (lk->locked) {
    80004aac:	409c                	lw	a5,0(s1)
    80004aae:	fbed                	bnez	a5,80004aa0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004ab0:	4785                	li	a5,1
    80004ab2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004ab4:	ffffd097          	auipc	ra,0xffffd
    80004ab8:	2f8080e7          	jalr	760(ra) # 80001dac <myproc>
    80004abc:	591c                	lw	a5,48(a0)
    80004abe:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ac0:	854a                	mv	a0,s2
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	3ca080e7          	jalr	970(ra) # 80000e8c <release>
}
    80004aca:	60e2                	ld	ra,24(sp)
    80004acc:	6442                	ld	s0,16(sp)
    80004ace:	64a2                	ld	s1,8(sp)
    80004ad0:	6902                	ld	s2,0(sp)
    80004ad2:	6105                	addi	sp,sp,32
    80004ad4:	8082                	ret

0000000080004ad6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ad6:	1101                	addi	sp,sp,-32
    80004ad8:	ec06                	sd	ra,24(sp)
    80004ada:	e822                	sd	s0,16(sp)
    80004adc:	e426                	sd	s1,8(sp)
    80004ade:	e04a                	sd	s2,0(sp)
    80004ae0:	1000                	addi	s0,sp,32
    80004ae2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ae4:	00850913          	addi	s2,a0,8
    80004ae8:	854a                	mv	a0,s2
    80004aea:	ffffc097          	auipc	ra,0xffffc
    80004aee:	2ee080e7          	jalr	750(ra) # 80000dd8 <acquire>
  lk->locked = 0;
    80004af2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004af6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004afa:	8526                	mv	a0,s1
    80004afc:	ffffe097          	auipc	ra,0xffffe
    80004b00:	a7c080e7          	jalr	-1412(ra) # 80002578 <wakeup>
  release(&lk->lk);
    80004b04:	854a                	mv	a0,s2
    80004b06:	ffffc097          	auipc	ra,0xffffc
    80004b0a:	386080e7          	jalr	902(ra) # 80000e8c <release>
}
    80004b0e:	60e2                	ld	ra,24(sp)
    80004b10:	6442                	ld	s0,16(sp)
    80004b12:	64a2                	ld	s1,8(sp)
    80004b14:	6902                	ld	s2,0(sp)
    80004b16:	6105                	addi	sp,sp,32
    80004b18:	8082                	ret

0000000080004b1a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b1a:	7179                	addi	sp,sp,-48
    80004b1c:	f406                	sd	ra,40(sp)
    80004b1e:	f022                	sd	s0,32(sp)
    80004b20:	ec26                	sd	s1,24(sp)
    80004b22:	e84a                	sd	s2,16(sp)
    80004b24:	e44e                	sd	s3,8(sp)
    80004b26:	1800                	addi	s0,sp,48
    80004b28:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b2a:	00850913          	addi	s2,a0,8
    80004b2e:	854a                	mv	a0,s2
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	2a8080e7          	jalr	680(ra) # 80000dd8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b38:	409c                	lw	a5,0(s1)
    80004b3a:	ef99                	bnez	a5,80004b58 <holdingsleep+0x3e>
    80004b3c:	4481                	li	s1,0
  release(&lk->lk);
    80004b3e:	854a                	mv	a0,s2
    80004b40:	ffffc097          	auipc	ra,0xffffc
    80004b44:	34c080e7          	jalr	844(ra) # 80000e8c <release>
  return r;
}
    80004b48:	8526                	mv	a0,s1
    80004b4a:	70a2                	ld	ra,40(sp)
    80004b4c:	7402                	ld	s0,32(sp)
    80004b4e:	64e2                	ld	s1,24(sp)
    80004b50:	6942                	ld	s2,16(sp)
    80004b52:	69a2                	ld	s3,8(sp)
    80004b54:	6145                	addi	sp,sp,48
    80004b56:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b58:	0284a983          	lw	s3,40(s1)
    80004b5c:	ffffd097          	auipc	ra,0xffffd
    80004b60:	250080e7          	jalr	592(ra) # 80001dac <myproc>
    80004b64:	5904                	lw	s1,48(a0)
    80004b66:	413484b3          	sub	s1,s1,s3
    80004b6a:	0014b493          	seqz	s1,s1
    80004b6e:	bfc1                	j	80004b3e <holdingsleep+0x24>

0000000080004b70 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b70:	1141                	addi	sp,sp,-16
    80004b72:	e406                	sd	ra,8(sp)
    80004b74:	e022                	sd	s0,0(sp)
    80004b76:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b78:	00004597          	auipc	a1,0x4
    80004b7c:	ca058593          	addi	a1,a1,-864 # 80008818 <syscalls+0x278>
    80004b80:	0023c517          	auipc	a0,0x23c
    80004b84:	29850513          	addi	a0,a0,664 # 80240e18 <ftable>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	1c0080e7          	jalr	448(ra) # 80000d48 <initlock>
}
    80004b90:	60a2                	ld	ra,8(sp)
    80004b92:	6402                	ld	s0,0(sp)
    80004b94:	0141                	addi	sp,sp,16
    80004b96:	8082                	ret

0000000080004b98 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b98:	1101                	addi	sp,sp,-32
    80004b9a:	ec06                	sd	ra,24(sp)
    80004b9c:	e822                	sd	s0,16(sp)
    80004b9e:	e426                	sd	s1,8(sp)
    80004ba0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004ba2:	0023c517          	auipc	a0,0x23c
    80004ba6:	27650513          	addi	a0,a0,630 # 80240e18 <ftable>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	22e080e7          	jalr	558(ra) # 80000dd8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bb2:	0023c497          	auipc	s1,0x23c
    80004bb6:	27e48493          	addi	s1,s1,638 # 80240e30 <ftable+0x18>
    80004bba:	0023d717          	auipc	a4,0x23d
    80004bbe:	21670713          	addi	a4,a4,534 # 80241dd0 <disk>
    if(f->ref == 0){
    80004bc2:	40dc                	lw	a5,4(s1)
    80004bc4:	cf99                	beqz	a5,80004be2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bc6:	02848493          	addi	s1,s1,40
    80004bca:	fee49ce3          	bne	s1,a4,80004bc2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bce:	0023c517          	auipc	a0,0x23c
    80004bd2:	24a50513          	addi	a0,a0,586 # 80240e18 <ftable>
    80004bd6:	ffffc097          	auipc	ra,0xffffc
    80004bda:	2b6080e7          	jalr	694(ra) # 80000e8c <release>
  return 0;
    80004bde:	4481                	li	s1,0
    80004be0:	a819                	j	80004bf6 <filealloc+0x5e>
      f->ref = 1;
    80004be2:	4785                	li	a5,1
    80004be4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004be6:	0023c517          	auipc	a0,0x23c
    80004bea:	23250513          	addi	a0,a0,562 # 80240e18 <ftable>
    80004bee:	ffffc097          	auipc	ra,0xffffc
    80004bf2:	29e080e7          	jalr	670(ra) # 80000e8c <release>
}
    80004bf6:	8526                	mv	a0,s1
    80004bf8:	60e2                	ld	ra,24(sp)
    80004bfa:	6442                	ld	s0,16(sp)
    80004bfc:	64a2                	ld	s1,8(sp)
    80004bfe:	6105                	addi	sp,sp,32
    80004c00:	8082                	ret

0000000080004c02 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004c02:	1101                	addi	sp,sp,-32
    80004c04:	ec06                	sd	ra,24(sp)
    80004c06:	e822                	sd	s0,16(sp)
    80004c08:	e426                	sd	s1,8(sp)
    80004c0a:	1000                	addi	s0,sp,32
    80004c0c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004c0e:	0023c517          	auipc	a0,0x23c
    80004c12:	20a50513          	addi	a0,a0,522 # 80240e18 <ftable>
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	1c2080e7          	jalr	450(ra) # 80000dd8 <acquire>
  if(f->ref < 1)
    80004c1e:	40dc                	lw	a5,4(s1)
    80004c20:	02f05263          	blez	a5,80004c44 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c24:	2785                	addiw	a5,a5,1
    80004c26:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c28:	0023c517          	auipc	a0,0x23c
    80004c2c:	1f050513          	addi	a0,a0,496 # 80240e18 <ftable>
    80004c30:	ffffc097          	auipc	ra,0xffffc
    80004c34:	25c080e7          	jalr	604(ra) # 80000e8c <release>
  return f;
}
    80004c38:	8526                	mv	a0,s1
    80004c3a:	60e2                	ld	ra,24(sp)
    80004c3c:	6442                	ld	s0,16(sp)
    80004c3e:	64a2                	ld	s1,8(sp)
    80004c40:	6105                	addi	sp,sp,32
    80004c42:	8082                	ret
    panic("filedup");
    80004c44:	00004517          	auipc	a0,0x4
    80004c48:	bdc50513          	addi	a0,a0,-1060 # 80008820 <syscalls+0x280>
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	8f0080e7          	jalr	-1808(ra) # 8000053c <panic>

0000000080004c54 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c54:	7139                	addi	sp,sp,-64
    80004c56:	fc06                	sd	ra,56(sp)
    80004c58:	f822                	sd	s0,48(sp)
    80004c5a:	f426                	sd	s1,40(sp)
    80004c5c:	f04a                	sd	s2,32(sp)
    80004c5e:	ec4e                	sd	s3,24(sp)
    80004c60:	e852                	sd	s4,16(sp)
    80004c62:	e456                	sd	s5,8(sp)
    80004c64:	0080                	addi	s0,sp,64
    80004c66:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c68:	0023c517          	auipc	a0,0x23c
    80004c6c:	1b050513          	addi	a0,a0,432 # 80240e18 <ftable>
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	168080e7          	jalr	360(ra) # 80000dd8 <acquire>
  if(f->ref < 1)
    80004c78:	40dc                	lw	a5,4(s1)
    80004c7a:	06f05163          	blez	a5,80004cdc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c7e:	37fd                	addiw	a5,a5,-1
    80004c80:	0007871b          	sext.w	a4,a5
    80004c84:	c0dc                	sw	a5,4(s1)
    80004c86:	06e04363          	bgtz	a4,80004cec <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c8a:	0004a903          	lw	s2,0(s1)
    80004c8e:	0094ca83          	lbu	s5,9(s1)
    80004c92:	0104ba03          	ld	s4,16(s1)
    80004c96:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c9a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c9e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004ca2:	0023c517          	auipc	a0,0x23c
    80004ca6:	17650513          	addi	a0,a0,374 # 80240e18 <ftable>
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	1e2080e7          	jalr	482(ra) # 80000e8c <release>

  if(ff.type == FD_PIPE){
    80004cb2:	4785                	li	a5,1
    80004cb4:	04f90d63          	beq	s2,a5,80004d0e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004cb8:	3979                	addiw	s2,s2,-2
    80004cba:	4785                	li	a5,1
    80004cbc:	0527e063          	bltu	a5,s2,80004cfc <fileclose+0xa8>
    begin_op();
    80004cc0:	00000097          	auipc	ra,0x0
    80004cc4:	ad0080e7          	jalr	-1328(ra) # 80004790 <begin_op>
    iput(ff.ip);
    80004cc8:	854e                	mv	a0,s3
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	2da080e7          	jalr	730(ra) # 80003fa4 <iput>
    end_op();
    80004cd2:	00000097          	auipc	ra,0x0
    80004cd6:	b38080e7          	jalr	-1224(ra) # 8000480a <end_op>
    80004cda:	a00d                	j	80004cfc <fileclose+0xa8>
    panic("fileclose");
    80004cdc:	00004517          	auipc	a0,0x4
    80004ce0:	b4c50513          	addi	a0,a0,-1204 # 80008828 <syscalls+0x288>
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	858080e7          	jalr	-1960(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004cec:	0023c517          	auipc	a0,0x23c
    80004cf0:	12c50513          	addi	a0,a0,300 # 80240e18 <ftable>
    80004cf4:	ffffc097          	auipc	ra,0xffffc
    80004cf8:	198080e7          	jalr	408(ra) # 80000e8c <release>
  }
}
    80004cfc:	70e2                	ld	ra,56(sp)
    80004cfe:	7442                	ld	s0,48(sp)
    80004d00:	74a2                	ld	s1,40(sp)
    80004d02:	7902                	ld	s2,32(sp)
    80004d04:	69e2                	ld	s3,24(sp)
    80004d06:	6a42                	ld	s4,16(sp)
    80004d08:	6aa2                	ld	s5,8(sp)
    80004d0a:	6121                	addi	sp,sp,64
    80004d0c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004d0e:	85d6                	mv	a1,s5
    80004d10:	8552                	mv	a0,s4
    80004d12:	00000097          	auipc	ra,0x0
    80004d16:	348080e7          	jalr	840(ra) # 8000505a <pipeclose>
    80004d1a:	b7cd                	j	80004cfc <fileclose+0xa8>

0000000080004d1c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d1c:	715d                	addi	sp,sp,-80
    80004d1e:	e486                	sd	ra,72(sp)
    80004d20:	e0a2                	sd	s0,64(sp)
    80004d22:	fc26                	sd	s1,56(sp)
    80004d24:	f84a                	sd	s2,48(sp)
    80004d26:	f44e                	sd	s3,40(sp)
    80004d28:	0880                	addi	s0,sp,80
    80004d2a:	84aa                	mv	s1,a0
    80004d2c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	07e080e7          	jalr	126(ra) # 80001dac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d36:	409c                	lw	a5,0(s1)
    80004d38:	37f9                	addiw	a5,a5,-2
    80004d3a:	4705                	li	a4,1
    80004d3c:	04f76763          	bltu	a4,a5,80004d8a <filestat+0x6e>
    80004d40:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d42:	6c88                	ld	a0,24(s1)
    80004d44:	fffff097          	auipc	ra,0xfffff
    80004d48:	0a6080e7          	jalr	166(ra) # 80003dea <ilock>
    stati(f->ip, &st);
    80004d4c:	fb840593          	addi	a1,s0,-72
    80004d50:	6c88                	ld	a0,24(s1)
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	322080e7          	jalr	802(ra) # 80004074 <stati>
    iunlock(f->ip);
    80004d5a:	6c88                	ld	a0,24(s1)
    80004d5c:	fffff097          	auipc	ra,0xfffff
    80004d60:	150080e7          	jalr	336(ra) # 80003eac <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d64:	46e1                	li	a3,24
    80004d66:	fb840613          	addi	a2,s0,-72
    80004d6a:	85ce                	mv	a1,s3
    80004d6c:	05093503          	ld	a0,80(s2)
    80004d70:	ffffd097          	auipc	ra,0xffffd
    80004d74:	bb4080e7          	jalr	-1100(ra) # 80001924 <copyout>
    80004d78:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d7c:	60a6                	ld	ra,72(sp)
    80004d7e:	6406                	ld	s0,64(sp)
    80004d80:	74e2                	ld	s1,56(sp)
    80004d82:	7942                	ld	s2,48(sp)
    80004d84:	79a2                	ld	s3,40(sp)
    80004d86:	6161                	addi	sp,sp,80
    80004d88:	8082                	ret
  return -1;
    80004d8a:	557d                	li	a0,-1
    80004d8c:	bfc5                	j	80004d7c <filestat+0x60>

0000000080004d8e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d8e:	7179                	addi	sp,sp,-48
    80004d90:	f406                	sd	ra,40(sp)
    80004d92:	f022                	sd	s0,32(sp)
    80004d94:	ec26                	sd	s1,24(sp)
    80004d96:	e84a                	sd	s2,16(sp)
    80004d98:	e44e                	sd	s3,8(sp)
    80004d9a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d9c:	00854783          	lbu	a5,8(a0)
    80004da0:	c3d5                	beqz	a5,80004e44 <fileread+0xb6>
    80004da2:	84aa                	mv	s1,a0
    80004da4:	89ae                	mv	s3,a1
    80004da6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004da8:	411c                	lw	a5,0(a0)
    80004daa:	4705                	li	a4,1
    80004dac:	04e78963          	beq	a5,a4,80004dfe <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004db0:	470d                	li	a4,3
    80004db2:	04e78d63          	beq	a5,a4,80004e0c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004db6:	4709                	li	a4,2
    80004db8:	06e79e63          	bne	a5,a4,80004e34 <fileread+0xa6>
    ilock(f->ip);
    80004dbc:	6d08                	ld	a0,24(a0)
    80004dbe:	fffff097          	auipc	ra,0xfffff
    80004dc2:	02c080e7          	jalr	44(ra) # 80003dea <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004dc6:	874a                	mv	a4,s2
    80004dc8:	5094                	lw	a3,32(s1)
    80004dca:	864e                	mv	a2,s3
    80004dcc:	4585                	li	a1,1
    80004dce:	6c88                	ld	a0,24(s1)
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	2ce080e7          	jalr	718(ra) # 8000409e <readi>
    80004dd8:	892a                	mv	s2,a0
    80004dda:	00a05563          	blez	a0,80004de4 <fileread+0x56>
      f->off += r;
    80004dde:	509c                	lw	a5,32(s1)
    80004de0:	9fa9                	addw	a5,a5,a0
    80004de2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004de4:	6c88                	ld	a0,24(s1)
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	0c6080e7          	jalr	198(ra) # 80003eac <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004dee:	854a                	mv	a0,s2
    80004df0:	70a2                	ld	ra,40(sp)
    80004df2:	7402                	ld	s0,32(sp)
    80004df4:	64e2                	ld	s1,24(sp)
    80004df6:	6942                	ld	s2,16(sp)
    80004df8:	69a2                	ld	s3,8(sp)
    80004dfa:	6145                	addi	sp,sp,48
    80004dfc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dfe:	6908                	ld	a0,16(a0)
    80004e00:	00000097          	auipc	ra,0x0
    80004e04:	3c2080e7          	jalr	962(ra) # 800051c2 <piperead>
    80004e08:	892a                	mv	s2,a0
    80004e0a:	b7d5                	j	80004dee <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004e0c:	02451783          	lh	a5,36(a0)
    80004e10:	03079693          	slli	a3,a5,0x30
    80004e14:	92c1                	srli	a3,a3,0x30
    80004e16:	4725                	li	a4,9
    80004e18:	02d76863          	bltu	a4,a3,80004e48 <fileread+0xba>
    80004e1c:	0792                	slli	a5,a5,0x4
    80004e1e:	0023c717          	auipc	a4,0x23c
    80004e22:	f5a70713          	addi	a4,a4,-166 # 80240d78 <devsw>
    80004e26:	97ba                	add	a5,a5,a4
    80004e28:	639c                	ld	a5,0(a5)
    80004e2a:	c38d                	beqz	a5,80004e4c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e2c:	4505                	li	a0,1
    80004e2e:	9782                	jalr	a5
    80004e30:	892a                	mv	s2,a0
    80004e32:	bf75                	j	80004dee <fileread+0x60>
    panic("fileread");
    80004e34:	00004517          	auipc	a0,0x4
    80004e38:	a0450513          	addi	a0,a0,-1532 # 80008838 <syscalls+0x298>
    80004e3c:	ffffb097          	auipc	ra,0xffffb
    80004e40:	700080e7          	jalr	1792(ra) # 8000053c <panic>
    return -1;
    80004e44:	597d                	li	s2,-1
    80004e46:	b765                	j	80004dee <fileread+0x60>
      return -1;
    80004e48:	597d                	li	s2,-1
    80004e4a:	b755                	j	80004dee <fileread+0x60>
    80004e4c:	597d                	li	s2,-1
    80004e4e:	b745                	j	80004dee <fileread+0x60>

0000000080004e50 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004e50:	00954783          	lbu	a5,9(a0)
    80004e54:	10078e63          	beqz	a5,80004f70 <filewrite+0x120>
{
    80004e58:	715d                	addi	sp,sp,-80
    80004e5a:	e486                	sd	ra,72(sp)
    80004e5c:	e0a2                	sd	s0,64(sp)
    80004e5e:	fc26                	sd	s1,56(sp)
    80004e60:	f84a                	sd	s2,48(sp)
    80004e62:	f44e                	sd	s3,40(sp)
    80004e64:	f052                	sd	s4,32(sp)
    80004e66:	ec56                	sd	s5,24(sp)
    80004e68:	e85a                	sd	s6,16(sp)
    80004e6a:	e45e                	sd	s7,8(sp)
    80004e6c:	e062                	sd	s8,0(sp)
    80004e6e:	0880                	addi	s0,sp,80
    80004e70:	892a                	mv	s2,a0
    80004e72:	8b2e                	mv	s6,a1
    80004e74:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e76:	411c                	lw	a5,0(a0)
    80004e78:	4705                	li	a4,1
    80004e7a:	02e78263          	beq	a5,a4,80004e9e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e7e:	470d                	li	a4,3
    80004e80:	02e78563          	beq	a5,a4,80004eaa <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e84:	4709                	li	a4,2
    80004e86:	0ce79d63          	bne	a5,a4,80004f60 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e8a:	0ac05b63          	blez	a2,80004f40 <filewrite+0xf0>
    int i = 0;
    80004e8e:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e90:	6b85                	lui	s7,0x1
    80004e92:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e96:	6c05                	lui	s8,0x1
    80004e98:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e9c:	a851                	j	80004f30 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e9e:	6908                	ld	a0,16(a0)
    80004ea0:	00000097          	auipc	ra,0x0
    80004ea4:	22a080e7          	jalr	554(ra) # 800050ca <pipewrite>
    80004ea8:	a045                	j	80004f48 <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004eaa:	02451783          	lh	a5,36(a0)
    80004eae:	03079693          	slli	a3,a5,0x30
    80004eb2:	92c1                	srli	a3,a3,0x30
    80004eb4:	4725                	li	a4,9
    80004eb6:	0ad76f63          	bltu	a4,a3,80004f74 <filewrite+0x124>
    80004eba:	0792                	slli	a5,a5,0x4
    80004ebc:	0023c717          	auipc	a4,0x23c
    80004ec0:	ebc70713          	addi	a4,a4,-324 # 80240d78 <devsw>
    80004ec4:	97ba                	add	a5,a5,a4
    80004ec6:	679c                	ld	a5,8(a5)
    80004ec8:	cbc5                	beqz	a5,80004f78 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004eca:	4505                	li	a0,1
    80004ecc:	9782                	jalr	a5
    80004ece:	a8ad                	j	80004f48 <filewrite+0xf8>
      if(n1 > max)
    80004ed0:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004ed4:	00000097          	auipc	ra,0x0
    80004ed8:	8bc080e7          	jalr	-1860(ra) # 80004790 <begin_op>
      ilock(f->ip);
    80004edc:	01893503          	ld	a0,24(s2)
    80004ee0:	fffff097          	auipc	ra,0xfffff
    80004ee4:	f0a080e7          	jalr	-246(ra) # 80003dea <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ee8:	8756                	mv	a4,s5
    80004eea:	02092683          	lw	a3,32(s2)
    80004eee:	01698633          	add	a2,s3,s6
    80004ef2:	4585                	li	a1,1
    80004ef4:	01893503          	ld	a0,24(s2)
    80004ef8:	fffff097          	auipc	ra,0xfffff
    80004efc:	29e080e7          	jalr	670(ra) # 80004196 <writei>
    80004f00:	84aa                	mv	s1,a0
    80004f02:	00a05763          	blez	a0,80004f10 <filewrite+0xc0>
        f->off += r;
    80004f06:	02092783          	lw	a5,32(s2)
    80004f0a:	9fa9                	addw	a5,a5,a0
    80004f0c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f10:	01893503          	ld	a0,24(s2)
    80004f14:	fffff097          	auipc	ra,0xfffff
    80004f18:	f98080e7          	jalr	-104(ra) # 80003eac <iunlock>
      end_op();
    80004f1c:	00000097          	auipc	ra,0x0
    80004f20:	8ee080e7          	jalr	-1810(ra) # 8000480a <end_op>

      if(r != n1){
    80004f24:	009a9f63          	bne	s5,s1,80004f42 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004f28:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f2c:	0149db63          	bge	s3,s4,80004f42 <filewrite+0xf2>
      int n1 = n - i;
    80004f30:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004f34:	0004879b          	sext.w	a5,s1
    80004f38:	f8fbdce3          	bge	s7,a5,80004ed0 <filewrite+0x80>
    80004f3c:	84e2                	mv	s1,s8
    80004f3e:	bf49                	j	80004ed0 <filewrite+0x80>
    int i = 0;
    80004f40:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f42:	033a1d63          	bne	s4,s3,80004f7c <filewrite+0x12c>
    80004f46:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f48:	60a6                	ld	ra,72(sp)
    80004f4a:	6406                	ld	s0,64(sp)
    80004f4c:	74e2                	ld	s1,56(sp)
    80004f4e:	7942                	ld	s2,48(sp)
    80004f50:	79a2                	ld	s3,40(sp)
    80004f52:	7a02                	ld	s4,32(sp)
    80004f54:	6ae2                	ld	s5,24(sp)
    80004f56:	6b42                	ld	s6,16(sp)
    80004f58:	6ba2                	ld	s7,8(sp)
    80004f5a:	6c02                	ld	s8,0(sp)
    80004f5c:	6161                	addi	sp,sp,80
    80004f5e:	8082                	ret
    panic("filewrite");
    80004f60:	00004517          	auipc	a0,0x4
    80004f64:	8e850513          	addi	a0,a0,-1816 # 80008848 <syscalls+0x2a8>
    80004f68:	ffffb097          	auipc	ra,0xffffb
    80004f6c:	5d4080e7          	jalr	1492(ra) # 8000053c <panic>
    return -1;
    80004f70:	557d                	li	a0,-1
}
    80004f72:	8082                	ret
      return -1;
    80004f74:	557d                	li	a0,-1
    80004f76:	bfc9                	j	80004f48 <filewrite+0xf8>
    80004f78:	557d                	li	a0,-1
    80004f7a:	b7f9                	j	80004f48 <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004f7c:	557d                	li	a0,-1
    80004f7e:	b7e9                	j	80004f48 <filewrite+0xf8>

0000000080004f80 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f80:	7179                	addi	sp,sp,-48
    80004f82:	f406                	sd	ra,40(sp)
    80004f84:	f022                	sd	s0,32(sp)
    80004f86:	ec26                	sd	s1,24(sp)
    80004f88:	e84a                	sd	s2,16(sp)
    80004f8a:	e44e                	sd	s3,8(sp)
    80004f8c:	e052                	sd	s4,0(sp)
    80004f8e:	1800                	addi	s0,sp,48
    80004f90:	84aa                	mv	s1,a0
    80004f92:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f94:	0005b023          	sd	zero,0(a1)
    80004f98:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f9c:	00000097          	auipc	ra,0x0
    80004fa0:	bfc080e7          	jalr	-1028(ra) # 80004b98 <filealloc>
    80004fa4:	e088                	sd	a0,0(s1)
    80004fa6:	c551                	beqz	a0,80005032 <pipealloc+0xb2>
    80004fa8:	00000097          	auipc	ra,0x0
    80004fac:	bf0080e7          	jalr	-1040(ra) # 80004b98 <filealloc>
    80004fb0:	00aa3023          	sd	a0,0(s4)
    80004fb4:	c92d                	beqz	a0,80005026 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004fb6:	ffffc097          	auipc	ra,0xffffc
    80004fba:	ca8080e7          	jalr	-856(ra) # 80000c5e <kalloc>
    80004fbe:	892a                	mv	s2,a0
    80004fc0:	c125                	beqz	a0,80005020 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fc2:	4985                	li	s3,1
    80004fc4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fc8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fcc:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fd0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fd4:	00004597          	auipc	a1,0x4
    80004fd8:	88458593          	addi	a1,a1,-1916 # 80008858 <syscalls+0x2b8>
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	d6c080e7          	jalr	-660(ra) # 80000d48 <initlock>
  (*f0)->type = FD_PIPE;
    80004fe4:	609c                	ld	a5,0(s1)
    80004fe6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fea:	609c                	ld	a5,0(s1)
    80004fec:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004ff0:	609c                	ld	a5,0(s1)
    80004ff2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004ff6:	609c                	ld	a5,0(s1)
    80004ff8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ffc:	000a3783          	ld	a5,0(s4)
    80005000:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005004:	000a3783          	ld	a5,0(s4)
    80005008:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000500c:	000a3783          	ld	a5,0(s4)
    80005010:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005014:	000a3783          	ld	a5,0(s4)
    80005018:	0127b823          	sd	s2,16(a5)
  return 0;
    8000501c:	4501                	li	a0,0
    8000501e:	a025                	j	80005046 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005020:	6088                	ld	a0,0(s1)
    80005022:	e501                	bnez	a0,8000502a <pipealloc+0xaa>
    80005024:	a039                	j	80005032 <pipealloc+0xb2>
    80005026:	6088                	ld	a0,0(s1)
    80005028:	c51d                	beqz	a0,80005056 <pipealloc+0xd6>
    fileclose(*f0);
    8000502a:	00000097          	auipc	ra,0x0
    8000502e:	c2a080e7          	jalr	-982(ra) # 80004c54 <fileclose>
  if(*f1)
    80005032:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80005036:	557d                	li	a0,-1
  if(*f1)
    80005038:	c799                	beqz	a5,80005046 <pipealloc+0xc6>
    fileclose(*f1);
    8000503a:	853e                	mv	a0,a5
    8000503c:	00000097          	auipc	ra,0x0
    80005040:	c18080e7          	jalr	-1000(ra) # 80004c54 <fileclose>
  return -1;
    80005044:	557d                	li	a0,-1
}
    80005046:	70a2                	ld	ra,40(sp)
    80005048:	7402                	ld	s0,32(sp)
    8000504a:	64e2                	ld	s1,24(sp)
    8000504c:	6942                	ld	s2,16(sp)
    8000504e:	69a2                	ld	s3,8(sp)
    80005050:	6a02                	ld	s4,0(sp)
    80005052:	6145                	addi	sp,sp,48
    80005054:	8082                	ret
  return -1;
    80005056:	557d                	li	a0,-1
    80005058:	b7fd                	j	80005046 <pipealloc+0xc6>

000000008000505a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000505a:	1101                	addi	sp,sp,-32
    8000505c:	ec06                	sd	ra,24(sp)
    8000505e:	e822                	sd	s0,16(sp)
    80005060:	e426                	sd	s1,8(sp)
    80005062:	e04a                	sd	s2,0(sp)
    80005064:	1000                	addi	s0,sp,32
    80005066:	84aa                	mv	s1,a0
    80005068:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000506a:	ffffc097          	auipc	ra,0xffffc
    8000506e:	d6e080e7          	jalr	-658(ra) # 80000dd8 <acquire>
  if(writable){
    80005072:	02090d63          	beqz	s2,800050ac <pipeclose+0x52>
    pi->writeopen = 0;
    80005076:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000507a:	21848513          	addi	a0,s1,536
    8000507e:	ffffd097          	auipc	ra,0xffffd
    80005082:	4fa080e7          	jalr	1274(ra) # 80002578 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005086:	2204b783          	ld	a5,544(s1)
    8000508a:	eb95                	bnez	a5,800050be <pipeclose+0x64>
    release(&pi->lock);
    8000508c:	8526                	mv	a0,s1
    8000508e:	ffffc097          	auipc	ra,0xffffc
    80005092:	dfe080e7          	jalr	-514(ra) # 80000e8c <release>
    kfree((char*)pi);
    80005096:	8526                	mv	a0,s1
    80005098:	ffffc097          	auipc	ra,0xffffc
    8000509c:	9da080e7          	jalr	-1574(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    800050a0:	60e2                	ld	ra,24(sp)
    800050a2:	6442                	ld	s0,16(sp)
    800050a4:	64a2                	ld	s1,8(sp)
    800050a6:	6902                	ld	s2,0(sp)
    800050a8:	6105                	addi	sp,sp,32
    800050aa:	8082                	ret
    pi->readopen = 0;
    800050ac:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050b0:	21c48513          	addi	a0,s1,540
    800050b4:	ffffd097          	auipc	ra,0xffffd
    800050b8:	4c4080e7          	jalr	1220(ra) # 80002578 <wakeup>
    800050bc:	b7e9                	j	80005086 <pipeclose+0x2c>
    release(&pi->lock);
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	dcc080e7          	jalr	-564(ra) # 80000e8c <release>
}
    800050c8:	bfe1                	j	800050a0 <pipeclose+0x46>

00000000800050ca <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050ca:	711d                	addi	sp,sp,-96
    800050cc:	ec86                	sd	ra,88(sp)
    800050ce:	e8a2                	sd	s0,80(sp)
    800050d0:	e4a6                	sd	s1,72(sp)
    800050d2:	e0ca                	sd	s2,64(sp)
    800050d4:	fc4e                	sd	s3,56(sp)
    800050d6:	f852                	sd	s4,48(sp)
    800050d8:	f456                	sd	s5,40(sp)
    800050da:	f05a                	sd	s6,32(sp)
    800050dc:	ec5e                	sd	s7,24(sp)
    800050de:	e862                	sd	s8,16(sp)
    800050e0:	1080                	addi	s0,sp,96
    800050e2:	84aa                	mv	s1,a0
    800050e4:	8aae                	mv	s5,a1
    800050e6:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050e8:	ffffd097          	auipc	ra,0xffffd
    800050ec:	cc4080e7          	jalr	-828(ra) # 80001dac <myproc>
    800050f0:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	ce4080e7          	jalr	-796(ra) # 80000dd8 <acquire>
  while(i < n){
    800050fc:	0b405663          	blez	s4,800051a8 <pipewrite+0xde>
  int i = 0;
    80005100:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005102:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005104:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005108:	21c48b93          	addi	s7,s1,540
    8000510c:	a089                	j	8000514e <pipewrite+0x84>
      release(&pi->lock);
    8000510e:	8526                	mv	a0,s1
    80005110:	ffffc097          	auipc	ra,0xffffc
    80005114:	d7c080e7          	jalr	-644(ra) # 80000e8c <release>
      return -1;
    80005118:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000511a:	854a                	mv	a0,s2
    8000511c:	60e6                	ld	ra,88(sp)
    8000511e:	6446                	ld	s0,80(sp)
    80005120:	64a6                	ld	s1,72(sp)
    80005122:	6906                	ld	s2,64(sp)
    80005124:	79e2                	ld	s3,56(sp)
    80005126:	7a42                	ld	s4,48(sp)
    80005128:	7aa2                	ld	s5,40(sp)
    8000512a:	7b02                	ld	s6,32(sp)
    8000512c:	6be2                	ld	s7,24(sp)
    8000512e:	6c42                	ld	s8,16(sp)
    80005130:	6125                	addi	sp,sp,96
    80005132:	8082                	ret
      wakeup(&pi->nread);
    80005134:	8562                	mv	a0,s8
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	442080e7          	jalr	1090(ra) # 80002578 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    8000513e:	85a6                	mv	a1,s1
    80005140:	855e                	mv	a0,s7
    80005142:	ffffd097          	auipc	ra,0xffffd
    80005146:	3d2080e7          	jalr	978(ra) # 80002514 <sleep>
  while(i < n){
    8000514a:	07495063          	bge	s2,s4,800051aa <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    8000514e:	2204a783          	lw	a5,544(s1)
    80005152:	dfd5                	beqz	a5,8000510e <pipewrite+0x44>
    80005154:	854e                	mv	a0,s3
    80005156:	ffffd097          	auipc	ra,0xffffd
    8000515a:	666080e7          	jalr	1638(ra) # 800027bc <killed>
    8000515e:	f945                	bnez	a0,8000510e <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005160:	2184a783          	lw	a5,536(s1)
    80005164:	21c4a703          	lw	a4,540(s1)
    80005168:	2007879b          	addiw	a5,a5,512
    8000516c:	fcf704e3          	beq	a4,a5,80005134 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005170:	4685                	li	a3,1
    80005172:	01590633          	add	a2,s2,s5
    80005176:	faf40593          	addi	a1,s0,-81
    8000517a:	0509b503          	ld	a0,80(s3)
    8000517e:	ffffd097          	auipc	ra,0xffffd
    80005182:	886080e7          	jalr	-1914(ra) # 80001a04 <copyin>
    80005186:	03650263          	beq	a0,s6,800051aa <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000518a:	21c4a783          	lw	a5,540(s1)
    8000518e:	0017871b          	addiw	a4,a5,1
    80005192:	20e4ae23          	sw	a4,540(s1)
    80005196:	1ff7f793          	andi	a5,a5,511
    8000519a:	97a6                	add	a5,a5,s1
    8000519c:	faf44703          	lbu	a4,-81(s0)
    800051a0:	00e78c23          	sb	a4,24(a5)
      i++;
    800051a4:	2905                	addiw	s2,s2,1
    800051a6:	b755                	j	8000514a <pipewrite+0x80>
  int i = 0;
    800051a8:	4901                	li	s2,0
  wakeup(&pi->nread);
    800051aa:	21848513          	addi	a0,s1,536
    800051ae:	ffffd097          	auipc	ra,0xffffd
    800051b2:	3ca080e7          	jalr	970(ra) # 80002578 <wakeup>
  release(&pi->lock);
    800051b6:	8526                	mv	a0,s1
    800051b8:	ffffc097          	auipc	ra,0xffffc
    800051bc:	cd4080e7          	jalr	-812(ra) # 80000e8c <release>
  return i;
    800051c0:	bfa9                	j	8000511a <pipewrite+0x50>

00000000800051c2 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051c2:	715d                	addi	sp,sp,-80
    800051c4:	e486                	sd	ra,72(sp)
    800051c6:	e0a2                	sd	s0,64(sp)
    800051c8:	fc26                	sd	s1,56(sp)
    800051ca:	f84a                	sd	s2,48(sp)
    800051cc:	f44e                	sd	s3,40(sp)
    800051ce:	f052                	sd	s4,32(sp)
    800051d0:	ec56                	sd	s5,24(sp)
    800051d2:	e85a                	sd	s6,16(sp)
    800051d4:	0880                	addi	s0,sp,80
    800051d6:	84aa                	mv	s1,a0
    800051d8:	892e                	mv	s2,a1
    800051da:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051dc:	ffffd097          	auipc	ra,0xffffd
    800051e0:	bd0080e7          	jalr	-1072(ra) # 80001dac <myproc>
    800051e4:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051e6:	8526                	mv	a0,s1
    800051e8:	ffffc097          	auipc	ra,0xffffc
    800051ec:	bf0080e7          	jalr	-1040(ra) # 80000dd8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051f0:	2184a703          	lw	a4,536(s1)
    800051f4:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051f8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051fc:	02f71763          	bne	a4,a5,8000522a <piperead+0x68>
    80005200:	2244a783          	lw	a5,548(s1)
    80005204:	c39d                	beqz	a5,8000522a <piperead+0x68>
    if(killed(pr)){
    80005206:	8552                	mv	a0,s4
    80005208:	ffffd097          	auipc	ra,0xffffd
    8000520c:	5b4080e7          	jalr	1460(ra) # 800027bc <killed>
    80005210:	e949                	bnez	a0,800052a2 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005212:	85a6                	mv	a1,s1
    80005214:	854e                	mv	a0,s3
    80005216:	ffffd097          	auipc	ra,0xffffd
    8000521a:	2fe080e7          	jalr	766(ra) # 80002514 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000521e:	2184a703          	lw	a4,536(s1)
    80005222:	21c4a783          	lw	a5,540(s1)
    80005226:	fcf70de3          	beq	a4,a5,80005200 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000522a:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000522c:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000522e:	05505463          	blez	s5,80005276 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005232:	2184a783          	lw	a5,536(s1)
    80005236:	21c4a703          	lw	a4,540(s1)
    8000523a:	02f70e63          	beq	a4,a5,80005276 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000523e:	0017871b          	addiw	a4,a5,1
    80005242:	20e4ac23          	sw	a4,536(s1)
    80005246:	1ff7f793          	andi	a5,a5,511
    8000524a:	97a6                	add	a5,a5,s1
    8000524c:	0187c783          	lbu	a5,24(a5)
    80005250:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005254:	4685                	li	a3,1
    80005256:	fbf40613          	addi	a2,s0,-65
    8000525a:	85ca                	mv	a1,s2
    8000525c:	050a3503          	ld	a0,80(s4)
    80005260:	ffffc097          	auipc	ra,0xffffc
    80005264:	6c4080e7          	jalr	1732(ra) # 80001924 <copyout>
    80005268:	01650763          	beq	a0,s6,80005276 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000526c:	2985                	addiw	s3,s3,1
    8000526e:	0905                	addi	s2,s2,1
    80005270:	fd3a91e3          	bne	s5,s3,80005232 <piperead+0x70>
    80005274:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005276:	21c48513          	addi	a0,s1,540
    8000527a:	ffffd097          	auipc	ra,0xffffd
    8000527e:	2fe080e7          	jalr	766(ra) # 80002578 <wakeup>
  release(&pi->lock);
    80005282:	8526                	mv	a0,s1
    80005284:	ffffc097          	auipc	ra,0xffffc
    80005288:	c08080e7          	jalr	-1016(ra) # 80000e8c <release>
  return i;
}
    8000528c:	854e                	mv	a0,s3
    8000528e:	60a6                	ld	ra,72(sp)
    80005290:	6406                	ld	s0,64(sp)
    80005292:	74e2                	ld	s1,56(sp)
    80005294:	7942                	ld	s2,48(sp)
    80005296:	79a2                	ld	s3,40(sp)
    80005298:	7a02                	ld	s4,32(sp)
    8000529a:	6ae2                	ld	s5,24(sp)
    8000529c:	6b42                	ld	s6,16(sp)
    8000529e:	6161                	addi	sp,sp,80
    800052a0:	8082                	ret
      release(&pi->lock);
    800052a2:	8526                	mv	a0,s1
    800052a4:	ffffc097          	auipc	ra,0xffffc
    800052a8:	be8080e7          	jalr	-1048(ra) # 80000e8c <release>
      return -1;
    800052ac:	59fd                	li	s3,-1
    800052ae:	bff9                	j	8000528c <piperead+0xca>

00000000800052b0 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052b0:	1141                	addi	sp,sp,-16
    800052b2:	e422                	sd	s0,8(sp)
    800052b4:	0800                	addi	s0,sp,16
    800052b6:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052b8:	8905                	andi	a0,a0,1
    800052ba:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    800052bc:	8b89                	andi	a5,a5,2
    800052be:	c399                	beqz	a5,800052c4 <flags2perm+0x14>
      perm |= PTE_W;
    800052c0:	00456513          	ori	a0,a0,4
    return perm;
}
    800052c4:	6422                	ld	s0,8(sp)
    800052c6:	0141                	addi	sp,sp,16
    800052c8:	8082                	ret

00000000800052ca <exec>:

int
exec(char *path, char **argv)
{
    800052ca:	df010113          	addi	sp,sp,-528
    800052ce:	20113423          	sd	ra,520(sp)
    800052d2:	20813023          	sd	s0,512(sp)
    800052d6:	ffa6                	sd	s1,504(sp)
    800052d8:	fbca                	sd	s2,496(sp)
    800052da:	f7ce                	sd	s3,488(sp)
    800052dc:	f3d2                	sd	s4,480(sp)
    800052de:	efd6                	sd	s5,472(sp)
    800052e0:	ebda                	sd	s6,464(sp)
    800052e2:	e7de                	sd	s7,456(sp)
    800052e4:	e3e2                	sd	s8,448(sp)
    800052e6:	ff66                	sd	s9,440(sp)
    800052e8:	fb6a                	sd	s10,432(sp)
    800052ea:	f76e                	sd	s11,424(sp)
    800052ec:	0c00                	addi	s0,sp,528
    800052ee:	892a                	mv	s2,a0
    800052f0:	dea43c23          	sd	a0,-520(s0)
    800052f4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052f8:	ffffd097          	auipc	ra,0xffffd
    800052fc:	ab4080e7          	jalr	-1356(ra) # 80001dac <myproc>
    80005300:	84aa                	mv	s1,a0

  begin_op();
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	48e080e7          	jalr	1166(ra) # 80004790 <begin_op>

  if((ip = namei(path)) == 0){
    8000530a:	854a                	mv	a0,s2
    8000530c:	fffff097          	auipc	ra,0xfffff
    80005310:	284080e7          	jalr	644(ra) # 80004590 <namei>
    80005314:	c92d                	beqz	a0,80005386 <exec+0xbc>
    80005316:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005318:	fffff097          	auipc	ra,0xfffff
    8000531c:	ad2080e7          	jalr	-1326(ra) # 80003dea <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005320:	04000713          	li	a4,64
    80005324:	4681                	li	a3,0
    80005326:	e5040613          	addi	a2,s0,-432
    8000532a:	4581                	li	a1,0
    8000532c:	8552                	mv	a0,s4
    8000532e:	fffff097          	auipc	ra,0xfffff
    80005332:	d70080e7          	jalr	-656(ra) # 8000409e <readi>
    80005336:	04000793          	li	a5,64
    8000533a:	00f51a63          	bne	a0,a5,8000534e <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000533e:	e5042703          	lw	a4,-432(s0)
    80005342:	464c47b7          	lui	a5,0x464c4
    80005346:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000534a:	04f70463          	beq	a4,a5,80005392 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000534e:	8552                	mv	a0,s4
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	cfc080e7          	jalr	-772(ra) # 8000404c <iunlockput>
    end_op();
    80005358:	fffff097          	auipc	ra,0xfffff
    8000535c:	4b2080e7          	jalr	1202(ra) # 8000480a <end_op>
  }
  return -1;
    80005360:	557d                	li	a0,-1
}
    80005362:	20813083          	ld	ra,520(sp)
    80005366:	20013403          	ld	s0,512(sp)
    8000536a:	74fe                	ld	s1,504(sp)
    8000536c:	795e                	ld	s2,496(sp)
    8000536e:	79be                	ld	s3,488(sp)
    80005370:	7a1e                	ld	s4,480(sp)
    80005372:	6afe                	ld	s5,472(sp)
    80005374:	6b5e                	ld	s6,464(sp)
    80005376:	6bbe                	ld	s7,456(sp)
    80005378:	6c1e                	ld	s8,448(sp)
    8000537a:	7cfa                	ld	s9,440(sp)
    8000537c:	7d5a                	ld	s10,432(sp)
    8000537e:	7dba                	ld	s11,424(sp)
    80005380:	21010113          	addi	sp,sp,528
    80005384:	8082                	ret
    end_op();
    80005386:	fffff097          	auipc	ra,0xfffff
    8000538a:	484080e7          	jalr	1156(ra) # 8000480a <end_op>
    return -1;
    8000538e:	557d                	li	a0,-1
    80005390:	bfc9                	j	80005362 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005392:	8526                	mv	a0,s1
    80005394:	ffffd097          	auipc	ra,0xffffd
    80005398:	adc080e7          	jalr	-1316(ra) # 80001e70 <proc_pagetable>
    8000539c:	8b2a                	mv	s6,a0
    8000539e:	d945                	beqz	a0,8000534e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a0:	e7042d03          	lw	s10,-400(s0)
    800053a4:	e8845783          	lhu	a5,-376(s0)
    800053a8:	10078463          	beqz	a5,800054b0 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053ac:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ae:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    800053b0:	6c85                	lui	s9,0x1
    800053b2:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800053b6:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    800053ba:	6a85                	lui	s5,0x1
    800053bc:	a0b5                	j	80005428 <exec+0x15e>
      panic("loadseg: address should exist");
    800053be:	00003517          	auipc	a0,0x3
    800053c2:	4a250513          	addi	a0,a0,1186 # 80008860 <syscalls+0x2c0>
    800053c6:	ffffb097          	auipc	ra,0xffffb
    800053ca:	176080e7          	jalr	374(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800053ce:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053d0:	8726                	mv	a4,s1
    800053d2:	012c06bb          	addw	a3,s8,s2
    800053d6:	4581                	li	a1,0
    800053d8:	8552                	mv	a0,s4
    800053da:	fffff097          	auipc	ra,0xfffff
    800053de:	cc4080e7          	jalr	-828(ra) # 8000409e <readi>
    800053e2:	2501                	sext.w	a0,a0
    800053e4:	24a49863          	bne	s1,a0,80005634 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800053e8:	012a893b          	addw	s2,s5,s2
    800053ec:	03397563          	bgeu	s2,s3,80005416 <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800053f0:	02091593          	slli	a1,s2,0x20
    800053f4:	9181                	srli	a1,a1,0x20
    800053f6:	95de                	add	a1,a1,s7
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	e62080e7          	jalr	-414(ra) # 8000125c <walkaddr>
    80005402:	862a                	mv	a2,a0
    if(pa == 0)
    80005404:	dd4d                	beqz	a0,800053be <exec+0xf4>
    if(sz - i < PGSIZE)
    80005406:	412984bb          	subw	s1,s3,s2
    8000540a:	0004879b          	sext.w	a5,s1
    8000540e:	fcfcf0e3          	bgeu	s9,a5,800053ce <exec+0x104>
    80005412:	84d6                	mv	s1,s5
    80005414:	bf6d                	j	800053ce <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005416:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000541a:	2d85                	addiw	s11,s11,1 # 1001 <_entry-0x7fffefff>
    8000541c:	038d0d1b          	addiw	s10,s10,56
    80005420:	e8845783          	lhu	a5,-376(s0)
    80005424:	08fdd763          	bge	s11,a5,800054b2 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005428:	2d01                	sext.w	s10,s10
    8000542a:	03800713          	li	a4,56
    8000542e:	86ea                	mv	a3,s10
    80005430:	e1840613          	addi	a2,s0,-488
    80005434:	4581                	li	a1,0
    80005436:	8552                	mv	a0,s4
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	c66080e7          	jalr	-922(ra) # 8000409e <readi>
    80005440:	03800793          	li	a5,56
    80005444:	1ef51663          	bne	a0,a5,80005630 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    80005448:	e1842783          	lw	a5,-488(s0)
    8000544c:	4705                	li	a4,1
    8000544e:	fce796e3          	bne	a5,a4,8000541a <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005452:	e4043483          	ld	s1,-448(s0)
    80005456:	e3843783          	ld	a5,-456(s0)
    8000545a:	1ef4e863          	bltu	s1,a5,8000564a <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000545e:	e2843783          	ld	a5,-472(s0)
    80005462:	94be                	add	s1,s1,a5
    80005464:	1ef4e663          	bltu	s1,a5,80005650 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    80005468:	df043703          	ld	a4,-528(s0)
    8000546c:	8ff9                	and	a5,a5,a4
    8000546e:	1e079463          	bnez	a5,80005656 <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005472:	e1c42503          	lw	a0,-484(s0)
    80005476:	00000097          	auipc	ra,0x0
    8000547a:	e3a080e7          	jalr	-454(ra) # 800052b0 <flags2perm>
    8000547e:	86aa                	mv	a3,a0
    80005480:	8626                	mv	a2,s1
    80005482:	85ca                	mv	a1,s2
    80005484:	855a                	mv	a0,s6
    80005486:	ffffc097          	auipc	ra,0xffffc
    8000548a:	18a080e7          	jalr	394(ra) # 80001610 <uvmalloc>
    8000548e:	e0a43423          	sd	a0,-504(s0)
    80005492:	1c050563          	beqz	a0,8000565c <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005496:	e2843b83          	ld	s7,-472(s0)
    8000549a:	e2042c03          	lw	s8,-480(s0)
    8000549e:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054a2:	00098463          	beqz	s3,800054aa <exec+0x1e0>
    800054a6:	4901                	li	s2,0
    800054a8:	b7a1                	j	800053f0 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054aa:	e0843903          	ld	s2,-504(s0)
    800054ae:	b7b5                	j	8000541a <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800054b0:	4901                	li	s2,0
  iunlockput(ip);
    800054b2:	8552                	mv	a0,s4
    800054b4:	fffff097          	auipc	ra,0xfffff
    800054b8:	b98080e7          	jalr	-1128(ra) # 8000404c <iunlockput>
  end_op();
    800054bc:	fffff097          	auipc	ra,0xfffff
    800054c0:	34e080e7          	jalr	846(ra) # 8000480a <end_op>
  p = myproc();
    800054c4:	ffffd097          	auipc	ra,0xffffd
    800054c8:	8e8080e7          	jalr	-1816(ra) # 80001dac <myproc>
    800054cc:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054ce:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800054d2:	6985                	lui	s3,0x1
    800054d4:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800054d6:	99ca                	add	s3,s3,s2
    800054d8:	77fd                	lui	a5,0xfffff
    800054da:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054de:	4691                	li	a3,4
    800054e0:	6609                	lui	a2,0x2
    800054e2:	964e                	add	a2,a2,s3
    800054e4:	85ce                	mv	a1,s3
    800054e6:	855a                	mv	a0,s6
    800054e8:	ffffc097          	auipc	ra,0xffffc
    800054ec:	128080e7          	jalr	296(ra) # 80001610 <uvmalloc>
    800054f0:	892a                	mv	s2,a0
    800054f2:	e0a43423          	sd	a0,-504(s0)
    800054f6:	e509                	bnez	a0,80005500 <exec+0x236>
  if(pagetable)
    800054f8:	e1343423          	sd	s3,-504(s0)
    800054fc:	4a01                	li	s4,0
    800054fe:	aa1d                	j	80005634 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005500:	75f9                	lui	a1,0xffffe
    80005502:	95aa                	add	a1,a1,a0
    80005504:	855a                	mv	a0,s6
    80005506:	ffffc097          	auipc	ra,0xffffc
    8000550a:	3ec080e7          	jalr	1004(ra) # 800018f2 <uvmclear>
  stackbase = sp - PGSIZE;
    8000550e:	7bfd                	lui	s7,0xfffff
    80005510:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    80005512:	e0043783          	ld	a5,-512(s0)
    80005516:	6388                	ld	a0,0(a5)
    80005518:	c52d                	beqz	a0,80005582 <exec+0x2b8>
    8000551a:	e9040993          	addi	s3,s0,-368
    8000551e:	f9040c13          	addi	s8,s0,-112
    80005522:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005524:	ffffc097          	auipc	ra,0xffffc
    80005528:	b2a080e7          	jalr	-1238(ra) # 8000104e <strlen>
    8000552c:	0015079b          	addiw	a5,a0,1
    80005530:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005534:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005538:	13796563          	bltu	s2,s7,80005662 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000553c:	e0043d03          	ld	s10,-512(s0)
    80005540:	000d3a03          	ld	s4,0(s10)
    80005544:	8552                	mv	a0,s4
    80005546:	ffffc097          	auipc	ra,0xffffc
    8000554a:	b08080e7          	jalr	-1272(ra) # 8000104e <strlen>
    8000554e:	0015069b          	addiw	a3,a0,1
    80005552:	8652                	mv	a2,s4
    80005554:	85ca                	mv	a1,s2
    80005556:	855a                	mv	a0,s6
    80005558:	ffffc097          	auipc	ra,0xffffc
    8000555c:	3cc080e7          	jalr	972(ra) # 80001924 <copyout>
    80005560:	10054363          	bltz	a0,80005666 <exec+0x39c>
    ustack[argc] = sp;
    80005564:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005568:	0485                	addi	s1,s1,1
    8000556a:	008d0793          	addi	a5,s10,8
    8000556e:	e0f43023          	sd	a5,-512(s0)
    80005572:	008d3503          	ld	a0,8(s10)
    80005576:	c909                	beqz	a0,80005588 <exec+0x2be>
    if(argc >= MAXARG)
    80005578:	09a1                	addi	s3,s3,8
    8000557a:	fb8995e3          	bne	s3,s8,80005524 <exec+0x25a>
  ip = 0;
    8000557e:	4a01                	li	s4,0
    80005580:	a855                	j	80005634 <exec+0x36a>
  sp = sz;
    80005582:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    80005586:	4481                	li	s1,0
  ustack[argc] = 0;
    80005588:	00349793          	slli	a5,s1,0x3
    8000558c:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbd080>
    80005590:	97a2                	add	a5,a5,s0
    80005592:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005596:	00148693          	addi	a3,s1,1
    8000559a:	068e                	slli	a3,a3,0x3
    8000559c:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800055a0:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    800055a4:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    800055a8:	f57968e3          	bltu	s2,s7,800054f8 <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800055ac:	e9040613          	addi	a2,s0,-368
    800055b0:	85ca                	mv	a1,s2
    800055b2:	855a                	mv	a0,s6
    800055b4:	ffffc097          	auipc	ra,0xffffc
    800055b8:	370080e7          	jalr	880(ra) # 80001924 <copyout>
    800055bc:	0a054763          	bltz	a0,8000566a <exec+0x3a0>
  p->trapframe->a1 = sp;
    800055c0:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    800055c4:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800055c8:	df843783          	ld	a5,-520(s0)
    800055cc:	0007c703          	lbu	a4,0(a5)
    800055d0:	cf11                	beqz	a4,800055ec <exec+0x322>
    800055d2:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055d4:	02f00693          	li	a3,47
    800055d8:	a039                	j	800055e6 <exec+0x31c>
      last = s+1;
    800055da:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055de:	0785                	addi	a5,a5,1
    800055e0:	fff7c703          	lbu	a4,-1(a5)
    800055e4:	c701                	beqz	a4,800055ec <exec+0x322>
    if(*s == '/')
    800055e6:	fed71ce3          	bne	a4,a3,800055de <exec+0x314>
    800055ea:	bfc5                	j	800055da <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800055ec:	4641                	li	a2,16
    800055ee:	df843583          	ld	a1,-520(s0)
    800055f2:	158a8513          	addi	a0,s5,344
    800055f6:	ffffc097          	auipc	ra,0xffffc
    800055fa:	a26080e7          	jalr	-1498(ra) # 8000101c <safestrcpy>
  oldpagetable = p->pagetable;
    800055fe:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80005602:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    80005606:	e0843783          	ld	a5,-504(s0)
    8000560a:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000560e:	058ab783          	ld	a5,88(s5)
    80005612:	e6843703          	ld	a4,-408(s0)
    80005616:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005618:	058ab783          	ld	a5,88(s5)
    8000561c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005620:	85e6                	mv	a1,s9
    80005622:	ffffd097          	auipc	ra,0xffffd
    80005626:	8ea080e7          	jalr	-1814(ra) # 80001f0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000562a:	0004851b          	sext.w	a0,s1
    8000562e:	bb15                	j	80005362 <exec+0x98>
    80005630:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005634:	e0843583          	ld	a1,-504(s0)
    80005638:	855a                	mv	a0,s6
    8000563a:	ffffd097          	auipc	ra,0xffffd
    8000563e:	8d2080e7          	jalr	-1838(ra) # 80001f0c <proc_freepagetable>
  return -1;
    80005642:	557d                	li	a0,-1
  if(ip){
    80005644:	d00a0fe3          	beqz	s4,80005362 <exec+0x98>
    80005648:	b319                	j	8000534e <exec+0x84>
    8000564a:	e1243423          	sd	s2,-504(s0)
    8000564e:	b7dd                	j	80005634 <exec+0x36a>
    80005650:	e1243423          	sd	s2,-504(s0)
    80005654:	b7c5                	j	80005634 <exec+0x36a>
    80005656:	e1243423          	sd	s2,-504(s0)
    8000565a:	bfe9                	j	80005634 <exec+0x36a>
    8000565c:	e1243423          	sd	s2,-504(s0)
    80005660:	bfd1                	j	80005634 <exec+0x36a>
  ip = 0;
    80005662:	4a01                	li	s4,0
    80005664:	bfc1                	j	80005634 <exec+0x36a>
    80005666:	4a01                	li	s4,0
  if(pagetable)
    80005668:	b7f1                	j	80005634 <exec+0x36a>
  sz = sz1;
    8000566a:	e0843983          	ld	s3,-504(s0)
    8000566e:	b569                	j	800054f8 <exec+0x22e>

0000000080005670 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005670:	7179                	addi	sp,sp,-48
    80005672:	f406                	sd	ra,40(sp)
    80005674:	f022                	sd	s0,32(sp)
    80005676:	ec26                	sd	s1,24(sp)
    80005678:	e84a                	sd	s2,16(sp)
    8000567a:	1800                	addi	s0,sp,48
    8000567c:	892e                	mv	s2,a1
    8000567e:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005680:	fdc40593          	addi	a1,s0,-36
    80005684:	ffffe097          	auipc	ra,0xffffe
    80005688:	a9a080e7          	jalr	-1382(ra) # 8000311e <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000568c:	fdc42703          	lw	a4,-36(s0)
    80005690:	47bd                	li	a5,15
    80005692:	02e7eb63          	bltu	a5,a4,800056c8 <argfd+0x58>
    80005696:	ffffc097          	auipc	ra,0xffffc
    8000569a:	716080e7          	jalr	1814(ra) # 80001dac <myproc>
    8000569e:	fdc42703          	lw	a4,-36(s0)
    800056a2:	01a70793          	addi	a5,a4,26
    800056a6:	078e                	slli	a5,a5,0x3
    800056a8:	953e                	add	a0,a0,a5
    800056aa:	611c                	ld	a5,0(a0)
    800056ac:	c385                	beqz	a5,800056cc <argfd+0x5c>
    return -1;
  if(pfd)
    800056ae:	00090463          	beqz	s2,800056b6 <argfd+0x46>
    *pfd = fd;
    800056b2:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056b6:	4501                	li	a0,0
  if(pf)
    800056b8:	c091                	beqz	s1,800056bc <argfd+0x4c>
    *pf = f;
    800056ba:	e09c                	sd	a5,0(s1)
}
    800056bc:	70a2                	ld	ra,40(sp)
    800056be:	7402                	ld	s0,32(sp)
    800056c0:	64e2                	ld	s1,24(sp)
    800056c2:	6942                	ld	s2,16(sp)
    800056c4:	6145                	addi	sp,sp,48
    800056c6:	8082                	ret
    return -1;
    800056c8:	557d                	li	a0,-1
    800056ca:	bfcd                	j	800056bc <argfd+0x4c>
    800056cc:	557d                	li	a0,-1
    800056ce:	b7fd                	j	800056bc <argfd+0x4c>

00000000800056d0 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056d0:	1101                	addi	sp,sp,-32
    800056d2:	ec06                	sd	ra,24(sp)
    800056d4:	e822                	sd	s0,16(sp)
    800056d6:	e426                	sd	s1,8(sp)
    800056d8:	1000                	addi	s0,sp,32
    800056da:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056dc:	ffffc097          	auipc	ra,0xffffc
    800056e0:	6d0080e7          	jalr	1744(ra) # 80001dac <myproc>
    800056e4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056e6:	0d050793          	addi	a5,a0,208
    800056ea:	4501                	li	a0,0
    800056ec:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056ee:	6398                	ld	a4,0(a5)
    800056f0:	cb19                	beqz	a4,80005706 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056f2:	2505                	addiw	a0,a0,1
    800056f4:	07a1                	addi	a5,a5,8
    800056f6:	fed51ce3          	bne	a0,a3,800056ee <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056fa:	557d                	li	a0,-1
}
    800056fc:	60e2                	ld	ra,24(sp)
    800056fe:	6442                	ld	s0,16(sp)
    80005700:	64a2                	ld	s1,8(sp)
    80005702:	6105                	addi	sp,sp,32
    80005704:	8082                	ret
      p->ofile[fd] = f;
    80005706:	01a50793          	addi	a5,a0,26
    8000570a:	078e                	slli	a5,a5,0x3
    8000570c:	963e                	add	a2,a2,a5
    8000570e:	e204                	sd	s1,0(a2)
      return fd;
    80005710:	b7f5                	j	800056fc <fdalloc+0x2c>

0000000080005712 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005712:	715d                	addi	sp,sp,-80
    80005714:	e486                	sd	ra,72(sp)
    80005716:	e0a2                	sd	s0,64(sp)
    80005718:	fc26                	sd	s1,56(sp)
    8000571a:	f84a                	sd	s2,48(sp)
    8000571c:	f44e                	sd	s3,40(sp)
    8000571e:	f052                	sd	s4,32(sp)
    80005720:	ec56                	sd	s5,24(sp)
    80005722:	e85a                	sd	s6,16(sp)
    80005724:	0880                	addi	s0,sp,80
    80005726:	8b2e                	mv	s6,a1
    80005728:	89b2                	mv	s3,a2
    8000572a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000572c:	fb040593          	addi	a1,s0,-80
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	e7e080e7          	jalr	-386(ra) # 800045ae <nameiparent>
    80005738:	84aa                	mv	s1,a0
    8000573a:	14050b63          	beqz	a0,80005890 <create+0x17e>
    return 0;

  ilock(dp);
    8000573e:	ffffe097          	auipc	ra,0xffffe
    80005742:	6ac080e7          	jalr	1708(ra) # 80003dea <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005746:	4601                	li	a2,0
    80005748:	fb040593          	addi	a1,s0,-80
    8000574c:	8526                	mv	a0,s1
    8000574e:	fffff097          	auipc	ra,0xfffff
    80005752:	b80080e7          	jalr	-1152(ra) # 800042ce <dirlookup>
    80005756:	8aaa                	mv	s5,a0
    80005758:	c921                	beqz	a0,800057a8 <create+0x96>
    iunlockput(dp);
    8000575a:	8526                	mv	a0,s1
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	8f0080e7          	jalr	-1808(ra) # 8000404c <iunlockput>
    ilock(ip);
    80005764:	8556                	mv	a0,s5
    80005766:	ffffe097          	auipc	ra,0xffffe
    8000576a:	684080e7          	jalr	1668(ra) # 80003dea <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000576e:	4789                	li	a5,2
    80005770:	02fb1563          	bne	s6,a5,8000579a <create+0x88>
    80005774:	044ad783          	lhu	a5,68(s5)
    80005778:	37f9                	addiw	a5,a5,-2
    8000577a:	17c2                	slli	a5,a5,0x30
    8000577c:	93c1                	srli	a5,a5,0x30
    8000577e:	4705                	li	a4,1
    80005780:	00f76d63          	bltu	a4,a5,8000579a <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005784:	8556                	mv	a0,s5
    80005786:	60a6                	ld	ra,72(sp)
    80005788:	6406                	ld	s0,64(sp)
    8000578a:	74e2                	ld	s1,56(sp)
    8000578c:	7942                	ld	s2,48(sp)
    8000578e:	79a2                	ld	s3,40(sp)
    80005790:	7a02                	ld	s4,32(sp)
    80005792:	6ae2                	ld	s5,24(sp)
    80005794:	6b42                	ld	s6,16(sp)
    80005796:	6161                	addi	sp,sp,80
    80005798:	8082                	ret
    iunlockput(ip);
    8000579a:	8556                	mv	a0,s5
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	8b0080e7          	jalr	-1872(ra) # 8000404c <iunlockput>
    return 0;
    800057a4:	4a81                	li	s5,0
    800057a6:	bff9                	j	80005784 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    800057a8:	85da                	mv	a1,s6
    800057aa:	4088                	lw	a0,0(s1)
    800057ac:	ffffe097          	auipc	ra,0xffffe
    800057b0:	4a6080e7          	jalr	1190(ra) # 80003c52 <ialloc>
    800057b4:	8a2a                	mv	s4,a0
    800057b6:	c529                	beqz	a0,80005800 <create+0xee>
  ilock(ip);
    800057b8:	ffffe097          	auipc	ra,0xffffe
    800057bc:	632080e7          	jalr	1586(ra) # 80003dea <ilock>
  ip->major = major;
    800057c0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057c4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057c8:	4905                	li	s2,1
    800057ca:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057ce:	8552                	mv	a0,s4
    800057d0:	ffffe097          	auipc	ra,0xffffe
    800057d4:	54e080e7          	jalr	1358(ra) # 80003d1e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057d8:	032b0b63          	beq	s6,s2,8000580e <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800057dc:	004a2603          	lw	a2,4(s4)
    800057e0:	fb040593          	addi	a1,s0,-80
    800057e4:	8526                	mv	a0,s1
    800057e6:	fffff097          	auipc	ra,0xfffff
    800057ea:	cf8080e7          	jalr	-776(ra) # 800044de <dirlink>
    800057ee:	06054f63          	bltz	a0,8000586c <create+0x15a>
  iunlockput(dp);
    800057f2:	8526                	mv	a0,s1
    800057f4:	fffff097          	auipc	ra,0xfffff
    800057f8:	858080e7          	jalr	-1960(ra) # 8000404c <iunlockput>
  return ip;
    800057fc:	8ad2                	mv	s5,s4
    800057fe:	b759                	j	80005784 <create+0x72>
    iunlockput(dp);
    80005800:	8526                	mv	a0,s1
    80005802:	fffff097          	auipc	ra,0xfffff
    80005806:	84a080e7          	jalr	-1974(ra) # 8000404c <iunlockput>
    return 0;
    8000580a:	8ad2                	mv	s5,s4
    8000580c:	bfa5                	j	80005784 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000580e:	004a2603          	lw	a2,4(s4)
    80005812:	00003597          	auipc	a1,0x3
    80005816:	06e58593          	addi	a1,a1,110 # 80008880 <syscalls+0x2e0>
    8000581a:	8552                	mv	a0,s4
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	cc2080e7          	jalr	-830(ra) # 800044de <dirlink>
    80005824:	04054463          	bltz	a0,8000586c <create+0x15a>
    80005828:	40d0                	lw	a2,4(s1)
    8000582a:	00003597          	auipc	a1,0x3
    8000582e:	05e58593          	addi	a1,a1,94 # 80008888 <syscalls+0x2e8>
    80005832:	8552                	mv	a0,s4
    80005834:	fffff097          	auipc	ra,0xfffff
    80005838:	caa080e7          	jalr	-854(ra) # 800044de <dirlink>
    8000583c:	02054863          	bltz	a0,8000586c <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005840:	004a2603          	lw	a2,4(s4)
    80005844:	fb040593          	addi	a1,s0,-80
    80005848:	8526                	mv	a0,s1
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	c94080e7          	jalr	-876(ra) # 800044de <dirlink>
    80005852:	00054d63          	bltz	a0,8000586c <create+0x15a>
    dp->nlink++;  // for ".."
    80005856:	04a4d783          	lhu	a5,74(s1)
    8000585a:	2785                	addiw	a5,a5,1
    8000585c:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005860:	8526                	mv	a0,s1
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	4bc080e7          	jalr	1212(ra) # 80003d1e <iupdate>
    8000586a:	b761                	j	800057f2 <create+0xe0>
  ip->nlink = 0;
    8000586c:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005870:	8552                	mv	a0,s4
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	4ac080e7          	jalr	1196(ra) # 80003d1e <iupdate>
  iunlockput(ip);
    8000587a:	8552                	mv	a0,s4
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	7d0080e7          	jalr	2000(ra) # 8000404c <iunlockput>
  iunlockput(dp);
    80005884:	8526                	mv	a0,s1
    80005886:	ffffe097          	auipc	ra,0xffffe
    8000588a:	7c6080e7          	jalr	1990(ra) # 8000404c <iunlockput>
  return 0;
    8000588e:	bddd                	j	80005784 <create+0x72>
    return 0;
    80005890:	8aaa                	mv	s5,a0
    80005892:	bdcd                	j	80005784 <create+0x72>

0000000080005894 <sys_dup>:
{
    80005894:	7179                	addi	sp,sp,-48
    80005896:	f406                	sd	ra,40(sp)
    80005898:	f022                	sd	s0,32(sp)
    8000589a:	ec26                	sd	s1,24(sp)
    8000589c:	e84a                	sd	s2,16(sp)
    8000589e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058a0:	fd840613          	addi	a2,s0,-40
    800058a4:	4581                	li	a1,0
    800058a6:	4501                	li	a0,0
    800058a8:	00000097          	auipc	ra,0x0
    800058ac:	dc8080e7          	jalr	-568(ra) # 80005670 <argfd>
    return -1;
    800058b0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058b2:	02054363          	bltz	a0,800058d8 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800058b6:	fd843903          	ld	s2,-40(s0)
    800058ba:	854a                	mv	a0,s2
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	e14080e7          	jalr	-492(ra) # 800056d0 <fdalloc>
    800058c4:	84aa                	mv	s1,a0
    return -1;
    800058c6:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058c8:	00054863          	bltz	a0,800058d8 <sys_dup+0x44>
  filedup(f);
    800058cc:	854a                	mv	a0,s2
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	334080e7          	jalr	820(ra) # 80004c02 <filedup>
  return fd;
    800058d6:	87a6                	mv	a5,s1
}
    800058d8:	853e                	mv	a0,a5
    800058da:	70a2                	ld	ra,40(sp)
    800058dc:	7402                	ld	s0,32(sp)
    800058de:	64e2                	ld	s1,24(sp)
    800058e0:	6942                	ld	s2,16(sp)
    800058e2:	6145                	addi	sp,sp,48
    800058e4:	8082                	ret

00000000800058e6 <sys_read>:
{
    800058e6:	7179                	addi	sp,sp,-48
    800058e8:	f406                	sd	ra,40(sp)
    800058ea:	f022                	sd	s0,32(sp)
    800058ec:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058ee:	fd840593          	addi	a1,s0,-40
    800058f2:	4505                	li	a0,1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	84a080e7          	jalr	-1974(ra) # 8000313e <argaddr>
  argint(2, &n);
    800058fc:	fe440593          	addi	a1,s0,-28
    80005900:	4509                	li	a0,2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	81c080e7          	jalr	-2020(ra) # 8000311e <argint>
  if(argfd(0, 0, &f) < 0)
    8000590a:	fe840613          	addi	a2,s0,-24
    8000590e:	4581                	li	a1,0
    80005910:	4501                	li	a0,0
    80005912:	00000097          	auipc	ra,0x0
    80005916:	d5e080e7          	jalr	-674(ra) # 80005670 <argfd>
    8000591a:	87aa                	mv	a5,a0
    return -1;
    8000591c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000591e:	0007cc63          	bltz	a5,80005936 <sys_read+0x50>
  return fileread(f, p, n);
    80005922:	fe442603          	lw	a2,-28(s0)
    80005926:	fd843583          	ld	a1,-40(s0)
    8000592a:	fe843503          	ld	a0,-24(s0)
    8000592e:	fffff097          	auipc	ra,0xfffff
    80005932:	460080e7          	jalr	1120(ra) # 80004d8e <fileread>
}
    80005936:	70a2                	ld	ra,40(sp)
    80005938:	7402                	ld	s0,32(sp)
    8000593a:	6145                	addi	sp,sp,48
    8000593c:	8082                	ret

000000008000593e <sys_write>:
{
    8000593e:	7179                	addi	sp,sp,-48
    80005940:	f406                	sd	ra,40(sp)
    80005942:	f022                	sd	s0,32(sp)
    80005944:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005946:	fd840593          	addi	a1,s0,-40
    8000594a:	4505                	li	a0,1
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	7f2080e7          	jalr	2034(ra) # 8000313e <argaddr>
  argint(2, &n);
    80005954:	fe440593          	addi	a1,s0,-28
    80005958:	4509                	li	a0,2
    8000595a:	ffffd097          	auipc	ra,0xffffd
    8000595e:	7c4080e7          	jalr	1988(ra) # 8000311e <argint>
  if(argfd(0, 0, &f) < 0)
    80005962:	fe840613          	addi	a2,s0,-24
    80005966:	4581                	li	a1,0
    80005968:	4501                	li	a0,0
    8000596a:	00000097          	auipc	ra,0x0
    8000596e:	d06080e7          	jalr	-762(ra) # 80005670 <argfd>
    80005972:	87aa                	mv	a5,a0
    return -1;
    80005974:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005976:	0007cc63          	bltz	a5,8000598e <sys_write+0x50>
  return filewrite(f, p, n);
    8000597a:	fe442603          	lw	a2,-28(s0)
    8000597e:	fd843583          	ld	a1,-40(s0)
    80005982:	fe843503          	ld	a0,-24(s0)
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	4ca080e7          	jalr	1226(ra) # 80004e50 <filewrite>
}
    8000598e:	70a2                	ld	ra,40(sp)
    80005990:	7402                	ld	s0,32(sp)
    80005992:	6145                	addi	sp,sp,48
    80005994:	8082                	ret

0000000080005996 <sys_close>:
{
    80005996:	1101                	addi	sp,sp,-32
    80005998:	ec06                	sd	ra,24(sp)
    8000599a:	e822                	sd	s0,16(sp)
    8000599c:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000599e:	fe040613          	addi	a2,s0,-32
    800059a2:	fec40593          	addi	a1,s0,-20
    800059a6:	4501                	li	a0,0
    800059a8:	00000097          	auipc	ra,0x0
    800059ac:	cc8080e7          	jalr	-824(ra) # 80005670 <argfd>
    return -1;
    800059b0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059b2:	02054463          	bltz	a0,800059da <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059b6:	ffffc097          	auipc	ra,0xffffc
    800059ba:	3f6080e7          	jalr	1014(ra) # 80001dac <myproc>
    800059be:	fec42783          	lw	a5,-20(s0)
    800059c2:	07e9                	addi	a5,a5,26
    800059c4:	078e                	slli	a5,a5,0x3
    800059c6:	953e                	add	a0,a0,a5
    800059c8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800059cc:	fe043503          	ld	a0,-32(s0)
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	284080e7          	jalr	644(ra) # 80004c54 <fileclose>
  return 0;
    800059d8:	4781                	li	a5,0
}
    800059da:	853e                	mv	a0,a5
    800059dc:	60e2                	ld	ra,24(sp)
    800059de:	6442                	ld	s0,16(sp)
    800059e0:	6105                	addi	sp,sp,32
    800059e2:	8082                	ret

00000000800059e4 <sys_fstat>:
{
    800059e4:	1101                	addi	sp,sp,-32
    800059e6:	ec06                	sd	ra,24(sp)
    800059e8:	e822                	sd	s0,16(sp)
    800059ea:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059ec:	fe040593          	addi	a1,s0,-32
    800059f0:	4505                	li	a0,1
    800059f2:	ffffd097          	auipc	ra,0xffffd
    800059f6:	74c080e7          	jalr	1868(ra) # 8000313e <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059fa:	fe840613          	addi	a2,s0,-24
    800059fe:	4581                	li	a1,0
    80005a00:	4501                	li	a0,0
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	c6e080e7          	jalr	-914(ra) # 80005670 <argfd>
    80005a0a:	87aa                	mv	a5,a0
    return -1;
    80005a0c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a0e:	0007ca63          	bltz	a5,80005a22 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a12:	fe043583          	ld	a1,-32(s0)
    80005a16:	fe843503          	ld	a0,-24(s0)
    80005a1a:	fffff097          	auipc	ra,0xfffff
    80005a1e:	302080e7          	jalr	770(ra) # 80004d1c <filestat>
}
    80005a22:	60e2                	ld	ra,24(sp)
    80005a24:	6442                	ld	s0,16(sp)
    80005a26:	6105                	addi	sp,sp,32
    80005a28:	8082                	ret

0000000080005a2a <sys_link>:
{
    80005a2a:	7169                	addi	sp,sp,-304
    80005a2c:	f606                	sd	ra,296(sp)
    80005a2e:	f222                	sd	s0,288(sp)
    80005a30:	ee26                	sd	s1,280(sp)
    80005a32:	ea4a                	sd	s2,272(sp)
    80005a34:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a36:	08000613          	li	a2,128
    80005a3a:	ed040593          	addi	a1,s0,-304
    80005a3e:	4501                	li	a0,0
    80005a40:	ffffd097          	auipc	ra,0xffffd
    80005a44:	71e080e7          	jalr	1822(ra) # 8000315e <argstr>
    return -1;
    80005a48:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a4a:	10054e63          	bltz	a0,80005b66 <sys_link+0x13c>
    80005a4e:	08000613          	li	a2,128
    80005a52:	f5040593          	addi	a1,s0,-176
    80005a56:	4505                	li	a0,1
    80005a58:	ffffd097          	auipc	ra,0xffffd
    80005a5c:	706080e7          	jalr	1798(ra) # 8000315e <argstr>
    return -1;
    80005a60:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a62:	10054263          	bltz	a0,80005b66 <sys_link+0x13c>
  begin_op();
    80005a66:	fffff097          	auipc	ra,0xfffff
    80005a6a:	d2a080e7          	jalr	-726(ra) # 80004790 <begin_op>
  if((ip = namei(old)) == 0){
    80005a6e:	ed040513          	addi	a0,s0,-304
    80005a72:	fffff097          	auipc	ra,0xfffff
    80005a76:	b1e080e7          	jalr	-1250(ra) # 80004590 <namei>
    80005a7a:	84aa                	mv	s1,a0
    80005a7c:	c551                	beqz	a0,80005b08 <sys_link+0xde>
  ilock(ip);
    80005a7e:	ffffe097          	auipc	ra,0xffffe
    80005a82:	36c080e7          	jalr	876(ra) # 80003dea <ilock>
  if(ip->type == T_DIR){
    80005a86:	04449703          	lh	a4,68(s1)
    80005a8a:	4785                	li	a5,1
    80005a8c:	08f70463          	beq	a4,a5,80005b14 <sys_link+0xea>
  ip->nlink++;
    80005a90:	04a4d783          	lhu	a5,74(s1)
    80005a94:	2785                	addiw	a5,a5,1
    80005a96:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	282080e7          	jalr	642(ra) # 80003d1e <iupdate>
  iunlock(ip);
    80005aa4:	8526                	mv	a0,s1
    80005aa6:	ffffe097          	auipc	ra,0xffffe
    80005aaa:	406080e7          	jalr	1030(ra) # 80003eac <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005aae:	fd040593          	addi	a1,s0,-48
    80005ab2:	f5040513          	addi	a0,s0,-176
    80005ab6:	fffff097          	auipc	ra,0xfffff
    80005aba:	af8080e7          	jalr	-1288(ra) # 800045ae <nameiparent>
    80005abe:	892a                	mv	s2,a0
    80005ac0:	c935                	beqz	a0,80005b34 <sys_link+0x10a>
  ilock(dp);
    80005ac2:	ffffe097          	auipc	ra,0xffffe
    80005ac6:	328080e7          	jalr	808(ra) # 80003dea <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005aca:	00092703          	lw	a4,0(s2)
    80005ace:	409c                	lw	a5,0(s1)
    80005ad0:	04f71d63          	bne	a4,a5,80005b2a <sys_link+0x100>
    80005ad4:	40d0                	lw	a2,4(s1)
    80005ad6:	fd040593          	addi	a1,s0,-48
    80005ada:	854a                	mv	a0,s2
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	a02080e7          	jalr	-1534(ra) # 800044de <dirlink>
    80005ae4:	04054363          	bltz	a0,80005b2a <sys_link+0x100>
  iunlockput(dp);
    80005ae8:	854a                	mv	a0,s2
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	562080e7          	jalr	1378(ra) # 8000404c <iunlockput>
  iput(ip);
    80005af2:	8526                	mv	a0,s1
    80005af4:	ffffe097          	auipc	ra,0xffffe
    80005af8:	4b0080e7          	jalr	1200(ra) # 80003fa4 <iput>
  end_op();
    80005afc:	fffff097          	auipc	ra,0xfffff
    80005b00:	d0e080e7          	jalr	-754(ra) # 8000480a <end_op>
  return 0;
    80005b04:	4781                	li	a5,0
    80005b06:	a085                	j	80005b66 <sys_link+0x13c>
    end_op();
    80005b08:	fffff097          	auipc	ra,0xfffff
    80005b0c:	d02080e7          	jalr	-766(ra) # 8000480a <end_op>
    return -1;
    80005b10:	57fd                	li	a5,-1
    80005b12:	a891                	j	80005b66 <sys_link+0x13c>
    iunlockput(ip);
    80005b14:	8526                	mv	a0,s1
    80005b16:	ffffe097          	auipc	ra,0xffffe
    80005b1a:	536080e7          	jalr	1334(ra) # 8000404c <iunlockput>
    end_op();
    80005b1e:	fffff097          	auipc	ra,0xfffff
    80005b22:	cec080e7          	jalr	-788(ra) # 8000480a <end_op>
    return -1;
    80005b26:	57fd                	li	a5,-1
    80005b28:	a83d                	j	80005b66 <sys_link+0x13c>
    iunlockput(dp);
    80005b2a:	854a                	mv	a0,s2
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	520080e7          	jalr	1312(ra) # 8000404c <iunlockput>
  ilock(ip);
    80005b34:	8526                	mv	a0,s1
    80005b36:	ffffe097          	auipc	ra,0xffffe
    80005b3a:	2b4080e7          	jalr	692(ra) # 80003dea <ilock>
  ip->nlink--;
    80005b3e:	04a4d783          	lhu	a5,74(s1)
    80005b42:	37fd                	addiw	a5,a5,-1
    80005b44:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b48:	8526                	mv	a0,s1
    80005b4a:	ffffe097          	auipc	ra,0xffffe
    80005b4e:	1d4080e7          	jalr	468(ra) # 80003d1e <iupdate>
  iunlockput(ip);
    80005b52:	8526                	mv	a0,s1
    80005b54:	ffffe097          	auipc	ra,0xffffe
    80005b58:	4f8080e7          	jalr	1272(ra) # 8000404c <iunlockput>
  end_op();
    80005b5c:	fffff097          	auipc	ra,0xfffff
    80005b60:	cae080e7          	jalr	-850(ra) # 8000480a <end_op>
  return -1;
    80005b64:	57fd                	li	a5,-1
}
    80005b66:	853e                	mv	a0,a5
    80005b68:	70b2                	ld	ra,296(sp)
    80005b6a:	7412                	ld	s0,288(sp)
    80005b6c:	64f2                	ld	s1,280(sp)
    80005b6e:	6952                	ld	s2,272(sp)
    80005b70:	6155                	addi	sp,sp,304
    80005b72:	8082                	ret

0000000080005b74 <sys_unlink>:
{
    80005b74:	7151                	addi	sp,sp,-240
    80005b76:	f586                	sd	ra,232(sp)
    80005b78:	f1a2                	sd	s0,224(sp)
    80005b7a:	eda6                	sd	s1,216(sp)
    80005b7c:	e9ca                	sd	s2,208(sp)
    80005b7e:	e5ce                	sd	s3,200(sp)
    80005b80:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b82:	08000613          	li	a2,128
    80005b86:	f3040593          	addi	a1,s0,-208
    80005b8a:	4501                	li	a0,0
    80005b8c:	ffffd097          	auipc	ra,0xffffd
    80005b90:	5d2080e7          	jalr	1490(ra) # 8000315e <argstr>
    80005b94:	18054163          	bltz	a0,80005d16 <sys_unlink+0x1a2>
  begin_op();
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	bf8080e7          	jalr	-1032(ra) # 80004790 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005ba0:	fb040593          	addi	a1,s0,-80
    80005ba4:	f3040513          	addi	a0,s0,-208
    80005ba8:	fffff097          	auipc	ra,0xfffff
    80005bac:	a06080e7          	jalr	-1530(ra) # 800045ae <nameiparent>
    80005bb0:	84aa                	mv	s1,a0
    80005bb2:	c979                	beqz	a0,80005c88 <sys_unlink+0x114>
  ilock(dp);
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	236080e7          	jalr	566(ra) # 80003dea <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bbc:	00003597          	auipc	a1,0x3
    80005bc0:	cc458593          	addi	a1,a1,-828 # 80008880 <syscalls+0x2e0>
    80005bc4:	fb040513          	addi	a0,s0,-80
    80005bc8:	ffffe097          	auipc	ra,0xffffe
    80005bcc:	6ec080e7          	jalr	1772(ra) # 800042b4 <namecmp>
    80005bd0:	14050a63          	beqz	a0,80005d24 <sys_unlink+0x1b0>
    80005bd4:	00003597          	auipc	a1,0x3
    80005bd8:	cb458593          	addi	a1,a1,-844 # 80008888 <syscalls+0x2e8>
    80005bdc:	fb040513          	addi	a0,s0,-80
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	6d4080e7          	jalr	1748(ra) # 800042b4 <namecmp>
    80005be8:	12050e63          	beqz	a0,80005d24 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bec:	f2c40613          	addi	a2,s0,-212
    80005bf0:	fb040593          	addi	a1,s0,-80
    80005bf4:	8526                	mv	a0,s1
    80005bf6:	ffffe097          	auipc	ra,0xffffe
    80005bfa:	6d8080e7          	jalr	1752(ra) # 800042ce <dirlookup>
    80005bfe:	892a                	mv	s2,a0
    80005c00:	12050263          	beqz	a0,80005d24 <sys_unlink+0x1b0>
  ilock(ip);
    80005c04:	ffffe097          	auipc	ra,0xffffe
    80005c08:	1e6080e7          	jalr	486(ra) # 80003dea <ilock>
  if(ip->nlink < 1)
    80005c0c:	04a91783          	lh	a5,74(s2)
    80005c10:	08f05263          	blez	a5,80005c94 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c14:	04491703          	lh	a4,68(s2)
    80005c18:	4785                	li	a5,1
    80005c1a:	08f70563          	beq	a4,a5,80005ca4 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c1e:	4641                	li	a2,16
    80005c20:	4581                	li	a1,0
    80005c22:	fc040513          	addi	a0,s0,-64
    80005c26:	ffffb097          	auipc	ra,0xffffb
    80005c2a:	2ae080e7          	jalr	686(ra) # 80000ed4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c2e:	4741                	li	a4,16
    80005c30:	f2c42683          	lw	a3,-212(s0)
    80005c34:	fc040613          	addi	a2,s0,-64
    80005c38:	4581                	li	a1,0
    80005c3a:	8526                	mv	a0,s1
    80005c3c:	ffffe097          	auipc	ra,0xffffe
    80005c40:	55a080e7          	jalr	1370(ra) # 80004196 <writei>
    80005c44:	47c1                	li	a5,16
    80005c46:	0af51563          	bne	a0,a5,80005cf0 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c4a:	04491703          	lh	a4,68(s2)
    80005c4e:	4785                	li	a5,1
    80005c50:	0af70863          	beq	a4,a5,80005d00 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c54:	8526                	mv	a0,s1
    80005c56:	ffffe097          	auipc	ra,0xffffe
    80005c5a:	3f6080e7          	jalr	1014(ra) # 8000404c <iunlockput>
  ip->nlink--;
    80005c5e:	04a95783          	lhu	a5,74(s2)
    80005c62:	37fd                	addiw	a5,a5,-1
    80005c64:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c68:	854a                	mv	a0,s2
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	0b4080e7          	jalr	180(ra) # 80003d1e <iupdate>
  iunlockput(ip);
    80005c72:	854a                	mv	a0,s2
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	3d8080e7          	jalr	984(ra) # 8000404c <iunlockput>
  end_op();
    80005c7c:	fffff097          	auipc	ra,0xfffff
    80005c80:	b8e080e7          	jalr	-1138(ra) # 8000480a <end_op>
  return 0;
    80005c84:	4501                	li	a0,0
    80005c86:	a84d                	j	80005d38 <sys_unlink+0x1c4>
    end_op();
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	b82080e7          	jalr	-1150(ra) # 8000480a <end_op>
    return -1;
    80005c90:	557d                	li	a0,-1
    80005c92:	a05d                	j	80005d38 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c94:	00003517          	auipc	a0,0x3
    80005c98:	bfc50513          	addi	a0,a0,-1028 # 80008890 <syscalls+0x2f0>
    80005c9c:	ffffb097          	auipc	ra,0xffffb
    80005ca0:	8a0080e7          	jalr	-1888(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ca4:	04c92703          	lw	a4,76(s2)
    80005ca8:	02000793          	li	a5,32
    80005cac:	f6e7f9e3          	bgeu	a5,a4,80005c1e <sys_unlink+0xaa>
    80005cb0:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cb4:	4741                	li	a4,16
    80005cb6:	86ce                	mv	a3,s3
    80005cb8:	f1840613          	addi	a2,s0,-232
    80005cbc:	4581                	li	a1,0
    80005cbe:	854a                	mv	a0,s2
    80005cc0:	ffffe097          	auipc	ra,0xffffe
    80005cc4:	3de080e7          	jalr	990(ra) # 8000409e <readi>
    80005cc8:	47c1                	li	a5,16
    80005cca:	00f51b63          	bne	a0,a5,80005ce0 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005cce:	f1845783          	lhu	a5,-232(s0)
    80005cd2:	e7a1                	bnez	a5,80005d1a <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cd4:	29c1                	addiw	s3,s3,16
    80005cd6:	04c92783          	lw	a5,76(s2)
    80005cda:	fcf9ede3          	bltu	s3,a5,80005cb4 <sys_unlink+0x140>
    80005cde:	b781                	j	80005c1e <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ce0:	00003517          	auipc	a0,0x3
    80005ce4:	bc850513          	addi	a0,a0,-1080 # 800088a8 <syscalls+0x308>
    80005ce8:	ffffb097          	auipc	ra,0xffffb
    80005cec:	854080e7          	jalr	-1964(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005cf0:	00003517          	auipc	a0,0x3
    80005cf4:	bd050513          	addi	a0,a0,-1072 # 800088c0 <syscalls+0x320>
    80005cf8:	ffffb097          	auipc	ra,0xffffb
    80005cfc:	844080e7          	jalr	-1980(ra) # 8000053c <panic>
    dp->nlink--;
    80005d00:	04a4d783          	lhu	a5,74(s1)
    80005d04:	37fd                	addiw	a5,a5,-1
    80005d06:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d0a:	8526                	mv	a0,s1
    80005d0c:	ffffe097          	auipc	ra,0xffffe
    80005d10:	012080e7          	jalr	18(ra) # 80003d1e <iupdate>
    80005d14:	b781                	j	80005c54 <sys_unlink+0xe0>
    return -1;
    80005d16:	557d                	li	a0,-1
    80005d18:	a005                	j	80005d38 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d1a:	854a                	mv	a0,s2
    80005d1c:	ffffe097          	auipc	ra,0xffffe
    80005d20:	330080e7          	jalr	816(ra) # 8000404c <iunlockput>
  iunlockput(dp);
    80005d24:	8526                	mv	a0,s1
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	326080e7          	jalr	806(ra) # 8000404c <iunlockput>
  end_op();
    80005d2e:	fffff097          	auipc	ra,0xfffff
    80005d32:	adc080e7          	jalr	-1316(ra) # 8000480a <end_op>
  return -1;
    80005d36:	557d                	li	a0,-1
}
    80005d38:	70ae                	ld	ra,232(sp)
    80005d3a:	740e                	ld	s0,224(sp)
    80005d3c:	64ee                	ld	s1,216(sp)
    80005d3e:	694e                	ld	s2,208(sp)
    80005d40:	69ae                	ld	s3,200(sp)
    80005d42:	616d                	addi	sp,sp,240
    80005d44:	8082                	ret

0000000080005d46 <sys_open>:

uint64
sys_open(void)
{
    80005d46:	7131                	addi	sp,sp,-192
    80005d48:	fd06                	sd	ra,184(sp)
    80005d4a:	f922                	sd	s0,176(sp)
    80005d4c:	f526                	sd	s1,168(sp)
    80005d4e:	f14a                	sd	s2,160(sp)
    80005d50:	ed4e                	sd	s3,152(sp)
    80005d52:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d54:	f4c40593          	addi	a1,s0,-180
    80005d58:	4505                	li	a0,1
    80005d5a:	ffffd097          	auipc	ra,0xffffd
    80005d5e:	3c4080e7          	jalr	964(ra) # 8000311e <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d62:	08000613          	li	a2,128
    80005d66:	f5040593          	addi	a1,s0,-176
    80005d6a:	4501                	li	a0,0
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	3f2080e7          	jalr	1010(ra) # 8000315e <argstr>
    80005d74:	87aa                	mv	a5,a0
    return -1;
    80005d76:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d78:	0a07c863          	bltz	a5,80005e28 <sys_open+0xe2>

  begin_op();
    80005d7c:	fffff097          	auipc	ra,0xfffff
    80005d80:	a14080e7          	jalr	-1516(ra) # 80004790 <begin_op>

  if(omode & O_CREATE){
    80005d84:	f4c42783          	lw	a5,-180(s0)
    80005d88:	2007f793          	andi	a5,a5,512
    80005d8c:	cbdd                	beqz	a5,80005e42 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005d8e:	4681                	li	a3,0
    80005d90:	4601                	li	a2,0
    80005d92:	4589                	li	a1,2
    80005d94:	f5040513          	addi	a0,s0,-176
    80005d98:	00000097          	auipc	ra,0x0
    80005d9c:	97a080e7          	jalr	-1670(ra) # 80005712 <create>
    80005da0:	84aa                	mv	s1,a0
    if(ip == 0){
    80005da2:	c951                	beqz	a0,80005e36 <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005da4:	04449703          	lh	a4,68(s1)
    80005da8:	478d                	li	a5,3
    80005daa:	00f71763          	bne	a4,a5,80005db8 <sys_open+0x72>
    80005dae:	0464d703          	lhu	a4,70(s1)
    80005db2:	47a5                	li	a5,9
    80005db4:	0ce7ec63          	bltu	a5,a4,80005e8c <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005db8:	fffff097          	auipc	ra,0xfffff
    80005dbc:	de0080e7          	jalr	-544(ra) # 80004b98 <filealloc>
    80005dc0:	892a                	mv	s2,a0
    80005dc2:	c56d                	beqz	a0,80005eac <sys_open+0x166>
    80005dc4:	00000097          	auipc	ra,0x0
    80005dc8:	90c080e7          	jalr	-1780(ra) # 800056d0 <fdalloc>
    80005dcc:	89aa                	mv	s3,a0
    80005dce:	0c054a63          	bltz	a0,80005ea2 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005dd2:	04449703          	lh	a4,68(s1)
    80005dd6:	478d                	li	a5,3
    80005dd8:	0ef70563          	beq	a4,a5,80005ec2 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005ddc:	4789                	li	a5,2
    80005dde:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005de2:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005de6:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005dea:	f4c42783          	lw	a5,-180(s0)
    80005dee:	0017c713          	xori	a4,a5,1
    80005df2:	8b05                	andi	a4,a4,1
    80005df4:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005df8:	0037f713          	andi	a4,a5,3
    80005dfc:	00e03733          	snez	a4,a4
    80005e00:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e04:	4007f793          	andi	a5,a5,1024
    80005e08:	c791                	beqz	a5,80005e14 <sys_open+0xce>
    80005e0a:	04449703          	lh	a4,68(s1)
    80005e0e:	4789                	li	a5,2
    80005e10:	0cf70063          	beq	a4,a5,80005ed0 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005e14:	8526                	mv	a0,s1
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	096080e7          	jalr	150(ra) # 80003eac <iunlock>
  end_op();
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	9ec080e7          	jalr	-1556(ra) # 8000480a <end_op>

  return fd;
    80005e26:	854e                	mv	a0,s3
}
    80005e28:	70ea                	ld	ra,184(sp)
    80005e2a:	744a                	ld	s0,176(sp)
    80005e2c:	74aa                	ld	s1,168(sp)
    80005e2e:	790a                	ld	s2,160(sp)
    80005e30:	69ea                	ld	s3,152(sp)
    80005e32:	6129                	addi	sp,sp,192
    80005e34:	8082                	ret
      end_op();
    80005e36:	fffff097          	auipc	ra,0xfffff
    80005e3a:	9d4080e7          	jalr	-1580(ra) # 8000480a <end_op>
      return -1;
    80005e3e:	557d                	li	a0,-1
    80005e40:	b7e5                	j	80005e28 <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005e42:	f5040513          	addi	a0,s0,-176
    80005e46:	ffffe097          	auipc	ra,0xffffe
    80005e4a:	74a080e7          	jalr	1866(ra) # 80004590 <namei>
    80005e4e:	84aa                	mv	s1,a0
    80005e50:	c905                	beqz	a0,80005e80 <sys_open+0x13a>
    ilock(ip);
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	f98080e7          	jalr	-104(ra) # 80003dea <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e5a:	04449703          	lh	a4,68(s1)
    80005e5e:	4785                	li	a5,1
    80005e60:	f4f712e3          	bne	a4,a5,80005da4 <sys_open+0x5e>
    80005e64:	f4c42783          	lw	a5,-180(s0)
    80005e68:	dba1                	beqz	a5,80005db8 <sys_open+0x72>
      iunlockput(ip);
    80005e6a:	8526                	mv	a0,s1
    80005e6c:	ffffe097          	auipc	ra,0xffffe
    80005e70:	1e0080e7          	jalr	480(ra) # 8000404c <iunlockput>
      end_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	996080e7          	jalr	-1642(ra) # 8000480a <end_op>
      return -1;
    80005e7c:	557d                	li	a0,-1
    80005e7e:	b76d                	j	80005e28 <sys_open+0xe2>
      end_op();
    80005e80:	fffff097          	auipc	ra,0xfffff
    80005e84:	98a080e7          	jalr	-1654(ra) # 8000480a <end_op>
      return -1;
    80005e88:	557d                	li	a0,-1
    80005e8a:	bf79                	j	80005e28 <sys_open+0xe2>
    iunlockput(ip);
    80005e8c:	8526                	mv	a0,s1
    80005e8e:	ffffe097          	auipc	ra,0xffffe
    80005e92:	1be080e7          	jalr	446(ra) # 8000404c <iunlockput>
    end_op();
    80005e96:	fffff097          	auipc	ra,0xfffff
    80005e9a:	974080e7          	jalr	-1676(ra) # 8000480a <end_op>
    return -1;
    80005e9e:	557d                	li	a0,-1
    80005ea0:	b761                	j	80005e28 <sys_open+0xe2>
      fileclose(f);
    80005ea2:	854a                	mv	a0,s2
    80005ea4:	fffff097          	auipc	ra,0xfffff
    80005ea8:	db0080e7          	jalr	-592(ra) # 80004c54 <fileclose>
    iunlockput(ip);
    80005eac:	8526                	mv	a0,s1
    80005eae:	ffffe097          	auipc	ra,0xffffe
    80005eb2:	19e080e7          	jalr	414(ra) # 8000404c <iunlockput>
    end_op();
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	954080e7          	jalr	-1708(ra) # 8000480a <end_op>
    return -1;
    80005ebe:	557d                	li	a0,-1
    80005ec0:	b7a5                	j	80005e28 <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005ec2:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005ec6:	04649783          	lh	a5,70(s1)
    80005eca:	02f91223          	sh	a5,36(s2)
    80005ece:	bf21                	j	80005de6 <sys_open+0xa0>
    itrunc(ip);
    80005ed0:	8526                	mv	a0,s1
    80005ed2:	ffffe097          	auipc	ra,0xffffe
    80005ed6:	026080e7          	jalr	38(ra) # 80003ef8 <itrunc>
    80005eda:	bf2d                	j	80005e14 <sys_open+0xce>

0000000080005edc <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005edc:	7175                	addi	sp,sp,-144
    80005ede:	e506                	sd	ra,136(sp)
    80005ee0:	e122                	sd	s0,128(sp)
    80005ee2:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	8ac080e7          	jalr	-1876(ra) # 80004790 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005eec:	08000613          	li	a2,128
    80005ef0:	f7040593          	addi	a1,s0,-144
    80005ef4:	4501                	li	a0,0
    80005ef6:	ffffd097          	auipc	ra,0xffffd
    80005efa:	268080e7          	jalr	616(ra) # 8000315e <argstr>
    80005efe:	02054963          	bltz	a0,80005f30 <sys_mkdir+0x54>
    80005f02:	4681                	li	a3,0
    80005f04:	4601                	li	a2,0
    80005f06:	4585                	li	a1,1
    80005f08:	f7040513          	addi	a0,s0,-144
    80005f0c:	00000097          	auipc	ra,0x0
    80005f10:	806080e7          	jalr	-2042(ra) # 80005712 <create>
    80005f14:	cd11                	beqz	a0,80005f30 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	136080e7          	jalr	310(ra) # 8000404c <iunlockput>
  end_op();
    80005f1e:	fffff097          	auipc	ra,0xfffff
    80005f22:	8ec080e7          	jalr	-1812(ra) # 8000480a <end_op>
  return 0;
    80005f26:	4501                	li	a0,0
}
    80005f28:	60aa                	ld	ra,136(sp)
    80005f2a:	640a                	ld	s0,128(sp)
    80005f2c:	6149                	addi	sp,sp,144
    80005f2e:	8082                	ret
    end_op();
    80005f30:	fffff097          	auipc	ra,0xfffff
    80005f34:	8da080e7          	jalr	-1830(ra) # 8000480a <end_op>
    return -1;
    80005f38:	557d                	li	a0,-1
    80005f3a:	b7fd                	j	80005f28 <sys_mkdir+0x4c>

0000000080005f3c <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f3c:	7135                	addi	sp,sp,-160
    80005f3e:	ed06                	sd	ra,152(sp)
    80005f40:	e922                	sd	s0,144(sp)
    80005f42:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	84c080e7          	jalr	-1972(ra) # 80004790 <begin_op>
  argint(1, &major);
    80005f4c:	f6c40593          	addi	a1,s0,-148
    80005f50:	4505                	li	a0,1
    80005f52:	ffffd097          	auipc	ra,0xffffd
    80005f56:	1cc080e7          	jalr	460(ra) # 8000311e <argint>
  argint(2, &minor);
    80005f5a:	f6840593          	addi	a1,s0,-152
    80005f5e:	4509                	li	a0,2
    80005f60:	ffffd097          	auipc	ra,0xffffd
    80005f64:	1be080e7          	jalr	446(ra) # 8000311e <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f68:	08000613          	li	a2,128
    80005f6c:	f7040593          	addi	a1,s0,-144
    80005f70:	4501                	li	a0,0
    80005f72:	ffffd097          	auipc	ra,0xffffd
    80005f76:	1ec080e7          	jalr	492(ra) # 8000315e <argstr>
    80005f7a:	02054b63          	bltz	a0,80005fb0 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f7e:	f6841683          	lh	a3,-152(s0)
    80005f82:	f6c41603          	lh	a2,-148(s0)
    80005f86:	458d                	li	a1,3
    80005f88:	f7040513          	addi	a0,s0,-144
    80005f8c:	fffff097          	auipc	ra,0xfffff
    80005f90:	786080e7          	jalr	1926(ra) # 80005712 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f94:	cd11                	beqz	a0,80005fb0 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f96:	ffffe097          	auipc	ra,0xffffe
    80005f9a:	0b6080e7          	jalr	182(ra) # 8000404c <iunlockput>
  end_op();
    80005f9e:	fffff097          	auipc	ra,0xfffff
    80005fa2:	86c080e7          	jalr	-1940(ra) # 8000480a <end_op>
  return 0;
    80005fa6:	4501                	li	a0,0
}
    80005fa8:	60ea                	ld	ra,152(sp)
    80005faa:	644a                	ld	s0,144(sp)
    80005fac:	610d                	addi	sp,sp,160
    80005fae:	8082                	ret
    end_op();
    80005fb0:	fffff097          	auipc	ra,0xfffff
    80005fb4:	85a080e7          	jalr	-1958(ra) # 8000480a <end_op>
    return -1;
    80005fb8:	557d                	li	a0,-1
    80005fba:	b7fd                	j	80005fa8 <sys_mknod+0x6c>

0000000080005fbc <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fbc:	7135                	addi	sp,sp,-160
    80005fbe:	ed06                	sd	ra,152(sp)
    80005fc0:	e922                	sd	s0,144(sp)
    80005fc2:	e526                	sd	s1,136(sp)
    80005fc4:	e14a                	sd	s2,128(sp)
    80005fc6:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	de4080e7          	jalr	-540(ra) # 80001dac <myproc>
    80005fd0:	892a                	mv	s2,a0
  
  begin_op();
    80005fd2:	ffffe097          	auipc	ra,0xffffe
    80005fd6:	7be080e7          	jalr	1982(ra) # 80004790 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fda:	08000613          	li	a2,128
    80005fde:	f6040593          	addi	a1,s0,-160
    80005fe2:	4501                	li	a0,0
    80005fe4:	ffffd097          	auipc	ra,0xffffd
    80005fe8:	17a080e7          	jalr	378(ra) # 8000315e <argstr>
    80005fec:	04054b63          	bltz	a0,80006042 <sys_chdir+0x86>
    80005ff0:	f6040513          	addi	a0,s0,-160
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	59c080e7          	jalr	1436(ra) # 80004590 <namei>
    80005ffc:	84aa                	mv	s1,a0
    80005ffe:	c131                	beqz	a0,80006042 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006000:	ffffe097          	auipc	ra,0xffffe
    80006004:	dea080e7          	jalr	-534(ra) # 80003dea <ilock>
  if(ip->type != T_DIR){
    80006008:	04449703          	lh	a4,68(s1)
    8000600c:	4785                	li	a5,1
    8000600e:	04f71063          	bne	a4,a5,8000604e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006012:	8526                	mv	a0,s1
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	e98080e7          	jalr	-360(ra) # 80003eac <iunlock>
  iput(p->cwd);
    8000601c:	15093503          	ld	a0,336(s2)
    80006020:	ffffe097          	auipc	ra,0xffffe
    80006024:	f84080e7          	jalr	-124(ra) # 80003fa4 <iput>
  end_op();
    80006028:	ffffe097          	auipc	ra,0xffffe
    8000602c:	7e2080e7          	jalr	2018(ra) # 8000480a <end_op>
  p->cwd = ip;
    80006030:	14993823          	sd	s1,336(s2)
  return 0;
    80006034:	4501                	li	a0,0
}
    80006036:	60ea                	ld	ra,152(sp)
    80006038:	644a                	ld	s0,144(sp)
    8000603a:	64aa                	ld	s1,136(sp)
    8000603c:	690a                	ld	s2,128(sp)
    8000603e:	610d                	addi	sp,sp,160
    80006040:	8082                	ret
    end_op();
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	7c8080e7          	jalr	1992(ra) # 8000480a <end_op>
    return -1;
    8000604a:	557d                	li	a0,-1
    8000604c:	b7ed                	j	80006036 <sys_chdir+0x7a>
    iunlockput(ip);
    8000604e:	8526                	mv	a0,s1
    80006050:	ffffe097          	auipc	ra,0xffffe
    80006054:	ffc080e7          	jalr	-4(ra) # 8000404c <iunlockput>
    end_op();
    80006058:	ffffe097          	auipc	ra,0xffffe
    8000605c:	7b2080e7          	jalr	1970(ra) # 8000480a <end_op>
    return -1;
    80006060:	557d                	li	a0,-1
    80006062:	bfd1                	j	80006036 <sys_chdir+0x7a>

0000000080006064 <sys_exec>:

uint64
sys_exec(void)
{
    80006064:	7121                	addi	sp,sp,-448
    80006066:	ff06                	sd	ra,440(sp)
    80006068:	fb22                	sd	s0,432(sp)
    8000606a:	f726                	sd	s1,424(sp)
    8000606c:	f34a                	sd	s2,416(sp)
    8000606e:	ef4e                	sd	s3,408(sp)
    80006070:	eb52                	sd	s4,400(sp)
    80006072:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006074:	e4840593          	addi	a1,s0,-440
    80006078:	4505                	li	a0,1
    8000607a:	ffffd097          	auipc	ra,0xffffd
    8000607e:	0c4080e7          	jalr	196(ra) # 8000313e <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006082:	08000613          	li	a2,128
    80006086:	f5040593          	addi	a1,s0,-176
    8000608a:	4501                	li	a0,0
    8000608c:	ffffd097          	auipc	ra,0xffffd
    80006090:	0d2080e7          	jalr	210(ra) # 8000315e <argstr>
    80006094:	87aa                	mv	a5,a0
    return -1;
    80006096:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006098:	0c07c263          	bltz	a5,8000615c <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    8000609c:	10000613          	li	a2,256
    800060a0:	4581                	li	a1,0
    800060a2:	e5040513          	addi	a0,s0,-432
    800060a6:	ffffb097          	auipc	ra,0xffffb
    800060aa:	e2e080e7          	jalr	-466(ra) # 80000ed4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060ae:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    800060b2:	89a6                	mv	s3,s1
    800060b4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060b6:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060ba:	00391513          	slli	a0,s2,0x3
    800060be:	e4040593          	addi	a1,s0,-448
    800060c2:	e4843783          	ld	a5,-440(s0)
    800060c6:	953e                	add	a0,a0,a5
    800060c8:	ffffd097          	auipc	ra,0xffffd
    800060cc:	fb8080e7          	jalr	-72(ra) # 80003080 <fetchaddr>
    800060d0:	02054a63          	bltz	a0,80006104 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800060d4:	e4043783          	ld	a5,-448(s0)
    800060d8:	c3b9                	beqz	a5,8000611e <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060da:	ffffb097          	auipc	ra,0xffffb
    800060de:	b84080e7          	jalr	-1148(ra) # 80000c5e <kalloc>
    800060e2:	85aa                	mv	a1,a0
    800060e4:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060e8:	cd11                	beqz	a0,80006104 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060ea:	6605                	lui	a2,0x1
    800060ec:	e4043503          	ld	a0,-448(s0)
    800060f0:	ffffd097          	auipc	ra,0xffffd
    800060f4:	fe2080e7          	jalr	-30(ra) # 800030d2 <fetchstr>
    800060f8:	00054663          	bltz	a0,80006104 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800060fc:	0905                	addi	s2,s2,1
    800060fe:	09a1                	addi	s3,s3,8
    80006100:	fb491de3          	bne	s2,s4,800060ba <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006104:	f5040913          	addi	s2,s0,-176
    80006108:	6088                	ld	a0,0(s1)
    8000610a:	c921                	beqz	a0,8000615a <sys_exec+0xf6>
    kfree(argv[i]);
    8000610c:	ffffb097          	auipc	ra,0xffffb
    80006110:	966080e7          	jalr	-1690(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006114:	04a1                	addi	s1,s1,8
    80006116:	ff2499e3          	bne	s1,s2,80006108 <sys_exec+0xa4>
  return -1;
    8000611a:	557d                	li	a0,-1
    8000611c:	a081                	j	8000615c <sys_exec+0xf8>
      argv[i] = 0;
    8000611e:	0009079b          	sext.w	a5,s2
    80006122:	078e                	slli	a5,a5,0x3
    80006124:	fd078793          	addi	a5,a5,-48
    80006128:	97a2                	add	a5,a5,s0
    8000612a:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    8000612e:	e5040593          	addi	a1,s0,-432
    80006132:	f5040513          	addi	a0,s0,-176
    80006136:	fffff097          	auipc	ra,0xfffff
    8000613a:	194080e7          	jalr	404(ra) # 800052ca <exec>
    8000613e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006140:	f5040993          	addi	s3,s0,-176
    80006144:	6088                	ld	a0,0(s1)
    80006146:	c901                	beqz	a0,80006156 <sys_exec+0xf2>
    kfree(argv[i]);
    80006148:	ffffb097          	auipc	ra,0xffffb
    8000614c:	92a080e7          	jalr	-1750(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006150:	04a1                	addi	s1,s1,8
    80006152:	ff3499e3          	bne	s1,s3,80006144 <sys_exec+0xe0>
  return ret;
    80006156:	854a                	mv	a0,s2
    80006158:	a011                	j	8000615c <sys_exec+0xf8>
  return -1;
    8000615a:	557d                	li	a0,-1
}
    8000615c:	70fa                	ld	ra,440(sp)
    8000615e:	745a                	ld	s0,432(sp)
    80006160:	74ba                	ld	s1,424(sp)
    80006162:	791a                	ld	s2,416(sp)
    80006164:	69fa                	ld	s3,408(sp)
    80006166:	6a5a                	ld	s4,400(sp)
    80006168:	6139                	addi	sp,sp,448
    8000616a:	8082                	ret

000000008000616c <sys_pipe>:

uint64
sys_pipe(void)
{
    8000616c:	7139                	addi	sp,sp,-64
    8000616e:	fc06                	sd	ra,56(sp)
    80006170:	f822                	sd	s0,48(sp)
    80006172:	f426                	sd	s1,40(sp)
    80006174:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006176:	ffffc097          	auipc	ra,0xffffc
    8000617a:	c36080e7          	jalr	-970(ra) # 80001dac <myproc>
    8000617e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006180:	fd840593          	addi	a1,s0,-40
    80006184:	4501                	li	a0,0
    80006186:	ffffd097          	auipc	ra,0xffffd
    8000618a:	fb8080e7          	jalr	-72(ra) # 8000313e <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    8000618e:	fc840593          	addi	a1,s0,-56
    80006192:	fd040513          	addi	a0,s0,-48
    80006196:	fffff097          	auipc	ra,0xfffff
    8000619a:	dea080e7          	jalr	-534(ra) # 80004f80 <pipealloc>
    return -1;
    8000619e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061a0:	0c054463          	bltz	a0,80006268 <sys_pipe+0xfc>
  fd0 = -1;
    800061a4:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061a8:	fd043503          	ld	a0,-48(s0)
    800061ac:	fffff097          	auipc	ra,0xfffff
    800061b0:	524080e7          	jalr	1316(ra) # 800056d0 <fdalloc>
    800061b4:	fca42223          	sw	a0,-60(s0)
    800061b8:	08054b63          	bltz	a0,8000624e <sys_pipe+0xe2>
    800061bc:	fc843503          	ld	a0,-56(s0)
    800061c0:	fffff097          	auipc	ra,0xfffff
    800061c4:	510080e7          	jalr	1296(ra) # 800056d0 <fdalloc>
    800061c8:	fca42023          	sw	a0,-64(s0)
    800061cc:	06054863          	bltz	a0,8000623c <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061d0:	4691                	li	a3,4
    800061d2:	fc440613          	addi	a2,s0,-60
    800061d6:	fd843583          	ld	a1,-40(s0)
    800061da:	68a8                	ld	a0,80(s1)
    800061dc:	ffffb097          	auipc	ra,0xffffb
    800061e0:	748080e7          	jalr	1864(ra) # 80001924 <copyout>
    800061e4:	02054063          	bltz	a0,80006204 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061e8:	4691                	li	a3,4
    800061ea:	fc040613          	addi	a2,s0,-64
    800061ee:	fd843583          	ld	a1,-40(s0)
    800061f2:	0591                	addi	a1,a1,4
    800061f4:	68a8                	ld	a0,80(s1)
    800061f6:	ffffb097          	auipc	ra,0xffffb
    800061fa:	72e080e7          	jalr	1838(ra) # 80001924 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061fe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006200:	06055463          	bgez	a0,80006268 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006204:	fc442783          	lw	a5,-60(s0)
    80006208:	07e9                	addi	a5,a5,26
    8000620a:	078e                	slli	a5,a5,0x3
    8000620c:	97a6                	add	a5,a5,s1
    8000620e:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006212:	fc042783          	lw	a5,-64(s0)
    80006216:	07e9                	addi	a5,a5,26
    80006218:	078e                	slli	a5,a5,0x3
    8000621a:	94be                	add	s1,s1,a5
    8000621c:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006220:	fd043503          	ld	a0,-48(s0)
    80006224:	fffff097          	auipc	ra,0xfffff
    80006228:	a30080e7          	jalr	-1488(ra) # 80004c54 <fileclose>
    fileclose(wf);
    8000622c:	fc843503          	ld	a0,-56(s0)
    80006230:	fffff097          	auipc	ra,0xfffff
    80006234:	a24080e7          	jalr	-1500(ra) # 80004c54 <fileclose>
    return -1;
    80006238:	57fd                	li	a5,-1
    8000623a:	a03d                	j	80006268 <sys_pipe+0xfc>
    if(fd0 >= 0)
    8000623c:	fc442783          	lw	a5,-60(s0)
    80006240:	0007c763          	bltz	a5,8000624e <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006244:	07e9                	addi	a5,a5,26
    80006246:	078e                	slli	a5,a5,0x3
    80006248:	97a6                	add	a5,a5,s1
    8000624a:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    8000624e:	fd043503          	ld	a0,-48(s0)
    80006252:	fffff097          	auipc	ra,0xfffff
    80006256:	a02080e7          	jalr	-1534(ra) # 80004c54 <fileclose>
    fileclose(wf);
    8000625a:	fc843503          	ld	a0,-56(s0)
    8000625e:	fffff097          	auipc	ra,0xfffff
    80006262:	9f6080e7          	jalr	-1546(ra) # 80004c54 <fileclose>
    return -1;
    80006266:	57fd                	li	a5,-1
}
    80006268:	853e                	mv	a0,a5
    8000626a:	70e2                	ld	ra,56(sp)
    8000626c:	7442                	ld	s0,48(sp)
    8000626e:	74a2                	ld	s1,40(sp)
    80006270:	6121                	addi	sp,sp,64
    80006272:	8082                	ret
	...

0000000080006280 <kernelvec>:
    80006280:	7111                	addi	sp,sp,-256
    80006282:	e006                	sd	ra,0(sp)
    80006284:	e40a                	sd	sp,8(sp)
    80006286:	e80e                	sd	gp,16(sp)
    80006288:	ec12                	sd	tp,24(sp)
    8000628a:	f016                	sd	t0,32(sp)
    8000628c:	f41a                	sd	t1,40(sp)
    8000628e:	f81e                	sd	t2,48(sp)
    80006290:	fc22                	sd	s0,56(sp)
    80006292:	e0a6                	sd	s1,64(sp)
    80006294:	e4aa                	sd	a0,72(sp)
    80006296:	e8ae                	sd	a1,80(sp)
    80006298:	ecb2                	sd	a2,88(sp)
    8000629a:	f0b6                	sd	a3,96(sp)
    8000629c:	f4ba                	sd	a4,104(sp)
    8000629e:	f8be                	sd	a5,112(sp)
    800062a0:	fcc2                	sd	a6,120(sp)
    800062a2:	e146                	sd	a7,128(sp)
    800062a4:	e54a                	sd	s2,136(sp)
    800062a6:	e94e                	sd	s3,144(sp)
    800062a8:	ed52                	sd	s4,152(sp)
    800062aa:	f156                	sd	s5,160(sp)
    800062ac:	f55a                	sd	s6,168(sp)
    800062ae:	f95e                	sd	s7,176(sp)
    800062b0:	fd62                	sd	s8,184(sp)
    800062b2:	e1e6                	sd	s9,192(sp)
    800062b4:	e5ea                	sd	s10,200(sp)
    800062b6:	e9ee                	sd	s11,208(sp)
    800062b8:	edf2                	sd	t3,216(sp)
    800062ba:	f1f6                	sd	t4,224(sp)
    800062bc:	f5fa                	sd	t5,232(sp)
    800062be:	f9fe                	sd	t6,240(sp)
    800062c0:	ac7fc0ef          	jal	ra,80002d86 <kerneltrap>
    800062c4:	6082                	ld	ra,0(sp)
    800062c6:	6122                	ld	sp,8(sp)
    800062c8:	61c2                	ld	gp,16(sp)
    800062ca:	7282                	ld	t0,32(sp)
    800062cc:	7322                	ld	t1,40(sp)
    800062ce:	73c2                	ld	t2,48(sp)
    800062d0:	7462                	ld	s0,56(sp)
    800062d2:	6486                	ld	s1,64(sp)
    800062d4:	6526                	ld	a0,72(sp)
    800062d6:	65c6                	ld	a1,80(sp)
    800062d8:	6666                	ld	a2,88(sp)
    800062da:	7686                	ld	a3,96(sp)
    800062dc:	7726                	ld	a4,104(sp)
    800062de:	77c6                	ld	a5,112(sp)
    800062e0:	7866                	ld	a6,120(sp)
    800062e2:	688a                	ld	a7,128(sp)
    800062e4:	692a                	ld	s2,136(sp)
    800062e6:	69ca                	ld	s3,144(sp)
    800062e8:	6a6a                	ld	s4,152(sp)
    800062ea:	7a8a                	ld	s5,160(sp)
    800062ec:	7b2a                	ld	s6,168(sp)
    800062ee:	7bca                	ld	s7,176(sp)
    800062f0:	7c6a                	ld	s8,184(sp)
    800062f2:	6c8e                	ld	s9,192(sp)
    800062f4:	6d2e                	ld	s10,200(sp)
    800062f6:	6dce                	ld	s11,208(sp)
    800062f8:	6e6e                	ld	t3,216(sp)
    800062fa:	7e8e                	ld	t4,224(sp)
    800062fc:	7f2e                	ld	t5,232(sp)
    800062fe:	7fce                	ld	t6,240(sp)
    80006300:	6111                	addi	sp,sp,256
    80006302:	10200073          	sret
    80006306:	00000013          	nop
    8000630a:	00000013          	nop
    8000630e:	0001                	nop

0000000080006310 <timervec>:
    80006310:	34051573          	csrrw	a0,mscratch,a0
    80006314:	e10c                	sd	a1,0(a0)
    80006316:	e510                	sd	a2,8(a0)
    80006318:	e914                	sd	a3,16(a0)
    8000631a:	6d0c                	ld	a1,24(a0)
    8000631c:	7110                	ld	a2,32(a0)
    8000631e:	6194                	ld	a3,0(a1)
    80006320:	96b2                	add	a3,a3,a2
    80006322:	e194                	sd	a3,0(a1)
    80006324:	4589                	li	a1,2
    80006326:	14459073          	csrw	sip,a1
    8000632a:	6914                	ld	a3,16(a0)
    8000632c:	6510                	ld	a2,8(a0)
    8000632e:	610c                	ld	a1,0(a0)
    80006330:	34051573          	csrrw	a0,mscratch,a0
    80006334:	30200073          	mret
	...

000000008000633a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000633a:	1141                	addi	sp,sp,-16
    8000633c:	e422                	sd	s0,8(sp)
    8000633e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006340:	0c0007b7          	lui	a5,0xc000
    80006344:	4705                	li	a4,1
    80006346:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006348:	c3d8                	sw	a4,4(a5)
}
    8000634a:	6422                	ld	s0,8(sp)
    8000634c:	0141                	addi	sp,sp,16
    8000634e:	8082                	ret

0000000080006350 <plicinithart>:

void
plicinithart(void)
{
    80006350:	1141                	addi	sp,sp,-16
    80006352:	e406                	sd	ra,8(sp)
    80006354:	e022                	sd	s0,0(sp)
    80006356:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006358:	ffffc097          	auipc	ra,0xffffc
    8000635c:	a28080e7          	jalr	-1496(ra) # 80001d80 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006360:	0085171b          	slliw	a4,a0,0x8
    80006364:	0c0027b7          	lui	a5,0xc002
    80006368:	97ba                	add	a5,a5,a4
    8000636a:	40200713          	li	a4,1026
    8000636e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006372:	00d5151b          	slliw	a0,a0,0xd
    80006376:	0c2017b7          	lui	a5,0xc201
    8000637a:	97aa                	add	a5,a5,a0
    8000637c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006380:	60a2                	ld	ra,8(sp)
    80006382:	6402                	ld	s0,0(sp)
    80006384:	0141                	addi	sp,sp,16
    80006386:	8082                	ret

0000000080006388 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006388:	1141                	addi	sp,sp,-16
    8000638a:	e406                	sd	ra,8(sp)
    8000638c:	e022                	sd	s0,0(sp)
    8000638e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006390:	ffffc097          	auipc	ra,0xffffc
    80006394:	9f0080e7          	jalr	-1552(ra) # 80001d80 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006398:	00d5151b          	slliw	a0,a0,0xd
    8000639c:	0c2017b7          	lui	a5,0xc201
    800063a0:	97aa                	add	a5,a5,a0
  return irq;
}
    800063a2:	43c8                	lw	a0,4(a5)
    800063a4:	60a2                	ld	ra,8(sp)
    800063a6:	6402                	ld	s0,0(sp)
    800063a8:	0141                	addi	sp,sp,16
    800063aa:	8082                	ret

00000000800063ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063ac:	1101                	addi	sp,sp,-32
    800063ae:	ec06                	sd	ra,24(sp)
    800063b0:	e822                	sd	s0,16(sp)
    800063b2:	e426                	sd	s1,8(sp)
    800063b4:	1000                	addi	s0,sp,32
    800063b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063b8:	ffffc097          	auipc	ra,0xffffc
    800063bc:	9c8080e7          	jalr	-1592(ra) # 80001d80 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063c0:	00d5151b          	slliw	a0,a0,0xd
    800063c4:	0c2017b7          	lui	a5,0xc201
    800063c8:	97aa                	add	a5,a5,a0
    800063ca:	c3c4                	sw	s1,4(a5)
}
    800063cc:	60e2                	ld	ra,24(sp)
    800063ce:	6442                	ld	s0,16(sp)
    800063d0:	64a2                	ld	s1,8(sp)
    800063d2:	6105                	addi	sp,sp,32
    800063d4:	8082                	ret

00000000800063d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063d6:	1141                	addi	sp,sp,-16
    800063d8:	e406                	sd	ra,8(sp)
    800063da:	e022                	sd	s0,0(sp)
    800063dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063de:	479d                	li	a5,7
    800063e0:	04a7cc63          	blt	a5,a0,80006438 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063e4:	0023c797          	auipc	a5,0x23c
    800063e8:	9ec78793          	addi	a5,a5,-1556 # 80241dd0 <disk>
    800063ec:	97aa                	add	a5,a5,a0
    800063ee:	0187c783          	lbu	a5,24(a5)
    800063f2:	ebb9                	bnez	a5,80006448 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063f4:	00451693          	slli	a3,a0,0x4
    800063f8:	0023c797          	auipc	a5,0x23c
    800063fc:	9d878793          	addi	a5,a5,-1576 # 80241dd0 <disk>
    80006400:	6398                	ld	a4,0(a5)
    80006402:	9736                	add	a4,a4,a3
    80006404:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006408:	6398                	ld	a4,0(a5)
    8000640a:	9736                	add	a4,a4,a3
    8000640c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006410:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006414:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006418:	97aa                	add	a5,a5,a0
    8000641a:	4705                	li	a4,1
    8000641c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006420:	0023c517          	auipc	a0,0x23c
    80006424:	9c850513          	addi	a0,a0,-1592 # 80241de8 <disk+0x18>
    80006428:	ffffc097          	auipc	ra,0xffffc
    8000642c:	150080e7          	jalr	336(ra) # 80002578 <wakeup>
}
    80006430:	60a2                	ld	ra,8(sp)
    80006432:	6402                	ld	s0,0(sp)
    80006434:	0141                	addi	sp,sp,16
    80006436:	8082                	ret
    panic("free_desc 1");
    80006438:	00002517          	auipc	a0,0x2
    8000643c:	49850513          	addi	a0,a0,1176 # 800088d0 <syscalls+0x330>
    80006440:	ffffa097          	auipc	ra,0xffffa
    80006444:	0fc080e7          	jalr	252(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006448:	00002517          	auipc	a0,0x2
    8000644c:	49850513          	addi	a0,a0,1176 # 800088e0 <syscalls+0x340>
    80006450:	ffffa097          	auipc	ra,0xffffa
    80006454:	0ec080e7          	jalr	236(ra) # 8000053c <panic>

0000000080006458 <virtio_disk_init>:
{
    80006458:	1101                	addi	sp,sp,-32
    8000645a:	ec06                	sd	ra,24(sp)
    8000645c:	e822                	sd	s0,16(sp)
    8000645e:	e426                	sd	s1,8(sp)
    80006460:	e04a                	sd	s2,0(sp)
    80006462:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006464:	00002597          	auipc	a1,0x2
    80006468:	48c58593          	addi	a1,a1,1164 # 800088f0 <syscalls+0x350>
    8000646c:	0023c517          	auipc	a0,0x23c
    80006470:	a8c50513          	addi	a0,a0,-1396 # 80241ef8 <disk+0x128>
    80006474:	ffffb097          	auipc	ra,0xffffb
    80006478:	8d4080e7          	jalr	-1836(ra) # 80000d48 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000647c:	100017b7          	lui	a5,0x10001
    80006480:	4398                	lw	a4,0(a5)
    80006482:	2701                	sext.w	a4,a4
    80006484:	747277b7          	lui	a5,0x74727
    80006488:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000648c:	14f71b63          	bne	a4,a5,800065e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006490:	100017b7          	lui	a5,0x10001
    80006494:	43dc                	lw	a5,4(a5)
    80006496:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006498:	4709                	li	a4,2
    8000649a:	14e79463          	bne	a5,a4,800065e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000649e:	100017b7          	lui	a5,0x10001
    800064a2:	479c                	lw	a5,8(a5)
    800064a4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064a6:	12e79e63          	bne	a5,a4,800065e2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064aa:	100017b7          	lui	a5,0x10001
    800064ae:	47d8                	lw	a4,12(a5)
    800064b0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064b2:	554d47b7          	lui	a5,0x554d4
    800064b6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064ba:	12f71463          	bne	a4,a5,800065e2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064be:	100017b7          	lui	a5,0x10001
    800064c2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064c6:	4705                	li	a4,1
    800064c8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ca:	470d                	li	a4,3
    800064cc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064ce:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064d0:	c7ffe6b7          	lui	a3,0xc7ffe
    800064d4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc84f>
    800064d8:	8f75                	and	a4,a4,a3
    800064da:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064dc:	472d                	li	a4,11
    800064de:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064e0:	5bbc                	lw	a5,112(a5)
    800064e2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064e6:	8ba1                	andi	a5,a5,8
    800064e8:	10078563          	beqz	a5,800065f2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064ec:	100017b7          	lui	a5,0x10001
    800064f0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064f4:	43fc                	lw	a5,68(a5)
    800064f6:	2781                	sext.w	a5,a5
    800064f8:	10079563          	bnez	a5,80006602 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064fc:	100017b7          	lui	a5,0x10001
    80006500:	5bdc                	lw	a5,52(a5)
    80006502:	2781                	sext.w	a5,a5
  if(max == 0)
    80006504:	10078763          	beqz	a5,80006612 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006508:	471d                	li	a4,7
    8000650a:	10f77c63          	bgeu	a4,a5,80006622 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000650e:	ffffa097          	auipc	ra,0xffffa
    80006512:	750080e7          	jalr	1872(ra) # 80000c5e <kalloc>
    80006516:	0023c497          	auipc	s1,0x23c
    8000651a:	8ba48493          	addi	s1,s1,-1862 # 80241dd0 <disk>
    8000651e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006520:	ffffa097          	auipc	ra,0xffffa
    80006524:	73e080e7          	jalr	1854(ra) # 80000c5e <kalloc>
    80006528:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000652a:	ffffa097          	auipc	ra,0xffffa
    8000652e:	734080e7          	jalr	1844(ra) # 80000c5e <kalloc>
    80006532:	87aa                	mv	a5,a0
    80006534:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006536:	6088                	ld	a0,0(s1)
    80006538:	cd6d                	beqz	a0,80006632 <virtio_disk_init+0x1da>
    8000653a:	0023c717          	auipc	a4,0x23c
    8000653e:	89e73703          	ld	a4,-1890(a4) # 80241dd8 <disk+0x8>
    80006542:	cb65                	beqz	a4,80006632 <virtio_disk_init+0x1da>
    80006544:	c7fd                	beqz	a5,80006632 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006546:	6605                	lui	a2,0x1
    80006548:	4581                	li	a1,0
    8000654a:	ffffb097          	auipc	ra,0xffffb
    8000654e:	98a080e7          	jalr	-1654(ra) # 80000ed4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006552:	0023c497          	auipc	s1,0x23c
    80006556:	87e48493          	addi	s1,s1,-1922 # 80241dd0 <disk>
    8000655a:	6605                	lui	a2,0x1
    8000655c:	4581                	li	a1,0
    8000655e:	6488                	ld	a0,8(s1)
    80006560:	ffffb097          	auipc	ra,0xffffb
    80006564:	974080e7          	jalr	-1676(ra) # 80000ed4 <memset>
  memset(disk.used, 0, PGSIZE);
    80006568:	6605                	lui	a2,0x1
    8000656a:	4581                	li	a1,0
    8000656c:	6888                	ld	a0,16(s1)
    8000656e:	ffffb097          	auipc	ra,0xffffb
    80006572:	966080e7          	jalr	-1690(ra) # 80000ed4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006576:	100017b7          	lui	a5,0x10001
    8000657a:	4721                	li	a4,8
    8000657c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000657e:	4098                	lw	a4,0(s1)
    80006580:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006584:	40d8                	lw	a4,4(s1)
    80006586:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000658a:	6498                	ld	a4,8(s1)
    8000658c:	0007069b          	sext.w	a3,a4
    80006590:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006594:	9701                	srai	a4,a4,0x20
    80006596:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000659a:	6898                	ld	a4,16(s1)
    8000659c:	0007069b          	sext.w	a3,a4
    800065a0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065a4:	9701                	srai	a4,a4,0x20
    800065a6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800065aa:	4705                	li	a4,1
    800065ac:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800065ae:	00e48c23          	sb	a4,24(s1)
    800065b2:	00e48ca3          	sb	a4,25(s1)
    800065b6:	00e48d23          	sb	a4,26(s1)
    800065ba:	00e48da3          	sb	a4,27(s1)
    800065be:	00e48e23          	sb	a4,28(s1)
    800065c2:	00e48ea3          	sb	a4,29(s1)
    800065c6:	00e48f23          	sb	a4,30(s1)
    800065ca:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065ce:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065d2:	0727a823          	sw	s2,112(a5)
}
    800065d6:	60e2                	ld	ra,24(sp)
    800065d8:	6442                	ld	s0,16(sp)
    800065da:	64a2                	ld	s1,8(sp)
    800065dc:	6902                	ld	s2,0(sp)
    800065de:	6105                	addi	sp,sp,32
    800065e0:	8082                	ret
    panic("could not find virtio disk");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	31e50513          	addi	a0,a0,798 # 80008900 <syscalls+0x360>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f52080e7          	jalr	-174(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	32e50513          	addi	a0,a0,814 # 80008920 <syscalls+0x380>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f42080e7          	jalr	-190(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    80006602:	00002517          	auipc	a0,0x2
    80006606:	33e50513          	addi	a0,a0,830 # 80008940 <syscalls+0x3a0>
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	f32080e7          	jalr	-206(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    80006612:	00002517          	auipc	a0,0x2
    80006616:	34e50513          	addi	a0,a0,846 # 80008960 <syscalls+0x3c0>
    8000661a:	ffffa097          	auipc	ra,0xffffa
    8000661e:	f22080e7          	jalr	-222(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    80006622:	00002517          	auipc	a0,0x2
    80006626:	35e50513          	addi	a0,a0,862 # 80008980 <syscalls+0x3e0>
    8000662a:	ffffa097          	auipc	ra,0xffffa
    8000662e:	f12080e7          	jalr	-238(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006632:	00002517          	auipc	a0,0x2
    80006636:	36e50513          	addi	a0,a0,878 # 800089a0 <syscalls+0x400>
    8000663a:	ffffa097          	auipc	ra,0xffffa
    8000663e:	f02080e7          	jalr	-254(ra) # 8000053c <panic>

0000000080006642 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006642:	7159                	addi	sp,sp,-112
    80006644:	f486                	sd	ra,104(sp)
    80006646:	f0a2                	sd	s0,96(sp)
    80006648:	eca6                	sd	s1,88(sp)
    8000664a:	e8ca                	sd	s2,80(sp)
    8000664c:	e4ce                	sd	s3,72(sp)
    8000664e:	e0d2                	sd	s4,64(sp)
    80006650:	fc56                	sd	s5,56(sp)
    80006652:	f85a                	sd	s6,48(sp)
    80006654:	f45e                	sd	s7,40(sp)
    80006656:	f062                	sd	s8,32(sp)
    80006658:	ec66                	sd	s9,24(sp)
    8000665a:	e86a                	sd	s10,16(sp)
    8000665c:	1880                	addi	s0,sp,112
    8000665e:	8a2a                	mv	s4,a0
    80006660:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006662:	00c52c83          	lw	s9,12(a0)
    80006666:	001c9c9b          	slliw	s9,s9,0x1
    8000666a:	1c82                	slli	s9,s9,0x20
    8000666c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006670:	0023c517          	auipc	a0,0x23c
    80006674:	88850513          	addi	a0,a0,-1912 # 80241ef8 <disk+0x128>
    80006678:	ffffa097          	auipc	ra,0xffffa
    8000667c:	760080e7          	jalr	1888(ra) # 80000dd8 <acquire>
  for(int i = 0; i < 3; i++){
    80006680:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006682:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006684:	0023bb17          	auipc	s6,0x23b
    80006688:	74cb0b13          	addi	s6,s6,1868 # 80241dd0 <disk>
  for(int i = 0; i < 3; i++){
    8000668c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000668e:	0023cc17          	auipc	s8,0x23c
    80006692:	86ac0c13          	addi	s8,s8,-1942 # 80241ef8 <disk+0x128>
    80006696:	a095                	j	800066fa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006698:	00fb0733          	add	a4,s6,a5
    8000669c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800066a0:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    800066a2:	0207c563          	bltz	a5,800066cc <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    800066a6:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    800066a8:	0591                	addi	a1,a1,4
    800066aa:	05560d63          	beq	a2,s5,80006704 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066ae:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    800066b0:	0023b717          	auipc	a4,0x23b
    800066b4:	72070713          	addi	a4,a4,1824 # 80241dd0 <disk>
    800066b8:	87ca                	mv	a5,s2
    if(disk.free[i]){
    800066ba:	01874683          	lbu	a3,24(a4)
    800066be:	fee9                	bnez	a3,80006698 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    800066c0:	2785                	addiw	a5,a5,1
    800066c2:	0705                	addi	a4,a4,1
    800066c4:	fe979be3          	bne	a5,s1,800066ba <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    800066c8:	57fd                	li	a5,-1
    800066ca:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    800066cc:	00c05e63          	blez	a2,800066e8 <virtio_disk_rw+0xa6>
    800066d0:	060a                	slli	a2,a2,0x2
    800066d2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800066d6:	0009a503          	lw	a0,0(s3)
    800066da:	00000097          	auipc	ra,0x0
    800066de:	cfc080e7          	jalr	-772(ra) # 800063d6 <free_desc>
      for(int j = 0; j < i; j++)
    800066e2:	0991                	addi	s3,s3,4
    800066e4:	ffa999e3          	bne	s3,s10,800066d6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066e8:	85e2                	mv	a1,s8
    800066ea:	0023b517          	auipc	a0,0x23b
    800066ee:	6fe50513          	addi	a0,a0,1790 # 80241de8 <disk+0x18>
    800066f2:	ffffc097          	auipc	ra,0xffffc
    800066f6:	e22080e7          	jalr	-478(ra) # 80002514 <sleep>
  for(int i = 0; i < 3; i++){
    800066fa:	f9040993          	addi	s3,s0,-112
{
    800066fe:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    80006700:	864a                	mv	a2,s2
    80006702:	b775                	j	800066ae <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006704:	f9042503          	lw	a0,-112(s0)
    80006708:	00a50713          	addi	a4,a0,10
    8000670c:	0712                	slli	a4,a4,0x4

  if(write)
    8000670e:	0023b797          	auipc	a5,0x23b
    80006712:	6c278793          	addi	a5,a5,1730 # 80241dd0 <disk>
    80006716:	00e786b3          	add	a3,a5,a4
    8000671a:	01703633          	snez	a2,s7
    8000671e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006720:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006724:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006728:	f6070613          	addi	a2,a4,-160
    8000672c:	6394                	ld	a3,0(a5)
    8000672e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006730:	00870593          	addi	a1,a4,8
    80006734:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006736:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006738:	0007b803          	ld	a6,0(a5)
    8000673c:	9642                	add	a2,a2,a6
    8000673e:	46c1                	li	a3,16
    80006740:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006742:	4585                	li	a1,1
    80006744:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006748:	f9442683          	lw	a3,-108(s0)
    8000674c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006750:	0692                	slli	a3,a3,0x4
    80006752:	9836                	add	a6,a6,a3
    80006754:	058a0613          	addi	a2,s4,88
    80006758:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000675c:	0007b803          	ld	a6,0(a5)
    80006760:	96c2                	add	a3,a3,a6
    80006762:	40000613          	li	a2,1024
    80006766:	c690                	sw	a2,8(a3)
  if(write)
    80006768:	001bb613          	seqz	a2,s7
    8000676c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006770:	00166613          	ori	a2,a2,1
    80006774:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006778:	f9842603          	lw	a2,-104(s0)
    8000677c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006780:	00250693          	addi	a3,a0,2
    80006784:	0692                	slli	a3,a3,0x4
    80006786:	96be                	add	a3,a3,a5
    80006788:	58fd                	li	a7,-1
    8000678a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000678e:	0612                	slli	a2,a2,0x4
    80006790:	9832                	add	a6,a6,a2
    80006792:	f9070713          	addi	a4,a4,-112
    80006796:	973e                	add	a4,a4,a5
    80006798:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000679c:	6398                	ld	a4,0(a5)
    8000679e:	9732                	add	a4,a4,a2
    800067a0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067a2:	4609                	li	a2,2
    800067a4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800067a8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067ac:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    800067b0:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067b4:	6794                	ld	a3,8(a5)
    800067b6:	0026d703          	lhu	a4,2(a3)
    800067ba:	8b1d                	andi	a4,a4,7
    800067bc:	0706                	slli	a4,a4,0x1
    800067be:	96ba                	add	a3,a3,a4
    800067c0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800067c4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067c8:	6798                	ld	a4,8(a5)
    800067ca:	00275783          	lhu	a5,2(a4)
    800067ce:	2785                	addiw	a5,a5,1
    800067d0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067d4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067d8:	100017b7          	lui	a5,0x10001
    800067dc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067e0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800067e4:	0023b917          	auipc	s2,0x23b
    800067e8:	71490913          	addi	s2,s2,1812 # 80241ef8 <disk+0x128>
  while(b->disk == 1) {
    800067ec:	4485                	li	s1,1
    800067ee:	00b79c63          	bne	a5,a1,80006806 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067f2:	85ca                	mv	a1,s2
    800067f4:	8552                	mv	a0,s4
    800067f6:	ffffc097          	auipc	ra,0xffffc
    800067fa:	d1e080e7          	jalr	-738(ra) # 80002514 <sleep>
  while(b->disk == 1) {
    800067fe:	004a2783          	lw	a5,4(s4)
    80006802:	fe9788e3          	beq	a5,s1,800067f2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006806:	f9042903          	lw	s2,-112(s0)
    8000680a:	00290713          	addi	a4,s2,2
    8000680e:	0712                	slli	a4,a4,0x4
    80006810:	0023b797          	auipc	a5,0x23b
    80006814:	5c078793          	addi	a5,a5,1472 # 80241dd0 <disk>
    80006818:	97ba                	add	a5,a5,a4
    8000681a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000681e:	0023b997          	auipc	s3,0x23b
    80006822:	5b298993          	addi	s3,s3,1458 # 80241dd0 <disk>
    80006826:	00491713          	slli	a4,s2,0x4
    8000682a:	0009b783          	ld	a5,0(s3)
    8000682e:	97ba                	add	a5,a5,a4
    80006830:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006834:	854a                	mv	a0,s2
    80006836:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000683a:	00000097          	auipc	ra,0x0
    8000683e:	b9c080e7          	jalr	-1124(ra) # 800063d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006842:	8885                	andi	s1,s1,1
    80006844:	f0ed                	bnez	s1,80006826 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006846:	0023b517          	auipc	a0,0x23b
    8000684a:	6b250513          	addi	a0,a0,1714 # 80241ef8 <disk+0x128>
    8000684e:	ffffa097          	auipc	ra,0xffffa
    80006852:	63e080e7          	jalr	1598(ra) # 80000e8c <release>
}
    80006856:	70a6                	ld	ra,104(sp)
    80006858:	7406                	ld	s0,96(sp)
    8000685a:	64e6                	ld	s1,88(sp)
    8000685c:	6946                	ld	s2,80(sp)
    8000685e:	69a6                	ld	s3,72(sp)
    80006860:	6a06                	ld	s4,64(sp)
    80006862:	7ae2                	ld	s5,56(sp)
    80006864:	7b42                	ld	s6,48(sp)
    80006866:	7ba2                	ld	s7,40(sp)
    80006868:	7c02                	ld	s8,32(sp)
    8000686a:	6ce2                	ld	s9,24(sp)
    8000686c:	6d42                	ld	s10,16(sp)
    8000686e:	6165                	addi	sp,sp,112
    80006870:	8082                	ret

0000000080006872 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006872:	1101                	addi	sp,sp,-32
    80006874:	ec06                	sd	ra,24(sp)
    80006876:	e822                	sd	s0,16(sp)
    80006878:	e426                	sd	s1,8(sp)
    8000687a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000687c:	0023b497          	auipc	s1,0x23b
    80006880:	55448493          	addi	s1,s1,1364 # 80241dd0 <disk>
    80006884:	0023b517          	auipc	a0,0x23b
    80006888:	67450513          	addi	a0,a0,1652 # 80241ef8 <disk+0x128>
    8000688c:	ffffa097          	auipc	ra,0xffffa
    80006890:	54c080e7          	jalr	1356(ra) # 80000dd8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006894:	10001737          	lui	a4,0x10001
    80006898:	533c                	lw	a5,96(a4)
    8000689a:	8b8d                	andi	a5,a5,3
    8000689c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000689e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068a2:	689c                	ld	a5,16(s1)
    800068a4:	0204d703          	lhu	a4,32(s1)
    800068a8:	0027d783          	lhu	a5,2(a5)
    800068ac:	04f70863          	beq	a4,a5,800068fc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068b0:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068b4:	6898                	ld	a4,16(s1)
    800068b6:	0204d783          	lhu	a5,32(s1)
    800068ba:	8b9d                	andi	a5,a5,7
    800068bc:	078e                	slli	a5,a5,0x3
    800068be:	97ba                	add	a5,a5,a4
    800068c0:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068c2:	00278713          	addi	a4,a5,2
    800068c6:	0712                	slli	a4,a4,0x4
    800068c8:	9726                	add	a4,a4,s1
    800068ca:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068ce:	e721                	bnez	a4,80006916 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068d0:	0789                	addi	a5,a5,2
    800068d2:	0792                	slli	a5,a5,0x4
    800068d4:	97a6                	add	a5,a5,s1
    800068d6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068d8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068dc:	ffffc097          	auipc	ra,0xffffc
    800068e0:	c9c080e7          	jalr	-868(ra) # 80002578 <wakeup>

    disk.used_idx += 1;
    800068e4:	0204d783          	lhu	a5,32(s1)
    800068e8:	2785                	addiw	a5,a5,1
    800068ea:	17c2                	slli	a5,a5,0x30
    800068ec:	93c1                	srli	a5,a5,0x30
    800068ee:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068f2:	6898                	ld	a4,16(s1)
    800068f4:	00275703          	lhu	a4,2(a4)
    800068f8:	faf71ce3          	bne	a4,a5,800068b0 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068fc:	0023b517          	auipc	a0,0x23b
    80006900:	5fc50513          	addi	a0,a0,1532 # 80241ef8 <disk+0x128>
    80006904:	ffffa097          	auipc	ra,0xffffa
    80006908:	588080e7          	jalr	1416(ra) # 80000e8c <release>
}
    8000690c:	60e2                	ld	ra,24(sp)
    8000690e:	6442                	ld	s0,16(sp)
    80006910:	64a2                	ld	s1,8(sp)
    80006912:	6105                	addi	sp,sp,32
    80006914:	8082                	ret
      panic("virtio_disk_intr status");
    80006916:	00002517          	auipc	a0,0x2
    8000691a:	0a250513          	addi	a0,a0,162 # 800089b8 <syscalls+0x418>
    8000691e:	ffffa097          	auipc	ra,0xffffa
    80006922:	c1e080e7          	jalr	-994(ra) # 8000053c <panic>
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
