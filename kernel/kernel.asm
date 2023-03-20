
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	c5010113          	addi	sp,sp,-944 # 80008c50 <stack0>
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
    80000054:	ac070713          	addi	a4,a4,-1344 # 80008b10 <timer_scratch>
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
    80000066:	27e78793          	addi	a5,a5,638 # 800062e0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdbc87f>
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
    80000188:	acc50513          	addi	a0,a0,-1332 # 80010c50 <cons>
    8000018c:	00001097          	auipc	ra,0x1
    80000190:	c4c080e7          	jalr	-948(ra) # 80000dd8 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    80000194:	00011497          	auipc	s1,0x11
    80000198:	abc48493          	addi	s1,s1,-1348 # 80010c50 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    8000019c:	00011917          	auipc	s2,0x11
    800001a0:	b4c90913          	addi	s2,s2,-1204 # 80010ce8 <cons+0x98>
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
    800001e2:	a7270713          	addi	a4,a4,-1422 # 80010c50 <cons>
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
    8000022c:	a2850513          	addi	a0,a0,-1496 # 80010c50 <cons>
    80000230:	00001097          	auipc	ra,0x1
    80000234:	c5c080e7          	jalr	-932(ra) # 80000e8c <release>

    return target - n;
    80000238:	413b053b          	subw	a0,s6,s3
    8000023c:	a811                	j	80000250 <consoleread+0xec>
                release(&cons.lock);
    8000023e:	00011517          	auipc	a0,0x11
    80000242:	a1250513          	addi	a0,a0,-1518 # 80010c50 <cons>
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
    80000272:	a6f72d23          	sw	a5,-1414(a4) # 80010ce8 <cons+0x98>
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
    800002cc:	98850513          	addi	a0,a0,-1656 # 80010c50 <cons>
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
    800002fa:	95a50513          	addi	a0,a0,-1702 # 80010c50 <cons>
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
    8000031e:	93670713          	addi	a4,a4,-1738 # 80010c50 <cons>
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
    80000348:	90c78793          	addi	a5,a5,-1780 # 80010c50 <cons>
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
    80000376:	9767a783          	lw	a5,-1674(a5) # 80010ce8 <cons+0x98>
    8000037a:	9f1d                	subw	a4,a4,a5
    8000037c:	08000793          	li	a5,128
    80000380:	f6f71be3          	bne	a4,a5,800002f6 <consoleintr+0x3c>
    80000384:	a07d                	j	80000432 <consoleintr+0x178>
        while (cons.e != cons.w &&
    80000386:	00011717          	auipc	a4,0x11
    8000038a:	8ca70713          	addi	a4,a4,-1846 # 80010c50 <cons>
    8000038e:	0a072783          	lw	a5,160(a4)
    80000392:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    80000396:	00011497          	auipc	s1,0x11
    8000039a:	8ba48493          	addi	s1,s1,-1862 # 80010c50 <cons>
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
    800003d6:	87e70713          	addi	a4,a4,-1922 # 80010c50 <cons>
    800003da:	0a072783          	lw	a5,160(a4)
    800003de:	09c72703          	lw	a4,156(a4)
    800003e2:	f0f70ae3          	beq	a4,a5,800002f6 <consoleintr+0x3c>
            cons.e--;
    800003e6:	37fd                	addiw	a5,a5,-1
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	90f72423          	sw	a5,-1784(a4) # 80010cf0 <cons+0xa0>
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
    80000412:	84278793          	addi	a5,a5,-1982 # 80010c50 <cons>
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
    80000436:	8ac7ad23          	sw	a2,-1862(a5) # 80010cec <cons+0x9c>
                wakeup(&cons.r);
    8000043a:	00011517          	auipc	a0,0x11
    8000043e:	8ae50513          	addi	a0,a0,-1874 # 80010ce8 <cons+0x98>
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
    80000460:	7f450513          	addi	a0,a0,2036 # 80010c50 <cons>
    80000464:	00001097          	auipc	ra,0x1
    80000468:	8e4080e7          	jalr	-1820(ra) # 80000d48 <initlock>

    uartinit();
    8000046c:	00000097          	auipc	ra,0x0
    80000470:	33e080e7          	jalr	830(ra) # 800007aa <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000474:	00241797          	auipc	a5,0x241
    80000478:	97478793          	addi	a5,a5,-1676 # 80240de8 <devsw>
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
    8000055e:	7a07ab23          	sw	zero,1974(a5) # 80010d10 <pr+0x18>
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
    80000592:	52f72923          	sw	a5,1330(a4) # 80008ac0 <panicked>
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
    800005ce:	746dad83          	lw	s11,1862(s11) # 80010d10 <pr+0x18>
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
    8000060c:	6f050513          	addi	a0,a0,1776 # 80010cf8 <pr>
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
    8000076a:	59250513          	addi	a0,a0,1426 # 80010cf8 <pr>
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
    80000786:	57648493          	addi	s1,s1,1398 # 80010cf8 <pr>
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
    800007e6:	53650513          	addi	a0,a0,1334 # 80010d18 <uart_tx_lock>
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
    80000812:	2b27a783          	lw	a5,690(a5) # 80008ac0 <panicked>
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
    8000084a:	2827b783          	ld	a5,642(a5) # 80008ac8 <uart_tx_r>
    8000084e:	00008717          	auipc	a4,0x8
    80000852:	28273703          	ld	a4,642(a4) # 80008ad0 <uart_tx_w>
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
    80000874:	4a8a0a13          	addi	s4,s4,1192 # 80010d18 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	25048493          	addi	s1,s1,592 # 80008ac8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	25098993          	addi	s3,s3,592 # 80008ad0 <uart_tx_w>
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
    800008e2:	43a50513          	addi	a0,a0,1082 # 80010d18 <uart_tx_lock>
    800008e6:	00000097          	auipc	ra,0x0
    800008ea:	4f2080e7          	jalr	1266(ra) # 80000dd8 <acquire>
  if(panicked){
    800008ee:	00008797          	auipc	a5,0x8
    800008f2:	1d27a783          	lw	a5,466(a5) # 80008ac0 <panicked>
    800008f6:	e7c9                	bnez	a5,80000980 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008717          	auipc	a4,0x8
    800008fc:	1d873703          	ld	a4,472(a4) # 80008ad0 <uart_tx_w>
    80000900:	00008797          	auipc	a5,0x8
    80000904:	1c87b783          	ld	a5,456(a5) # 80008ac8 <uart_tx_r>
    80000908:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    8000090c:	00010997          	auipc	s3,0x10
    80000910:	40c98993          	addi	s3,s3,1036 # 80010d18 <uart_tx_lock>
    80000914:	00008497          	auipc	s1,0x8
    80000918:	1b448493          	addi	s1,s1,436 # 80008ac8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000091c:	00008917          	auipc	s2,0x8
    80000920:	1b490913          	addi	s2,s2,436 # 80008ad0 <uart_tx_w>
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
    80000946:	3d648493          	addi	s1,s1,982 # 80010d18 <uart_tx_lock>
    8000094a:	01f77793          	andi	a5,a4,31
    8000094e:	97a6                	add	a5,a5,s1
    80000950:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000954:	0705                	addi	a4,a4,1
    80000956:	00008797          	auipc	a5,0x8
    8000095a:	16e7bd23          	sd	a4,378(a5) # 80008ad0 <uart_tx_w>
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
    800009cc:	35048493          	addi	s1,s1,848 # 80010d18 <uart_tx_lock>
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
    80000a0c:	34850513          	addi	a0,a0,840 # 80010d50 <kmem>
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	3c8080e7          	jalr	968(ra) # 80000dd8 <acquire>
    if (pa >= PHYSTOP || reference_count[pn] < 1) {
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f97363          	bgeu	s2,a5,80000a62 <increment_refcount+0x6c>
    80000a20:	2481                	sext.w	s1,s1
    80000a22:	00249713          	slli	a4,s1,0x2
    80000a26:	00010797          	auipc	a5,0x10
    80000a2a:	34a78793          	addi	a5,a5,842 # 80010d70 <reference_count>
    80000a2e:	97ba                	add	a5,a5,a4
    80000a30:	439c                	lw	a5,0(a5)
    80000a32:	02f05863          	blez	a5,80000a62 <increment_refcount+0x6c>
        panic("increment_refcount");
    }
    reference_count[pn]++;
    80000a36:	048a                	slli	s1,s1,0x2
    80000a38:	00010717          	auipc	a4,0x10
    80000a3c:	33870713          	addi	a4,a4,824 # 80010d70 <reference_count>
    80000a40:	9726                	add	a4,a4,s1
    80000a42:	2785                	addiw	a5,a5,1
    80000a44:	c31c                	sw	a5,0(a4)
    release(&kmem.lock);
    80000a46:	00010517          	auipc	a0,0x10
    80000a4a:	30a50513          	addi	a0,a0,778 # 80010d50 <kmem>
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
    80000a84:	0607b783          	ld	a5,96(a5) # 80008ae0 <MAX_PAGES>
    80000a88:	c799                	beqz	a5,80000a96 <kfree+0x24>
        assert(FREE_PAGES < MAX_PAGES);
    80000a8a:	00008717          	auipc	a4,0x8
    80000a8e:	04e73703          	ld	a4,78(a4) # 80008ad8 <FREE_PAGES>
    80000a92:	06f77e63          	bgeu	a4,a5,80000b0e <kfree+0x9c>
    struct run *r;

    if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP) {
    80000a96:	03449793          	slli	a5,s1,0x34
    80000a9a:	e7c5                	bnez	a5,80000b42 <kfree+0xd0>
    80000a9c:	00241797          	auipc	a5,0x241
    80000aa0:	4e478793          	addi	a5,a5,1252 # 80241f80 <end>
    80000aa4:	08f4ef63          	bltu	s1,a5,80000b42 <kfree+0xd0>
    80000aa8:	47c5                	li	a5,17
    80000aaa:	07ee                	slli	a5,a5,0x1b
    80000aac:	08f4fb63          	bgeu	s1,a5,80000b42 <kfree+0xd0>
        panic("kfree");
    }

    acquire(&kmem.lock);
    80000ab0:	00010517          	auipc	a0,0x10
    80000ab4:	2a050513          	addi	a0,a0,672 # 80010d50 <kmem>
    80000ab8:	00000097          	auipc	ra,0x0
    80000abc:	320080e7          	jalr	800(ra) # 80000dd8 <acquire>
    int pn = (uint64) pa / PGSIZE;
    80000ac0:	00c4d793          	srli	a5,s1,0xc
    80000ac4:	2781                	sext.w	a5,a5
    if (reference_count[pn] < 1) {
    80000ac6:	00279693          	slli	a3,a5,0x2
    80000aca:	00010717          	auipc	a4,0x10
    80000ace:	2a670713          	addi	a4,a4,678 # 80010d70 <reference_count>
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
    80000ae6:	28e68693          	addi	a3,a3,654 # 80010d70 <reference_count>
    80000aea:	97b6                	add	a5,a5,a3
    80000aec:	c398                	sw	a4,0(a5)
    int temp = reference_count[pn];
    release(&kmem.lock);
    80000aee:	00010517          	auipc	a0,0x10
    80000af2:	26250513          	addi	a0,a0,610 # 80010d50 <kmem>
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
    80000b74:	1e090913          	addi	s2,s2,480 # 80010d50 <kmem>
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
    80000b90:	f4c70713          	addi	a4,a4,-180 # 80008ad8 <FREE_PAGES>
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
    80000bd4:	1a0b0b13          	addi	s6,s6,416 # 80010d70 <reference_count>
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
    80000c26:	12e50513          	addi	a0,a0,302 # 80010d50 <kmem>
    80000c2a:	00000097          	auipc	ra,0x0
    80000c2e:	11e080e7          	jalr	286(ra) # 80000d48 <initlock>
    freerange(end, (void *)PHYSTOP);
    80000c32:	45c5                	li	a1,17
    80000c34:	05ee                	slli	a1,a1,0x1b
    80000c36:	00241517          	auipc	a0,0x241
    80000c3a:	34a50513          	addi	a0,a0,842 # 80241f80 <end>
    80000c3e:	00000097          	auipc	ra,0x0
    80000c42:	f68080e7          	jalr	-152(ra) # 80000ba6 <freerange>
    MAX_PAGES = FREE_PAGES;
    80000c46:	00008797          	auipc	a5,0x8
    80000c4a:	e927b783          	ld	a5,-366(a5) # 80008ad8 <FREE_PAGES>
    80000c4e:	00008717          	auipc	a4,0x8
    80000c52:	e8f73923          	sd	a5,-366(a4) # 80008ae0 <MAX_PAGES>
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
    80000c6c:	e707b783          	ld	a5,-400(a5) # 80008ad8 <FREE_PAGES>
    80000c70:	c3c9                	beqz	a5,80000cf2 <kalloc+0x94>
    struct run *r;

    acquire(&kmem.lock);
    80000c72:	00010497          	auipc	s1,0x10
    80000c76:	0de48493          	addi	s1,s1,222 # 80010d50 <kmem>
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
    80000c8e:	0cf73f23          	sd	a5,222(a4) # 80010d68 <kmem+0x18>
        int pn = (uint64) r / PGSIZE;
    80000c92:	00c4d793          	srli	a5,s1,0xc
    80000c96:	2781                	sext.w	a5,a5
        // Check that refcount is not 0
        if (reference_count[pn] != 0) {
    80000c98:	00279693          	slli	a3,a5,0x2
    80000c9c:	00010717          	auipc	a4,0x10
    80000ca0:	0d470713          	addi	a4,a4,212 # 80010d70 <reference_count>
    80000ca4:	9736                	add	a4,a4,a3
    80000ca6:	4318                	lw	a4,0(a4)
    80000ca8:	ef3d                	bnez	a4,80000d26 <kalloc+0xc8>
            panic("kalloc");
        }
        reference_count[pn] = 1;
    80000caa:	078a                	slli	a5,a5,0x2
    80000cac:	00010717          	auipc	a4,0x10
    80000cb0:	0c470713          	addi	a4,a4,196 # 80010d70 <reference_count>
    80000cb4:	97ba                	add	a5,a5,a4
    80000cb6:	4705                	li	a4,1
    80000cb8:	c398                	sw	a4,0(a5)
    } 
    release(&kmem.lock);
    80000cba:	00010517          	auipc	a0,0x10
    80000cbe:	09650513          	addi	a0,a0,150 # 80010d50 <kmem>
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
    80000cdc:	e0070713          	addi	a4,a4,-512 # 80008ad8 <FREE_PAGES>
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
    80000d3a:	01a50513          	addi	a0,a0,26 # 80010d50 <kmem>
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
    8000108c:	a6070713          	addi	a4,a4,-1440 # 80008ae8 <started>
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
    800010ca:	25a080e7          	jalr	602(ra) # 80006320 <plicinithart>
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
    8000114a:	1c4080e7          	jalr	452(ra) # 8000630a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000114e:	00005097          	auipc	ra,0x5
    80001152:	1d2080e7          	jalr	466(ra) # 80006320 <plicinithart>
    binit();         // buffer cache
    80001156:	00002097          	auipc	ra,0x2
    8000115a:	3ca080e7          	jalr	970(ra) # 80003520 <binit>
    iinit();         // inode table
    8000115e:	00003097          	auipc	ra,0x3
    80001162:	a68080e7          	jalr	-1432(ra) # 80003bc6 <iinit>
    fileinit();      // file table
    80001166:	00004097          	auipc	ra,0x4
    8000116a:	9de080e7          	jalr	-1570(ra) # 80004b44 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000116e:	00005097          	auipc	ra,0x5
    80001172:	2ba080e7          	jalr	698(ra) # 80006428 <virtio_disk_init>
    userinit();      // first user process
    80001176:	00001097          	auipc	ra,0x1
    8000117a:	ece080e7          	jalr	-306(ra) # 80002044 <userinit>
    __sync_synchronize();
    8000117e:	0ff0000f          	fence
    started = 1;
    80001182:	4785                	li	a5,1
    80001184:	00008717          	auipc	a4,0x8
    80001188:	96f72223          	sw	a5,-1692(a4) # 80008ae8 <started>
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
    8000119c:	9587b783          	ld	a5,-1704(a5) # 80008af0 <kernel_pagetable>
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
    80001458:	68a7be23          	sd	a0,1692(a5) # 80008af0 <kernel_pagetable>
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
    80001ad6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7fdbd080>
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
    80001b22:	252a8a93          	addi	s5,s5,594 # 80230d70 <cpus>
    80001b26:	00779713          	slli	a4,a5,0x7
    80001b2a:	00ea86b3          	add	a3,s5,a4
    80001b2e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7fdbd080>
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
    80001b3c:	f10c0c13          	addi	s8,s8,-240 # 80008a48 <sched_pointer>
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
    80001b58:	64c48493          	addi	s1,s1,1612 # 802311a0 <proc>
            if (p->state == RUNNABLE)
    80001b5c:	498d                	li	s3,3
                p->state = RUNNING;
    80001b5e:	4b11                	li	s6,4
        for (p = proc; p < &proc[NPROC]; p++)
    80001b60:	00235a17          	auipc	s4,0x235
    80001b64:	040a0a13          	addi	s4,s4,64 # 80236ba0 <tickslock>
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
    80001bec:	5b848493          	addi	s1,s1,1464 # 802311a0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001bf0:	8b26                	mv	s6,s1
    80001bf2:	00006a97          	auipc	s5,0x6
    80001bf6:	41ea8a93          	addi	s5,s5,1054 # 80008010 <__func__.1+0x8>
    80001bfa:	04000937          	lui	s2,0x4000
    80001bfe:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001c00:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001c02:	00235a17          	auipc	s4,0x235
    80001c06:	f9ea0a13          	addi	s4,s4,-98 # 80236ba0 <tickslock>
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
    80001c88:	4ec50513          	addi	a0,a0,1260 # 80231170 <pid_lock>
    80001c8c:	fffff097          	auipc	ra,0xfffff
    80001c90:	0bc080e7          	jalr	188(ra) # 80000d48 <initlock>
    initlock(&wait_lock, "wait_lock");
    80001c94:	00006597          	auipc	a1,0x6
    80001c98:	5ac58593          	addi	a1,a1,1452 # 80008240 <digits+0x1f0>
    80001c9c:	0022f517          	auipc	a0,0x22f
    80001ca0:	4ec50513          	addi	a0,a0,1260 # 80231188 <wait_lock>
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	0a4080e7          	jalr	164(ra) # 80000d48 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    80001cac:	0022f497          	auipc	s1,0x22f
    80001cb0:	4f448493          	addi	s1,s1,1268 # 802311a0 <proc>
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
    80001cd2:	ed298993          	addi	s3,s3,-302 # 80236ba0 <tickslock>
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
    80001d60:	01450513          	addi	a0,a0,20 # 80230d70 <cpus>
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
    80001d88:	fec70713          	addi	a4,a4,-20 # 80230d70 <cpus>
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
    80001dc0:	c847a783          	lw	a5,-892(a5) # 80008a40 <first.1>
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
    80001dda:	c607a523          	sw	zero,-918(a5) # 80008a40 <first.1>
        fsinit(ROOTDEV);
    80001dde:	4505                	li	a0,1
    80001de0:	00002097          	auipc	ra,0x2
    80001de4:	d66080e7          	jalr	-666(ra) # 80003b46 <fsinit>
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
    80001dfa:	37a90913          	addi	s2,s2,890 # 80231170 <pid_lock>
    80001dfe:	854a                	mv	a0,s2
    80001e00:	fffff097          	auipc	ra,0xfffff
    80001e04:	fd8080e7          	jalr	-40(ra) # 80000dd8 <acquire>
    pid = nextpid;
    80001e08:	00007797          	auipc	a5,0x7
    80001e0c:	c4878793          	addi	a5,a5,-952 # 80008a50 <nextpid>
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
    80001f86:	21e48493          	addi	s1,s1,542 # 802311a0 <proc>
    80001f8a:	00235917          	auipc	s2,0x235
    80001f8e:	c1690913          	addi	s2,s2,-1002 # 80236ba0 <tickslock>
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
    8000205c:	aaa7b023          	sd	a0,-1376(a5) # 80008af8 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80002060:	03400613          	li	a2,52
    80002064:	00007597          	auipc	a1,0x7
    80002068:	9fc58593          	addi	a1,a1,-1540 # 80008a60 <initcode>
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
    800020a6:	4c2080e7          	jalr	1218(ra) # 80004564 <namei>
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
    80002188:	01c78793          	addi	a5,a5,28 # 802311a0 <proc>
    8000218c:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    8000218e:	00235797          	auipc	a5,0x235
    80002192:	a1278793          	addi	a5,a5,-1518 # 80236ba0 <tickslock>
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
    80002326:	8b4080e7          	jalr	-1868(ra) # 80004bd6 <filedup>
    8000232a:	00a93023          	sd	a0,0(s2)
    8000232e:	b7e5                	j	80002316 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002330:	150ab503          	ld	a0,336(s5)
    80002334:	00002097          	auipc	ra,0x2
    80002338:	a4c080e7          	jalr	-1460(ra) # 80003d80 <idup>
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
    80002364:	e2848493          	addi	s1,s1,-472 # 80231188 <wait_lock>
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
    800023c0:	68c48493          	addi	s1,s1,1676 # 80008a48 <sched_pointer>
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
    800023f6:	97e70713          	addi	a4,a4,-1666 # 80230d70 <cpus>
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
    8000241a:	95a90913          	addi	s2,s2,-1702 # 80230d70 <cpus>
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
    80002550:	c5448493          	addi	s1,s1,-940 # 802311a0 <proc>
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
    8000255c:	64890913          	addi	s2,s2,1608 # 80236ba0 <tickslock>
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
    800025c4:	be048493          	addi	s1,s1,-1056 # 802311a0 <proc>
            pp->parent = initproc;
    800025c8:	00006a17          	auipc	s4,0x6
    800025cc:	530a0a13          	addi	s4,s4,1328 # 80008af8 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800025d0:	00234997          	auipc	s3,0x234
    800025d4:	5d098993          	addi	s3,s3,1488 # 80236ba0 <tickslock>
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
    80002628:	4d47b783          	ld	a5,1236(a5) # 80008af8 <initproc>
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
    8000264c:	5e0080e7          	jalr	1504(ra) # 80004c28 <fileclose>
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
    80002664:	104080e7          	jalr	260(ra) # 80004764 <begin_op>
    iput(p->cwd);
    80002668:	1509b503          	ld	a0,336(s3)
    8000266c:	00002097          	auipc	ra,0x2
    80002670:	90c080e7          	jalr	-1780(ra) # 80003f78 <iput>
    end_op();
    80002674:	00002097          	auipc	ra,0x2
    80002678:	16a080e7          	jalr	362(ra) # 800047de <end_op>
    p->cwd = 0;
    8000267c:	1409b823          	sd	zero,336(s3)
    acquire(&wait_lock);
    80002680:	0022f497          	auipc	s1,0x22f
    80002684:	b0848493          	addi	s1,s1,-1272 # 80231188 <wait_lock>
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
    800026f2:	ab248493          	addi	s1,s1,-1358 # 802311a0 <proc>
    800026f6:	00234997          	auipc	s3,0x234
    800026fa:	4aa98993          	addi	s3,s3,1194 # 80236ba0 <tickslock>
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
    800027d6:	9b650513          	addi	a0,a0,-1610 # 80231188 <wait_lock>
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
    800027ec:	3b898993          	addi	s3,s3,952 # 80236ba0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    800027f0:	0022fc17          	auipc	s8,0x22f
    800027f4:	998c0c13          	addi	s8,s8,-1640 # 80231188 <wait_lock>
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
    80002832:	95a50513          	addi	a0,a0,-1702 # 80231188 <wait_lock>
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
    80002866:	92650513          	addi	a0,a0,-1754 # 80231188 <wait_lock>
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
    800028c2:	8e248493          	addi	s1,s1,-1822 # 802311a0 <proc>
    800028c6:	bf65                	j	8000287e <wait+0xd0>
            release(&wait_lock);
    800028c8:	0022f517          	auipc	a0,0x22f
    800028cc:	8c050513          	addi	a0,a0,-1856 # 80231188 <wait_lock>
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
    800029b2:	94a48493          	addi	s1,s1,-1718 # 802312f8 <proc+0x158>
    800029b6:	00234917          	auipc	s2,0x234
    800029ba:	34290913          	addi	s2,s2,834 # 80236cf8 <bcache+0x140>
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
    80002a64:	04873703          	ld	a4,72(a4) # 80008aa8 <available_schedulers+0x10>
    80002a68:	00006797          	auipc	a5,0x6
    80002a6c:	fe07b783          	ld	a5,-32(a5) # 80008a48 <sched_pointer>
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
    80002a88:	02c62603          	lw	a2,44(a2) # 80008ab0 <available_schedulers+0x18>
    80002a8c:	00006597          	auipc	a1,0x6
    80002a90:	00c58593          	addi	a1,a1,12 # 80008a98 <available_schedulers>
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
    80002adc:	fd07b783          	ld	a5,-48(a5) # 80008aa8 <available_schedulers+0x10>
    80002ae0:	00006717          	auipc	a4,0x6
    80002ae4:	f6f73423          	sd	a5,-152(a4) # 80008a48 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002ae8:	00006597          	auipc	a1,0x6
    80002aec:	fb058593          	addi	a1,a1,-80 # 80008a98 <available_schedulers>
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
    80002b98:	00c50513          	addi	a0,a0,12 # 80236ba0 <tickslock>
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
    80002bb6:	69e78793          	addi	a5,a5,1694 # 80006250 <kernelvec>
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
    80002c68:	f3c48493          	addi	s1,s1,-196 # 80236ba0 <tickslock>
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	16a080e7          	jalr	362(ra) # 80000dd8 <acquire>
  ticks++;
    80002c76:	00006517          	auipc	a0,0x6
    80002c7a:	e8a50513          	addi	a0,a0,-374 # 80008b00 <ticks>
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
    80002cd8:	684080e7          	jalr	1668(ra) # 80006358 <plic_claim>
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
    80002d06:	67a080e7          	jalr	1658(ra) # 8000637c <plic_complete>
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
    80002d1c:	b2a080e7          	jalr	-1238(ra) # 80006842 <virtio_disk_intr>
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
    80002ed4:	38078793          	addi	a5,a5,896 # 80006250 <kernelvec>
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
    800032c0:	8e450513          	addi	a0,a0,-1820 # 80236ba0 <tickslock>
    800032c4:	ffffe097          	auipc	ra,0xffffe
    800032c8:	b14080e7          	jalr	-1260(ra) # 80000dd8 <acquire>
    ticks0 = ticks;
    800032cc:	00006917          	auipc	s2,0x6
    800032d0:	83492903          	lw	s2,-1996(s2) # 80008b00 <ticks>
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
    800032de:	8c698993          	addi	s3,s3,-1850 # 80236ba0 <tickslock>
    800032e2:	00006497          	auipc	s1,0x6
    800032e6:	81e48493          	addi	s1,s1,-2018 # 80008b00 <ticks>
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
    8000331a:	88a50513          	addi	a0,a0,-1910 # 80236ba0 <tickslock>
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
    8000333a:	86a50513          	addi	a0,a0,-1942 # 80236ba0 <tickslock>
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
    80003382:	82250513          	addi	a0,a0,-2014 # 80236ba0 <tickslock>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	a52080e7          	jalr	-1454(ra) # 80000dd8 <acquire>
    xticks = ticks;
    8000338e:	00005497          	auipc	s1,0x5
    80003392:	7724a483          	lw	s1,1906(s1) # 80008b00 <ticks>
    release(&tickslock);
    80003396:	00234517          	auipc	a0,0x234
    8000339a:	80a50513          	addi	a0,a0,-2038 # 80236ba0 <tickslock>
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
    
    argint(0, &pid);
    8000345a:	fdc40593          	addi	a1,s0,-36
    8000345e:	4501                	li	a0,0
    80003460:	00000097          	auipc	ra,0x0
    80003464:	c92080e7          	jalr	-878(ra) # 800030f2 <argint>
    argaddr(1, &va);
    80003468:	fd040593          	addi	a1,s0,-48
    8000346c:	4505                	li	a0,1
    8000346e:	00000097          	auipc	ra,0x0
    80003472:	ca4080e7          	jalr	-860(ra) # 80003112 <argaddr>

    struct proc *p;
    int pidExists = 0;

    if (pid != 0) {
    80003476:	fdc42783          	lw	a5,-36(s0)
    8000347a:	c3a5                	beqz	a5,800034da <sys_va2pa+0x94>
        for (p = proc; p < &proc[NPROC]; p++) {
    8000347c:	0022e497          	auipc	s1,0x22e
    80003480:	d2448493          	addi	s1,s1,-732 # 802311a0 <proc>
    80003484:	00233917          	auipc	s2,0x233
    80003488:	71c90913          	addi	s2,s2,1820 # 80236ba0 <tickslock>
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
        printf("No pid supplied pid\n");
    800034da:	00005517          	auipc	a0,0x5
    800034de:	20e50513          	addi	a0,a0,526 # 800086e8 <syscalls+0xd8>
    800034e2:	ffffd097          	auipc	ra,0xffffd
    800034e6:	0b6080e7          	jalr	182(ra) # 80000598 <printf>
        p = myproc();
    800034ea:	fffff097          	auipc	ra,0xfffff
    800034ee:	882080e7          	jalr	-1918(ra) # 80001d6c <myproc>
    800034f2:	84aa                	mv	s1,a0
    800034f4:	b7f1                	j	800034c0 <sys_va2pa+0x7a>

00000000800034f6 <sys_pfreepages>:

uint64 sys_pfreepages(void)
{
    800034f6:	1141                	addi	sp,sp,-16
    800034f8:	e406                	sd	ra,8(sp)
    800034fa:	e022                	sd	s0,0(sp)
    800034fc:	0800                	addi	s0,sp,16
    printf("%d\n", FREE_PAGES);
    800034fe:	00005597          	auipc	a1,0x5
    80003502:	5da5b583          	ld	a1,1498(a1) # 80008ad8 <FREE_PAGES>
    80003506:	00005517          	auipc	a0,0x5
    8000350a:	0ea50513          	addi	a0,a0,234 # 800085f0 <states.0+0x200>
    8000350e:	ffffd097          	auipc	ra,0xffffd
    80003512:	08a080e7          	jalr	138(ra) # 80000598 <printf>
    return 0;
    80003516:	4501                	li	a0,0
    80003518:	60a2                	ld	ra,8(sp)
    8000351a:	6402                	ld	s0,0(sp)
    8000351c:	0141                	addi	sp,sp,16
    8000351e:	8082                	ret

0000000080003520 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003520:	7179                	addi	sp,sp,-48
    80003522:	f406                	sd	ra,40(sp)
    80003524:	f022                	sd	s0,32(sp)
    80003526:	ec26                	sd	s1,24(sp)
    80003528:	e84a                	sd	s2,16(sp)
    8000352a:	e44e                	sd	s3,8(sp)
    8000352c:	e052                	sd	s4,0(sp)
    8000352e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003530:	00005597          	auipc	a1,0x5
    80003534:	1d058593          	addi	a1,a1,464 # 80008700 <syscalls+0xf0>
    80003538:	00233517          	auipc	a0,0x233
    8000353c:	68050513          	addi	a0,a0,1664 # 80236bb8 <bcache>
    80003540:	ffffe097          	auipc	ra,0xffffe
    80003544:	808080e7          	jalr	-2040(ra) # 80000d48 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003548:	0023b797          	auipc	a5,0x23b
    8000354c:	67078793          	addi	a5,a5,1648 # 8023ebb8 <bcache+0x8000>
    80003550:	0023c717          	auipc	a4,0x23c
    80003554:	8d070713          	addi	a4,a4,-1840 # 8023ee20 <bcache+0x8268>
    80003558:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000355c:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003560:	00233497          	auipc	s1,0x233
    80003564:	67048493          	addi	s1,s1,1648 # 80236bd0 <bcache+0x18>
    b->next = bcache.head.next;
    80003568:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    8000356a:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000356c:	00005a17          	auipc	s4,0x5
    80003570:	19ca0a13          	addi	s4,s4,412 # 80008708 <syscalls+0xf8>
    b->next = bcache.head.next;
    80003574:	2b893783          	ld	a5,696(s2)
    80003578:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    8000357a:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000357e:	85d2                	mv	a1,s4
    80003580:	01048513          	addi	a0,s1,16
    80003584:	00001097          	auipc	ra,0x1
    80003588:	496080e7          	jalr	1174(ra) # 80004a1a <initsleeplock>
    bcache.head.next->prev = b;
    8000358c:	2b893783          	ld	a5,696(s2)
    80003590:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003592:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003596:	45848493          	addi	s1,s1,1112
    8000359a:	fd349de3          	bne	s1,s3,80003574 <binit+0x54>
  }
}
    8000359e:	70a2                	ld	ra,40(sp)
    800035a0:	7402                	ld	s0,32(sp)
    800035a2:	64e2                	ld	s1,24(sp)
    800035a4:	6942                	ld	s2,16(sp)
    800035a6:	69a2                	ld	s3,8(sp)
    800035a8:	6a02                	ld	s4,0(sp)
    800035aa:	6145                	addi	sp,sp,48
    800035ac:	8082                	ret

00000000800035ae <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800035ae:	7179                	addi	sp,sp,-48
    800035b0:	f406                	sd	ra,40(sp)
    800035b2:	f022                	sd	s0,32(sp)
    800035b4:	ec26                	sd	s1,24(sp)
    800035b6:	e84a                	sd	s2,16(sp)
    800035b8:	e44e                	sd	s3,8(sp)
    800035ba:	1800                	addi	s0,sp,48
    800035bc:	892a                	mv	s2,a0
    800035be:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035c0:	00233517          	auipc	a0,0x233
    800035c4:	5f850513          	addi	a0,a0,1528 # 80236bb8 <bcache>
    800035c8:	ffffe097          	auipc	ra,0xffffe
    800035cc:	810080e7          	jalr	-2032(ra) # 80000dd8 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035d0:	0023c497          	auipc	s1,0x23c
    800035d4:	8a04b483          	ld	s1,-1888(s1) # 8023ee70 <bcache+0x82b8>
    800035d8:	0023c797          	auipc	a5,0x23c
    800035dc:	84878793          	addi	a5,a5,-1976 # 8023ee20 <bcache+0x8268>
    800035e0:	02f48f63          	beq	s1,a5,8000361e <bread+0x70>
    800035e4:	873e                	mv	a4,a5
    800035e6:	a021                	j	800035ee <bread+0x40>
    800035e8:	68a4                	ld	s1,80(s1)
    800035ea:	02e48a63          	beq	s1,a4,8000361e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035ee:	449c                	lw	a5,8(s1)
    800035f0:	ff279ce3          	bne	a5,s2,800035e8 <bread+0x3a>
    800035f4:	44dc                	lw	a5,12(s1)
    800035f6:	ff3799e3          	bne	a5,s3,800035e8 <bread+0x3a>
      b->refcnt++;
    800035fa:	40bc                	lw	a5,64(s1)
    800035fc:	2785                	addiw	a5,a5,1
    800035fe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003600:	00233517          	auipc	a0,0x233
    80003604:	5b850513          	addi	a0,a0,1464 # 80236bb8 <bcache>
    80003608:	ffffe097          	auipc	ra,0xffffe
    8000360c:	884080e7          	jalr	-1916(ra) # 80000e8c <release>
      acquiresleep(&b->lock);
    80003610:	01048513          	addi	a0,s1,16
    80003614:	00001097          	auipc	ra,0x1
    80003618:	440080e7          	jalr	1088(ra) # 80004a54 <acquiresleep>
      return b;
    8000361c:	a8b9                	j	8000367a <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000361e:	0023c497          	auipc	s1,0x23c
    80003622:	84a4b483          	ld	s1,-1974(s1) # 8023ee68 <bcache+0x82b0>
    80003626:	0023b797          	auipc	a5,0x23b
    8000362a:	7fa78793          	addi	a5,a5,2042 # 8023ee20 <bcache+0x8268>
    8000362e:	00f48863          	beq	s1,a5,8000363e <bread+0x90>
    80003632:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003634:	40bc                	lw	a5,64(s1)
    80003636:	cf81                	beqz	a5,8000364e <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003638:	64a4                	ld	s1,72(s1)
    8000363a:	fee49de3          	bne	s1,a4,80003634 <bread+0x86>
  panic("bget: no buffers");
    8000363e:	00005517          	auipc	a0,0x5
    80003642:	0d250513          	addi	a0,a0,210 # 80008710 <syscalls+0x100>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	ef6080e7          	jalr	-266(ra) # 8000053c <panic>
      b->dev = dev;
    8000364e:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003652:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003656:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000365a:	4785                	li	a5,1
    8000365c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000365e:	00233517          	auipc	a0,0x233
    80003662:	55a50513          	addi	a0,a0,1370 # 80236bb8 <bcache>
    80003666:	ffffe097          	auipc	ra,0xffffe
    8000366a:	826080e7          	jalr	-2010(ra) # 80000e8c <release>
      acquiresleep(&b->lock);
    8000366e:	01048513          	addi	a0,s1,16
    80003672:	00001097          	auipc	ra,0x1
    80003676:	3e2080e7          	jalr	994(ra) # 80004a54 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000367a:	409c                	lw	a5,0(s1)
    8000367c:	cb89                	beqz	a5,8000368e <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000367e:	8526                	mv	a0,s1
    80003680:	70a2                	ld	ra,40(sp)
    80003682:	7402                	ld	s0,32(sp)
    80003684:	64e2                	ld	s1,24(sp)
    80003686:	6942                	ld	s2,16(sp)
    80003688:	69a2                	ld	s3,8(sp)
    8000368a:	6145                	addi	sp,sp,48
    8000368c:	8082                	ret
    virtio_disk_rw(b, 0);
    8000368e:	4581                	li	a1,0
    80003690:	8526                	mv	a0,s1
    80003692:	00003097          	auipc	ra,0x3
    80003696:	f80080e7          	jalr	-128(ra) # 80006612 <virtio_disk_rw>
    b->valid = 1;
    8000369a:	4785                	li	a5,1
    8000369c:	c09c                	sw	a5,0(s1)
  return b;
    8000369e:	b7c5                	j	8000367e <bread+0xd0>

00000000800036a0 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800036a0:	1101                	addi	sp,sp,-32
    800036a2:	ec06                	sd	ra,24(sp)
    800036a4:	e822                	sd	s0,16(sp)
    800036a6:	e426                	sd	s1,8(sp)
    800036a8:	1000                	addi	s0,sp,32
    800036aa:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036ac:	0541                	addi	a0,a0,16
    800036ae:	00001097          	auipc	ra,0x1
    800036b2:	440080e7          	jalr	1088(ra) # 80004aee <holdingsleep>
    800036b6:	cd01                	beqz	a0,800036ce <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036b8:	4585                	li	a1,1
    800036ba:	8526                	mv	a0,s1
    800036bc:	00003097          	auipc	ra,0x3
    800036c0:	f56080e7          	jalr	-170(ra) # 80006612 <virtio_disk_rw>
}
    800036c4:	60e2                	ld	ra,24(sp)
    800036c6:	6442                	ld	s0,16(sp)
    800036c8:	64a2                	ld	s1,8(sp)
    800036ca:	6105                	addi	sp,sp,32
    800036cc:	8082                	ret
    panic("bwrite");
    800036ce:	00005517          	auipc	a0,0x5
    800036d2:	05a50513          	addi	a0,a0,90 # 80008728 <syscalls+0x118>
    800036d6:	ffffd097          	auipc	ra,0xffffd
    800036da:	e66080e7          	jalr	-410(ra) # 8000053c <panic>

00000000800036de <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036de:	1101                	addi	sp,sp,-32
    800036e0:	ec06                	sd	ra,24(sp)
    800036e2:	e822                	sd	s0,16(sp)
    800036e4:	e426                	sd	s1,8(sp)
    800036e6:	e04a                	sd	s2,0(sp)
    800036e8:	1000                	addi	s0,sp,32
    800036ea:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036ec:	01050913          	addi	s2,a0,16
    800036f0:	854a                	mv	a0,s2
    800036f2:	00001097          	auipc	ra,0x1
    800036f6:	3fc080e7          	jalr	1020(ra) # 80004aee <holdingsleep>
    800036fa:	c925                	beqz	a0,8000376a <brelse+0x8c>
    panic("brelse");

  releasesleep(&b->lock);
    800036fc:	854a                	mv	a0,s2
    800036fe:	00001097          	auipc	ra,0x1
    80003702:	3ac080e7          	jalr	940(ra) # 80004aaa <releasesleep>

  acquire(&bcache.lock);
    80003706:	00233517          	auipc	a0,0x233
    8000370a:	4b250513          	addi	a0,a0,1202 # 80236bb8 <bcache>
    8000370e:	ffffd097          	auipc	ra,0xffffd
    80003712:	6ca080e7          	jalr	1738(ra) # 80000dd8 <acquire>
  b->refcnt--;
    80003716:	40bc                	lw	a5,64(s1)
    80003718:	37fd                	addiw	a5,a5,-1
    8000371a:	0007871b          	sext.w	a4,a5
    8000371e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003720:	e71d                	bnez	a4,8000374e <brelse+0x70>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003722:	68b8                	ld	a4,80(s1)
    80003724:	64bc                	ld	a5,72(s1)
    80003726:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80003728:	68b8                	ld	a4,80(s1)
    8000372a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000372c:	0023b797          	auipc	a5,0x23b
    80003730:	48c78793          	addi	a5,a5,1164 # 8023ebb8 <bcache+0x8000>
    80003734:	2b87b703          	ld	a4,696(a5)
    80003738:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000373a:	0023b717          	auipc	a4,0x23b
    8000373e:	6e670713          	addi	a4,a4,1766 # 8023ee20 <bcache+0x8268>
    80003742:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003744:	2b87b703          	ld	a4,696(a5)
    80003748:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000374a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000374e:	00233517          	auipc	a0,0x233
    80003752:	46a50513          	addi	a0,a0,1130 # 80236bb8 <bcache>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	736080e7          	jalr	1846(ra) # 80000e8c <release>
}
    8000375e:	60e2                	ld	ra,24(sp)
    80003760:	6442                	ld	s0,16(sp)
    80003762:	64a2                	ld	s1,8(sp)
    80003764:	6902                	ld	s2,0(sp)
    80003766:	6105                	addi	sp,sp,32
    80003768:	8082                	ret
    panic("brelse");
    8000376a:	00005517          	auipc	a0,0x5
    8000376e:	fc650513          	addi	a0,a0,-58 # 80008730 <syscalls+0x120>
    80003772:	ffffd097          	auipc	ra,0xffffd
    80003776:	dca080e7          	jalr	-566(ra) # 8000053c <panic>

000000008000377a <bpin>:

void
bpin(struct buf *b) {
    8000377a:	1101                	addi	sp,sp,-32
    8000377c:	ec06                	sd	ra,24(sp)
    8000377e:	e822                	sd	s0,16(sp)
    80003780:	e426                	sd	s1,8(sp)
    80003782:	1000                	addi	s0,sp,32
    80003784:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003786:	00233517          	auipc	a0,0x233
    8000378a:	43250513          	addi	a0,a0,1074 # 80236bb8 <bcache>
    8000378e:	ffffd097          	auipc	ra,0xffffd
    80003792:	64a080e7          	jalr	1610(ra) # 80000dd8 <acquire>
  b->refcnt++;
    80003796:	40bc                	lw	a5,64(s1)
    80003798:	2785                	addiw	a5,a5,1
    8000379a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000379c:	00233517          	auipc	a0,0x233
    800037a0:	41c50513          	addi	a0,a0,1052 # 80236bb8 <bcache>
    800037a4:	ffffd097          	auipc	ra,0xffffd
    800037a8:	6e8080e7          	jalr	1768(ra) # 80000e8c <release>
}
    800037ac:	60e2                	ld	ra,24(sp)
    800037ae:	6442                	ld	s0,16(sp)
    800037b0:	64a2                	ld	s1,8(sp)
    800037b2:	6105                	addi	sp,sp,32
    800037b4:	8082                	ret

00000000800037b6 <bunpin>:

void
bunpin(struct buf *b) {
    800037b6:	1101                	addi	sp,sp,-32
    800037b8:	ec06                	sd	ra,24(sp)
    800037ba:	e822                	sd	s0,16(sp)
    800037bc:	e426                	sd	s1,8(sp)
    800037be:	1000                	addi	s0,sp,32
    800037c0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037c2:	00233517          	auipc	a0,0x233
    800037c6:	3f650513          	addi	a0,a0,1014 # 80236bb8 <bcache>
    800037ca:	ffffd097          	auipc	ra,0xffffd
    800037ce:	60e080e7          	jalr	1550(ra) # 80000dd8 <acquire>
  b->refcnt--;
    800037d2:	40bc                	lw	a5,64(s1)
    800037d4:	37fd                	addiw	a5,a5,-1
    800037d6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037d8:	00233517          	auipc	a0,0x233
    800037dc:	3e050513          	addi	a0,a0,992 # 80236bb8 <bcache>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	6ac080e7          	jalr	1708(ra) # 80000e8c <release>
}
    800037e8:	60e2                	ld	ra,24(sp)
    800037ea:	6442                	ld	s0,16(sp)
    800037ec:	64a2                	ld	s1,8(sp)
    800037ee:	6105                	addi	sp,sp,32
    800037f0:	8082                	ret

00000000800037f2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037f2:	1101                	addi	sp,sp,-32
    800037f4:	ec06                	sd	ra,24(sp)
    800037f6:	e822                	sd	s0,16(sp)
    800037f8:	e426                	sd	s1,8(sp)
    800037fa:	e04a                	sd	s2,0(sp)
    800037fc:	1000                	addi	s0,sp,32
    800037fe:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003800:	00d5d59b          	srliw	a1,a1,0xd
    80003804:	0023c797          	auipc	a5,0x23c
    80003808:	a907a783          	lw	a5,-1392(a5) # 8023f294 <sb+0x1c>
    8000380c:	9dbd                	addw	a1,a1,a5
    8000380e:	00000097          	auipc	ra,0x0
    80003812:	da0080e7          	jalr	-608(ra) # 800035ae <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003816:	0074f713          	andi	a4,s1,7
    8000381a:	4785                	li	a5,1
    8000381c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003820:	14ce                	slli	s1,s1,0x33
    80003822:	90d9                	srli	s1,s1,0x36
    80003824:	00950733          	add	a4,a0,s1
    80003828:	05874703          	lbu	a4,88(a4)
    8000382c:	00e7f6b3          	and	a3,a5,a4
    80003830:	c69d                	beqz	a3,8000385e <bfree+0x6c>
    80003832:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003834:	94aa                	add	s1,s1,a0
    80003836:	fff7c793          	not	a5,a5
    8000383a:	8f7d                	and	a4,a4,a5
    8000383c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003840:	00001097          	auipc	ra,0x1
    80003844:	0f6080e7          	jalr	246(ra) # 80004936 <log_write>
  brelse(bp);
    80003848:	854a                	mv	a0,s2
    8000384a:	00000097          	auipc	ra,0x0
    8000384e:	e94080e7          	jalr	-364(ra) # 800036de <brelse>
}
    80003852:	60e2                	ld	ra,24(sp)
    80003854:	6442                	ld	s0,16(sp)
    80003856:	64a2                	ld	s1,8(sp)
    80003858:	6902                	ld	s2,0(sp)
    8000385a:	6105                	addi	sp,sp,32
    8000385c:	8082                	ret
    panic("freeing free block");
    8000385e:	00005517          	auipc	a0,0x5
    80003862:	eda50513          	addi	a0,a0,-294 # 80008738 <syscalls+0x128>
    80003866:	ffffd097          	auipc	ra,0xffffd
    8000386a:	cd6080e7          	jalr	-810(ra) # 8000053c <panic>

000000008000386e <balloc>:
{
    8000386e:	711d                	addi	sp,sp,-96
    80003870:	ec86                	sd	ra,88(sp)
    80003872:	e8a2                	sd	s0,80(sp)
    80003874:	e4a6                	sd	s1,72(sp)
    80003876:	e0ca                	sd	s2,64(sp)
    80003878:	fc4e                	sd	s3,56(sp)
    8000387a:	f852                	sd	s4,48(sp)
    8000387c:	f456                	sd	s5,40(sp)
    8000387e:	f05a                	sd	s6,32(sp)
    80003880:	ec5e                	sd	s7,24(sp)
    80003882:	e862                	sd	s8,16(sp)
    80003884:	e466                	sd	s9,8(sp)
    80003886:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003888:	0023c797          	auipc	a5,0x23c
    8000388c:	9f47a783          	lw	a5,-1548(a5) # 8023f27c <sb+0x4>
    80003890:	cff5                	beqz	a5,8000398c <balloc+0x11e>
    80003892:	8baa                	mv	s7,a0
    80003894:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003896:	0023cb17          	auipc	s6,0x23c
    8000389a:	9e2b0b13          	addi	s6,s6,-1566 # 8023f278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000389e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800038a0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800038a2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800038a4:	6c89                	lui	s9,0x2
    800038a6:	a061                	j	8000392e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800038a8:	97ca                	add	a5,a5,s2
    800038aa:	8e55                	or	a2,a2,a3
    800038ac:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800038b0:	854a                	mv	a0,s2
    800038b2:	00001097          	auipc	ra,0x1
    800038b6:	084080e7          	jalr	132(ra) # 80004936 <log_write>
        brelse(bp);
    800038ba:	854a                	mv	a0,s2
    800038bc:	00000097          	auipc	ra,0x0
    800038c0:	e22080e7          	jalr	-478(ra) # 800036de <brelse>
  bp = bread(dev, bno);
    800038c4:	85a6                	mv	a1,s1
    800038c6:	855e                	mv	a0,s7
    800038c8:	00000097          	auipc	ra,0x0
    800038cc:	ce6080e7          	jalr	-794(ra) # 800035ae <bread>
    800038d0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038d2:	40000613          	li	a2,1024
    800038d6:	4581                	li	a1,0
    800038d8:	05850513          	addi	a0,a0,88
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	5f8080e7          	jalr	1528(ra) # 80000ed4 <memset>
  log_write(bp);
    800038e4:	854a                	mv	a0,s2
    800038e6:	00001097          	auipc	ra,0x1
    800038ea:	050080e7          	jalr	80(ra) # 80004936 <log_write>
  brelse(bp);
    800038ee:	854a                	mv	a0,s2
    800038f0:	00000097          	auipc	ra,0x0
    800038f4:	dee080e7          	jalr	-530(ra) # 800036de <brelse>
}
    800038f8:	8526                	mv	a0,s1
    800038fa:	60e6                	ld	ra,88(sp)
    800038fc:	6446                	ld	s0,80(sp)
    800038fe:	64a6                	ld	s1,72(sp)
    80003900:	6906                	ld	s2,64(sp)
    80003902:	79e2                	ld	s3,56(sp)
    80003904:	7a42                	ld	s4,48(sp)
    80003906:	7aa2                	ld	s5,40(sp)
    80003908:	7b02                	ld	s6,32(sp)
    8000390a:	6be2                	ld	s7,24(sp)
    8000390c:	6c42                	ld	s8,16(sp)
    8000390e:	6ca2                	ld	s9,8(sp)
    80003910:	6125                	addi	sp,sp,96
    80003912:	8082                	ret
    brelse(bp);
    80003914:	854a                	mv	a0,s2
    80003916:	00000097          	auipc	ra,0x0
    8000391a:	dc8080e7          	jalr	-568(ra) # 800036de <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000391e:	015c87bb          	addw	a5,s9,s5
    80003922:	00078a9b          	sext.w	s5,a5
    80003926:	004b2703          	lw	a4,4(s6)
    8000392a:	06eaf163          	bgeu	s5,a4,8000398c <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000392e:	41fad79b          	sraiw	a5,s5,0x1f
    80003932:	0137d79b          	srliw	a5,a5,0x13
    80003936:	015787bb          	addw	a5,a5,s5
    8000393a:	40d7d79b          	sraiw	a5,a5,0xd
    8000393e:	01cb2583          	lw	a1,28(s6)
    80003942:	9dbd                	addw	a1,a1,a5
    80003944:	855e                	mv	a0,s7
    80003946:	00000097          	auipc	ra,0x0
    8000394a:	c68080e7          	jalr	-920(ra) # 800035ae <bread>
    8000394e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003950:	004b2503          	lw	a0,4(s6)
    80003954:	000a849b          	sext.w	s1,s5
    80003958:	8762                	mv	a4,s8
    8000395a:	faa4fde3          	bgeu	s1,a0,80003914 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000395e:	00777693          	andi	a3,a4,7
    80003962:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003966:	41f7579b          	sraiw	a5,a4,0x1f
    8000396a:	01d7d79b          	srliw	a5,a5,0x1d
    8000396e:	9fb9                	addw	a5,a5,a4
    80003970:	4037d79b          	sraiw	a5,a5,0x3
    80003974:	00f90633          	add	a2,s2,a5
    80003978:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    8000397c:	00c6f5b3          	and	a1,a3,a2
    80003980:	d585                	beqz	a1,800038a8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003982:	2705                	addiw	a4,a4,1
    80003984:	2485                	addiw	s1,s1,1
    80003986:	fd471ae3          	bne	a4,s4,8000395a <balloc+0xec>
    8000398a:	b769                	j	80003914 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	dc450513          	addi	a0,a0,-572 # 80008750 <syscalls+0x140>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	c04080e7          	jalr	-1020(ra) # 80000598 <printf>
  return 0;
    8000399c:	4481                	li	s1,0
    8000399e:	bfa9                	j	800038f8 <balloc+0x8a>

00000000800039a0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800039a0:	7179                	addi	sp,sp,-48
    800039a2:	f406                	sd	ra,40(sp)
    800039a4:	f022                	sd	s0,32(sp)
    800039a6:	ec26                	sd	s1,24(sp)
    800039a8:	e84a                	sd	s2,16(sp)
    800039aa:	e44e                	sd	s3,8(sp)
    800039ac:	e052                	sd	s4,0(sp)
    800039ae:	1800                	addi	s0,sp,48
    800039b0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039b2:	47ad                	li	a5,11
    800039b4:	02b7e863          	bltu	a5,a1,800039e4 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800039b8:	02059793          	slli	a5,a1,0x20
    800039bc:	01e7d593          	srli	a1,a5,0x1e
    800039c0:	00b504b3          	add	s1,a0,a1
    800039c4:	0504a903          	lw	s2,80(s1)
    800039c8:	06091e63          	bnez	s2,80003a44 <bmap+0xa4>
      addr = balloc(ip->dev);
    800039cc:	4108                	lw	a0,0(a0)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	ea0080e7          	jalr	-352(ra) # 8000386e <balloc>
    800039d6:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039da:	06090563          	beqz	s2,80003a44 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800039de:	0524a823          	sw	s2,80(s1)
    800039e2:	a08d                	j	80003a44 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039e4:	ff45849b          	addiw	s1,a1,-12
    800039e8:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039ec:	0ff00793          	li	a5,255
    800039f0:	08e7e563          	bltu	a5,a4,80003a7a <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039f4:	08052903          	lw	s2,128(a0)
    800039f8:	00091d63          	bnez	s2,80003a12 <bmap+0x72>
      addr = balloc(ip->dev);
    800039fc:	4108                	lw	a0,0(a0)
    800039fe:	00000097          	auipc	ra,0x0
    80003a02:	e70080e7          	jalr	-400(ra) # 8000386e <balloc>
    80003a06:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003a0a:	02090d63          	beqz	s2,80003a44 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a0e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a12:	85ca                	mv	a1,s2
    80003a14:	0009a503          	lw	a0,0(s3)
    80003a18:	00000097          	auipc	ra,0x0
    80003a1c:	b96080e7          	jalr	-1130(ra) # 800035ae <bread>
    80003a20:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a22:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a26:	02049713          	slli	a4,s1,0x20
    80003a2a:	01e75593          	srli	a1,a4,0x1e
    80003a2e:	00b784b3          	add	s1,a5,a1
    80003a32:	0004a903          	lw	s2,0(s1)
    80003a36:	02090063          	beqz	s2,80003a56 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a3a:	8552                	mv	a0,s4
    80003a3c:	00000097          	auipc	ra,0x0
    80003a40:	ca2080e7          	jalr	-862(ra) # 800036de <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a44:	854a                	mv	a0,s2
    80003a46:	70a2                	ld	ra,40(sp)
    80003a48:	7402                	ld	s0,32(sp)
    80003a4a:	64e2                	ld	s1,24(sp)
    80003a4c:	6942                	ld	s2,16(sp)
    80003a4e:	69a2                	ld	s3,8(sp)
    80003a50:	6a02                	ld	s4,0(sp)
    80003a52:	6145                	addi	sp,sp,48
    80003a54:	8082                	ret
      addr = balloc(ip->dev);
    80003a56:	0009a503          	lw	a0,0(s3)
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	e14080e7          	jalr	-492(ra) # 8000386e <balloc>
    80003a62:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a66:	fc090ae3          	beqz	s2,80003a3a <bmap+0x9a>
        a[bn] = addr;
    80003a6a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a6e:	8552                	mv	a0,s4
    80003a70:	00001097          	auipc	ra,0x1
    80003a74:	ec6080e7          	jalr	-314(ra) # 80004936 <log_write>
    80003a78:	b7c9                	j	80003a3a <bmap+0x9a>
  panic("bmap: out of range");
    80003a7a:	00005517          	auipc	a0,0x5
    80003a7e:	cee50513          	addi	a0,a0,-786 # 80008768 <syscalls+0x158>
    80003a82:	ffffd097          	auipc	ra,0xffffd
    80003a86:	aba080e7          	jalr	-1350(ra) # 8000053c <panic>

0000000080003a8a <iget>:
{
    80003a8a:	7179                	addi	sp,sp,-48
    80003a8c:	f406                	sd	ra,40(sp)
    80003a8e:	f022                	sd	s0,32(sp)
    80003a90:	ec26                	sd	s1,24(sp)
    80003a92:	e84a                	sd	s2,16(sp)
    80003a94:	e44e                	sd	s3,8(sp)
    80003a96:	e052                	sd	s4,0(sp)
    80003a98:	1800                	addi	s0,sp,48
    80003a9a:	89aa                	mv	s3,a0
    80003a9c:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a9e:	0023b517          	auipc	a0,0x23b
    80003aa2:	7fa50513          	addi	a0,a0,2042 # 8023f298 <itable>
    80003aa6:	ffffd097          	auipc	ra,0xffffd
    80003aaa:	332080e7          	jalr	818(ra) # 80000dd8 <acquire>
  empty = 0;
    80003aae:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ab0:	0023c497          	auipc	s1,0x23c
    80003ab4:	80048493          	addi	s1,s1,-2048 # 8023f2b0 <itable+0x18>
    80003ab8:	0023d697          	auipc	a3,0x23d
    80003abc:	28868693          	addi	a3,a3,648 # 80240d40 <log>
    80003ac0:	a039                	j	80003ace <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ac2:	02090b63          	beqz	s2,80003af8 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003ac6:	08848493          	addi	s1,s1,136
    80003aca:	02d48a63          	beq	s1,a3,80003afe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ace:	449c                	lw	a5,8(s1)
    80003ad0:	fef059e3          	blez	a5,80003ac2 <iget+0x38>
    80003ad4:	4098                	lw	a4,0(s1)
    80003ad6:	ff3716e3          	bne	a4,s3,80003ac2 <iget+0x38>
    80003ada:	40d8                	lw	a4,4(s1)
    80003adc:	ff4713e3          	bne	a4,s4,80003ac2 <iget+0x38>
      ip->ref++;
    80003ae0:	2785                	addiw	a5,a5,1
    80003ae2:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ae4:	0023b517          	auipc	a0,0x23b
    80003ae8:	7b450513          	addi	a0,a0,1972 # 8023f298 <itable>
    80003aec:	ffffd097          	auipc	ra,0xffffd
    80003af0:	3a0080e7          	jalr	928(ra) # 80000e8c <release>
      return ip;
    80003af4:	8926                	mv	s2,s1
    80003af6:	a03d                	j	80003b24 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003af8:	f7f9                	bnez	a5,80003ac6 <iget+0x3c>
    80003afa:	8926                	mv	s2,s1
    80003afc:	b7e9                	j	80003ac6 <iget+0x3c>
  if(empty == 0)
    80003afe:	02090c63          	beqz	s2,80003b36 <iget+0xac>
  ip->dev = dev;
    80003b02:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003b06:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003b0a:	4785                	li	a5,1
    80003b0c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b10:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b14:	0023b517          	auipc	a0,0x23b
    80003b18:	78450513          	addi	a0,a0,1924 # 8023f298 <itable>
    80003b1c:	ffffd097          	auipc	ra,0xffffd
    80003b20:	370080e7          	jalr	880(ra) # 80000e8c <release>
}
    80003b24:	854a                	mv	a0,s2
    80003b26:	70a2                	ld	ra,40(sp)
    80003b28:	7402                	ld	s0,32(sp)
    80003b2a:	64e2                	ld	s1,24(sp)
    80003b2c:	6942                	ld	s2,16(sp)
    80003b2e:	69a2                	ld	s3,8(sp)
    80003b30:	6a02                	ld	s4,0(sp)
    80003b32:	6145                	addi	sp,sp,48
    80003b34:	8082                	ret
    panic("iget: no inodes");
    80003b36:	00005517          	auipc	a0,0x5
    80003b3a:	c4a50513          	addi	a0,a0,-950 # 80008780 <syscalls+0x170>
    80003b3e:	ffffd097          	auipc	ra,0xffffd
    80003b42:	9fe080e7          	jalr	-1538(ra) # 8000053c <panic>

0000000080003b46 <fsinit>:
fsinit(int dev) {
    80003b46:	7179                	addi	sp,sp,-48
    80003b48:	f406                	sd	ra,40(sp)
    80003b4a:	f022                	sd	s0,32(sp)
    80003b4c:	ec26                	sd	s1,24(sp)
    80003b4e:	e84a                	sd	s2,16(sp)
    80003b50:	e44e                	sd	s3,8(sp)
    80003b52:	1800                	addi	s0,sp,48
    80003b54:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b56:	4585                	li	a1,1
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	a56080e7          	jalr	-1450(ra) # 800035ae <bread>
    80003b60:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b62:	0023b997          	auipc	s3,0x23b
    80003b66:	71698993          	addi	s3,s3,1814 # 8023f278 <sb>
    80003b6a:	02000613          	li	a2,32
    80003b6e:	05850593          	addi	a1,a0,88
    80003b72:	854e                	mv	a0,s3
    80003b74:	ffffd097          	auipc	ra,0xffffd
    80003b78:	3bc080e7          	jalr	956(ra) # 80000f30 <memmove>
  brelse(bp);
    80003b7c:	8526                	mv	a0,s1
    80003b7e:	00000097          	auipc	ra,0x0
    80003b82:	b60080e7          	jalr	-1184(ra) # 800036de <brelse>
  if(sb.magic != FSMAGIC)
    80003b86:	0009a703          	lw	a4,0(s3)
    80003b8a:	102037b7          	lui	a5,0x10203
    80003b8e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b92:	02f71263          	bne	a4,a5,80003bb6 <fsinit+0x70>
  initlog(dev, &sb);
    80003b96:	0023b597          	auipc	a1,0x23b
    80003b9a:	6e258593          	addi	a1,a1,1762 # 8023f278 <sb>
    80003b9e:	854a                	mv	a0,s2
    80003ba0:	00001097          	auipc	ra,0x1
    80003ba4:	b2c080e7          	jalr	-1236(ra) # 800046cc <initlog>
}
    80003ba8:	70a2                	ld	ra,40(sp)
    80003baa:	7402                	ld	s0,32(sp)
    80003bac:	64e2                	ld	s1,24(sp)
    80003bae:	6942                	ld	s2,16(sp)
    80003bb0:	69a2                	ld	s3,8(sp)
    80003bb2:	6145                	addi	sp,sp,48
    80003bb4:	8082                	ret
    panic("invalid file system");
    80003bb6:	00005517          	auipc	a0,0x5
    80003bba:	bda50513          	addi	a0,a0,-1062 # 80008790 <syscalls+0x180>
    80003bbe:	ffffd097          	auipc	ra,0xffffd
    80003bc2:	97e080e7          	jalr	-1666(ra) # 8000053c <panic>

0000000080003bc6 <iinit>:
{
    80003bc6:	7179                	addi	sp,sp,-48
    80003bc8:	f406                	sd	ra,40(sp)
    80003bca:	f022                	sd	s0,32(sp)
    80003bcc:	ec26                	sd	s1,24(sp)
    80003bce:	e84a                	sd	s2,16(sp)
    80003bd0:	e44e                	sd	s3,8(sp)
    80003bd2:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bd4:	00005597          	auipc	a1,0x5
    80003bd8:	bd458593          	addi	a1,a1,-1068 # 800087a8 <syscalls+0x198>
    80003bdc:	0023b517          	auipc	a0,0x23b
    80003be0:	6bc50513          	addi	a0,a0,1724 # 8023f298 <itable>
    80003be4:	ffffd097          	auipc	ra,0xffffd
    80003be8:	164080e7          	jalr	356(ra) # 80000d48 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003bec:	0023b497          	auipc	s1,0x23b
    80003bf0:	6d448493          	addi	s1,s1,1748 # 8023f2c0 <itable+0x28>
    80003bf4:	0023d997          	auipc	s3,0x23d
    80003bf8:	15c98993          	addi	s3,s3,348 # 80240d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bfc:	00005917          	auipc	s2,0x5
    80003c00:	bb490913          	addi	s2,s2,-1100 # 800087b0 <syscalls+0x1a0>
    80003c04:	85ca                	mv	a1,s2
    80003c06:	8526                	mv	a0,s1
    80003c08:	00001097          	auipc	ra,0x1
    80003c0c:	e12080e7          	jalr	-494(ra) # 80004a1a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c10:	08848493          	addi	s1,s1,136
    80003c14:	ff3498e3          	bne	s1,s3,80003c04 <iinit+0x3e>
}
    80003c18:	70a2                	ld	ra,40(sp)
    80003c1a:	7402                	ld	s0,32(sp)
    80003c1c:	64e2                	ld	s1,24(sp)
    80003c1e:	6942                	ld	s2,16(sp)
    80003c20:	69a2                	ld	s3,8(sp)
    80003c22:	6145                	addi	sp,sp,48
    80003c24:	8082                	ret

0000000080003c26 <ialloc>:
{
    80003c26:	7139                	addi	sp,sp,-64
    80003c28:	fc06                	sd	ra,56(sp)
    80003c2a:	f822                	sd	s0,48(sp)
    80003c2c:	f426                	sd	s1,40(sp)
    80003c2e:	f04a                	sd	s2,32(sp)
    80003c30:	ec4e                	sd	s3,24(sp)
    80003c32:	e852                	sd	s4,16(sp)
    80003c34:	e456                	sd	s5,8(sp)
    80003c36:	e05a                	sd	s6,0(sp)
    80003c38:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c3a:	0023b717          	auipc	a4,0x23b
    80003c3e:	64a72703          	lw	a4,1610(a4) # 8023f284 <sb+0xc>
    80003c42:	4785                	li	a5,1
    80003c44:	04e7f863          	bgeu	a5,a4,80003c94 <ialloc+0x6e>
    80003c48:	8aaa                	mv	s5,a0
    80003c4a:	8b2e                	mv	s6,a1
    80003c4c:	4905                	li	s2,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c4e:	0023ba17          	auipc	s4,0x23b
    80003c52:	62aa0a13          	addi	s4,s4,1578 # 8023f278 <sb>
    80003c56:	00495593          	srli	a1,s2,0x4
    80003c5a:	018a2783          	lw	a5,24(s4)
    80003c5e:	9dbd                	addw	a1,a1,a5
    80003c60:	8556                	mv	a0,s5
    80003c62:	00000097          	auipc	ra,0x0
    80003c66:	94c080e7          	jalr	-1716(ra) # 800035ae <bread>
    80003c6a:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c6c:	05850993          	addi	s3,a0,88
    80003c70:	00f97793          	andi	a5,s2,15
    80003c74:	079a                	slli	a5,a5,0x6
    80003c76:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c78:	00099783          	lh	a5,0(s3)
    80003c7c:	cf9d                	beqz	a5,80003cba <ialloc+0x94>
    brelse(bp);
    80003c7e:	00000097          	auipc	ra,0x0
    80003c82:	a60080e7          	jalr	-1440(ra) # 800036de <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c86:	0905                	addi	s2,s2,1
    80003c88:	00ca2703          	lw	a4,12(s4)
    80003c8c:	0009079b          	sext.w	a5,s2
    80003c90:	fce7e3e3          	bltu	a5,a4,80003c56 <ialloc+0x30>
  printf("ialloc: no inodes\n");
    80003c94:	00005517          	auipc	a0,0x5
    80003c98:	b2450513          	addi	a0,a0,-1244 # 800087b8 <syscalls+0x1a8>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	8fc080e7          	jalr	-1796(ra) # 80000598 <printf>
  return 0;
    80003ca4:	4501                	li	a0,0
}
    80003ca6:	70e2                	ld	ra,56(sp)
    80003ca8:	7442                	ld	s0,48(sp)
    80003caa:	74a2                	ld	s1,40(sp)
    80003cac:	7902                	ld	s2,32(sp)
    80003cae:	69e2                	ld	s3,24(sp)
    80003cb0:	6a42                	ld	s4,16(sp)
    80003cb2:	6aa2                	ld	s5,8(sp)
    80003cb4:	6b02                	ld	s6,0(sp)
    80003cb6:	6121                	addi	sp,sp,64
    80003cb8:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003cba:	04000613          	li	a2,64
    80003cbe:	4581                	li	a1,0
    80003cc0:	854e                	mv	a0,s3
    80003cc2:	ffffd097          	auipc	ra,0xffffd
    80003cc6:	212080e7          	jalr	530(ra) # 80000ed4 <memset>
      dip->type = type;
    80003cca:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cce:	8526                	mv	a0,s1
    80003cd0:	00001097          	auipc	ra,0x1
    80003cd4:	c66080e7          	jalr	-922(ra) # 80004936 <log_write>
      brelse(bp);
    80003cd8:	8526                	mv	a0,s1
    80003cda:	00000097          	auipc	ra,0x0
    80003cde:	a04080e7          	jalr	-1532(ra) # 800036de <brelse>
      return iget(dev, inum);
    80003ce2:	0009059b          	sext.w	a1,s2
    80003ce6:	8556                	mv	a0,s5
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	da2080e7          	jalr	-606(ra) # 80003a8a <iget>
    80003cf0:	bf5d                	j	80003ca6 <ialloc+0x80>

0000000080003cf2 <iupdate>:
{
    80003cf2:	1101                	addi	sp,sp,-32
    80003cf4:	ec06                	sd	ra,24(sp)
    80003cf6:	e822                	sd	s0,16(sp)
    80003cf8:	e426                	sd	s1,8(sp)
    80003cfa:	e04a                	sd	s2,0(sp)
    80003cfc:	1000                	addi	s0,sp,32
    80003cfe:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003d00:	415c                	lw	a5,4(a0)
    80003d02:	0047d79b          	srliw	a5,a5,0x4
    80003d06:	0023b597          	auipc	a1,0x23b
    80003d0a:	58a5a583          	lw	a1,1418(a1) # 8023f290 <sb+0x18>
    80003d0e:	9dbd                	addw	a1,a1,a5
    80003d10:	4108                	lw	a0,0(a0)
    80003d12:	00000097          	auipc	ra,0x0
    80003d16:	89c080e7          	jalr	-1892(ra) # 800035ae <bread>
    80003d1a:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d1c:	05850793          	addi	a5,a0,88
    80003d20:	40d8                	lw	a4,4(s1)
    80003d22:	8b3d                	andi	a4,a4,15
    80003d24:	071a                	slli	a4,a4,0x6
    80003d26:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003d28:	04449703          	lh	a4,68(s1)
    80003d2c:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003d30:	04649703          	lh	a4,70(s1)
    80003d34:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003d38:	04849703          	lh	a4,72(s1)
    80003d3c:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003d40:	04a49703          	lh	a4,74(s1)
    80003d44:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003d48:	44f8                	lw	a4,76(s1)
    80003d4a:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d4c:	03400613          	li	a2,52
    80003d50:	05048593          	addi	a1,s1,80
    80003d54:	00c78513          	addi	a0,a5,12
    80003d58:	ffffd097          	auipc	ra,0xffffd
    80003d5c:	1d8080e7          	jalr	472(ra) # 80000f30 <memmove>
  log_write(bp);
    80003d60:	854a                	mv	a0,s2
    80003d62:	00001097          	auipc	ra,0x1
    80003d66:	bd4080e7          	jalr	-1068(ra) # 80004936 <log_write>
  brelse(bp);
    80003d6a:	854a                	mv	a0,s2
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	972080e7          	jalr	-1678(ra) # 800036de <brelse>
}
    80003d74:	60e2                	ld	ra,24(sp)
    80003d76:	6442                	ld	s0,16(sp)
    80003d78:	64a2                	ld	s1,8(sp)
    80003d7a:	6902                	ld	s2,0(sp)
    80003d7c:	6105                	addi	sp,sp,32
    80003d7e:	8082                	ret

0000000080003d80 <idup>:
{
    80003d80:	1101                	addi	sp,sp,-32
    80003d82:	ec06                	sd	ra,24(sp)
    80003d84:	e822                	sd	s0,16(sp)
    80003d86:	e426                	sd	s1,8(sp)
    80003d88:	1000                	addi	s0,sp,32
    80003d8a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d8c:	0023b517          	auipc	a0,0x23b
    80003d90:	50c50513          	addi	a0,a0,1292 # 8023f298 <itable>
    80003d94:	ffffd097          	auipc	ra,0xffffd
    80003d98:	044080e7          	jalr	68(ra) # 80000dd8 <acquire>
  ip->ref++;
    80003d9c:	449c                	lw	a5,8(s1)
    80003d9e:	2785                	addiw	a5,a5,1
    80003da0:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003da2:	0023b517          	auipc	a0,0x23b
    80003da6:	4f650513          	addi	a0,a0,1270 # 8023f298 <itable>
    80003daa:	ffffd097          	auipc	ra,0xffffd
    80003dae:	0e2080e7          	jalr	226(ra) # 80000e8c <release>
}
    80003db2:	8526                	mv	a0,s1
    80003db4:	60e2                	ld	ra,24(sp)
    80003db6:	6442                	ld	s0,16(sp)
    80003db8:	64a2                	ld	s1,8(sp)
    80003dba:	6105                	addi	sp,sp,32
    80003dbc:	8082                	ret

0000000080003dbe <ilock>:
{
    80003dbe:	1101                	addi	sp,sp,-32
    80003dc0:	ec06                	sd	ra,24(sp)
    80003dc2:	e822                	sd	s0,16(sp)
    80003dc4:	e426                	sd	s1,8(sp)
    80003dc6:	e04a                	sd	s2,0(sp)
    80003dc8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dca:	c115                	beqz	a0,80003dee <ilock+0x30>
    80003dcc:	84aa                	mv	s1,a0
    80003dce:	451c                	lw	a5,8(a0)
    80003dd0:	00f05f63          	blez	a5,80003dee <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dd4:	0541                	addi	a0,a0,16
    80003dd6:	00001097          	auipc	ra,0x1
    80003dda:	c7e080e7          	jalr	-898(ra) # 80004a54 <acquiresleep>
  if(ip->valid == 0){
    80003dde:	40bc                	lw	a5,64(s1)
    80003de0:	cf99                	beqz	a5,80003dfe <ilock+0x40>
}
    80003de2:	60e2                	ld	ra,24(sp)
    80003de4:	6442                	ld	s0,16(sp)
    80003de6:	64a2                	ld	s1,8(sp)
    80003de8:	6902                	ld	s2,0(sp)
    80003dea:	6105                	addi	sp,sp,32
    80003dec:	8082                	ret
    panic("ilock");
    80003dee:	00005517          	auipc	a0,0x5
    80003df2:	9e250513          	addi	a0,a0,-1566 # 800087d0 <syscalls+0x1c0>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	746080e7          	jalr	1862(ra) # 8000053c <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003dfe:	40dc                	lw	a5,4(s1)
    80003e00:	0047d79b          	srliw	a5,a5,0x4
    80003e04:	0023b597          	auipc	a1,0x23b
    80003e08:	48c5a583          	lw	a1,1164(a1) # 8023f290 <sb+0x18>
    80003e0c:	9dbd                	addw	a1,a1,a5
    80003e0e:	4088                	lw	a0,0(s1)
    80003e10:	fffff097          	auipc	ra,0xfffff
    80003e14:	79e080e7          	jalr	1950(ra) # 800035ae <bread>
    80003e18:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e1a:	05850593          	addi	a1,a0,88
    80003e1e:	40dc                	lw	a5,4(s1)
    80003e20:	8bbd                	andi	a5,a5,15
    80003e22:	079a                	slli	a5,a5,0x6
    80003e24:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e26:	00059783          	lh	a5,0(a1)
    80003e2a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e2e:	00259783          	lh	a5,2(a1)
    80003e32:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e36:	00459783          	lh	a5,4(a1)
    80003e3a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e3e:	00659783          	lh	a5,6(a1)
    80003e42:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e46:	459c                	lw	a5,8(a1)
    80003e48:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e4a:	03400613          	li	a2,52
    80003e4e:	05b1                	addi	a1,a1,12
    80003e50:	05048513          	addi	a0,s1,80
    80003e54:	ffffd097          	auipc	ra,0xffffd
    80003e58:	0dc080e7          	jalr	220(ra) # 80000f30 <memmove>
    brelse(bp);
    80003e5c:	854a                	mv	a0,s2
    80003e5e:	00000097          	auipc	ra,0x0
    80003e62:	880080e7          	jalr	-1920(ra) # 800036de <brelse>
    ip->valid = 1;
    80003e66:	4785                	li	a5,1
    80003e68:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e6a:	04449783          	lh	a5,68(s1)
    80003e6e:	fbb5                	bnez	a5,80003de2 <ilock+0x24>
      panic("ilock: no type");
    80003e70:	00005517          	auipc	a0,0x5
    80003e74:	96850513          	addi	a0,a0,-1688 # 800087d8 <syscalls+0x1c8>
    80003e78:	ffffc097          	auipc	ra,0xffffc
    80003e7c:	6c4080e7          	jalr	1732(ra) # 8000053c <panic>

0000000080003e80 <iunlock>:
{
    80003e80:	1101                	addi	sp,sp,-32
    80003e82:	ec06                	sd	ra,24(sp)
    80003e84:	e822                	sd	s0,16(sp)
    80003e86:	e426                	sd	s1,8(sp)
    80003e88:	e04a                	sd	s2,0(sp)
    80003e8a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e8c:	c905                	beqz	a0,80003ebc <iunlock+0x3c>
    80003e8e:	84aa                	mv	s1,a0
    80003e90:	01050913          	addi	s2,a0,16
    80003e94:	854a                	mv	a0,s2
    80003e96:	00001097          	auipc	ra,0x1
    80003e9a:	c58080e7          	jalr	-936(ra) # 80004aee <holdingsleep>
    80003e9e:	cd19                	beqz	a0,80003ebc <iunlock+0x3c>
    80003ea0:	449c                	lw	a5,8(s1)
    80003ea2:	00f05d63          	blez	a5,80003ebc <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003ea6:	854a                	mv	a0,s2
    80003ea8:	00001097          	auipc	ra,0x1
    80003eac:	c02080e7          	jalr	-1022(ra) # 80004aaa <releasesleep>
}
    80003eb0:	60e2                	ld	ra,24(sp)
    80003eb2:	6442                	ld	s0,16(sp)
    80003eb4:	64a2                	ld	s1,8(sp)
    80003eb6:	6902                	ld	s2,0(sp)
    80003eb8:	6105                	addi	sp,sp,32
    80003eba:	8082                	ret
    panic("iunlock");
    80003ebc:	00005517          	auipc	a0,0x5
    80003ec0:	92c50513          	addi	a0,a0,-1748 # 800087e8 <syscalls+0x1d8>
    80003ec4:	ffffc097          	auipc	ra,0xffffc
    80003ec8:	678080e7          	jalr	1656(ra) # 8000053c <panic>

0000000080003ecc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ecc:	7179                	addi	sp,sp,-48
    80003ece:	f406                	sd	ra,40(sp)
    80003ed0:	f022                	sd	s0,32(sp)
    80003ed2:	ec26                	sd	s1,24(sp)
    80003ed4:	e84a                	sd	s2,16(sp)
    80003ed6:	e44e                	sd	s3,8(sp)
    80003ed8:	e052                	sd	s4,0(sp)
    80003eda:	1800                	addi	s0,sp,48
    80003edc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ede:	05050493          	addi	s1,a0,80
    80003ee2:	08050913          	addi	s2,a0,128
    80003ee6:	a021                	j	80003eee <itrunc+0x22>
    80003ee8:	0491                	addi	s1,s1,4
    80003eea:	01248d63          	beq	s1,s2,80003f04 <itrunc+0x38>
    if(ip->addrs[i]){
    80003eee:	408c                	lw	a1,0(s1)
    80003ef0:	dde5                	beqz	a1,80003ee8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ef2:	0009a503          	lw	a0,0(s3)
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	8fc080e7          	jalr	-1796(ra) # 800037f2 <bfree>
      ip->addrs[i] = 0;
    80003efe:	0004a023          	sw	zero,0(s1)
    80003f02:	b7dd                	j	80003ee8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003f04:	0809a583          	lw	a1,128(s3)
    80003f08:	e185                	bnez	a1,80003f28 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f0a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f0e:	854e                	mv	a0,s3
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	de2080e7          	jalr	-542(ra) # 80003cf2 <iupdate>
}
    80003f18:	70a2                	ld	ra,40(sp)
    80003f1a:	7402                	ld	s0,32(sp)
    80003f1c:	64e2                	ld	s1,24(sp)
    80003f1e:	6942                	ld	s2,16(sp)
    80003f20:	69a2                	ld	s3,8(sp)
    80003f22:	6a02                	ld	s4,0(sp)
    80003f24:	6145                	addi	sp,sp,48
    80003f26:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f28:	0009a503          	lw	a0,0(s3)
    80003f2c:	fffff097          	auipc	ra,0xfffff
    80003f30:	682080e7          	jalr	1666(ra) # 800035ae <bread>
    80003f34:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f36:	05850493          	addi	s1,a0,88
    80003f3a:	45850913          	addi	s2,a0,1112
    80003f3e:	a021                	j	80003f46 <itrunc+0x7a>
    80003f40:	0491                	addi	s1,s1,4
    80003f42:	01248b63          	beq	s1,s2,80003f58 <itrunc+0x8c>
      if(a[j])
    80003f46:	408c                	lw	a1,0(s1)
    80003f48:	dde5                	beqz	a1,80003f40 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f4a:	0009a503          	lw	a0,0(s3)
    80003f4e:	00000097          	auipc	ra,0x0
    80003f52:	8a4080e7          	jalr	-1884(ra) # 800037f2 <bfree>
    80003f56:	b7ed                	j	80003f40 <itrunc+0x74>
    brelse(bp);
    80003f58:	8552                	mv	a0,s4
    80003f5a:	fffff097          	auipc	ra,0xfffff
    80003f5e:	784080e7          	jalr	1924(ra) # 800036de <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f62:	0809a583          	lw	a1,128(s3)
    80003f66:	0009a503          	lw	a0,0(s3)
    80003f6a:	00000097          	auipc	ra,0x0
    80003f6e:	888080e7          	jalr	-1912(ra) # 800037f2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f72:	0809a023          	sw	zero,128(s3)
    80003f76:	bf51                	j	80003f0a <itrunc+0x3e>

0000000080003f78 <iput>:
{
    80003f78:	1101                	addi	sp,sp,-32
    80003f7a:	ec06                	sd	ra,24(sp)
    80003f7c:	e822                	sd	s0,16(sp)
    80003f7e:	e426                	sd	s1,8(sp)
    80003f80:	e04a                	sd	s2,0(sp)
    80003f82:	1000                	addi	s0,sp,32
    80003f84:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f86:	0023b517          	auipc	a0,0x23b
    80003f8a:	31250513          	addi	a0,a0,786 # 8023f298 <itable>
    80003f8e:	ffffd097          	auipc	ra,0xffffd
    80003f92:	e4a080e7          	jalr	-438(ra) # 80000dd8 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f96:	4498                	lw	a4,8(s1)
    80003f98:	4785                	li	a5,1
    80003f9a:	02f70363          	beq	a4,a5,80003fc0 <iput+0x48>
  ip->ref--;
    80003f9e:	449c                	lw	a5,8(s1)
    80003fa0:	37fd                	addiw	a5,a5,-1
    80003fa2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003fa4:	0023b517          	auipc	a0,0x23b
    80003fa8:	2f450513          	addi	a0,a0,756 # 8023f298 <itable>
    80003fac:	ffffd097          	auipc	ra,0xffffd
    80003fb0:	ee0080e7          	jalr	-288(ra) # 80000e8c <release>
}
    80003fb4:	60e2                	ld	ra,24(sp)
    80003fb6:	6442                	ld	s0,16(sp)
    80003fb8:	64a2                	ld	s1,8(sp)
    80003fba:	6902                	ld	s2,0(sp)
    80003fbc:	6105                	addi	sp,sp,32
    80003fbe:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fc0:	40bc                	lw	a5,64(s1)
    80003fc2:	dff1                	beqz	a5,80003f9e <iput+0x26>
    80003fc4:	04a49783          	lh	a5,74(s1)
    80003fc8:	fbf9                	bnez	a5,80003f9e <iput+0x26>
    acquiresleep(&ip->lock);
    80003fca:	01048913          	addi	s2,s1,16
    80003fce:	854a                	mv	a0,s2
    80003fd0:	00001097          	auipc	ra,0x1
    80003fd4:	a84080e7          	jalr	-1404(ra) # 80004a54 <acquiresleep>
    release(&itable.lock);
    80003fd8:	0023b517          	auipc	a0,0x23b
    80003fdc:	2c050513          	addi	a0,a0,704 # 8023f298 <itable>
    80003fe0:	ffffd097          	auipc	ra,0xffffd
    80003fe4:	eac080e7          	jalr	-340(ra) # 80000e8c <release>
    itrunc(ip);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	00000097          	auipc	ra,0x0
    80003fee:	ee2080e7          	jalr	-286(ra) # 80003ecc <itrunc>
    ip->type = 0;
    80003ff2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003ff6:	8526                	mv	a0,s1
    80003ff8:	00000097          	auipc	ra,0x0
    80003ffc:	cfa080e7          	jalr	-774(ra) # 80003cf2 <iupdate>
    ip->valid = 0;
    80004000:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004004:	854a                	mv	a0,s2
    80004006:	00001097          	auipc	ra,0x1
    8000400a:	aa4080e7          	jalr	-1372(ra) # 80004aaa <releasesleep>
    acquire(&itable.lock);
    8000400e:	0023b517          	auipc	a0,0x23b
    80004012:	28a50513          	addi	a0,a0,650 # 8023f298 <itable>
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	dc2080e7          	jalr	-574(ra) # 80000dd8 <acquire>
    8000401e:	b741                	j	80003f9e <iput+0x26>

0000000080004020 <iunlockput>:
{
    80004020:	1101                	addi	sp,sp,-32
    80004022:	ec06                	sd	ra,24(sp)
    80004024:	e822                	sd	s0,16(sp)
    80004026:	e426                	sd	s1,8(sp)
    80004028:	1000                	addi	s0,sp,32
    8000402a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000402c:	00000097          	auipc	ra,0x0
    80004030:	e54080e7          	jalr	-428(ra) # 80003e80 <iunlock>
  iput(ip);
    80004034:	8526                	mv	a0,s1
    80004036:	00000097          	auipc	ra,0x0
    8000403a:	f42080e7          	jalr	-190(ra) # 80003f78 <iput>
}
    8000403e:	60e2                	ld	ra,24(sp)
    80004040:	6442                	ld	s0,16(sp)
    80004042:	64a2                	ld	s1,8(sp)
    80004044:	6105                	addi	sp,sp,32
    80004046:	8082                	ret

0000000080004048 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004048:	1141                	addi	sp,sp,-16
    8000404a:	e422                	sd	s0,8(sp)
    8000404c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000404e:	411c                	lw	a5,0(a0)
    80004050:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004052:	415c                	lw	a5,4(a0)
    80004054:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004056:	04451783          	lh	a5,68(a0)
    8000405a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000405e:	04a51783          	lh	a5,74(a0)
    80004062:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004066:	04c56783          	lwu	a5,76(a0)
    8000406a:	e99c                	sd	a5,16(a1)
}
    8000406c:	6422                	ld	s0,8(sp)
    8000406e:	0141                	addi	sp,sp,16
    80004070:	8082                	ret

0000000080004072 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004072:	457c                	lw	a5,76(a0)
    80004074:	0ed7e963          	bltu	a5,a3,80004166 <readi+0xf4>
{
    80004078:	7159                	addi	sp,sp,-112
    8000407a:	f486                	sd	ra,104(sp)
    8000407c:	f0a2                	sd	s0,96(sp)
    8000407e:	eca6                	sd	s1,88(sp)
    80004080:	e8ca                	sd	s2,80(sp)
    80004082:	e4ce                	sd	s3,72(sp)
    80004084:	e0d2                	sd	s4,64(sp)
    80004086:	fc56                	sd	s5,56(sp)
    80004088:	f85a                	sd	s6,48(sp)
    8000408a:	f45e                	sd	s7,40(sp)
    8000408c:	f062                	sd	s8,32(sp)
    8000408e:	ec66                	sd	s9,24(sp)
    80004090:	e86a                	sd	s10,16(sp)
    80004092:	e46e                	sd	s11,8(sp)
    80004094:	1880                	addi	s0,sp,112
    80004096:	8b2a                	mv	s6,a0
    80004098:	8bae                	mv	s7,a1
    8000409a:	8a32                	mv	s4,a2
    8000409c:	84b6                	mv	s1,a3
    8000409e:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    800040a0:	9f35                	addw	a4,a4,a3
    return 0;
    800040a2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800040a4:	0ad76063          	bltu	a4,a3,80004144 <readi+0xd2>
  if(off + n > ip->size)
    800040a8:	00e7f463          	bgeu	a5,a4,800040b0 <readi+0x3e>
    n = ip->size - off;
    800040ac:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040b0:	0a0a8963          	beqz	s5,80004162 <readi+0xf0>
    800040b4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040b6:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040ba:	5c7d                	li	s8,-1
    800040bc:	a82d                	j	800040f6 <readi+0x84>
    800040be:	020d1d93          	slli	s11,s10,0x20
    800040c2:	020ddd93          	srli	s11,s11,0x20
    800040c6:	05890613          	addi	a2,s2,88
    800040ca:	86ee                	mv	a3,s11
    800040cc:	963a                	add	a2,a2,a4
    800040ce:	85d2                	mv	a1,s4
    800040d0:	855e                	mv	a0,s7
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	80a080e7          	jalr	-2038(ra) # 800028dc <either_copyout>
    800040da:	05850d63          	beq	a0,s8,80004134 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040de:	854a                	mv	a0,s2
    800040e0:	fffff097          	auipc	ra,0xfffff
    800040e4:	5fe080e7          	jalr	1534(ra) # 800036de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040e8:	013d09bb          	addw	s3,s10,s3
    800040ec:	009d04bb          	addw	s1,s10,s1
    800040f0:	9a6e                	add	s4,s4,s11
    800040f2:	0559f763          	bgeu	s3,s5,80004140 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040f6:	00a4d59b          	srliw	a1,s1,0xa
    800040fa:	855a                	mv	a0,s6
    800040fc:	00000097          	auipc	ra,0x0
    80004100:	8a4080e7          	jalr	-1884(ra) # 800039a0 <bmap>
    80004104:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004108:	cd85                	beqz	a1,80004140 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000410a:	000b2503          	lw	a0,0(s6)
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	4a0080e7          	jalr	1184(ra) # 800035ae <bread>
    80004116:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004118:	3ff4f713          	andi	a4,s1,1023
    8000411c:	40ec87bb          	subw	a5,s9,a4
    80004120:	413a86bb          	subw	a3,s5,s3
    80004124:	8d3e                	mv	s10,a5
    80004126:	2781                	sext.w	a5,a5
    80004128:	0006861b          	sext.w	a2,a3
    8000412c:	f8f679e3          	bgeu	a2,a5,800040be <readi+0x4c>
    80004130:	8d36                	mv	s10,a3
    80004132:	b771                	j	800040be <readi+0x4c>
      brelse(bp);
    80004134:	854a                	mv	a0,s2
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	5a8080e7          	jalr	1448(ra) # 800036de <brelse>
      tot = -1;
    8000413e:	59fd                	li	s3,-1
  }
  return tot;
    80004140:	0009851b          	sext.w	a0,s3
}
    80004144:	70a6                	ld	ra,104(sp)
    80004146:	7406                	ld	s0,96(sp)
    80004148:	64e6                	ld	s1,88(sp)
    8000414a:	6946                	ld	s2,80(sp)
    8000414c:	69a6                	ld	s3,72(sp)
    8000414e:	6a06                	ld	s4,64(sp)
    80004150:	7ae2                	ld	s5,56(sp)
    80004152:	7b42                	ld	s6,48(sp)
    80004154:	7ba2                	ld	s7,40(sp)
    80004156:	7c02                	ld	s8,32(sp)
    80004158:	6ce2                	ld	s9,24(sp)
    8000415a:	6d42                	ld	s10,16(sp)
    8000415c:	6da2                	ld	s11,8(sp)
    8000415e:	6165                	addi	sp,sp,112
    80004160:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004162:	89d6                	mv	s3,s5
    80004164:	bff1                	j	80004140 <readi+0xce>
    return 0;
    80004166:	4501                	li	a0,0
}
    80004168:	8082                	ret

000000008000416a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000416a:	457c                	lw	a5,76(a0)
    8000416c:	10d7e863          	bltu	a5,a3,8000427c <writei+0x112>
{
    80004170:	7159                	addi	sp,sp,-112
    80004172:	f486                	sd	ra,104(sp)
    80004174:	f0a2                	sd	s0,96(sp)
    80004176:	eca6                	sd	s1,88(sp)
    80004178:	e8ca                	sd	s2,80(sp)
    8000417a:	e4ce                	sd	s3,72(sp)
    8000417c:	e0d2                	sd	s4,64(sp)
    8000417e:	fc56                	sd	s5,56(sp)
    80004180:	f85a                	sd	s6,48(sp)
    80004182:	f45e                	sd	s7,40(sp)
    80004184:	f062                	sd	s8,32(sp)
    80004186:	ec66                	sd	s9,24(sp)
    80004188:	e86a                	sd	s10,16(sp)
    8000418a:	e46e                	sd	s11,8(sp)
    8000418c:	1880                	addi	s0,sp,112
    8000418e:	8aaa                	mv	s5,a0
    80004190:	8bae                	mv	s7,a1
    80004192:	8a32                	mv	s4,a2
    80004194:	8936                	mv	s2,a3
    80004196:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004198:	00e687bb          	addw	a5,a3,a4
    8000419c:	0ed7e263          	bltu	a5,a3,80004280 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800041a0:	00043737          	lui	a4,0x43
    800041a4:	0ef76063          	bltu	a4,a5,80004284 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a8:	0c0b0863          	beqz	s6,80004278 <writei+0x10e>
    800041ac:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041ae:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041b2:	5c7d                	li	s8,-1
    800041b4:	a091                	j	800041f8 <writei+0x8e>
    800041b6:	020d1d93          	slli	s11,s10,0x20
    800041ba:	020ddd93          	srli	s11,s11,0x20
    800041be:	05848513          	addi	a0,s1,88
    800041c2:	86ee                	mv	a3,s11
    800041c4:	8652                	mv	a2,s4
    800041c6:	85de                	mv	a1,s7
    800041c8:	953a                	add	a0,a0,a4
    800041ca:	ffffe097          	auipc	ra,0xffffe
    800041ce:	768080e7          	jalr	1896(ra) # 80002932 <either_copyin>
    800041d2:	07850263          	beq	a0,s8,80004236 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041d6:	8526                	mv	a0,s1
    800041d8:	00000097          	auipc	ra,0x0
    800041dc:	75e080e7          	jalr	1886(ra) # 80004936 <log_write>
    brelse(bp);
    800041e0:	8526                	mv	a0,s1
    800041e2:	fffff097          	auipc	ra,0xfffff
    800041e6:	4fc080e7          	jalr	1276(ra) # 800036de <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041ea:	013d09bb          	addw	s3,s10,s3
    800041ee:	012d093b          	addw	s2,s10,s2
    800041f2:	9a6e                	add	s4,s4,s11
    800041f4:	0569f663          	bgeu	s3,s6,80004240 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041f8:	00a9559b          	srliw	a1,s2,0xa
    800041fc:	8556                	mv	a0,s5
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	7a2080e7          	jalr	1954(ra) # 800039a0 <bmap>
    80004206:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000420a:	c99d                	beqz	a1,80004240 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000420c:	000aa503          	lw	a0,0(s5)
    80004210:	fffff097          	auipc	ra,0xfffff
    80004214:	39e080e7          	jalr	926(ra) # 800035ae <bread>
    80004218:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000421a:	3ff97713          	andi	a4,s2,1023
    8000421e:	40ec87bb          	subw	a5,s9,a4
    80004222:	413b06bb          	subw	a3,s6,s3
    80004226:	8d3e                	mv	s10,a5
    80004228:	2781                	sext.w	a5,a5
    8000422a:	0006861b          	sext.w	a2,a3
    8000422e:	f8f674e3          	bgeu	a2,a5,800041b6 <writei+0x4c>
    80004232:	8d36                	mv	s10,a3
    80004234:	b749                	j	800041b6 <writei+0x4c>
      brelse(bp);
    80004236:	8526                	mv	a0,s1
    80004238:	fffff097          	auipc	ra,0xfffff
    8000423c:	4a6080e7          	jalr	1190(ra) # 800036de <brelse>
  }

  if(off > ip->size)
    80004240:	04caa783          	lw	a5,76(s5)
    80004244:	0127f463          	bgeu	a5,s2,8000424c <writei+0xe2>
    ip->size = off;
    80004248:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000424c:	8556                	mv	a0,s5
    8000424e:	00000097          	auipc	ra,0x0
    80004252:	aa4080e7          	jalr	-1372(ra) # 80003cf2 <iupdate>

  return tot;
    80004256:	0009851b          	sext.w	a0,s3
}
    8000425a:	70a6                	ld	ra,104(sp)
    8000425c:	7406                	ld	s0,96(sp)
    8000425e:	64e6                	ld	s1,88(sp)
    80004260:	6946                	ld	s2,80(sp)
    80004262:	69a6                	ld	s3,72(sp)
    80004264:	6a06                	ld	s4,64(sp)
    80004266:	7ae2                	ld	s5,56(sp)
    80004268:	7b42                	ld	s6,48(sp)
    8000426a:	7ba2                	ld	s7,40(sp)
    8000426c:	7c02                	ld	s8,32(sp)
    8000426e:	6ce2                	ld	s9,24(sp)
    80004270:	6d42                	ld	s10,16(sp)
    80004272:	6da2                	ld	s11,8(sp)
    80004274:	6165                	addi	sp,sp,112
    80004276:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004278:	89da                	mv	s3,s6
    8000427a:	bfc9                	j	8000424c <writei+0xe2>
    return -1;
    8000427c:	557d                	li	a0,-1
}
    8000427e:	8082                	ret
    return -1;
    80004280:	557d                	li	a0,-1
    80004282:	bfe1                	j	8000425a <writei+0xf0>
    return -1;
    80004284:	557d                	li	a0,-1
    80004286:	bfd1                	j	8000425a <writei+0xf0>

0000000080004288 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004288:	1141                	addi	sp,sp,-16
    8000428a:	e406                	sd	ra,8(sp)
    8000428c:	e022                	sd	s0,0(sp)
    8000428e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004290:	4639                	li	a2,14
    80004292:	ffffd097          	auipc	ra,0xffffd
    80004296:	d12080e7          	jalr	-750(ra) # 80000fa4 <strncmp>
}
    8000429a:	60a2                	ld	ra,8(sp)
    8000429c:	6402                	ld	s0,0(sp)
    8000429e:	0141                	addi	sp,sp,16
    800042a0:	8082                	ret

00000000800042a2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800042a2:	7139                	addi	sp,sp,-64
    800042a4:	fc06                	sd	ra,56(sp)
    800042a6:	f822                	sd	s0,48(sp)
    800042a8:	f426                	sd	s1,40(sp)
    800042aa:	f04a                	sd	s2,32(sp)
    800042ac:	ec4e                	sd	s3,24(sp)
    800042ae:	e852                	sd	s4,16(sp)
    800042b0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042b2:	04451703          	lh	a4,68(a0)
    800042b6:	4785                	li	a5,1
    800042b8:	00f71a63          	bne	a4,a5,800042cc <dirlookup+0x2a>
    800042bc:	892a                	mv	s2,a0
    800042be:	89ae                	mv	s3,a1
    800042c0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c2:	457c                	lw	a5,76(a0)
    800042c4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042c6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c8:	e79d                	bnez	a5,800042f6 <dirlookup+0x54>
    800042ca:	a8a5                	j	80004342 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042cc:	00004517          	auipc	a0,0x4
    800042d0:	52450513          	addi	a0,a0,1316 # 800087f0 <syscalls+0x1e0>
    800042d4:	ffffc097          	auipc	ra,0xffffc
    800042d8:	268080e7          	jalr	616(ra) # 8000053c <panic>
      panic("dirlookup read");
    800042dc:	00004517          	auipc	a0,0x4
    800042e0:	52c50513          	addi	a0,a0,1324 # 80008808 <syscalls+0x1f8>
    800042e4:	ffffc097          	auipc	ra,0xffffc
    800042e8:	258080e7          	jalr	600(ra) # 8000053c <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ec:	24c1                	addiw	s1,s1,16
    800042ee:	04c92783          	lw	a5,76(s2)
    800042f2:	04f4f763          	bgeu	s1,a5,80004340 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042f6:	4741                	li	a4,16
    800042f8:	86a6                	mv	a3,s1
    800042fa:	fc040613          	addi	a2,s0,-64
    800042fe:	4581                	li	a1,0
    80004300:	854a                	mv	a0,s2
    80004302:	00000097          	auipc	ra,0x0
    80004306:	d70080e7          	jalr	-656(ra) # 80004072 <readi>
    8000430a:	47c1                	li	a5,16
    8000430c:	fcf518e3          	bne	a0,a5,800042dc <dirlookup+0x3a>
    if(de.inum == 0)
    80004310:	fc045783          	lhu	a5,-64(s0)
    80004314:	dfe1                	beqz	a5,800042ec <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004316:	fc240593          	addi	a1,s0,-62
    8000431a:	854e                	mv	a0,s3
    8000431c:	00000097          	auipc	ra,0x0
    80004320:	f6c080e7          	jalr	-148(ra) # 80004288 <namecmp>
    80004324:	f561                	bnez	a0,800042ec <dirlookup+0x4a>
      if(poff)
    80004326:	000a0463          	beqz	s4,8000432e <dirlookup+0x8c>
        *poff = off;
    8000432a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000432e:	fc045583          	lhu	a1,-64(s0)
    80004332:	00092503          	lw	a0,0(s2)
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	754080e7          	jalr	1876(ra) # 80003a8a <iget>
    8000433e:	a011                	j	80004342 <dirlookup+0xa0>
  return 0;
    80004340:	4501                	li	a0,0
}
    80004342:	70e2                	ld	ra,56(sp)
    80004344:	7442                	ld	s0,48(sp)
    80004346:	74a2                	ld	s1,40(sp)
    80004348:	7902                	ld	s2,32(sp)
    8000434a:	69e2                	ld	s3,24(sp)
    8000434c:	6a42                	ld	s4,16(sp)
    8000434e:	6121                	addi	sp,sp,64
    80004350:	8082                	ret

0000000080004352 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004352:	711d                	addi	sp,sp,-96
    80004354:	ec86                	sd	ra,88(sp)
    80004356:	e8a2                	sd	s0,80(sp)
    80004358:	e4a6                	sd	s1,72(sp)
    8000435a:	e0ca                	sd	s2,64(sp)
    8000435c:	fc4e                	sd	s3,56(sp)
    8000435e:	f852                	sd	s4,48(sp)
    80004360:	f456                	sd	s5,40(sp)
    80004362:	f05a                	sd	s6,32(sp)
    80004364:	ec5e                	sd	s7,24(sp)
    80004366:	e862                	sd	s8,16(sp)
    80004368:	e466                	sd	s9,8(sp)
    8000436a:	1080                	addi	s0,sp,96
    8000436c:	84aa                	mv	s1,a0
    8000436e:	8b2e                	mv	s6,a1
    80004370:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004372:	00054703          	lbu	a4,0(a0)
    80004376:	02f00793          	li	a5,47
    8000437a:	02f70263          	beq	a4,a5,8000439e <namex+0x4c>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000437e:	ffffe097          	auipc	ra,0xffffe
    80004382:	9ee080e7          	jalr	-1554(ra) # 80001d6c <myproc>
    80004386:	15053503          	ld	a0,336(a0)
    8000438a:	00000097          	auipc	ra,0x0
    8000438e:	9f6080e7          	jalr	-1546(ra) # 80003d80 <idup>
    80004392:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004394:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004398:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000439a:	4b85                	li	s7,1
    8000439c:	a875                	j	80004458 <namex+0x106>
    ip = iget(ROOTDEV, ROOTINO);
    8000439e:	4585                	li	a1,1
    800043a0:	4505                	li	a0,1
    800043a2:	fffff097          	auipc	ra,0xfffff
    800043a6:	6e8080e7          	jalr	1768(ra) # 80003a8a <iget>
    800043aa:	8a2a                	mv	s4,a0
    800043ac:	b7e5                	j	80004394 <namex+0x42>
      iunlockput(ip);
    800043ae:	8552                	mv	a0,s4
    800043b0:	00000097          	auipc	ra,0x0
    800043b4:	c70080e7          	jalr	-912(ra) # 80004020 <iunlockput>
      return 0;
    800043b8:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043ba:	8552                	mv	a0,s4
    800043bc:	60e6                	ld	ra,88(sp)
    800043be:	6446                	ld	s0,80(sp)
    800043c0:	64a6                	ld	s1,72(sp)
    800043c2:	6906                	ld	s2,64(sp)
    800043c4:	79e2                	ld	s3,56(sp)
    800043c6:	7a42                	ld	s4,48(sp)
    800043c8:	7aa2                	ld	s5,40(sp)
    800043ca:	7b02                	ld	s6,32(sp)
    800043cc:	6be2                	ld	s7,24(sp)
    800043ce:	6c42                	ld	s8,16(sp)
    800043d0:	6ca2                	ld	s9,8(sp)
    800043d2:	6125                	addi	sp,sp,96
    800043d4:	8082                	ret
      iunlock(ip);
    800043d6:	8552                	mv	a0,s4
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	aa8080e7          	jalr	-1368(ra) # 80003e80 <iunlock>
      return ip;
    800043e0:	bfe9                	j	800043ba <namex+0x68>
      iunlockput(ip);
    800043e2:	8552                	mv	a0,s4
    800043e4:	00000097          	auipc	ra,0x0
    800043e8:	c3c080e7          	jalr	-964(ra) # 80004020 <iunlockput>
      return 0;
    800043ec:	8a4e                	mv	s4,s3
    800043ee:	b7f1                	j	800043ba <namex+0x68>
  len = path - s;
    800043f0:	40998633          	sub	a2,s3,s1
    800043f4:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043f8:	099c5863          	bge	s8,s9,80004488 <namex+0x136>
    memmove(name, s, DIRSIZ);
    800043fc:	4639                	li	a2,14
    800043fe:	85a6                	mv	a1,s1
    80004400:	8556                	mv	a0,s5
    80004402:	ffffd097          	auipc	ra,0xffffd
    80004406:	b2e080e7          	jalr	-1234(ra) # 80000f30 <memmove>
    8000440a:	84ce                	mv	s1,s3
  while(*path == '/')
    8000440c:	0004c783          	lbu	a5,0(s1)
    80004410:	01279763          	bne	a5,s2,8000441e <namex+0xcc>
    path++;
    80004414:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004416:	0004c783          	lbu	a5,0(s1)
    8000441a:	ff278de3          	beq	a5,s2,80004414 <namex+0xc2>
    ilock(ip);
    8000441e:	8552                	mv	a0,s4
    80004420:	00000097          	auipc	ra,0x0
    80004424:	99e080e7          	jalr	-1634(ra) # 80003dbe <ilock>
    if(ip->type != T_DIR){
    80004428:	044a1783          	lh	a5,68(s4)
    8000442c:	f97791e3          	bne	a5,s7,800043ae <namex+0x5c>
    if(nameiparent && *path == '\0'){
    80004430:	000b0563          	beqz	s6,8000443a <namex+0xe8>
    80004434:	0004c783          	lbu	a5,0(s1)
    80004438:	dfd9                	beqz	a5,800043d6 <namex+0x84>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000443a:	4601                	li	a2,0
    8000443c:	85d6                	mv	a1,s5
    8000443e:	8552                	mv	a0,s4
    80004440:	00000097          	auipc	ra,0x0
    80004444:	e62080e7          	jalr	-414(ra) # 800042a2 <dirlookup>
    80004448:	89aa                	mv	s3,a0
    8000444a:	dd41                	beqz	a0,800043e2 <namex+0x90>
    iunlockput(ip);
    8000444c:	8552                	mv	a0,s4
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	bd2080e7          	jalr	-1070(ra) # 80004020 <iunlockput>
    ip = next;
    80004456:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004458:	0004c783          	lbu	a5,0(s1)
    8000445c:	01279763          	bne	a5,s2,8000446a <namex+0x118>
    path++;
    80004460:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004462:	0004c783          	lbu	a5,0(s1)
    80004466:	ff278de3          	beq	a5,s2,80004460 <namex+0x10e>
  if(*path == 0)
    8000446a:	cb9d                	beqz	a5,800044a0 <namex+0x14e>
  while(*path != '/' && *path != 0)
    8000446c:	0004c783          	lbu	a5,0(s1)
    80004470:	89a6                	mv	s3,s1
  len = path - s;
    80004472:	4c81                	li	s9,0
    80004474:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    80004476:	01278963          	beq	a5,s2,80004488 <namex+0x136>
    8000447a:	dbbd                	beqz	a5,800043f0 <namex+0x9e>
    path++;
    8000447c:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    8000447e:	0009c783          	lbu	a5,0(s3)
    80004482:	ff279ce3          	bne	a5,s2,8000447a <namex+0x128>
    80004486:	b7ad                	j	800043f0 <namex+0x9e>
    memmove(name, s, len);
    80004488:	2601                	sext.w	a2,a2
    8000448a:	85a6                	mv	a1,s1
    8000448c:	8556                	mv	a0,s5
    8000448e:	ffffd097          	auipc	ra,0xffffd
    80004492:	aa2080e7          	jalr	-1374(ra) # 80000f30 <memmove>
    name[len] = 0;
    80004496:	9cd6                	add	s9,s9,s5
    80004498:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000449c:	84ce                	mv	s1,s3
    8000449e:	b7bd                	j	8000440c <namex+0xba>
  if(nameiparent){
    800044a0:	f00b0de3          	beqz	s6,800043ba <namex+0x68>
    iput(ip);
    800044a4:	8552                	mv	a0,s4
    800044a6:	00000097          	auipc	ra,0x0
    800044aa:	ad2080e7          	jalr	-1326(ra) # 80003f78 <iput>
    return 0;
    800044ae:	4a01                	li	s4,0
    800044b0:	b729                	j	800043ba <namex+0x68>

00000000800044b2 <dirlink>:
{
    800044b2:	7139                	addi	sp,sp,-64
    800044b4:	fc06                	sd	ra,56(sp)
    800044b6:	f822                	sd	s0,48(sp)
    800044b8:	f426                	sd	s1,40(sp)
    800044ba:	f04a                	sd	s2,32(sp)
    800044bc:	ec4e                	sd	s3,24(sp)
    800044be:	e852                	sd	s4,16(sp)
    800044c0:	0080                	addi	s0,sp,64
    800044c2:	892a                	mv	s2,a0
    800044c4:	8a2e                	mv	s4,a1
    800044c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044c8:	4601                	li	a2,0
    800044ca:	00000097          	auipc	ra,0x0
    800044ce:	dd8080e7          	jalr	-552(ra) # 800042a2 <dirlookup>
    800044d2:	e93d                	bnez	a0,80004548 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044d4:	04c92483          	lw	s1,76(s2)
    800044d8:	c49d                	beqz	s1,80004506 <dirlink+0x54>
    800044da:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044dc:	4741                	li	a4,16
    800044de:	86a6                	mv	a3,s1
    800044e0:	fc040613          	addi	a2,s0,-64
    800044e4:	4581                	li	a1,0
    800044e6:	854a                	mv	a0,s2
    800044e8:	00000097          	auipc	ra,0x0
    800044ec:	b8a080e7          	jalr	-1142(ra) # 80004072 <readi>
    800044f0:	47c1                	li	a5,16
    800044f2:	06f51163          	bne	a0,a5,80004554 <dirlink+0xa2>
    if(de.inum == 0)
    800044f6:	fc045783          	lhu	a5,-64(s0)
    800044fa:	c791                	beqz	a5,80004506 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044fc:	24c1                	addiw	s1,s1,16
    800044fe:	04c92783          	lw	a5,76(s2)
    80004502:	fcf4ede3          	bltu	s1,a5,800044dc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004506:	4639                	li	a2,14
    80004508:	85d2                	mv	a1,s4
    8000450a:	fc240513          	addi	a0,s0,-62
    8000450e:	ffffd097          	auipc	ra,0xffffd
    80004512:	ad2080e7          	jalr	-1326(ra) # 80000fe0 <strncpy>
  de.inum = inum;
    80004516:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000451a:	4741                	li	a4,16
    8000451c:	86a6                	mv	a3,s1
    8000451e:	fc040613          	addi	a2,s0,-64
    80004522:	4581                	li	a1,0
    80004524:	854a                	mv	a0,s2
    80004526:	00000097          	auipc	ra,0x0
    8000452a:	c44080e7          	jalr	-956(ra) # 8000416a <writei>
    8000452e:	1541                	addi	a0,a0,-16
    80004530:	00a03533          	snez	a0,a0
    80004534:	40a00533          	neg	a0,a0
}
    80004538:	70e2                	ld	ra,56(sp)
    8000453a:	7442                	ld	s0,48(sp)
    8000453c:	74a2                	ld	s1,40(sp)
    8000453e:	7902                	ld	s2,32(sp)
    80004540:	69e2                	ld	s3,24(sp)
    80004542:	6a42                	ld	s4,16(sp)
    80004544:	6121                	addi	sp,sp,64
    80004546:	8082                	ret
    iput(ip);
    80004548:	00000097          	auipc	ra,0x0
    8000454c:	a30080e7          	jalr	-1488(ra) # 80003f78 <iput>
    return -1;
    80004550:	557d                	li	a0,-1
    80004552:	b7dd                	j	80004538 <dirlink+0x86>
      panic("dirlink read");
    80004554:	00004517          	auipc	a0,0x4
    80004558:	2c450513          	addi	a0,a0,708 # 80008818 <syscalls+0x208>
    8000455c:	ffffc097          	auipc	ra,0xffffc
    80004560:	fe0080e7          	jalr	-32(ra) # 8000053c <panic>

0000000080004564 <namei>:

struct inode*
namei(char *path)
{
    80004564:	1101                	addi	sp,sp,-32
    80004566:	ec06                	sd	ra,24(sp)
    80004568:	e822                	sd	s0,16(sp)
    8000456a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000456c:	fe040613          	addi	a2,s0,-32
    80004570:	4581                	li	a1,0
    80004572:	00000097          	auipc	ra,0x0
    80004576:	de0080e7          	jalr	-544(ra) # 80004352 <namex>
}
    8000457a:	60e2                	ld	ra,24(sp)
    8000457c:	6442                	ld	s0,16(sp)
    8000457e:	6105                	addi	sp,sp,32
    80004580:	8082                	ret

0000000080004582 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004582:	1141                	addi	sp,sp,-16
    80004584:	e406                	sd	ra,8(sp)
    80004586:	e022                	sd	s0,0(sp)
    80004588:	0800                	addi	s0,sp,16
    8000458a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000458c:	4585                	li	a1,1
    8000458e:	00000097          	auipc	ra,0x0
    80004592:	dc4080e7          	jalr	-572(ra) # 80004352 <namex>
}
    80004596:	60a2                	ld	ra,8(sp)
    80004598:	6402                	ld	s0,0(sp)
    8000459a:	0141                	addi	sp,sp,16
    8000459c:	8082                	ret

000000008000459e <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    8000459e:	1101                	addi	sp,sp,-32
    800045a0:	ec06                	sd	ra,24(sp)
    800045a2:	e822                	sd	s0,16(sp)
    800045a4:	e426                	sd	s1,8(sp)
    800045a6:	e04a                	sd	s2,0(sp)
    800045a8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045aa:	0023c917          	auipc	s2,0x23c
    800045ae:	79690913          	addi	s2,s2,1942 # 80240d40 <log>
    800045b2:	01892583          	lw	a1,24(s2)
    800045b6:	02892503          	lw	a0,40(s2)
    800045ba:	fffff097          	auipc	ra,0xfffff
    800045be:	ff4080e7          	jalr	-12(ra) # 800035ae <bread>
    800045c2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045c4:	02c92603          	lw	a2,44(s2)
    800045c8:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045ca:	00c05f63          	blez	a2,800045e8 <write_head+0x4a>
    800045ce:	0023c717          	auipc	a4,0x23c
    800045d2:	7a270713          	addi	a4,a4,1954 # 80240d70 <log+0x30>
    800045d6:	87aa                	mv	a5,a0
    800045d8:	060a                	slli	a2,a2,0x2
    800045da:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    800045dc:	4314                	lw	a3,0(a4)
    800045de:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    800045e0:	0711                	addi	a4,a4,4
    800045e2:	0791                	addi	a5,a5,4
    800045e4:	fec79ce3          	bne	a5,a2,800045dc <write_head+0x3e>
  }
  bwrite(buf);
    800045e8:	8526                	mv	a0,s1
    800045ea:	fffff097          	auipc	ra,0xfffff
    800045ee:	0b6080e7          	jalr	182(ra) # 800036a0 <bwrite>
  brelse(buf);
    800045f2:	8526                	mv	a0,s1
    800045f4:	fffff097          	auipc	ra,0xfffff
    800045f8:	0ea080e7          	jalr	234(ra) # 800036de <brelse>
}
    800045fc:	60e2                	ld	ra,24(sp)
    800045fe:	6442                	ld	s0,16(sp)
    80004600:	64a2                	ld	s1,8(sp)
    80004602:	6902                	ld	s2,0(sp)
    80004604:	6105                	addi	sp,sp,32
    80004606:	8082                	ret

0000000080004608 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004608:	0023c797          	auipc	a5,0x23c
    8000460c:	7647a783          	lw	a5,1892(a5) # 80240d6c <log+0x2c>
    80004610:	0af05d63          	blez	a5,800046ca <install_trans+0xc2>
{
    80004614:	7139                	addi	sp,sp,-64
    80004616:	fc06                	sd	ra,56(sp)
    80004618:	f822                	sd	s0,48(sp)
    8000461a:	f426                	sd	s1,40(sp)
    8000461c:	f04a                	sd	s2,32(sp)
    8000461e:	ec4e                	sd	s3,24(sp)
    80004620:	e852                	sd	s4,16(sp)
    80004622:	e456                	sd	s5,8(sp)
    80004624:	e05a                	sd	s6,0(sp)
    80004626:	0080                	addi	s0,sp,64
    80004628:	8b2a                	mv	s6,a0
    8000462a:	0023ca97          	auipc	s5,0x23c
    8000462e:	746a8a93          	addi	s5,s5,1862 # 80240d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004632:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004634:	0023c997          	auipc	s3,0x23c
    80004638:	70c98993          	addi	s3,s3,1804 # 80240d40 <log>
    8000463c:	a00d                	j	8000465e <install_trans+0x56>
    brelse(lbuf);
    8000463e:	854a                	mv	a0,s2
    80004640:	fffff097          	auipc	ra,0xfffff
    80004644:	09e080e7          	jalr	158(ra) # 800036de <brelse>
    brelse(dbuf);
    80004648:	8526                	mv	a0,s1
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	094080e7          	jalr	148(ra) # 800036de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004652:	2a05                	addiw	s4,s4,1
    80004654:	0a91                	addi	s5,s5,4
    80004656:	02c9a783          	lw	a5,44(s3)
    8000465a:	04fa5e63          	bge	s4,a5,800046b6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000465e:	0189a583          	lw	a1,24(s3)
    80004662:	014585bb          	addw	a1,a1,s4
    80004666:	2585                	addiw	a1,a1,1
    80004668:	0289a503          	lw	a0,40(s3)
    8000466c:	fffff097          	auipc	ra,0xfffff
    80004670:	f42080e7          	jalr	-190(ra) # 800035ae <bread>
    80004674:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004676:	000aa583          	lw	a1,0(s5)
    8000467a:	0289a503          	lw	a0,40(s3)
    8000467e:	fffff097          	auipc	ra,0xfffff
    80004682:	f30080e7          	jalr	-208(ra) # 800035ae <bread>
    80004686:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004688:	40000613          	li	a2,1024
    8000468c:	05890593          	addi	a1,s2,88
    80004690:	05850513          	addi	a0,a0,88
    80004694:	ffffd097          	auipc	ra,0xffffd
    80004698:	89c080e7          	jalr	-1892(ra) # 80000f30 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000469c:	8526                	mv	a0,s1
    8000469e:	fffff097          	auipc	ra,0xfffff
    800046a2:	002080e7          	jalr	2(ra) # 800036a0 <bwrite>
    if(recovering == 0)
    800046a6:	f80b1ce3          	bnez	s6,8000463e <install_trans+0x36>
      bunpin(dbuf);
    800046aa:	8526                	mv	a0,s1
    800046ac:	fffff097          	auipc	ra,0xfffff
    800046b0:	10a080e7          	jalr	266(ra) # 800037b6 <bunpin>
    800046b4:	b769                	j	8000463e <install_trans+0x36>
}
    800046b6:	70e2                	ld	ra,56(sp)
    800046b8:	7442                	ld	s0,48(sp)
    800046ba:	74a2                	ld	s1,40(sp)
    800046bc:	7902                	ld	s2,32(sp)
    800046be:	69e2                	ld	s3,24(sp)
    800046c0:	6a42                	ld	s4,16(sp)
    800046c2:	6aa2                	ld	s5,8(sp)
    800046c4:	6b02                	ld	s6,0(sp)
    800046c6:	6121                	addi	sp,sp,64
    800046c8:	8082                	ret
    800046ca:	8082                	ret

00000000800046cc <initlog>:
{
    800046cc:	7179                	addi	sp,sp,-48
    800046ce:	f406                	sd	ra,40(sp)
    800046d0:	f022                	sd	s0,32(sp)
    800046d2:	ec26                	sd	s1,24(sp)
    800046d4:	e84a                	sd	s2,16(sp)
    800046d6:	e44e                	sd	s3,8(sp)
    800046d8:	1800                	addi	s0,sp,48
    800046da:	892a                	mv	s2,a0
    800046dc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046de:	0023c497          	auipc	s1,0x23c
    800046e2:	66248493          	addi	s1,s1,1634 # 80240d40 <log>
    800046e6:	00004597          	auipc	a1,0x4
    800046ea:	14258593          	addi	a1,a1,322 # 80008828 <syscalls+0x218>
    800046ee:	8526                	mv	a0,s1
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	658080e7          	jalr	1624(ra) # 80000d48 <initlock>
  log.start = sb->logstart;
    800046f8:	0149a583          	lw	a1,20(s3)
    800046fc:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800046fe:	0109a783          	lw	a5,16(s3)
    80004702:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004704:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004708:	854a                	mv	a0,s2
    8000470a:	fffff097          	auipc	ra,0xfffff
    8000470e:	ea4080e7          	jalr	-348(ra) # 800035ae <bread>
  log.lh.n = lh->n;
    80004712:	4d30                	lw	a2,88(a0)
    80004714:	d4d0                	sw	a2,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004716:	00c05f63          	blez	a2,80004734 <initlog+0x68>
    8000471a:	87aa                	mv	a5,a0
    8000471c:	0023c717          	auipc	a4,0x23c
    80004720:	65470713          	addi	a4,a4,1620 # 80240d70 <log+0x30>
    80004724:	060a                	slli	a2,a2,0x2
    80004726:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80004728:	4ff4                	lw	a3,92(a5)
    8000472a:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000472c:	0791                	addi	a5,a5,4
    8000472e:	0711                	addi	a4,a4,4
    80004730:	fec79ce3          	bne	a5,a2,80004728 <initlog+0x5c>
  brelse(buf);
    80004734:	fffff097          	auipc	ra,0xfffff
    80004738:	faa080e7          	jalr	-86(ra) # 800036de <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000473c:	4505                	li	a0,1
    8000473e:	00000097          	auipc	ra,0x0
    80004742:	eca080e7          	jalr	-310(ra) # 80004608 <install_trans>
  log.lh.n = 0;
    80004746:	0023c797          	auipc	a5,0x23c
    8000474a:	6207a323          	sw	zero,1574(a5) # 80240d6c <log+0x2c>
  write_head(); // clear the log
    8000474e:	00000097          	auipc	ra,0x0
    80004752:	e50080e7          	jalr	-432(ra) # 8000459e <write_head>
}
    80004756:	70a2                	ld	ra,40(sp)
    80004758:	7402                	ld	s0,32(sp)
    8000475a:	64e2                	ld	s1,24(sp)
    8000475c:	6942                	ld	s2,16(sp)
    8000475e:	69a2                	ld	s3,8(sp)
    80004760:	6145                	addi	sp,sp,48
    80004762:	8082                	ret

0000000080004764 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004764:	1101                	addi	sp,sp,-32
    80004766:	ec06                	sd	ra,24(sp)
    80004768:	e822                	sd	s0,16(sp)
    8000476a:	e426                	sd	s1,8(sp)
    8000476c:	e04a                	sd	s2,0(sp)
    8000476e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004770:	0023c517          	auipc	a0,0x23c
    80004774:	5d050513          	addi	a0,a0,1488 # 80240d40 <log>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	660080e7          	jalr	1632(ra) # 80000dd8 <acquire>
  while(1){
    if(log.committing){
    80004780:	0023c497          	auipc	s1,0x23c
    80004784:	5c048493          	addi	s1,s1,1472 # 80240d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004788:	4979                	li	s2,30
    8000478a:	a039                	j	80004798 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000478c:	85a6                	mv	a1,s1
    8000478e:	8526                	mv	a0,s1
    80004790:	ffffe097          	auipc	ra,0xffffe
    80004794:	d44080e7          	jalr	-700(ra) # 800024d4 <sleep>
    if(log.committing){
    80004798:	50dc                	lw	a5,36(s1)
    8000479a:	fbed                	bnez	a5,8000478c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000479c:	5098                	lw	a4,32(s1)
    8000479e:	2705                	addiw	a4,a4,1
    800047a0:	0027179b          	slliw	a5,a4,0x2
    800047a4:	9fb9                	addw	a5,a5,a4
    800047a6:	0017979b          	slliw	a5,a5,0x1
    800047aa:	54d4                	lw	a3,44(s1)
    800047ac:	9fb5                	addw	a5,a5,a3
    800047ae:	00f95963          	bge	s2,a5,800047c0 <begin_op+0x5c>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047b2:	85a6                	mv	a1,s1
    800047b4:	8526                	mv	a0,s1
    800047b6:	ffffe097          	auipc	ra,0xffffe
    800047ba:	d1e080e7          	jalr	-738(ra) # 800024d4 <sleep>
    800047be:	bfe9                	j	80004798 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047c0:	0023c517          	auipc	a0,0x23c
    800047c4:	58050513          	addi	a0,a0,1408 # 80240d40 <log>
    800047c8:	d118                	sw	a4,32(a0)
      release(&log.lock);
    800047ca:	ffffc097          	auipc	ra,0xffffc
    800047ce:	6c2080e7          	jalr	1730(ra) # 80000e8c <release>
      break;
    }
  }
}
    800047d2:	60e2                	ld	ra,24(sp)
    800047d4:	6442                	ld	s0,16(sp)
    800047d6:	64a2                	ld	s1,8(sp)
    800047d8:	6902                	ld	s2,0(sp)
    800047da:	6105                	addi	sp,sp,32
    800047dc:	8082                	ret

00000000800047de <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047de:	7139                	addi	sp,sp,-64
    800047e0:	fc06                	sd	ra,56(sp)
    800047e2:	f822                	sd	s0,48(sp)
    800047e4:	f426                	sd	s1,40(sp)
    800047e6:	f04a                	sd	s2,32(sp)
    800047e8:	ec4e                	sd	s3,24(sp)
    800047ea:	e852                	sd	s4,16(sp)
    800047ec:	e456                	sd	s5,8(sp)
    800047ee:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800047f0:	0023c497          	auipc	s1,0x23c
    800047f4:	55048493          	addi	s1,s1,1360 # 80240d40 <log>
    800047f8:	8526                	mv	a0,s1
    800047fa:	ffffc097          	auipc	ra,0xffffc
    800047fe:	5de080e7          	jalr	1502(ra) # 80000dd8 <acquire>
  log.outstanding -= 1;
    80004802:	509c                	lw	a5,32(s1)
    80004804:	37fd                	addiw	a5,a5,-1
    80004806:	0007891b          	sext.w	s2,a5
    8000480a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000480c:	50dc                	lw	a5,36(s1)
    8000480e:	e7b9                	bnez	a5,8000485c <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004810:	04091e63          	bnez	s2,8000486c <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004814:	0023c497          	auipc	s1,0x23c
    80004818:	52c48493          	addi	s1,s1,1324 # 80240d40 <log>
    8000481c:	4785                	li	a5,1
    8000481e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004820:	8526                	mv	a0,s1
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	66a080e7          	jalr	1642(ra) # 80000e8c <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000482a:	54dc                	lw	a5,44(s1)
    8000482c:	06f04763          	bgtz	a5,8000489a <end_op+0xbc>
    acquire(&log.lock);
    80004830:	0023c497          	auipc	s1,0x23c
    80004834:	51048493          	addi	s1,s1,1296 # 80240d40 <log>
    80004838:	8526                	mv	a0,s1
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	59e080e7          	jalr	1438(ra) # 80000dd8 <acquire>
    log.committing = 0;
    80004842:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004846:	8526                	mv	a0,s1
    80004848:	ffffe097          	auipc	ra,0xffffe
    8000484c:	cf0080e7          	jalr	-784(ra) # 80002538 <wakeup>
    release(&log.lock);
    80004850:	8526                	mv	a0,s1
    80004852:	ffffc097          	auipc	ra,0xffffc
    80004856:	63a080e7          	jalr	1594(ra) # 80000e8c <release>
}
    8000485a:	a03d                	j	80004888 <end_op+0xaa>
    panic("log.committing");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	fd450513          	addi	a0,a0,-44 # 80008830 <syscalls+0x220>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	cd8080e7          	jalr	-808(ra) # 8000053c <panic>
    wakeup(&log);
    8000486c:	0023c497          	auipc	s1,0x23c
    80004870:	4d448493          	addi	s1,s1,1236 # 80240d40 <log>
    80004874:	8526                	mv	a0,s1
    80004876:	ffffe097          	auipc	ra,0xffffe
    8000487a:	cc2080e7          	jalr	-830(ra) # 80002538 <wakeup>
  release(&log.lock);
    8000487e:	8526                	mv	a0,s1
    80004880:	ffffc097          	auipc	ra,0xffffc
    80004884:	60c080e7          	jalr	1548(ra) # 80000e8c <release>
}
    80004888:	70e2                	ld	ra,56(sp)
    8000488a:	7442                	ld	s0,48(sp)
    8000488c:	74a2                	ld	s1,40(sp)
    8000488e:	7902                	ld	s2,32(sp)
    80004890:	69e2                	ld	s3,24(sp)
    80004892:	6a42                	ld	s4,16(sp)
    80004894:	6aa2                	ld	s5,8(sp)
    80004896:	6121                	addi	sp,sp,64
    80004898:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000489a:	0023ca97          	auipc	s5,0x23c
    8000489e:	4d6a8a93          	addi	s5,s5,1238 # 80240d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048a2:	0023ca17          	auipc	s4,0x23c
    800048a6:	49ea0a13          	addi	s4,s4,1182 # 80240d40 <log>
    800048aa:	018a2583          	lw	a1,24(s4)
    800048ae:	012585bb          	addw	a1,a1,s2
    800048b2:	2585                	addiw	a1,a1,1
    800048b4:	028a2503          	lw	a0,40(s4)
    800048b8:	fffff097          	auipc	ra,0xfffff
    800048bc:	cf6080e7          	jalr	-778(ra) # 800035ae <bread>
    800048c0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048c2:	000aa583          	lw	a1,0(s5)
    800048c6:	028a2503          	lw	a0,40(s4)
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	ce4080e7          	jalr	-796(ra) # 800035ae <bread>
    800048d2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048d4:	40000613          	li	a2,1024
    800048d8:	05850593          	addi	a1,a0,88
    800048dc:	05848513          	addi	a0,s1,88
    800048e0:	ffffc097          	auipc	ra,0xffffc
    800048e4:	650080e7          	jalr	1616(ra) # 80000f30 <memmove>
    bwrite(to);  // write the log
    800048e8:	8526                	mv	a0,s1
    800048ea:	fffff097          	auipc	ra,0xfffff
    800048ee:	db6080e7          	jalr	-586(ra) # 800036a0 <bwrite>
    brelse(from);
    800048f2:	854e                	mv	a0,s3
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	dea080e7          	jalr	-534(ra) # 800036de <brelse>
    brelse(to);
    800048fc:	8526                	mv	a0,s1
    800048fe:	fffff097          	auipc	ra,0xfffff
    80004902:	de0080e7          	jalr	-544(ra) # 800036de <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004906:	2905                	addiw	s2,s2,1
    80004908:	0a91                	addi	s5,s5,4
    8000490a:	02ca2783          	lw	a5,44(s4)
    8000490e:	f8f94ee3          	blt	s2,a5,800048aa <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004912:	00000097          	auipc	ra,0x0
    80004916:	c8c080e7          	jalr	-884(ra) # 8000459e <write_head>
    install_trans(0); // Now install writes to home locations
    8000491a:	4501                	li	a0,0
    8000491c:	00000097          	auipc	ra,0x0
    80004920:	cec080e7          	jalr	-788(ra) # 80004608 <install_trans>
    log.lh.n = 0;
    80004924:	0023c797          	auipc	a5,0x23c
    80004928:	4407a423          	sw	zero,1096(a5) # 80240d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	c72080e7          	jalr	-910(ra) # 8000459e <write_head>
    80004934:	bdf5                	j	80004830 <end_op+0x52>

0000000080004936 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004936:	1101                	addi	sp,sp,-32
    80004938:	ec06                	sd	ra,24(sp)
    8000493a:	e822                	sd	s0,16(sp)
    8000493c:	e426                	sd	s1,8(sp)
    8000493e:	e04a                	sd	s2,0(sp)
    80004940:	1000                	addi	s0,sp,32
    80004942:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004944:	0023c917          	auipc	s2,0x23c
    80004948:	3fc90913          	addi	s2,s2,1020 # 80240d40 <log>
    8000494c:	854a                	mv	a0,s2
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	48a080e7          	jalr	1162(ra) # 80000dd8 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004956:	02c92603          	lw	a2,44(s2)
    8000495a:	47f5                	li	a5,29
    8000495c:	06c7c563          	blt	a5,a2,800049c6 <log_write+0x90>
    80004960:	0023c797          	auipc	a5,0x23c
    80004964:	3fc7a783          	lw	a5,1020(a5) # 80240d5c <log+0x1c>
    80004968:	37fd                	addiw	a5,a5,-1
    8000496a:	04f65e63          	bge	a2,a5,800049c6 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000496e:	0023c797          	auipc	a5,0x23c
    80004972:	3f27a783          	lw	a5,1010(a5) # 80240d60 <log+0x20>
    80004976:	06f05063          	blez	a5,800049d6 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000497a:	4781                	li	a5,0
    8000497c:	06c05563          	blez	a2,800049e6 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004980:	44cc                	lw	a1,12(s1)
    80004982:	0023c717          	auipc	a4,0x23c
    80004986:	3ee70713          	addi	a4,a4,1006 # 80240d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000498a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000498c:	4314                	lw	a3,0(a4)
    8000498e:	04b68c63          	beq	a3,a1,800049e6 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004992:	2785                	addiw	a5,a5,1
    80004994:	0711                	addi	a4,a4,4
    80004996:	fef61be3          	bne	a2,a5,8000498c <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000499a:	0621                	addi	a2,a2,8
    8000499c:	060a                	slli	a2,a2,0x2
    8000499e:	0023c797          	auipc	a5,0x23c
    800049a2:	3a278793          	addi	a5,a5,930 # 80240d40 <log>
    800049a6:	97b2                	add	a5,a5,a2
    800049a8:	44d8                	lw	a4,12(s1)
    800049aa:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049ac:	8526                	mv	a0,s1
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	dcc080e7          	jalr	-564(ra) # 8000377a <bpin>
    log.lh.n++;
    800049b6:	0023c717          	auipc	a4,0x23c
    800049ba:	38a70713          	addi	a4,a4,906 # 80240d40 <log>
    800049be:	575c                	lw	a5,44(a4)
    800049c0:	2785                	addiw	a5,a5,1
    800049c2:	d75c                	sw	a5,44(a4)
    800049c4:	a82d                	j	800049fe <log_write+0xc8>
    panic("too big a transaction");
    800049c6:	00004517          	auipc	a0,0x4
    800049ca:	e7a50513          	addi	a0,a0,-390 # 80008840 <syscalls+0x230>
    800049ce:	ffffc097          	auipc	ra,0xffffc
    800049d2:	b6e080e7          	jalr	-1170(ra) # 8000053c <panic>
    panic("log_write outside of trans");
    800049d6:	00004517          	auipc	a0,0x4
    800049da:	e8250513          	addi	a0,a0,-382 # 80008858 <syscalls+0x248>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	b5e080e7          	jalr	-1186(ra) # 8000053c <panic>
  log.lh.block[i] = b->blockno;
    800049e6:	00878693          	addi	a3,a5,8
    800049ea:	068a                	slli	a3,a3,0x2
    800049ec:	0023c717          	auipc	a4,0x23c
    800049f0:	35470713          	addi	a4,a4,852 # 80240d40 <log>
    800049f4:	9736                	add	a4,a4,a3
    800049f6:	44d4                	lw	a3,12(s1)
    800049f8:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800049fa:	faf609e3          	beq	a2,a5,800049ac <log_write+0x76>
  }
  release(&log.lock);
    800049fe:	0023c517          	auipc	a0,0x23c
    80004a02:	34250513          	addi	a0,a0,834 # 80240d40 <log>
    80004a06:	ffffc097          	auipc	ra,0xffffc
    80004a0a:	486080e7          	jalr	1158(ra) # 80000e8c <release>
}
    80004a0e:	60e2                	ld	ra,24(sp)
    80004a10:	6442                	ld	s0,16(sp)
    80004a12:	64a2                	ld	s1,8(sp)
    80004a14:	6902                	ld	s2,0(sp)
    80004a16:	6105                	addi	sp,sp,32
    80004a18:	8082                	ret

0000000080004a1a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a1a:	1101                	addi	sp,sp,-32
    80004a1c:	ec06                	sd	ra,24(sp)
    80004a1e:	e822                	sd	s0,16(sp)
    80004a20:	e426                	sd	s1,8(sp)
    80004a22:	e04a                	sd	s2,0(sp)
    80004a24:	1000                	addi	s0,sp,32
    80004a26:	84aa                	mv	s1,a0
    80004a28:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a2a:	00004597          	auipc	a1,0x4
    80004a2e:	e4e58593          	addi	a1,a1,-434 # 80008878 <syscalls+0x268>
    80004a32:	0521                	addi	a0,a0,8
    80004a34:	ffffc097          	auipc	ra,0xffffc
    80004a38:	314080e7          	jalr	788(ra) # 80000d48 <initlock>
  lk->name = name;
    80004a3c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a40:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a44:	0204a423          	sw	zero,40(s1)
}
    80004a48:	60e2                	ld	ra,24(sp)
    80004a4a:	6442                	ld	s0,16(sp)
    80004a4c:	64a2                	ld	s1,8(sp)
    80004a4e:	6902                	ld	s2,0(sp)
    80004a50:	6105                	addi	sp,sp,32
    80004a52:	8082                	ret

0000000080004a54 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a54:	1101                	addi	sp,sp,-32
    80004a56:	ec06                	sd	ra,24(sp)
    80004a58:	e822                	sd	s0,16(sp)
    80004a5a:	e426                	sd	s1,8(sp)
    80004a5c:	e04a                	sd	s2,0(sp)
    80004a5e:	1000                	addi	s0,sp,32
    80004a60:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a62:	00850913          	addi	s2,a0,8
    80004a66:	854a                	mv	a0,s2
    80004a68:	ffffc097          	auipc	ra,0xffffc
    80004a6c:	370080e7          	jalr	880(ra) # 80000dd8 <acquire>
  while (lk->locked) {
    80004a70:	409c                	lw	a5,0(s1)
    80004a72:	cb89                	beqz	a5,80004a84 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a74:	85ca                	mv	a1,s2
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffe097          	auipc	ra,0xffffe
    80004a7c:	a5c080e7          	jalr	-1444(ra) # 800024d4 <sleep>
  while (lk->locked) {
    80004a80:	409c                	lw	a5,0(s1)
    80004a82:	fbed                	bnez	a5,80004a74 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004a84:	4785                	li	a5,1
    80004a86:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004a88:	ffffd097          	auipc	ra,0xffffd
    80004a8c:	2e4080e7          	jalr	740(ra) # 80001d6c <myproc>
    80004a90:	591c                	lw	a5,48(a0)
    80004a92:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004a94:	854a                	mv	a0,s2
    80004a96:	ffffc097          	auipc	ra,0xffffc
    80004a9a:	3f6080e7          	jalr	1014(ra) # 80000e8c <release>
}
    80004a9e:	60e2                	ld	ra,24(sp)
    80004aa0:	6442                	ld	s0,16(sp)
    80004aa2:	64a2                	ld	s1,8(sp)
    80004aa4:	6902                	ld	s2,0(sp)
    80004aa6:	6105                	addi	sp,sp,32
    80004aa8:	8082                	ret

0000000080004aaa <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004aaa:	1101                	addi	sp,sp,-32
    80004aac:	ec06                	sd	ra,24(sp)
    80004aae:	e822                	sd	s0,16(sp)
    80004ab0:	e426                	sd	s1,8(sp)
    80004ab2:	e04a                	sd	s2,0(sp)
    80004ab4:	1000                	addi	s0,sp,32
    80004ab6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ab8:	00850913          	addi	s2,a0,8
    80004abc:	854a                	mv	a0,s2
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	31a080e7          	jalr	794(ra) # 80000dd8 <acquire>
  lk->locked = 0;
    80004ac6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004aca:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004ace:	8526                	mv	a0,s1
    80004ad0:	ffffe097          	auipc	ra,0xffffe
    80004ad4:	a68080e7          	jalr	-1432(ra) # 80002538 <wakeup>
  release(&lk->lk);
    80004ad8:	854a                	mv	a0,s2
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	3b2080e7          	jalr	946(ra) # 80000e8c <release>
}
    80004ae2:	60e2                	ld	ra,24(sp)
    80004ae4:	6442                	ld	s0,16(sp)
    80004ae6:	64a2                	ld	s1,8(sp)
    80004ae8:	6902                	ld	s2,0(sp)
    80004aea:	6105                	addi	sp,sp,32
    80004aec:	8082                	ret

0000000080004aee <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004aee:	7179                	addi	sp,sp,-48
    80004af0:	f406                	sd	ra,40(sp)
    80004af2:	f022                	sd	s0,32(sp)
    80004af4:	ec26                	sd	s1,24(sp)
    80004af6:	e84a                	sd	s2,16(sp)
    80004af8:	e44e                	sd	s3,8(sp)
    80004afa:	1800                	addi	s0,sp,48
    80004afc:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004afe:	00850913          	addi	s2,a0,8
    80004b02:	854a                	mv	a0,s2
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	2d4080e7          	jalr	724(ra) # 80000dd8 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b0c:	409c                	lw	a5,0(s1)
    80004b0e:	ef99                	bnez	a5,80004b2c <holdingsleep+0x3e>
    80004b10:	4481                	li	s1,0
  release(&lk->lk);
    80004b12:	854a                	mv	a0,s2
    80004b14:	ffffc097          	auipc	ra,0xffffc
    80004b18:	378080e7          	jalr	888(ra) # 80000e8c <release>
  return r;
}
    80004b1c:	8526                	mv	a0,s1
    80004b1e:	70a2                	ld	ra,40(sp)
    80004b20:	7402                	ld	s0,32(sp)
    80004b22:	64e2                	ld	s1,24(sp)
    80004b24:	6942                	ld	s2,16(sp)
    80004b26:	69a2                	ld	s3,8(sp)
    80004b28:	6145                	addi	sp,sp,48
    80004b2a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b2c:	0284a983          	lw	s3,40(s1)
    80004b30:	ffffd097          	auipc	ra,0xffffd
    80004b34:	23c080e7          	jalr	572(ra) # 80001d6c <myproc>
    80004b38:	5904                	lw	s1,48(a0)
    80004b3a:	413484b3          	sub	s1,s1,s3
    80004b3e:	0014b493          	seqz	s1,s1
    80004b42:	bfc1                	j	80004b12 <holdingsleep+0x24>

0000000080004b44 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b44:	1141                	addi	sp,sp,-16
    80004b46:	e406                	sd	ra,8(sp)
    80004b48:	e022                	sd	s0,0(sp)
    80004b4a:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b4c:	00004597          	auipc	a1,0x4
    80004b50:	d3c58593          	addi	a1,a1,-708 # 80008888 <syscalls+0x278>
    80004b54:	0023c517          	auipc	a0,0x23c
    80004b58:	33450513          	addi	a0,a0,820 # 80240e88 <ftable>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	1ec080e7          	jalr	492(ra) # 80000d48 <initlock>
}
    80004b64:	60a2                	ld	ra,8(sp)
    80004b66:	6402                	ld	s0,0(sp)
    80004b68:	0141                	addi	sp,sp,16
    80004b6a:	8082                	ret

0000000080004b6c <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b6c:	1101                	addi	sp,sp,-32
    80004b6e:	ec06                	sd	ra,24(sp)
    80004b70:	e822                	sd	s0,16(sp)
    80004b72:	e426                	sd	s1,8(sp)
    80004b74:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b76:	0023c517          	auipc	a0,0x23c
    80004b7a:	31250513          	addi	a0,a0,786 # 80240e88 <ftable>
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	25a080e7          	jalr	602(ra) # 80000dd8 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b86:	0023c497          	auipc	s1,0x23c
    80004b8a:	31a48493          	addi	s1,s1,794 # 80240ea0 <ftable+0x18>
    80004b8e:	0023d717          	auipc	a4,0x23d
    80004b92:	2b270713          	addi	a4,a4,690 # 80241e40 <disk>
    if(f->ref == 0){
    80004b96:	40dc                	lw	a5,4(s1)
    80004b98:	cf99                	beqz	a5,80004bb6 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004b9a:	02848493          	addi	s1,s1,40
    80004b9e:	fee49ce3          	bne	s1,a4,80004b96 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004ba2:	0023c517          	auipc	a0,0x23c
    80004ba6:	2e650513          	addi	a0,a0,742 # 80240e88 <ftable>
    80004baa:	ffffc097          	auipc	ra,0xffffc
    80004bae:	2e2080e7          	jalr	738(ra) # 80000e8c <release>
  return 0;
    80004bb2:	4481                	li	s1,0
    80004bb4:	a819                	j	80004bca <filealloc+0x5e>
      f->ref = 1;
    80004bb6:	4785                	li	a5,1
    80004bb8:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bba:	0023c517          	auipc	a0,0x23c
    80004bbe:	2ce50513          	addi	a0,a0,718 # 80240e88 <ftable>
    80004bc2:	ffffc097          	auipc	ra,0xffffc
    80004bc6:	2ca080e7          	jalr	714(ra) # 80000e8c <release>
}
    80004bca:	8526                	mv	a0,s1
    80004bcc:	60e2                	ld	ra,24(sp)
    80004bce:	6442                	ld	s0,16(sp)
    80004bd0:	64a2                	ld	s1,8(sp)
    80004bd2:	6105                	addi	sp,sp,32
    80004bd4:	8082                	ret

0000000080004bd6 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bd6:	1101                	addi	sp,sp,-32
    80004bd8:	ec06                	sd	ra,24(sp)
    80004bda:	e822                	sd	s0,16(sp)
    80004bdc:	e426                	sd	s1,8(sp)
    80004bde:	1000                	addi	s0,sp,32
    80004be0:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004be2:	0023c517          	auipc	a0,0x23c
    80004be6:	2a650513          	addi	a0,a0,678 # 80240e88 <ftable>
    80004bea:	ffffc097          	auipc	ra,0xffffc
    80004bee:	1ee080e7          	jalr	494(ra) # 80000dd8 <acquire>
  if(f->ref < 1)
    80004bf2:	40dc                	lw	a5,4(s1)
    80004bf4:	02f05263          	blez	a5,80004c18 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004bf8:	2785                	addiw	a5,a5,1
    80004bfa:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004bfc:	0023c517          	auipc	a0,0x23c
    80004c00:	28c50513          	addi	a0,a0,652 # 80240e88 <ftable>
    80004c04:	ffffc097          	auipc	ra,0xffffc
    80004c08:	288080e7          	jalr	648(ra) # 80000e8c <release>
  return f;
}
    80004c0c:	8526                	mv	a0,s1
    80004c0e:	60e2                	ld	ra,24(sp)
    80004c10:	6442                	ld	s0,16(sp)
    80004c12:	64a2                	ld	s1,8(sp)
    80004c14:	6105                	addi	sp,sp,32
    80004c16:	8082                	ret
    panic("filedup");
    80004c18:	00004517          	auipc	a0,0x4
    80004c1c:	c7850513          	addi	a0,a0,-904 # 80008890 <syscalls+0x280>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	91c080e7          	jalr	-1764(ra) # 8000053c <panic>

0000000080004c28 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c28:	7139                	addi	sp,sp,-64
    80004c2a:	fc06                	sd	ra,56(sp)
    80004c2c:	f822                	sd	s0,48(sp)
    80004c2e:	f426                	sd	s1,40(sp)
    80004c30:	f04a                	sd	s2,32(sp)
    80004c32:	ec4e                	sd	s3,24(sp)
    80004c34:	e852                	sd	s4,16(sp)
    80004c36:	e456                	sd	s5,8(sp)
    80004c38:	0080                	addi	s0,sp,64
    80004c3a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c3c:	0023c517          	auipc	a0,0x23c
    80004c40:	24c50513          	addi	a0,a0,588 # 80240e88 <ftable>
    80004c44:	ffffc097          	auipc	ra,0xffffc
    80004c48:	194080e7          	jalr	404(ra) # 80000dd8 <acquire>
  if(f->ref < 1)
    80004c4c:	40dc                	lw	a5,4(s1)
    80004c4e:	06f05163          	blez	a5,80004cb0 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c52:	37fd                	addiw	a5,a5,-1
    80004c54:	0007871b          	sext.w	a4,a5
    80004c58:	c0dc                	sw	a5,4(s1)
    80004c5a:	06e04363          	bgtz	a4,80004cc0 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c5e:	0004a903          	lw	s2,0(s1)
    80004c62:	0094ca83          	lbu	s5,9(s1)
    80004c66:	0104ba03          	ld	s4,16(s1)
    80004c6a:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c6e:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c72:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c76:	0023c517          	auipc	a0,0x23c
    80004c7a:	21250513          	addi	a0,a0,530 # 80240e88 <ftable>
    80004c7e:	ffffc097          	auipc	ra,0xffffc
    80004c82:	20e080e7          	jalr	526(ra) # 80000e8c <release>

  if(ff.type == FD_PIPE){
    80004c86:	4785                	li	a5,1
    80004c88:	04f90d63          	beq	s2,a5,80004ce2 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004c8c:	3979                	addiw	s2,s2,-2
    80004c8e:	4785                	li	a5,1
    80004c90:	0527e063          	bltu	a5,s2,80004cd0 <fileclose+0xa8>
    begin_op();
    80004c94:	00000097          	auipc	ra,0x0
    80004c98:	ad0080e7          	jalr	-1328(ra) # 80004764 <begin_op>
    iput(ff.ip);
    80004c9c:	854e                	mv	a0,s3
    80004c9e:	fffff097          	auipc	ra,0xfffff
    80004ca2:	2da080e7          	jalr	730(ra) # 80003f78 <iput>
    end_op();
    80004ca6:	00000097          	auipc	ra,0x0
    80004caa:	b38080e7          	jalr	-1224(ra) # 800047de <end_op>
    80004cae:	a00d                	j	80004cd0 <fileclose+0xa8>
    panic("fileclose");
    80004cb0:	00004517          	auipc	a0,0x4
    80004cb4:	be850513          	addi	a0,a0,-1048 # 80008898 <syscalls+0x288>
    80004cb8:	ffffc097          	auipc	ra,0xffffc
    80004cbc:	884080e7          	jalr	-1916(ra) # 8000053c <panic>
    release(&ftable.lock);
    80004cc0:	0023c517          	auipc	a0,0x23c
    80004cc4:	1c850513          	addi	a0,a0,456 # 80240e88 <ftable>
    80004cc8:	ffffc097          	auipc	ra,0xffffc
    80004ccc:	1c4080e7          	jalr	452(ra) # 80000e8c <release>
  }
}
    80004cd0:	70e2                	ld	ra,56(sp)
    80004cd2:	7442                	ld	s0,48(sp)
    80004cd4:	74a2                	ld	s1,40(sp)
    80004cd6:	7902                	ld	s2,32(sp)
    80004cd8:	69e2                	ld	s3,24(sp)
    80004cda:	6a42                	ld	s4,16(sp)
    80004cdc:	6aa2                	ld	s5,8(sp)
    80004cde:	6121                	addi	sp,sp,64
    80004ce0:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004ce2:	85d6                	mv	a1,s5
    80004ce4:	8552                	mv	a0,s4
    80004ce6:	00000097          	auipc	ra,0x0
    80004cea:	348080e7          	jalr	840(ra) # 8000502e <pipeclose>
    80004cee:	b7cd                	j	80004cd0 <fileclose+0xa8>

0000000080004cf0 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004cf0:	715d                	addi	sp,sp,-80
    80004cf2:	e486                	sd	ra,72(sp)
    80004cf4:	e0a2                	sd	s0,64(sp)
    80004cf6:	fc26                	sd	s1,56(sp)
    80004cf8:	f84a                	sd	s2,48(sp)
    80004cfa:	f44e                	sd	s3,40(sp)
    80004cfc:	0880                	addi	s0,sp,80
    80004cfe:	84aa                	mv	s1,a0
    80004d00:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d02:	ffffd097          	auipc	ra,0xffffd
    80004d06:	06a080e7          	jalr	106(ra) # 80001d6c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d0a:	409c                	lw	a5,0(s1)
    80004d0c:	37f9                	addiw	a5,a5,-2
    80004d0e:	4705                	li	a4,1
    80004d10:	04f76763          	bltu	a4,a5,80004d5e <filestat+0x6e>
    80004d14:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d16:	6c88                	ld	a0,24(s1)
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	0a6080e7          	jalr	166(ra) # 80003dbe <ilock>
    stati(f->ip, &st);
    80004d20:	fb840593          	addi	a1,s0,-72
    80004d24:	6c88                	ld	a0,24(s1)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	322080e7          	jalr	802(ra) # 80004048 <stati>
    iunlock(f->ip);
    80004d2e:	6c88                	ld	a0,24(s1)
    80004d30:	fffff097          	auipc	ra,0xfffff
    80004d34:	150080e7          	jalr	336(ra) # 80003e80 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d38:	46e1                	li	a3,24
    80004d3a:	fb840613          	addi	a2,s0,-72
    80004d3e:	85ce                	mv	a1,s3
    80004d40:	05093503          	ld	a0,80(s2)
    80004d44:	ffffd097          	auipc	ra,0xffffd
    80004d48:	be0080e7          	jalr	-1056(ra) # 80001924 <copyout>
    80004d4c:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d50:	60a6                	ld	ra,72(sp)
    80004d52:	6406                	ld	s0,64(sp)
    80004d54:	74e2                	ld	s1,56(sp)
    80004d56:	7942                	ld	s2,48(sp)
    80004d58:	79a2                	ld	s3,40(sp)
    80004d5a:	6161                	addi	sp,sp,80
    80004d5c:	8082                	ret
  return -1;
    80004d5e:	557d                	li	a0,-1
    80004d60:	bfc5                	j	80004d50 <filestat+0x60>

0000000080004d62 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d62:	7179                	addi	sp,sp,-48
    80004d64:	f406                	sd	ra,40(sp)
    80004d66:	f022                	sd	s0,32(sp)
    80004d68:	ec26                	sd	s1,24(sp)
    80004d6a:	e84a                	sd	s2,16(sp)
    80004d6c:	e44e                	sd	s3,8(sp)
    80004d6e:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d70:	00854783          	lbu	a5,8(a0)
    80004d74:	c3d5                	beqz	a5,80004e18 <fileread+0xb6>
    80004d76:	84aa                	mv	s1,a0
    80004d78:	89ae                	mv	s3,a1
    80004d7a:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d7c:	411c                	lw	a5,0(a0)
    80004d7e:	4705                	li	a4,1
    80004d80:	04e78963          	beq	a5,a4,80004dd2 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004d84:	470d                	li	a4,3
    80004d86:	04e78d63          	beq	a5,a4,80004de0 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004d8a:	4709                	li	a4,2
    80004d8c:	06e79e63          	bne	a5,a4,80004e08 <fileread+0xa6>
    ilock(f->ip);
    80004d90:	6d08                	ld	a0,24(a0)
    80004d92:	fffff097          	auipc	ra,0xfffff
    80004d96:	02c080e7          	jalr	44(ra) # 80003dbe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004d9a:	874a                	mv	a4,s2
    80004d9c:	5094                	lw	a3,32(s1)
    80004d9e:	864e                	mv	a2,s3
    80004da0:	4585                	li	a1,1
    80004da2:	6c88                	ld	a0,24(s1)
    80004da4:	fffff097          	auipc	ra,0xfffff
    80004da8:	2ce080e7          	jalr	718(ra) # 80004072 <readi>
    80004dac:	892a                	mv	s2,a0
    80004dae:	00a05563          	blez	a0,80004db8 <fileread+0x56>
      f->off += r;
    80004db2:	509c                	lw	a5,32(s1)
    80004db4:	9fa9                	addw	a5,a5,a0
    80004db6:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004db8:	6c88                	ld	a0,24(s1)
    80004dba:	fffff097          	auipc	ra,0xfffff
    80004dbe:	0c6080e7          	jalr	198(ra) # 80003e80 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004dc2:	854a                	mv	a0,s2
    80004dc4:	70a2                	ld	ra,40(sp)
    80004dc6:	7402                	ld	s0,32(sp)
    80004dc8:	64e2                	ld	s1,24(sp)
    80004dca:	6942                	ld	s2,16(sp)
    80004dcc:	69a2                	ld	s3,8(sp)
    80004dce:	6145                	addi	sp,sp,48
    80004dd0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dd2:	6908                	ld	a0,16(a0)
    80004dd4:	00000097          	auipc	ra,0x0
    80004dd8:	3c2080e7          	jalr	962(ra) # 80005196 <piperead>
    80004ddc:	892a                	mv	s2,a0
    80004dde:	b7d5                	j	80004dc2 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004de0:	02451783          	lh	a5,36(a0)
    80004de4:	03079693          	slli	a3,a5,0x30
    80004de8:	92c1                	srli	a3,a3,0x30
    80004dea:	4725                	li	a4,9
    80004dec:	02d76863          	bltu	a4,a3,80004e1c <fileread+0xba>
    80004df0:	0792                	slli	a5,a5,0x4
    80004df2:	0023c717          	auipc	a4,0x23c
    80004df6:	ff670713          	addi	a4,a4,-10 # 80240de8 <devsw>
    80004dfa:	97ba                	add	a5,a5,a4
    80004dfc:	639c                	ld	a5,0(a5)
    80004dfe:	c38d                	beqz	a5,80004e20 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e00:	4505                	li	a0,1
    80004e02:	9782                	jalr	a5
    80004e04:	892a                	mv	s2,a0
    80004e06:	bf75                	j	80004dc2 <fileread+0x60>
    panic("fileread");
    80004e08:	00004517          	auipc	a0,0x4
    80004e0c:	aa050513          	addi	a0,a0,-1376 # 800088a8 <syscalls+0x298>
    80004e10:	ffffb097          	auipc	ra,0xffffb
    80004e14:	72c080e7          	jalr	1836(ra) # 8000053c <panic>
    return -1;
    80004e18:	597d                	li	s2,-1
    80004e1a:	b765                	j	80004dc2 <fileread+0x60>
      return -1;
    80004e1c:	597d                	li	s2,-1
    80004e1e:	b755                	j	80004dc2 <fileread+0x60>
    80004e20:	597d                	li	s2,-1
    80004e22:	b745                	j	80004dc2 <fileread+0x60>

0000000080004e24 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004e24:	00954783          	lbu	a5,9(a0)
    80004e28:	10078e63          	beqz	a5,80004f44 <filewrite+0x120>
{
    80004e2c:	715d                	addi	sp,sp,-80
    80004e2e:	e486                	sd	ra,72(sp)
    80004e30:	e0a2                	sd	s0,64(sp)
    80004e32:	fc26                	sd	s1,56(sp)
    80004e34:	f84a                	sd	s2,48(sp)
    80004e36:	f44e                	sd	s3,40(sp)
    80004e38:	f052                	sd	s4,32(sp)
    80004e3a:	ec56                	sd	s5,24(sp)
    80004e3c:	e85a                	sd	s6,16(sp)
    80004e3e:	e45e                	sd	s7,8(sp)
    80004e40:	e062                	sd	s8,0(sp)
    80004e42:	0880                	addi	s0,sp,80
    80004e44:	892a                	mv	s2,a0
    80004e46:	8b2e                	mv	s6,a1
    80004e48:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e4a:	411c                	lw	a5,0(a0)
    80004e4c:	4705                	li	a4,1
    80004e4e:	02e78263          	beq	a5,a4,80004e72 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e52:	470d                	li	a4,3
    80004e54:	02e78563          	beq	a5,a4,80004e7e <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e58:	4709                	li	a4,2
    80004e5a:	0ce79d63          	bne	a5,a4,80004f34 <filewrite+0x110>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e5e:	0ac05b63          	blez	a2,80004f14 <filewrite+0xf0>
    int i = 0;
    80004e62:	4981                	li	s3,0
      int n1 = n - i;
      if(n1 > max)
    80004e64:	6b85                	lui	s7,0x1
    80004e66:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004e6a:	6c05                	lui	s8,0x1
    80004e6c:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004e70:	a851                	j	80004f04 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004e72:	6908                	ld	a0,16(a0)
    80004e74:	00000097          	auipc	ra,0x0
    80004e78:	22a080e7          	jalr	554(ra) # 8000509e <pipewrite>
    80004e7c:	a045                	j	80004f1c <filewrite+0xf8>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e7e:	02451783          	lh	a5,36(a0)
    80004e82:	03079693          	slli	a3,a5,0x30
    80004e86:	92c1                	srli	a3,a3,0x30
    80004e88:	4725                	li	a4,9
    80004e8a:	0ad76f63          	bltu	a4,a3,80004f48 <filewrite+0x124>
    80004e8e:	0792                	slli	a5,a5,0x4
    80004e90:	0023c717          	auipc	a4,0x23c
    80004e94:	f5870713          	addi	a4,a4,-168 # 80240de8 <devsw>
    80004e98:	97ba                	add	a5,a5,a4
    80004e9a:	679c                	ld	a5,8(a5)
    80004e9c:	cbc5                	beqz	a5,80004f4c <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    80004e9e:	4505                	li	a0,1
    80004ea0:	9782                	jalr	a5
    80004ea2:	a8ad                	j	80004f1c <filewrite+0xf8>
      if(n1 > max)
    80004ea4:	00048a9b          	sext.w	s5,s1
        n1 = max;

      begin_op();
    80004ea8:	00000097          	auipc	ra,0x0
    80004eac:	8bc080e7          	jalr	-1860(ra) # 80004764 <begin_op>
      ilock(f->ip);
    80004eb0:	01893503          	ld	a0,24(s2)
    80004eb4:	fffff097          	auipc	ra,0xfffff
    80004eb8:	f0a080e7          	jalr	-246(ra) # 80003dbe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ebc:	8756                	mv	a4,s5
    80004ebe:	02092683          	lw	a3,32(s2)
    80004ec2:	01698633          	add	a2,s3,s6
    80004ec6:	4585                	li	a1,1
    80004ec8:	01893503          	ld	a0,24(s2)
    80004ecc:	fffff097          	auipc	ra,0xfffff
    80004ed0:	29e080e7          	jalr	670(ra) # 8000416a <writei>
    80004ed4:	84aa                	mv	s1,a0
    80004ed6:	00a05763          	blez	a0,80004ee4 <filewrite+0xc0>
        f->off += r;
    80004eda:	02092783          	lw	a5,32(s2)
    80004ede:	9fa9                	addw	a5,a5,a0
    80004ee0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004ee4:	01893503          	ld	a0,24(s2)
    80004ee8:	fffff097          	auipc	ra,0xfffff
    80004eec:	f98080e7          	jalr	-104(ra) # 80003e80 <iunlock>
      end_op();
    80004ef0:	00000097          	auipc	ra,0x0
    80004ef4:	8ee080e7          	jalr	-1810(ra) # 800047de <end_op>

      if(r != n1){
    80004ef8:	009a9f63          	bne	s5,s1,80004f16 <filewrite+0xf2>
        // error from writei
        break;
      }
      i += r;
    80004efc:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f00:	0149db63          	bge	s3,s4,80004f16 <filewrite+0xf2>
      int n1 = n - i;
    80004f04:	413a04bb          	subw	s1,s4,s3
      if(n1 > max)
    80004f08:	0004879b          	sext.w	a5,s1
    80004f0c:	f8fbdce3          	bge	s7,a5,80004ea4 <filewrite+0x80>
    80004f10:	84e2                	mv	s1,s8
    80004f12:	bf49                	j	80004ea4 <filewrite+0x80>
    int i = 0;
    80004f14:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f16:	033a1d63          	bne	s4,s3,80004f50 <filewrite+0x12c>
    80004f1a:	8552                	mv	a0,s4
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f1c:	60a6                	ld	ra,72(sp)
    80004f1e:	6406                	ld	s0,64(sp)
    80004f20:	74e2                	ld	s1,56(sp)
    80004f22:	7942                	ld	s2,48(sp)
    80004f24:	79a2                	ld	s3,40(sp)
    80004f26:	7a02                	ld	s4,32(sp)
    80004f28:	6ae2                	ld	s5,24(sp)
    80004f2a:	6b42                	ld	s6,16(sp)
    80004f2c:	6ba2                	ld	s7,8(sp)
    80004f2e:	6c02                	ld	s8,0(sp)
    80004f30:	6161                	addi	sp,sp,80
    80004f32:	8082                	ret
    panic("filewrite");
    80004f34:	00004517          	auipc	a0,0x4
    80004f38:	98450513          	addi	a0,a0,-1660 # 800088b8 <syscalls+0x2a8>
    80004f3c:	ffffb097          	auipc	ra,0xffffb
    80004f40:	600080e7          	jalr	1536(ra) # 8000053c <panic>
    return -1;
    80004f44:	557d                	li	a0,-1
}
    80004f46:	8082                	ret
      return -1;
    80004f48:	557d                	li	a0,-1
    80004f4a:	bfc9                	j	80004f1c <filewrite+0xf8>
    80004f4c:	557d                	li	a0,-1
    80004f4e:	b7f9                	j	80004f1c <filewrite+0xf8>
    ret = (i == n ? n : -1);
    80004f50:	557d                	li	a0,-1
    80004f52:	b7e9                	j	80004f1c <filewrite+0xf8>

0000000080004f54 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f54:	7179                	addi	sp,sp,-48
    80004f56:	f406                	sd	ra,40(sp)
    80004f58:	f022                	sd	s0,32(sp)
    80004f5a:	ec26                	sd	s1,24(sp)
    80004f5c:	e84a                	sd	s2,16(sp)
    80004f5e:	e44e                	sd	s3,8(sp)
    80004f60:	e052                	sd	s4,0(sp)
    80004f62:	1800                	addi	s0,sp,48
    80004f64:	84aa                	mv	s1,a0
    80004f66:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f68:	0005b023          	sd	zero,0(a1)
    80004f6c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f70:	00000097          	auipc	ra,0x0
    80004f74:	bfc080e7          	jalr	-1028(ra) # 80004b6c <filealloc>
    80004f78:	e088                	sd	a0,0(s1)
    80004f7a:	c551                	beqz	a0,80005006 <pipealloc+0xb2>
    80004f7c:	00000097          	auipc	ra,0x0
    80004f80:	bf0080e7          	jalr	-1040(ra) # 80004b6c <filealloc>
    80004f84:	00aa3023          	sd	a0,0(s4)
    80004f88:	c92d                	beqz	a0,80004ffa <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004f8a:	ffffc097          	auipc	ra,0xffffc
    80004f8e:	cd4080e7          	jalr	-812(ra) # 80000c5e <kalloc>
    80004f92:	892a                	mv	s2,a0
    80004f94:	c125                	beqz	a0,80004ff4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004f96:	4985                	li	s3,1
    80004f98:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004f9c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fa0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fa4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fa8:	00004597          	auipc	a1,0x4
    80004fac:	92058593          	addi	a1,a1,-1760 # 800088c8 <syscalls+0x2b8>
    80004fb0:	ffffc097          	auipc	ra,0xffffc
    80004fb4:	d98080e7          	jalr	-616(ra) # 80000d48 <initlock>
  (*f0)->type = FD_PIPE;
    80004fb8:	609c                	ld	a5,0(s1)
    80004fba:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fbe:	609c                	ld	a5,0(s1)
    80004fc0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fc4:	609c                	ld	a5,0(s1)
    80004fc6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004fca:	609c                	ld	a5,0(s1)
    80004fcc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004fd0:	000a3783          	ld	a5,0(s4)
    80004fd4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004fd8:	000a3783          	ld	a5,0(s4)
    80004fdc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004fe0:	000a3783          	ld	a5,0(s4)
    80004fe4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004fe8:	000a3783          	ld	a5,0(s4)
    80004fec:	0127b823          	sd	s2,16(a5)
  return 0;
    80004ff0:	4501                	li	a0,0
    80004ff2:	a025                	j	8000501a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004ff4:	6088                	ld	a0,0(s1)
    80004ff6:	e501                	bnez	a0,80004ffe <pipealloc+0xaa>
    80004ff8:	a039                	j	80005006 <pipealloc+0xb2>
    80004ffa:	6088                	ld	a0,0(s1)
    80004ffc:	c51d                	beqz	a0,8000502a <pipealloc+0xd6>
    fileclose(*f0);
    80004ffe:	00000097          	auipc	ra,0x0
    80005002:	c2a080e7          	jalr	-982(ra) # 80004c28 <fileclose>
  if(*f1)
    80005006:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000500a:	557d                	li	a0,-1
  if(*f1)
    8000500c:	c799                	beqz	a5,8000501a <pipealloc+0xc6>
    fileclose(*f1);
    8000500e:	853e                	mv	a0,a5
    80005010:	00000097          	auipc	ra,0x0
    80005014:	c18080e7          	jalr	-1000(ra) # 80004c28 <fileclose>
  return -1;
    80005018:	557d                	li	a0,-1
}
    8000501a:	70a2                	ld	ra,40(sp)
    8000501c:	7402                	ld	s0,32(sp)
    8000501e:	64e2                	ld	s1,24(sp)
    80005020:	6942                	ld	s2,16(sp)
    80005022:	69a2                	ld	s3,8(sp)
    80005024:	6a02                	ld	s4,0(sp)
    80005026:	6145                	addi	sp,sp,48
    80005028:	8082                	ret
  return -1;
    8000502a:	557d                	li	a0,-1
    8000502c:	b7fd                	j	8000501a <pipealloc+0xc6>

000000008000502e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000502e:	1101                	addi	sp,sp,-32
    80005030:	ec06                	sd	ra,24(sp)
    80005032:	e822                	sd	s0,16(sp)
    80005034:	e426                	sd	s1,8(sp)
    80005036:	e04a                	sd	s2,0(sp)
    80005038:	1000                	addi	s0,sp,32
    8000503a:	84aa                	mv	s1,a0
    8000503c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000503e:	ffffc097          	auipc	ra,0xffffc
    80005042:	d9a080e7          	jalr	-614(ra) # 80000dd8 <acquire>
  if(writable){
    80005046:	02090d63          	beqz	s2,80005080 <pipeclose+0x52>
    pi->writeopen = 0;
    8000504a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000504e:	21848513          	addi	a0,s1,536
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	4e6080e7          	jalr	1254(ra) # 80002538 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000505a:	2204b783          	ld	a5,544(s1)
    8000505e:	eb95                	bnez	a5,80005092 <pipeclose+0x64>
    release(&pi->lock);
    80005060:	8526                	mv	a0,s1
    80005062:	ffffc097          	auipc	ra,0xffffc
    80005066:	e2a080e7          	jalr	-470(ra) # 80000e8c <release>
    kfree((char*)pi);
    8000506a:	8526                	mv	a0,s1
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	a06080e7          	jalr	-1530(ra) # 80000a72 <kfree>
  } else
    release(&pi->lock);
}
    80005074:	60e2                	ld	ra,24(sp)
    80005076:	6442                	ld	s0,16(sp)
    80005078:	64a2                	ld	s1,8(sp)
    8000507a:	6902                	ld	s2,0(sp)
    8000507c:	6105                	addi	sp,sp,32
    8000507e:	8082                	ret
    pi->readopen = 0;
    80005080:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80005084:	21c48513          	addi	a0,s1,540
    80005088:	ffffd097          	auipc	ra,0xffffd
    8000508c:	4b0080e7          	jalr	1200(ra) # 80002538 <wakeup>
    80005090:	b7e9                	j	8000505a <pipeclose+0x2c>
    release(&pi->lock);
    80005092:	8526                	mv	a0,s1
    80005094:	ffffc097          	auipc	ra,0xffffc
    80005098:	df8080e7          	jalr	-520(ra) # 80000e8c <release>
}
    8000509c:	bfe1                	j	80005074 <pipeclose+0x46>

000000008000509e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000509e:	711d                	addi	sp,sp,-96
    800050a0:	ec86                	sd	ra,88(sp)
    800050a2:	e8a2                	sd	s0,80(sp)
    800050a4:	e4a6                	sd	s1,72(sp)
    800050a6:	e0ca                	sd	s2,64(sp)
    800050a8:	fc4e                	sd	s3,56(sp)
    800050aa:	f852                	sd	s4,48(sp)
    800050ac:	f456                	sd	s5,40(sp)
    800050ae:	f05a                	sd	s6,32(sp)
    800050b0:	ec5e                	sd	s7,24(sp)
    800050b2:	e862                	sd	s8,16(sp)
    800050b4:	1080                	addi	s0,sp,96
    800050b6:	84aa                	mv	s1,a0
    800050b8:	8aae                	mv	s5,a1
    800050ba:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050bc:	ffffd097          	auipc	ra,0xffffd
    800050c0:	cb0080e7          	jalr	-848(ra) # 80001d6c <myproc>
    800050c4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050c6:	8526                	mv	a0,s1
    800050c8:	ffffc097          	auipc	ra,0xffffc
    800050cc:	d10080e7          	jalr	-752(ra) # 80000dd8 <acquire>
  while(i < n){
    800050d0:	0b405663          	blez	s4,8000517c <pipewrite+0xde>
  int i = 0;
    800050d4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050d6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050d8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050dc:	21c48b93          	addi	s7,s1,540
    800050e0:	a089                	j	80005122 <pipewrite+0x84>
      release(&pi->lock);
    800050e2:	8526                	mv	a0,s1
    800050e4:	ffffc097          	auipc	ra,0xffffc
    800050e8:	da8080e7          	jalr	-600(ra) # 80000e8c <release>
      return -1;
    800050ec:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800050ee:	854a                	mv	a0,s2
    800050f0:	60e6                	ld	ra,88(sp)
    800050f2:	6446                	ld	s0,80(sp)
    800050f4:	64a6                	ld	s1,72(sp)
    800050f6:	6906                	ld	s2,64(sp)
    800050f8:	79e2                	ld	s3,56(sp)
    800050fa:	7a42                	ld	s4,48(sp)
    800050fc:	7aa2                	ld	s5,40(sp)
    800050fe:	7b02                	ld	s6,32(sp)
    80005100:	6be2                	ld	s7,24(sp)
    80005102:	6c42                	ld	s8,16(sp)
    80005104:	6125                	addi	sp,sp,96
    80005106:	8082                	ret
      wakeup(&pi->nread);
    80005108:	8562                	mv	a0,s8
    8000510a:	ffffd097          	auipc	ra,0xffffd
    8000510e:	42e080e7          	jalr	1070(ra) # 80002538 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005112:	85a6                	mv	a1,s1
    80005114:	855e                	mv	a0,s7
    80005116:	ffffd097          	auipc	ra,0xffffd
    8000511a:	3be080e7          	jalr	958(ra) # 800024d4 <sleep>
  while(i < n){
    8000511e:	07495063          	bge	s2,s4,8000517e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005122:	2204a783          	lw	a5,544(s1)
    80005126:	dfd5                	beqz	a5,800050e2 <pipewrite+0x44>
    80005128:	854e                	mv	a0,s3
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	652080e7          	jalr	1618(ra) # 8000277c <killed>
    80005132:	f945                	bnez	a0,800050e2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005134:	2184a783          	lw	a5,536(s1)
    80005138:	21c4a703          	lw	a4,540(s1)
    8000513c:	2007879b          	addiw	a5,a5,512
    80005140:	fcf704e3          	beq	a4,a5,80005108 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005144:	4685                	li	a3,1
    80005146:	01590633          	add	a2,s2,s5
    8000514a:	faf40593          	addi	a1,s0,-81
    8000514e:	0509b503          	ld	a0,80(s3)
    80005152:	ffffd097          	auipc	ra,0xffffd
    80005156:	872080e7          	jalr	-1934(ra) # 800019c4 <copyin>
    8000515a:	03650263          	beq	a0,s6,8000517e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000515e:	21c4a783          	lw	a5,540(s1)
    80005162:	0017871b          	addiw	a4,a5,1
    80005166:	20e4ae23          	sw	a4,540(s1)
    8000516a:	1ff7f793          	andi	a5,a5,511
    8000516e:	97a6                	add	a5,a5,s1
    80005170:	faf44703          	lbu	a4,-81(s0)
    80005174:	00e78c23          	sb	a4,24(a5)
      i++;
    80005178:	2905                	addiw	s2,s2,1
    8000517a:	b755                	j	8000511e <pipewrite+0x80>
  int i = 0;
    8000517c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000517e:	21848513          	addi	a0,s1,536
    80005182:	ffffd097          	auipc	ra,0xffffd
    80005186:	3b6080e7          	jalr	950(ra) # 80002538 <wakeup>
  release(&pi->lock);
    8000518a:	8526                	mv	a0,s1
    8000518c:	ffffc097          	auipc	ra,0xffffc
    80005190:	d00080e7          	jalr	-768(ra) # 80000e8c <release>
  return i;
    80005194:	bfa9                	j	800050ee <pipewrite+0x50>

0000000080005196 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005196:	715d                	addi	sp,sp,-80
    80005198:	e486                	sd	ra,72(sp)
    8000519a:	e0a2                	sd	s0,64(sp)
    8000519c:	fc26                	sd	s1,56(sp)
    8000519e:	f84a                	sd	s2,48(sp)
    800051a0:	f44e                	sd	s3,40(sp)
    800051a2:	f052                	sd	s4,32(sp)
    800051a4:	ec56                	sd	s5,24(sp)
    800051a6:	e85a                	sd	s6,16(sp)
    800051a8:	0880                	addi	s0,sp,80
    800051aa:	84aa                	mv	s1,a0
    800051ac:	892e                	mv	s2,a1
    800051ae:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051b0:	ffffd097          	auipc	ra,0xffffd
    800051b4:	bbc080e7          	jalr	-1092(ra) # 80001d6c <myproc>
    800051b8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051ba:	8526                	mv	a0,s1
    800051bc:	ffffc097          	auipc	ra,0xffffc
    800051c0:	c1c080e7          	jalr	-996(ra) # 80000dd8 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051c4:	2184a703          	lw	a4,536(s1)
    800051c8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051cc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051d0:	02f71763          	bne	a4,a5,800051fe <piperead+0x68>
    800051d4:	2244a783          	lw	a5,548(s1)
    800051d8:	c39d                	beqz	a5,800051fe <piperead+0x68>
    if(killed(pr)){
    800051da:	8552                	mv	a0,s4
    800051dc:	ffffd097          	auipc	ra,0xffffd
    800051e0:	5a0080e7          	jalr	1440(ra) # 8000277c <killed>
    800051e4:	e949                	bnez	a0,80005276 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051e6:	85a6                	mv	a1,s1
    800051e8:	854e                	mv	a0,s3
    800051ea:	ffffd097          	auipc	ra,0xffffd
    800051ee:	2ea080e7          	jalr	746(ra) # 800024d4 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051f2:	2184a703          	lw	a4,536(s1)
    800051f6:	21c4a783          	lw	a5,540(s1)
    800051fa:	fcf70de3          	beq	a4,a5,800051d4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800051fe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005200:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005202:	05505463          	blez	s5,8000524a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005206:	2184a783          	lw	a5,536(s1)
    8000520a:	21c4a703          	lw	a4,540(s1)
    8000520e:	02f70e63          	beq	a4,a5,8000524a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005212:	0017871b          	addiw	a4,a5,1
    80005216:	20e4ac23          	sw	a4,536(s1)
    8000521a:	1ff7f793          	andi	a5,a5,511
    8000521e:	97a6                	add	a5,a5,s1
    80005220:	0187c783          	lbu	a5,24(a5)
    80005224:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005228:	4685                	li	a3,1
    8000522a:	fbf40613          	addi	a2,s0,-65
    8000522e:	85ca                	mv	a1,s2
    80005230:	050a3503          	ld	a0,80(s4)
    80005234:	ffffc097          	auipc	ra,0xffffc
    80005238:	6f0080e7          	jalr	1776(ra) # 80001924 <copyout>
    8000523c:	01650763          	beq	a0,s6,8000524a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005240:	2985                	addiw	s3,s3,1
    80005242:	0905                	addi	s2,s2,1
    80005244:	fd3a91e3          	bne	s5,s3,80005206 <piperead+0x70>
    80005248:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000524a:	21c48513          	addi	a0,s1,540
    8000524e:	ffffd097          	auipc	ra,0xffffd
    80005252:	2ea080e7          	jalr	746(ra) # 80002538 <wakeup>
  release(&pi->lock);
    80005256:	8526                	mv	a0,s1
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	c34080e7          	jalr	-972(ra) # 80000e8c <release>
  return i;
}
    80005260:	854e                	mv	a0,s3
    80005262:	60a6                	ld	ra,72(sp)
    80005264:	6406                	ld	s0,64(sp)
    80005266:	74e2                	ld	s1,56(sp)
    80005268:	7942                	ld	s2,48(sp)
    8000526a:	79a2                	ld	s3,40(sp)
    8000526c:	7a02                	ld	s4,32(sp)
    8000526e:	6ae2                	ld	s5,24(sp)
    80005270:	6b42                	ld	s6,16(sp)
    80005272:	6161                	addi	sp,sp,80
    80005274:	8082                	ret
      release(&pi->lock);
    80005276:	8526                	mv	a0,s1
    80005278:	ffffc097          	auipc	ra,0xffffc
    8000527c:	c14080e7          	jalr	-1004(ra) # 80000e8c <release>
      return -1;
    80005280:	59fd                	li	s3,-1
    80005282:	bff9                	j	80005260 <piperead+0xca>

0000000080005284 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005284:	1141                	addi	sp,sp,-16
    80005286:	e422                	sd	s0,8(sp)
    80005288:	0800                	addi	s0,sp,16
    8000528a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    8000528c:	8905                	andi	a0,a0,1
    8000528e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005290:	8b89                	andi	a5,a5,2
    80005292:	c399                	beqz	a5,80005298 <flags2perm+0x14>
      perm |= PTE_W;
    80005294:	00456513          	ori	a0,a0,4
    return perm;
}
    80005298:	6422                	ld	s0,8(sp)
    8000529a:	0141                	addi	sp,sp,16
    8000529c:	8082                	ret

000000008000529e <exec>:

int
exec(char *path, char **argv)
{
    8000529e:	df010113          	addi	sp,sp,-528
    800052a2:	20113423          	sd	ra,520(sp)
    800052a6:	20813023          	sd	s0,512(sp)
    800052aa:	ffa6                	sd	s1,504(sp)
    800052ac:	fbca                	sd	s2,496(sp)
    800052ae:	f7ce                	sd	s3,488(sp)
    800052b0:	f3d2                	sd	s4,480(sp)
    800052b2:	efd6                	sd	s5,472(sp)
    800052b4:	ebda                	sd	s6,464(sp)
    800052b6:	e7de                	sd	s7,456(sp)
    800052b8:	e3e2                	sd	s8,448(sp)
    800052ba:	ff66                	sd	s9,440(sp)
    800052bc:	fb6a                	sd	s10,432(sp)
    800052be:	f76e                	sd	s11,424(sp)
    800052c0:	0c00                	addi	s0,sp,528
    800052c2:	892a                	mv	s2,a0
    800052c4:	dea43c23          	sd	a0,-520(s0)
    800052c8:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052cc:	ffffd097          	auipc	ra,0xffffd
    800052d0:	aa0080e7          	jalr	-1376(ra) # 80001d6c <myproc>
    800052d4:	84aa                	mv	s1,a0

  begin_op();
    800052d6:	fffff097          	auipc	ra,0xfffff
    800052da:	48e080e7          	jalr	1166(ra) # 80004764 <begin_op>

  if((ip = namei(path)) == 0){
    800052de:	854a                	mv	a0,s2
    800052e0:	fffff097          	auipc	ra,0xfffff
    800052e4:	284080e7          	jalr	644(ra) # 80004564 <namei>
    800052e8:	c92d                	beqz	a0,8000535a <exec+0xbc>
    800052ea:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800052ec:	fffff097          	auipc	ra,0xfffff
    800052f0:	ad2080e7          	jalr	-1326(ra) # 80003dbe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800052f4:	04000713          	li	a4,64
    800052f8:	4681                	li	a3,0
    800052fa:	e5040613          	addi	a2,s0,-432
    800052fe:	4581                	li	a1,0
    80005300:	8552                	mv	a0,s4
    80005302:	fffff097          	auipc	ra,0xfffff
    80005306:	d70080e7          	jalr	-656(ra) # 80004072 <readi>
    8000530a:	04000793          	li	a5,64
    8000530e:	00f51a63          	bne	a0,a5,80005322 <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005312:	e5042703          	lw	a4,-432(s0)
    80005316:	464c47b7          	lui	a5,0x464c4
    8000531a:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000531e:	04f70463          	beq	a4,a5,80005366 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005322:	8552                	mv	a0,s4
    80005324:	fffff097          	auipc	ra,0xfffff
    80005328:	cfc080e7          	jalr	-772(ra) # 80004020 <iunlockput>
    end_op();
    8000532c:	fffff097          	auipc	ra,0xfffff
    80005330:	4b2080e7          	jalr	1202(ra) # 800047de <end_op>
  }
  return -1;
    80005334:	557d                	li	a0,-1
}
    80005336:	20813083          	ld	ra,520(sp)
    8000533a:	20013403          	ld	s0,512(sp)
    8000533e:	74fe                	ld	s1,504(sp)
    80005340:	795e                	ld	s2,496(sp)
    80005342:	79be                	ld	s3,488(sp)
    80005344:	7a1e                	ld	s4,480(sp)
    80005346:	6afe                	ld	s5,472(sp)
    80005348:	6b5e                	ld	s6,464(sp)
    8000534a:	6bbe                	ld	s7,456(sp)
    8000534c:	6c1e                	ld	s8,448(sp)
    8000534e:	7cfa                	ld	s9,440(sp)
    80005350:	7d5a                	ld	s10,432(sp)
    80005352:	7dba                	ld	s11,424(sp)
    80005354:	21010113          	addi	sp,sp,528
    80005358:	8082                	ret
    end_op();
    8000535a:	fffff097          	auipc	ra,0xfffff
    8000535e:	484080e7          	jalr	1156(ra) # 800047de <end_op>
    return -1;
    80005362:	557d                	li	a0,-1
    80005364:	bfc9                	j	80005336 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80005366:	8526                	mv	a0,s1
    80005368:	ffffd097          	auipc	ra,0xffffd
    8000536c:	ac8080e7          	jalr	-1336(ra) # 80001e30 <proc_pagetable>
    80005370:	8b2a                	mv	s6,a0
    80005372:	d945                	beqz	a0,80005322 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005374:	e7042d03          	lw	s10,-400(s0)
    80005378:	e8845783          	lhu	a5,-376(s0)
    8000537c:	10078463          	beqz	a5,80005484 <exec+0x1e6>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005380:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005382:	4d81                	li	s11,0
    if(ph.vaddr % PGSIZE != 0)
    80005384:	6c85                	lui	s9,0x1
    80005386:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000538a:	def43823          	sd	a5,-528(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    8000538e:	6a85                	lui	s5,0x1
    80005390:	a0b5                	j	800053fc <exec+0x15e>
      panic("loadseg: address should exist");
    80005392:	00003517          	auipc	a0,0x3
    80005396:	53e50513          	addi	a0,a0,1342 # 800088d0 <syscalls+0x2c0>
    8000539a:	ffffb097          	auipc	ra,0xffffb
    8000539e:	1a2080e7          	jalr	418(ra) # 8000053c <panic>
    if(sz - i < PGSIZE)
    800053a2:	2481                	sext.w	s1,s1
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053a4:	8726                	mv	a4,s1
    800053a6:	012c06bb          	addw	a3,s8,s2
    800053aa:	4581                	li	a1,0
    800053ac:	8552                	mv	a0,s4
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	cc4080e7          	jalr	-828(ra) # 80004072 <readi>
    800053b6:	2501                	sext.w	a0,a0
    800053b8:	24a49863          	bne	s1,a0,80005608 <exec+0x36a>
  for(i = 0; i < sz; i += PGSIZE){
    800053bc:	012a893b          	addw	s2,s5,s2
    800053c0:	03397563          	bgeu	s2,s3,800053ea <exec+0x14c>
    pa = walkaddr(pagetable, va + i);
    800053c4:	02091593          	slli	a1,s2,0x20
    800053c8:	9181                	srli	a1,a1,0x20
    800053ca:	95de                	add	a1,a1,s7
    800053cc:	855a                	mv	a0,s6
    800053ce:	ffffc097          	auipc	ra,0xffffc
    800053d2:	e8e080e7          	jalr	-370(ra) # 8000125c <walkaddr>
    800053d6:	862a                	mv	a2,a0
    if(pa == 0)
    800053d8:	dd4d                	beqz	a0,80005392 <exec+0xf4>
    if(sz - i < PGSIZE)
    800053da:	412984bb          	subw	s1,s3,s2
    800053de:	0004879b          	sext.w	a5,s1
    800053e2:	fcfcf0e3          	bgeu	s9,a5,800053a2 <exec+0x104>
    800053e6:	84d6                	mv	s1,s5
    800053e8:	bf6d                	j	800053a2 <exec+0x104>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800053ea:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053ee:	2d85                	addiw	s11,s11,1
    800053f0:	038d0d1b          	addiw	s10,s10,56
    800053f4:	e8845783          	lhu	a5,-376(s0)
    800053f8:	08fdd763          	bge	s11,a5,80005486 <exec+0x1e8>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800053fc:	2d01                	sext.w	s10,s10
    800053fe:	03800713          	li	a4,56
    80005402:	86ea                	mv	a3,s10
    80005404:	e1840613          	addi	a2,s0,-488
    80005408:	4581                	li	a1,0
    8000540a:	8552                	mv	a0,s4
    8000540c:	fffff097          	auipc	ra,0xfffff
    80005410:	c66080e7          	jalr	-922(ra) # 80004072 <readi>
    80005414:	03800793          	li	a5,56
    80005418:	1ef51663          	bne	a0,a5,80005604 <exec+0x366>
    if(ph.type != ELF_PROG_LOAD)
    8000541c:	e1842783          	lw	a5,-488(s0)
    80005420:	4705                	li	a4,1
    80005422:	fce796e3          	bne	a5,a4,800053ee <exec+0x150>
    if(ph.memsz < ph.filesz)
    80005426:	e4043483          	ld	s1,-448(s0)
    8000542a:	e3843783          	ld	a5,-456(s0)
    8000542e:	1ef4e863          	bltu	s1,a5,8000561e <exec+0x380>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005432:	e2843783          	ld	a5,-472(s0)
    80005436:	94be                	add	s1,s1,a5
    80005438:	1ef4e663          	bltu	s1,a5,80005624 <exec+0x386>
    if(ph.vaddr % PGSIZE != 0)
    8000543c:	df043703          	ld	a4,-528(s0)
    80005440:	8ff9                	and	a5,a5,a4
    80005442:	1e079463          	bnez	a5,8000562a <exec+0x38c>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005446:	e1c42503          	lw	a0,-484(s0)
    8000544a:	00000097          	auipc	ra,0x0
    8000544e:	e3a080e7          	jalr	-454(ra) # 80005284 <flags2perm>
    80005452:	86aa                	mv	a3,a0
    80005454:	8626                	mv	a2,s1
    80005456:	85ca                	mv	a1,s2
    80005458:	855a                	mv	a0,s6
    8000545a:	ffffc097          	auipc	ra,0xffffc
    8000545e:	1b6080e7          	jalr	438(ra) # 80001610 <uvmalloc>
    80005462:	e0a43423          	sd	a0,-504(s0)
    80005466:	1c050563          	beqz	a0,80005630 <exec+0x392>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000546a:	e2843b83          	ld	s7,-472(s0)
    8000546e:	e2042c03          	lw	s8,-480(s0)
    80005472:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005476:	00098463          	beqz	s3,8000547e <exec+0x1e0>
    8000547a:	4901                	li	s2,0
    8000547c:	b7a1                	j	800053c4 <exec+0x126>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000547e:	e0843903          	ld	s2,-504(s0)
    80005482:	b7b5                	j	800053ee <exec+0x150>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005484:	4901                	li	s2,0
  iunlockput(ip);
    80005486:	8552                	mv	a0,s4
    80005488:	fffff097          	auipc	ra,0xfffff
    8000548c:	b98080e7          	jalr	-1128(ra) # 80004020 <iunlockput>
  end_op();
    80005490:	fffff097          	auipc	ra,0xfffff
    80005494:	34e080e7          	jalr	846(ra) # 800047de <end_op>
  p = myproc();
    80005498:	ffffd097          	auipc	ra,0xffffd
    8000549c:	8d4080e7          	jalr	-1836(ra) # 80001d6c <myproc>
    800054a0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800054a2:	04853c83          	ld	s9,72(a0)
  sz = PGROUNDUP(sz);
    800054a6:	6985                	lui	s3,0x1
    800054a8:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    800054aa:	99ca                	add	s3,s3,s2
    800054ac:	77fd                	lui	a5,0xfffff
    800054ae:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800054b2:	4691                	li	a3,4
    800054b4:	6609                	lui	a2,0x2
    800054b6:	964e                	add	a2,a2,s3
    800054b8:	85ce                	mv	a1,s3
    800054ba:	855a                	mv	a0,s6
    800054bc:	ffffc097          	auipc	ra,0xffffc
    800054c0:	154080e7          	jalr	340(ra) # 80001610 <uvmalloc>
    800054c4:	892a                	mv	s2,a0
    800054c6:	e0a43423          	sd	a0,-504(s0)
    800054ca:	e509                	bnez	a0,800054d4 <exec+0x236>
  if(pagetable)
    800054cc:	e1343423          	sd	s3,-504(s0)
    800054d0:	4a01                	li	s4,0
    800054d2:	aa1d                	j	80005608 <exec+0x36a>
  uvmclear(pagetable, sz-2*PGSIZE);
    800054d4:	75f9                	lui	a1,0xffffe
    800054d6:	95aa                	add	a1,a1,a0
    800054d8:	855a                	mv	a0,s6
    800054da:	ffffc097          	auipc	ra,0xffffc
    800054de:	418080e7          	jalr	1048(ra) # 800018f2 <uvmclear>
  stackbase = sp - PGSIZE;
    800054e2:	7bfd                	lui	s7,0xfffff
    800054e4:	9bca                	add	s7,s7,s2
  for(argc = 0; argv[argc]; argc++) {
    800054e6:	e0043783          	ld	a5,-512(s0)
    800054ea:	6388                	ld	a0,0(a5)
    800054ec:	c52d                	beqz	a0,80005556 <exec+0x2b8>
    800054ee:	e9040993          	addi	s3,s0,-368
    800054f2:	f9040c13          	addi	s8,s0,-112
    800054f6:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800054f8:	ffffc097          	auipc	ra,0xffffc
    800054fc:	b56080e7          	jalr	-1194(ra) # 8000104e <strlen>
    80005500:	0015079b          	addiw	a5,a0,1
    80005504:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005508:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    8000550c:	13796563          	bltu	s2,s7,80005636 <exec+0x398>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005510:	e0043d03          	ld	s10,-512(s0)
    80005514:	000d3a03          	ld	s4,0(s10)
    80005518:	8552                	mv	a0,s4
    8000551a:	ffffc097          	auipc	ra,0xffffc
    8000551e:	b34080e7          	jalr	-1228(ra) # 8000104e <strlen>
    80005522:	0015069b          	addiw	a3,a0,1
    80005526:	8652                	mv	a2,s4
    80005528:	85ca                	mv	a1,s2
    8000552a:	855a                	mv	a0,s6
    8000552c:	ffffc097          	auipc	ra,0xffffc
    80005530:	3f8080e7          	jalr	1016(ra) # 80001924 <copyout>
    80005534:	10054363          	bltz	a0,8000563a <exec+0x39c>
    ustack[argc] = sp;
    80005538:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000553c:	0485                	addi	s1,s1,1
    8000553e:	008d0793          	addi	a5,s10,8
    80005542:	e0f43023          	sd	a5,-512(s0)
    80005546:	008d3503          	ld	a0,8(s10)
    8000554a:	c909                	beqz	a0,8000555c <exec+0x2be>
    if(argc >= MAXARG)
    8000554c:	09a1                	addi	s3,s3,8
    8000554e:	fb8995e3          	bne	s3,s8,800054f8 <exec+0x25a>
  ip = 0;
    80005552:	4a01                	li	s4,0
    80005554:	a855                	j	80005608 <exec+0x36a>
  sp = sz;
    80005556:	e0843903          	ld	s2,-504(s0)
  for(argc = 0; argv[argc]; argc++) {
    8000555a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000555c:	00349793          	slli	a5,s1,0x3
    80005560:	f9078793          	addi	a5,a5,-112 # ffffffffffffef90 <end+0xffffffff7fdbd010>
    80005564:	97a2                	add	a5,a5,s0
    80005566:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000556a:	00148693          	addi	a3,s1,1
    8000556e:	068e                	slli	a3,a3,0x3
    80005570:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005574:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80005578:	e0843983          	ld	s3,-504(s0)
  if(sp < stackbase)
    8000557c:	f57968e3          	bltu	s2,s7,800054cc <exec+0x22e>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005580:	e9040613          	addi	a2,s0,-368
    80005584:	85ca                	mv	a1,s2
    80005586:	855a                	mv	a0,s6
    80005588:	ffffc097          	auipc	ra,0xffffc
    8000558c:	39c080e7          	jalr	924(ra) # 80001924 <copyout>
    80005590:	0a054763          	bltz	a0,8000563e <exec+0x3a0>
  p->trapframe->a1 = sp;
    80005594:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    80005598:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000559c:	df843783          	ld	a5,-520(s0)
    800055a0:	0007c703          	lbu	a4,0(a5)
    800055a4:	cf11                	beqz	a4,800055c0 <exec+0x322>
    800055a6:	0785                	addi	a5,a5,1
    if(*s == '/')
    800055a8:	02f00693          	li	a3,47
    800055ac:	a039                	j	800055ba <exec+0x31c>
      last = s+1;
    800055ae:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800055b2:	0785                	addi	a5,a5,1
    800055b4:	fff7c703          	lbu	a4,-1(a5)
    800055b8:	c701                	beqz	a4,800055c0 <exec+0x322>
    if(*s == '/')
    800055ba:	fed71ce3          	bne	a4,a3,800055b2 <exec+0x314>
    800055be:	bfc5                	j	800055ae <exec+0x310>
  safestrcpy(p->name, last, sizeof(p->name));
    800055c0:	4641                	li	a2,16
    800055c2:	df843583          	ld	a1,-520(s0)
    800055c6:	158a8513          	addi	a0,s5,344
    800055ca:	ffffc097          	auipc	ra,0xffffc
    800055ce:	a52080e7          	jalr	-1454(ra) # 8000101c <safestrcpy>
  oldpagetable = p->pagetable;
    800055d2:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    800055d6:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    800055da:	e0843783          	ld	a5,-504(s0)
    800055de:	04fab423          	sd	a5,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800055e2:	058ab783          	ld	a5,88(s5)
    800055e6:	e6843703          	ld	a4,-408(s0)
    800055ea:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800055ec:	058ab783          	ld	a5,88(s5)
    800055f0:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800055f4:	85e6                	mv	a1,s9
    800055f6:	ffffd097          	auipc	ra,0xffffd
    800055fa:	8d6080e7          	jalr	-1834(ra) # 80001ecc <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800055fe:	0004851b          	sext.w	a0,s1
    80005602:	bb15                	j	80005336 <exec+0x98>
    80005604:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005608:	e0843583          	ld	a1,-504(s0)
    8000560c:	855a                	mv	a0,s6
    8000560e:	ffffd097          	auipc	ra,0xffffd
    80005612:	8be080e7          	jalr	-1858(ra) # 80001ecc <proc_freepagetable>
  return -1;
    80005616:	557d                	li	a0,-1
  if(ip){
    80005618:	d00a0fe3          	beqz	s4,80005336 <exec+0x98>
    8000561c:	b319                	j	80005322 <exec+0x84>
    8000561e:	e1243423          	sd	s2,-504(s0)
    80005622:	b7dd                	j	80005608 <exec+0x36a>
    80005624:	e1243423          	sd	s2,-504(s0)
    80005628:	b7c5                	j	80005608 <exec+0x36a>
    8000562a:	e1243423          	sd	s2,-504(s0)
    8000562e:	bfe9                	j	80005608 <exec+0x36a>
    80005630:	e1243423          	sd	s2,-504(s0)
    80005634:	bfd1                	j	80005608 <exec+0x36a>
  ip = 0;
    80005636:	4a01                	li	s4,0
    80005638:	bfc1                	j	80005608 <exec+0x36a>
    8000563a:	4a01                	li	s4,0
  if(pagetable)
    8000563c:	b7f1                	j	80005608 <exec+0x36a>
  sz = sz1;
    8000563e:	e0843983          	ld	s3,-504(s0)
    80005642:	b569                	j	800054cc <exec+0x22e>

0000000080005644 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005644:	7179                	addi	sp,sp,-48
    80005646:	f406                	sd	ra,40(sp)
    80005648:	f022                	sd	s0,32(sp)
    8000564a:	ec26                	sd	s1,24(sp)
    8000564c:	e84a                	sd	s2,16(sp)
    8000564e:	1800                	addi	s0,sp,48
    80005650:	892e                	mv	s2,a1
    80005652:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005654:	fdc40593          	addi	a1,s0,-36
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	a9a080e7          	jalr	-1382(ra) # 800030f2 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005660:	fdc42703          	lw	a4,-36(s0)
    80005664:	47bd                	li	a5,15
    80005666:	02e7eb63          	bltu	a5,a4,8000569c <argfd+0x58>
    8000566a:	ffffc097          	auipc	ra,0xffffc
    8000566e:	702080e7          	jalr	1794(ra) # 80001d6c <myproc>
    80005672:	fdc42703          	lw	a4,-36(s0)
    80005676:	01a70793          	addi	a5,a4,26
    8000567a:	078e                	slli	a5,a5,0x3
    8000567c:	953e                	add	a0,a0,a5
    8000567e:	611c                	ld	a5,0(a0)
    80005680:	c385                	beqz	a5,800056a0 <argfd+0x5c>
    return -1;
  if(pfd)
    80005682:	00090463          	beqz	s2,8000568a <argfd+0x46>
    *pfd = fd;
    80005686:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000568a:	4501                	li	a0,0
  if(pf)
    8000568c:	c091                	beqz	s1,80005690 <argfd+0x4c>
    *pf = f;
    8000568e:	e09c                	sd	a5,0(s1)
}
    80005690:	70a2                	ld	ra,40(sp)
    80005692:	7402                	ld	s0,32(sp)
    80005694:	64e2                	ld	s1,24(sp)
    80005696:	6942                	ld	s2,16(sp)
    80005698:	6145                	addi	sp,sp,48
    8000569a:	8082                	ret
    return -1;
    8000569c:	557d                	li	a0,-1
    8000569e:	bfcd                	j	80005690 <argfd+0x4c>
    800056a0:	557d                	li	a0,-1
    800056a2:	b7fd                	j	80005690 <argfd+0x4c>

00000000800056a4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056a4:	1101                	addi	sp,sp,-32
    800056a6:	ec06                	sd	ra,24(sp)
    800056a8:	e822                	sd	s0,16(sp)
    800056aa:	e426                	sd	s1,8(sp)
    800056ac:	1000                	addi	s0,sp,32
    800056ae:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056b0:	ffffc097          	auipc	ra,0xffffc
    800056b4:	6bc080e7          	jalr	1724(ra) # 80001d6c <myproc>
    800056b8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056ba:	0d050793          	addi	a5,a0,208
    800056be:	4501                	li	a0,0
    800056c0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056c2:	6398                	ld	a4,0(a5)
    800056c4:	cb19                	beqz	a4,800056da <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800056c6:	2505                	addiw	a0,a0,1
    800056c8:	07a1                	addi	a5,a5,8
    800056ca:	fed51ce3          	bne	a0,a3,800056c2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800056ce:	557d                	li	a0,-1
}
    800056d0:	60e2                	ld	ra,24(sp)
    800056d2:	6442                	ld	s0,16(sp)
    800056d4:	64a2                	ld	s1,8(sp)
    800056d6:	6105                	addi	sp,sp,32
    800056d8:	8082                	ret
      p->ofile[fd] = f;
    800056da:	01a50793          	addi	a5,a0,26
    800056de:	078e                	slli	a5,a5,0x3
    800056e0:	963e                	add	a2,a2,a5
    800056e2:	e204                	sd	s1,0(a2)
      return fd;
    800056e4:	b7f5                	j	800056d0 <fdalloc+0x2c>

00000000800056e6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800056e6:	715d                	addi	sp,sp,-80
    800056e8:	e486                	sd	ra,72(sp)
    800056ea:	e0a2                	sd	s0,64(sp)
    800056ec:	fc26                	sd	s1,56(sp)
    800056ee:	f84a                	sd	s2,48(sp)
    800056f0:	f44e                	sd	s3,40(sp)
    800056f2:	f052                	sd	s4,32(sp)
    800056f4:	ec56                	sd	s5,24(sp)
    800056f6:	e85a                	sd	s6,16(sp)
    800056f8:	0880                	addi	s0,sp,80
    800056fa:	8b2e                	mv	s6,a1
    800056fc:	89b2                	mv	s3,a2
    800056fe:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005700:	fb040593          	addi	a1,s0,-80
    80005704:	fffff097          	auipc	ra,0xfffff
    80005708:	e7e080e7          	jalr	-386(ra) # 80004582 <nameiparent>
    8000570c:	84aa                	mv	s1,a0
    8000570e:	14050b63          	beqz	a0,80005864 <create+0x17e>
    return 0;

  ilock(dp);
    80005712:	ffffe097          	auipc	ra,0xffffe
    80005716:	6ac080e7          	jalr	1708(ra) # 80003dbe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000571a:	4601                	li	a2,0
    8000571c:	fb040593          	addi	a1,s0,-80
    80005720:	8526                	mv	a0,s1
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	b80080e7          	jalr	-1152(ra) # 800042a2 <dirlookup>
    8000572a:	8aaa                	mv	s5,a0
    8000572c:	c921                	beqz	a0,8000577c <create+0x96>
    iunlockput(dp);
    8000572e:	8526                	mv	a0,s1
    80005730:	fffff097          	auipc	ra,0xfffff
    80005734:	8f0080e7          	jalr	-1808(ra) # 80004020 <iunlockput>
    ilock(ip);
    80005738:	8556                	mv	a0,s5
    8000573a:	ffffe097          	auipc	ra,0xffffe
    8000573e:	684080e7          	jalr	1668(ra) # 80003dbe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005742:	4789                	li	a5,2
    80005744:	02fb1563          	bne	s6,a5,8000576e <create+0x88>
    80005748:	044ad783          	lhu	a5,68(s5)
    8000574c:	37f9                	addiw	a5,a5,-2
    8000574e:	17c2                	slli	a5,a5,0x30
    80005750:	93c1                	srli	a5,a5,0x30
    80005752:	4705                	li	a4,1
    80005754:	00f76d63          	bltu	a4,a5,8000576e <create+0x88>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005758:	8556                	mv	a0,s5
    8000575a:	60a6                	ld	ra,72(sp)
    8000575c:	6406                	ld	s0,64(sp)
    8000575e:	74e2                	ld	s1,56(sp)
    80005760:	7942                	ld	s2,48(sp)
    80005762:	79a2                	ld	s3,40(sp)
    80005764:	7a02                	ld	s4,32(sp)
    80005766:	6ae2                	ld	s5,24(sp)
    80005768:	6b42                	ld	s6,16(sp)
    8000576a:	6161                	addi	sp,sp,80
    8000576c:	8082                	ret
    iunlockput(ip);
    8000576e:	8556                	mv	a0,s5
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	8b0080e7          	jalr	-1872(ra) # 80004020 <iunlockput>
    return 0;
    80005778:	4a81                	li	s5,0
    8000577a:	bff9                	j	80005758 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000577c:	85da                	mv	a1,s6
    8000577e:	4088                	lw	a0,0(s1)
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	4a6080e7          	jalr	1190(ra) # 80003c26 <ialloc>
    80005788:	8a2a                	mv	s4,a0
    8000578a:	c529                	beqz	a0,800057d4 <create+0xee>
  ilock(ip);
    8000578c:	ffffe097          	auipc	ra,0xffffe
    80005790:	632080e7          	jalr	1586(ra) # 80003dbe <ilock>
  ip->major = major;
    80005794:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005798:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000579c:	4905                	li	s2,1
    8000579e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057a2:	8552                	mv	a0,s4
    800057a4:	ffffe097          	auipc	ra,0xffffe
    800057a8:	54e080e7          	jalr	1358(ra) # 80003cf2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057ac:	032b0b63          	beq	s6,s2,800057e2 <create+0xfc>
  if(dirlink(dp, name, ip->inum) < 0)
    800057b0:	004a2603          	lw	a2,4(s4)
    800057b4:	fb040593          	addi	a1,s0,-80
    800057b8:	8526                	mv	a0,s1
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	cf8080e7          	jalr	-776(ra) # 800044b2 <dirlink>
    800057c2:	06054f63          	bltz	a0,80005840 <create+0x15a>
  iunlockput(dp);
    800057c6:	8526                	mv	a0,s1
    800057c8:	fffff097          	auipc	ra,0xfffff
    800057cc:	858080e7          	jalr	-1960(ra) # 80004020 <iunlockput>
  return ip;
    800057d0:	8ad2                	mv	s5,s4
    800057d2:	b759                	j	80005758 <create+0x72>
    iunlockput(dp);
    800057d4:	8526                	mv	a0,s1
    800057d6:	fffff097          	auipc	ra,0xfffff
    800057da:	84a080e7          	jalr	-1974(ra) # 80004020 <iunlockput>
    return 0;
    800057de:	8ad2                	mv	s5,s4
    800057e0:	bfa5                	j	80005758 <create+0x72>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800057e2:	004a2603          	lw	a2,4(s4)
    800057e6:	00003597          	auipc	a1,0x3
    800057ea:	10a58593          	addi	a1,a1,266 # 800088f0 <syscalls+0x2e0>
    800057ee:	8552                	mv	a0,s4
    800057f0:	fffff097          	auipc	ra,0xfffff
    800057f4:	cc2080e7          	jalr	-830(ra) # 800044b2 <dirlink>
    800057f8:	04054463          	bltz	a0,80005840 <create+0x15a>
    800057fc:	40d0                	lw	a2,4(s1)
    800057fe:	00003597          	auipc	a1,0x3
    80005802:	0fa58593          	addi	a1,a1,250 # 800088f8 <syscalls+0x2e8>
    80005806:	8552                	mv	a0,s4
    80005808:	fffff097          	auipc	ra,0xfffff
    8000580c:	caa080e7          	jalr	-854(ra) # 800044b2 <dirlink>
    80005810:	02054863          	bltz	a0,80005840 <create+0x15a>
  if(dirlink(dp, name, ip->inum) < 0)
    80005814:	004a2603          	lw	a2,4(s4)
    80005818:	fb040593          	addi	a1,s0,-80
    8000581c:	8526                	mv	a0,s1
    8000581e:	fffff097          	auipc	ra,0xfffff
    80005822:	c94080e7          	jalr	-876(ra) # 800044b2 <dirlink>
    80005826:	00054d63          	bltz	a0,80005840 <create+0x15a>
    dp->nlink++;  // for ".."
    8000582a:	04a4d783          	lhu	a5,74(s1)
    8000582e:	2785                	addiw	a5,a5,1
    80005830:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005834:	8526                	mv	a0,s1
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	4bc080e7          	jalr	1212(ra) # 80003cf2 <iupdate>
    8000583e:	b761                	j	800057c6 <create+0xe0>
  ip->nlink = 0;
    80005840:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005844:	8552                	mv	a0,s4
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	4ac080e7          	jalr	1196(ra) # 80003cf2 <iupdate>
  iunlockput(ip);
    8000584e:	8552                	mv	a0,s4
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	7d0080e7          	jalr	2000(ra) # 80004020 <iunlockput>
  iunlockput(dp);
    80005858:	8526                	mv	a0,s1
    8000585a:	ffffe097          	auipc	ra,0xffffe
    8000585e:	7c6080e7          	jalr	1990(ra) # 80004020 <iunlockput>
  return 0;
    80005862:	bddd                	j	80005758 <create+0x72>
    return 0;
    80005864:	8aaa                	mv	s5,a0
    80005866:	bdcd                	j	80005758 <create+0x72>

0000000080005868 <sys_dup>:
{
    80005868:	7179                	addi	sp,sp,-48
    8000586a:	f406                	sd	ra,40(sp)
    8000586c:	f022                	sd	s0,32(sp)
    8000586e:	ec26                	sd	s1,24(sp)
    80005870:	e84a                	sd	s2,16(sp)
    80005872:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005874:	fd840613          	addi	a2,s0,-40
    80005878:	4581                	li	a1,0
    8000587a:	4501                	li	a0,0
    8000587c:	00000097          	auipc	ra,0x0
    80005880:	dc8080e7          	jalr	-568(ra) # 80005644 <argfd>
    return -1;
    80005884:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005886:	02054363          	bltz	a0,800058ac <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000588a:	fd843903          	ld	s2,-40(s0)
    8000588e:	854a                	mv	a0,s2
    80005890:	00000097          	auipc	ra,0x0
    80005894:	e14080e7          	jalr	-492(ra) # 800056a4 <fdalloc>
    80005898:	84aa                	mv	s1,a0
    return -1;
    8000589a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000589c:	00054863          	bltz	a0,800058ac <sys_dup+0x44>
  filedup(f);
    800058a0:	854a                	mv	a0,s2
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	334080e7          	jalr	820(ra) # 80004bd6 <filedup>
  return fd;
    800058aa:	87a6                	mv	a5,s1
}
    800058ac:	853e                	mv	a0,a5
    800058ae:	70a2                	ld	ra,40(sp)
    800058b0:	7402                	ld	s0,32(sp)
    800058b2:	64e2                	ld	s1,24(sp)
    800058b4:	6942                	ld	s2,16(sp)
    800058b6:	6145                	addi	sp,sp,48
    800058b8:	8082                	ret

00000000800058ba <sys_read>:
{
    800058ba:	7179                	addi	sp,sp,-48
    800058bc:	f406                	sd	ra,40(sp)
    800058be:	f022                	sd	s0,32(sp)
    800058c0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800058c2:	fd840593          	addi	a1,s0,-40
    800058c6:	4505                	li	a0,1
    800058c8:	ffffe097          	auipc	ra,0xffffe
    800058cc:	84a080e7          	jalr	-1974(ra) # 80003112 <argaddr>
  argint(2, &n);
    800058d0:	fe440593          	addi	a1,s0,-28
    800058d4:	4509                	li	a0,2
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	81c080e7          	jalr	-2020(ra) # 800030f2 <argint>
  if(argfd(0, 0, &f) < 0)
    800058de:	fe840613          	addi	a2,s0,-24
    800058e2:	4581                	li	a1,0
    800058e4:	4501                	li	a0,0
    800058e6:	00000097          	auipc	ra,0x0
    800058ea:	d5e080e7          	jalr	-674(ra) # 80005644 <argfd>
    800058ee:	87aa                	mv	a5,a0
    return -1;
    800058f0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800058f2:	0007cc63          	bltz	a5,8000590a <sys_read+0x50>
  return fileread(f, p, n);
    800058f6:	fe442603          	lw	a2,-28(s0)
    800058fa:	fd843583          	ld	a1,-40(s0)
    800058fe:	fe843503          	ld	a0,-24(s0)
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	460080e7          	jalr	1120(ra) # 80004d62 <fileread>
}
    8000590a:	70a2                	ld	ra,40(sp)
    8000590c:	7402                	ld	s0,32(sp)
    8000590e:	6145                	addi	sp,sp,48
    80005910:	8082                	ret

0000000080005912 <sys_write>:
{
    80005912:	7179                	addi	sp,sp,-48
    80005914:	f406                	sd	ra,40(sp)
    80005916:	f022                	sd	s0,32(sp)
    80005918:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000591a:	fd840593          	addi	a1,s0,-40
    8000591e:	4505                	li	a0,1
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	7f2080e7          	jalr	2034(ra) # 80003112 <argaddr>
  argint(2, &n);
    80005928:	fe440593          	addi	a1,s0,-28
    8000592c:	4509                	li	a0,2
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	7c4080e7          	jalr	1988(ra) # 800030f2 <argint>
  if(argfd(0, 0, &f) < 0)
    80005936:	fe840613          	addi	a2,s0,-24
    8000593a:	4581                	li	a1,0
    8000593c:	4501                	li	a0,0
    8000593e:	00000097          	auipc	ra,0x0
    80005942:	d06080e7          	jalr	-762(ra) # 80005644 <argfd>
    80005946:	87aa                	mv	a5,a0
    return -1;
    80005948:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000594a:	0007cc63          	bltz	a5,80005962 <sys_write+0x50>
  return filewrite(f, p, n);
    8000594e:	fe442603          	lw	a2,-28(s0)
    80005952:	fd843583          	ld	a1,-40(s0)
    80005956:	fe843503          	ld	a0,-24(s0)
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	4ca080e7          	jalr	1226(ra) # 80004e24 <filewrite>
}
    80005962:	70a2                	ld	ra,40(sp)
    80005964:	7402                	ld	s0,32(sp)
    80005966:	6145                	addi	sp,sp,48
    80005968:	8082                	ret

000000008000596a <sys_close>:
{
    8000596a:	1101                	addi	sp,sp,-32
    8000596c:	ec06                	sd	ra,24(sp)
    8000596e:	e822                	sd	s0,16(sp)
    80005970:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005972:	fe040613          	addi	a2,s0,-32
    80005976:	fec40593          	addi	a1,s0,-20
    8000597a:	4501                	li	a0,0
    8000597c:	00000097          	auipc	ra,0x0
    80005980:	cc8080e7          	jalr	-824(ra) # 80005644 <argfd>
    return -1;
    80005984:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005986:	02054463          	bltz	a0,800059ae <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000598a:	ffffc097          	auipc	ra,0xffffc
    8000598e:	3e2080e7          	jalr	994(ra) # 80001d6c <myproc>
    80005992:	fec42783          	lw	a5,-20(s0)
    80005996:	07e9                	addi	a5,a5,26
    80005998:	078e                	slli	a5,a5,0x3
    8000599a:	953e                	add	a0,a0,a5
    8000599c:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800059a0:	fe043503          	ld	a0,-32(s0)
    800059a4:	fffff097          	auipc	ra,0xfffff
    800059a8:	284080e7          	jalr	644(ra) # 80004c28 <fileclose>
  return 0;
    800059ac:	4781                	li	a5,0
}
    800059ae:	853e                	mv	a0,a5
    800059b0:	60e2                	ld	ra,24(sp)
    800059b2:	6442                	ld	s0,16(sp)
    800059b4:	6105                	addi	sp,sp,32
    800059b6:	8082                	ret

00000000800059b8 <sys_fstat>:
{
    800059b8:	1101                	addi	sp,sp,-32
    800059ba:	ec06                	sd	ra,24(sp)
    800059bc:	e822                	sd	s0,16(sp)
    800059be:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059c0:	fe040593          	addi	a1,s0,-32
    800059c4:	4505                	li	a0,1
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	74c080e7          	jalr	1868(ra) # 80003112 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800059ce:	fe840613          	addi	a2,s0,-24
    800059d2:	4581                	li	a1,0
    800059d4:	4501                	li	a0,0
    800059d6:	00000097          	auipc	ra,0x0
    800059da:	c6e080e7          	jalr	-914(ra) # 80005644 <argfd>
    800059de:	87aa                	mv	a5,a0
    return -1;
    800059e0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800059e2:	0007ca63          	bltz	a5,800059f6 <sys_fstat+0x3e>
  return filestat(f, st);
    800059e6:	fe043583          	ld	a1,-32(s0)
    800059ea:	fe843503          	ld	a0,-24(s0)
    800059ee:	fffff097          	auipc	ra,0xfffff
    800059f2:	302080e7          	jalr	770(ra) # 80004cf0 <filestat>
}
    800059f6:	60e2                	ld	ra,24(sp)
    800059f8:	6442                	ld	s0,16(sp)
    800059fa:	6105                	addi	sp,sp,32
    800059fc:	8082                	ret

00000000800059fe <sys_link>:
{
    800059fe:	7169                	addi	sp,sp,-304
    80005a00:	f606                	sd	ra,296(sp)
    80005a02:	f222                	sd	s0,288(sp)
    80005a04:	ee26                	sd	s1,280(sp)
    80005a06:	ea4a                	sd	s2,272(sp)
    80005a08:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a0a:	08000613          	li	a2,128
    80005a0e:	ed040593          	addi	a1,s0,-304
    80005a12:	4501                	li	a0,0
    80005a14:	ffffd097          	auipc	ra,0xffffd
    80005a18:	71e080e7          	jalr	1822(ra) # 80003132 <argstr>
    return -1;
    80005a1c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a1e:	10054e63          	bltz	a0,80005b3a <sys_link+0x13c>
    80005a22:	08000613          	li	a2,128
    80005a26:	f5040593          	addi	a1,s0,-176
    80005a2a:	4505                	li	a0,1
    80005a2c:	ffffd097          	auipc	ra,0xffffd
    80005a30:	706080e7          	jalr	1798(ra) # 80003132 <argstr>
    return -1;
    80005a34:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a36:	10054263          	bltz	a0,80005b3a <sys_link+0x13c>
  begin_op();
    80005a3a:	fffff097          	auipc	ra,0xfffff
    80005a3e:	d2a080e7          	jalr	-726(ra) # 80004764 <begin_op>
  if((ip = namei(old)) == 0){
    80005a42:	ed040513          	addi	a0,s0,-304
    80005a46:	fffff097          	auipc	ra,0xfffff
    80005a4a:	b1e080e7          	jalr	-1250(ra) # 80004564 <namei>
    80005a4e:	84aa                	mv	s1,a0
    80005a50:	c551                	beqz	a0,80005adc <sys_link+0xde>
  ilock(ip);
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	36c080e7          	jalr	876(ra) # 80003dbe <ilock>
  if(ip->type == T_DIR){
    80005a5a:	04449703          	lh	a4,68(s1)
    80005a5e:	4785                	li	a5,1
    80005a60:	08f70463          	beq	a4,a5,80005ae8 <sys_link+0xea>
  ip->nlink++;
    80005a64:	04a4d783          	lhu	a5,74(s1)
    80005a68:	2785                	addiw	a5,a5,1
    80005a6a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005a6e:	8526                	mv	a0,s1
    80005a70:	ffffe097          	auipc	ra,0xffffe
    80005a74:	282080e7          	jalr	642(ra) # 80003cf2 <iupdate>
  iunlock(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	406080e7          	jalr	1030(ra) # 80003e80 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005a82:	fd040593          	addi	a1,s0,-48
    80005a86:	f5040513          	addi	a0,s0,-176
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	af8080e7          	jalr	-1288(ra) # 80004582 <nameiparent>
    80005a92:	892a                	mv	s2,a0
    80005a94:	c935                	beqz	a0,80005b08 <sys_link+0x10a>
  ilock(dp);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	328080e7          	jalr	808(ra) # 80003dbe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005a9e:	00092703          	lw	a4,0(s2)
    80005aa2:	409c                	lw	a5,0(s1)
    80005aa4:	04f71d63          	bne	a4,a5,80005afe <sys_link+0x100>
    80005aa8:	40d0                	lw	a2,4(s1)
    80005aaa:	fd040593          	addi	a1,s0,-48
    80005aae:	854a                	mv	a0,s2
    80005ab0:	fffff097          	auipc	ra,0xfffff
    80005ab4:	a02080e7          	jalr	-1534(ra) # 800044b2 <dirlink>
    80005ab8:	04054363          	bltz	a0,80005afe <sys_link+0x100>
  iunlockput(dp);
    80005abc:	854a                	mv	a0,s2
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	562080e7          	jalr	1378(ra) # 80004020 <iunlockput>
  iput(ip);
    80005ac6:	8526                	mv	a0,s1
    80005ac8:	ffffe097          	auipc	ra,0xffffe
    80005acc:	4b0080e7          	jalr	1200(ra) # 80003f78 <iput>
  end_op();
    80005ad0:	fffff097          	auipc	ra,0xfffff
    80005ad4:	d0e080e7          	jalr	-754(ra) # 800047de <end_op>
  return 0;
    80005ad8:	4781                	li	a5,0
    80005ada:	a085                	j	80005b3a <sys_link+0x13c>
    end_op();
    80005adc:	fffff097          	auipc	ra,0xfffff
    80005ae0:	d02080e7          	jalr	-766(ra) # 800047de <end_op>
    return -1;
    80005ae4:	57fd                	li	a5,-1
    80005ae6:	a891                	j	80005b3a <sys_link+0x13c>
    iunlockput(ip);
    80005ae8:	8526                	mv	a0,s1
    80005aea:	ffffe097          	auipc	ra,0xffffe
    80005aee:	536080e7          	jalr	1334(ra) # 80004020 <iunlockput>
    end_op();
    80005af2:	fffff097          	auipc	ra,0xfffff
    80005af6:	cec080e7          	jalr	-788(ra) # 800047de <end_op>
    return -1;
    80005afa:	57fd                	li	a5,-1
    80005afc:	a83d                	j	80005b3a <sys_link+0x13c>
    iunlockput(dp);
    80005afe:	854a                	mv	a0,s2
    80005b00:	ffffe097          	auipc	ra,0xffffe
    80005b04:	520080e7          	jalr	1312(ra) # 80004020 <iunlockput>
  ilock(ip);
    80005b08:	8526                	mv	a0,s1
    80005b0a:	ffffe097          	auipc	ra,0xffffe
    80005b0e:	2b4080e7          	jalr	692(ra) # 80003dbe <ilock>
  ip->nlink--;
    80005b12:	04a4d783          	lhu	a5,74(s1)
    80005b16:	37fd                	addiw	a5,a5,-1
    80005b18:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	ffffe097          	auipc	ra,0xffffe
    80005b22:	1d4080e7          	jalr	468(ra) # 80003cf2 <iupdate>
  iunlockput(ip);
    80005b26:	8526                	mv	a0,s1
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	4f8080e7          	jalr	1272(ra) # 80004020 <iunlockput>
  end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	cae080e7          	jalr	-850(ra) # 800047de <end_op>
  return -1;
    80005b38:	57fd                	li	a5,-1
}
    80005b3a:	853e                	mv	a0,a5
    80005b3c:	70b2                	ld	ra,296(sp)
    80005b3e:	7412                	ld	s0,288(sp)
    80005b40:	64f2                	ld	s1,280(sp)
    80005b42:	6952                	ld	s2,272(sp)
    80005b44:	6155                	addi	sp,sp,304
    80005b46:	8082                	ret

0000000080005b48 <sys_unlink>:
{
    80005b48:	7151                	addi	sp,sp,-240
    80005b4a:	f586                	sd	ra,232(sp)
    80005b4c:	f1a2                	sd	s0,224(sp)
    80005b4e:	eda6                	sd	s1,216(sp)
    80005b50:	e9ca                	sd	s2,208(sp)
    80005b52:	e5ce                	sd	s3,200(sp)
    80005b54:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b56:	08000613          	li	a2,128
    80005b5a:	f3040593          	addi	a1,s0,-208
    80005b5e:	4501                	li	a0,0
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	5d2080e7          	jalr	1490(ra) # 80003132 <argstr>
    80005b68:	18054163          	bltz	a0,80005cea <sys_unlink+0x1a2>
  begin_op();
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	bf8080e7          	jalr	-1032(ra) # 80004764 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005b74:	fb040593          	addi	a1,s0,-80
    80005b78:	f3040513          	addi	a0,s0,-208
    80005b7c:	fffff097          	auipc	ra,0xfffff
    80005b80:	a06080e7          	jalr	-1530(ra) # 80004582 <nameiparent>
    80005b84:	84aa                	mv	s1,a0
    80005b86:	c979                	beqz	a0,80005c5c <sys_unlink+0x114>
  ilock(dp);
    80005b88:	ffffe097          	auipc	ra,0xffffe
    80005b8c:	236080e7          	jalr	566(ra) # 80003dbe <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005b90:	00003597          	auipc	a1,0x3
    80005b94:	d6058593          	addi	a1,a1,-672 # 800088f0 <syscalls+0x2e0>
    80005b98:	fb040513          	addi	a0,s0,-80
    80005b9c:	ffffe097          	auipc	ra,0xffffe
    80005ba0:	6ec080e7          	jalr	1772(ra) # 80004288 <namecmp>
    80005ba4:	14050a63          	beqz	a0,80005cf8 <sys_unlink+0x1b0>
    80005ba8:	00003597          	auipc	a1,0x3
    80005bac:	d5058593          	addi	a1,a1,-688 # 800088f8 <syscalls+0x2e8>
    80005bb0:	fb040513          	addi	a0,s0,-80
    80005bb4:	ffffe097          	auipc	ra,0xffffe
    80005bb8:	6d4080e7          	jalr	1748(ra) # 80004288 <namecmp>
    80005bbc:	12050e63          	beqz	a0,80005cf8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bc0:	f2c40613          	addi	a2,s0,-212
    80005bc4:	fb040593          	addi	a1,s0,-80
    80005bc8:	8526                	mv	a0,s1
    80005bca:	ffffe097          	auipc	ra,0xffffe
    80005bce:	6d8080e7          	jalr	1752(ra) # 800042a2 <dirlookup>
    80005bd2:	892a                	mv	s2,a0
    80005bd4:	12050263          	beqz	a0,80005cf8 <sys_unlink+0x1b0>
  ilock(ip);
    80005bd8:	ffffe097          	auipc	ra,0xffffe
    80005bdc:	1e6080e7          	jalr	486(ra) # 80003dbe <ilock>
  if(ip->nlink < 1)
    80005be0:	04a91783          	lh	a5,74(s2)
    80005be4:	08f05263          	blez	a5,80005c68 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005be8:	04491703          	lh	a4,68(s2)
    80005bec:	4785                	li	a5,1
    80005bee:	08f70563          	beq	a4,a5,80005c78 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005bf2:	4641                	li	a2,16
    80005bf4:	4581                	li	a1,0
    80005bf6:	fc040513          	addi	a0,s0,-64
    80005bfa:	ffffb097          	auipc	ra,0xffffb
    80005bfe:	2da080e7          	jalr	730(ra) # 80000ed4 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c02:	4741                	li	a4,16
    80005c04:	f2c42683          	lw	a3,-212(s0)
    80005c08:	fc040613          	addi	a2,s0,-64
    80005c0c:	4581                	li	a1,0
    80005c0e:	8526                	mv	a0,s1
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	55a080e7          	jalr	1370(ra) # 8000416a <writei>
    80005c18:	47c1                	li	a5,16
    80005c1a:	0af51563          	bne	a0,a5,80005cc4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c1e:	04491703          	lh	a4,68(s2)
    80005c22:	4785                	li	a5,1
    80005c24:	0af70863          	beq	a4,a5,80005cd4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c28:	8526                	mv	a0,s1
    80005c2a:	ffffe097          	auipc	ra,0xffffe
    80005c2e:	3f6080e7          	jalr	1014(ra) # 80004020 <iunlockput>
  ip->nlink--;
    80005c32:	04a95783          	lhu	a5,74(s2)
    80005c36:	37fd                	addiw	a5,a5,-1
    80005c38:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c3c:	854a                	mv	a0,s2
    80005c3e:	ffffe097          	auipc	ra,0xffffe
    80005c42:	0b4080e7          	jalr	180(ra) # 80003cf2 <iupdate>
  iunlockput(ip);
    80005c46:	854a                	mv	a0,s2
    80005c48:	ffffe097          	auipc	ra,0xffffe
    80005c4c:	3d8080e7          	jalr	984(ra) # 80004020 <iunlockput>
  end_op();
    80005c50:	fffff097          	auipc	ra,0xfffff
    80005c54:	b8e080e7          	jalr	-1138(ra) # 800047de <end_op>
  return 0;
    80005c58:	4501                	li	a0,0
    80005c5a:	a84d                	j	80005d0c <sys_unlink+0x1c4>
    end_op();
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	b82080e7          	jalr	-1150(ra) # 800047de <end_op>
    return -1;
    80005c64:	557d                	li	a0,-1
    80005c66:	a05d                	j	80005d0c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005c68:	00003517          	auipc	a0,0x3
    80005c6c:	c9850513          	addi	a0,a0,-872 # 80008900 <syscalls+0x2f0>
    80005c70:	ffffb097          	auipc	ra,0xffffb
    80005c74:	8cc080e7          	jalr	-1844(ra) # 8000053c <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005c78:	04c92703          	lw	a4,76(s2)
    80005c7c:	02000793          	li	a5,32
    80005c80:	f6e7f9e3          	bgeu	a5,a4,80005bf2 <sys_unlink+0xaa>
    80005c84:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c88:	4741                	li	a4,16
    80005c8a:	86ce                	mv	a3,s3
    80005c8c:	f1840613          	addi	a2,s0,-232
    80005c90:	4581                	li	a1,0
    80005c92:	854a                	mv	a0,s2
    80005c94:	ffffe097          	auipc	ra,0xffffe
    80005c98:	3de080e7          	jalr	990(ra) # 80004072 <readi>
    80005c9c:	47c1                	li	a5,16
    80005c9e:	00f51b63          	bne	a0,a5,80005cb4 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ca2:	f1845783          	lhu	a5,-232(s0)
    80005ca6:	e7a1                	bnez	a5,80005cee <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ca8:	29c1                	addiw	s3,s3,16
    80005caa:	04c92783          	lw	a5,76(s2)
    80005cae:	fcf9ede3          	bltu	s3,a5,80005c88 <sys_unlink+0x140>
    80005cb2:	b781                	j	80005bf2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cb4:	00003517          	auipc	a0,0x3
    80005cb8:	c6450513          	addi	a0,a0,-924 # 80008918 <syscalls+0x308>
    80005cbc:	ffffb097          	auipc	ra,0xffffb
    80005cc0:	880080e7          	jalr	-1920(ra) # 8000053c <panic>
    panic("unlink: writei");
    80005cc4:	00003517          	auipc	a0,0x3
    80005cc8:	c6c50513          	addi	a0,a0,-916 # 80008930 <syscalls+0x320>
    80005ccc:	ffffb097          	auipc	ra,0xffffb
    80005cd0:	870080e7          	jalr	-1936(ra) # 8000053c <panic>
    dp->nlink--;
    80005cd4:	04a4d783          	lhu	a5,74(s1)
    80005cd8:	37fd                	addiw	a5,a5,-1
    80005cda:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	012080e7          	jalr	18(ra) # 80003cf2 <iupdate>
    80005ce8:	b781                	j	80005c28 <sys_unlink+0xe0>
    return -1;
    80005cea:	557d                	li	a0,-1
    80005cec:	a005                	j	80005d0c <sys_unlink+0x1c4>
    iunlockput(ip);
    80005cee:	854a                	mv	a0,s2
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	330080e7          	jalr	816(ra) # 80004020 <iunlockput>
  iunlockput(dp);
    80005cf8:	8526                	mv	a0,s1
    80005cfa:	ffffe097          	auipc	ra,0xffffe
    80005cfe:	326080e7          	jalr	806(ra) # 80004020 <iunlockput>
  end_op();
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	adc080e7          	jalr	-1316(ra) # 800047de <end_op>
  return -1;
    80005d0a:	557d                	li	a0,-1
}
    80005d0c:	70ae                	ld	ra,232(sp)
    80005d0e:	740e                	ld	s0,224(sp)
    80005d10:	64ee                	ld	s1,216(sp)
    80005d12:	694e                	ld	s2,208(sp)
    80005d14:	69ae                	ld	s3,200(sp)
    80005d16:	616d                	addi	sp,sp,240
    80005d18:	8082                	ret

0000000080005d1a <sys_open>:

uint64
sys_open(void)
{
    80005d1a:	7131                	addi	sp,sp,-192
    80005d1c:	fd06                	sd	ra,184(sp)
    80005d1e:	f922                	sd	s0,176(sp)
    80005d20:	f526                	sd	s1,168(sp)
    80005d22:	f14a                	sd	s2,160(sp)
    80005d24:	ed4e                	sd	s3,152(sp)
    80005d26:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d28:	f4c40593          	addi	a1,s0,-180
    80005d2c:	4505                	li	a0,1
    80005d2e:	ffffd097          	auipc	ra,0xffffd
    80005d32:	3c4080e7          	jalr	964(ra) # 800030f2 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d36:	08000613          	li	a2,128
    80005d3a:	f5040593          	addi	a1,s0,-176
    80005d3e:	4501                	li	a0,0
    80005d40:	ffffd097          	auipc	ra,0xffffd
    80005d44:	3f2080e7          	jalr	1010(ra) # 80003132 <argstr>
    80005d48:	87aa                	mv	a5,a0
    return -1;
    80005d4a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d4c:	0a07c863          	bltz	a5,80005dfc <sys_open+0xe2>

  begin_op();
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	a14080e7          	jalr	-1516(ra) # 80004764 <begin_op>

  if(omode & O_CREATE){
    80005d58:	f4c42783          	lw	a5,-180(s0)
    80005d5c:	2007f793          	andi	a5,a5,512
    80005d60:	cbdd                	beqz	a5,80005e16 <sys_open+0xfc>
    ip = create(path, T_FILE, 0, 0);
    80005d62:	4681                	li	a3,0
    80005d64:	4601                	li	a2,0
    80005d66:	4589                	li	a1,2
    80005d68:	f5040513          	addi	a0,s0,-176
    80005d6c:	00000097          	auipc	ra,0x0
    80005d70:	97a080e7          	jalr	-1670(ra) # 800056e6 <create>
    80005d74:	84aa                	mv	s1,a0
    if(ip == 0){
    80005d76:	c951                	beqz	a0,80005e0a <sys_open+0xf0>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005d78:	04449703          	lh	a4,68(s1)
    80005d7c:	478d                	li	a5,3
    80005d7e:	00f71763          	bne	a4,a5,80005d8c <sys_open+0x72>
    80005d82:	0464d703          	lhu	a4,70(s1)
    80005d86:	47a5                	li	a5,9
    80005d88:	0ce7ec63          	bltu	a5,a4,80005e60 <sys_open+0x146>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	de0080e7          	jalr	-544(ra) # 80004b6c <filealloc>
    80005d94:	892a                	mv	s2,a0
    80005d96:	c56d                	beqz	a0,80005e80 <sys_open+0x166>
    80005d98:	00000097          	auipc	ra,0x0
    80005d9c:	90c080e7          	jalr	-1780(ra) # 800056a4 <fdalloc>
    80005da0:	89aa                	mv	s3,a0
    80005da2:	0c054a63          	bltz	a0,80005e76 <sys_open+0x15c>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005da6:	04449703          	lh	a4,68(s1)
    80005daa:	478d                	li	a5,3
    80005dac:	0ef70563          	beq	a4,a5,80005e96 <sys_open+0x17c>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005db0:	4789                	li	a5,2
    80005db2:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005db6:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005dba:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    80005dbe:	f4c42783          	lw	a5,-180(s0)
    80005dc2:	0017c713          	xori	a4,a5,1
    80005dc6:	8b05                	andi	a4,a4,1
    80005dc8:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005dcc:	0037f713          	andi	a4,a5,3
    80005dd0:	00e03733          	snez	a4,a4
    80005dd4:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005dd8:	4007f793          	andi	a5,a5,1024
    80005ddc:	c791                	beqz	a5,80005de8 <sys_open+0xce>
    80005dde:	04449703          	lh	a4,68(s1)
    80005de2:	4789                	li	a5,2
    80005de4:	0cf70063          	beq	a4,a5,80005ea4 <sys_open+0x18a>
    itrunc(ip);
  }

  iunlock(ip);
    80005de8:	8526                	mv	a0,s1
    80005dea:	ffffe097          	auipc	ra,0xffffe
    80005dee:	096080e7          	jalr	150(ra) # 80003e80 <iunlock>
  end_op();
    80005df2:	fffff097          	auipc	ra,0xfffff
    80005df6:	9ec080e7          	jalr	-1556(ra) # 800047de <end_op>

  return fd;
    80005dfa:	854e                	mv	a0,s3
}
    80005dfc:	70ea                	ld	ra,184(sp)
    80005dfe:	744a                	ld	s0,176(sp)
    80005e00:	74aa                	ld	s1,168(sp)
    80005e02:	790a                	ld	s2,160(sp)
    80005e04:	69ea                	ld	s3,152(sp)
    80005e06:	6129                	addi	sp,sp,192
    80005e08:	8082                	ret
      end_op();
    80005e0a:	fffff097          	auipc	ra,0xfffff
    80005e0e:	9d4080e7          	jalr	-1580(ra) # 800047de <end_op>
      return -1;
    80005e12:	557d                	li	a0,-1
    80005e14:	b7e5                	j	80005dfc <sys_open+0xe2>
    if((ip = namei(path)) == 0){
    80005e16:	f5040513          	addi	a0,s0,-176
    80005e1a:	ffffe097          	auipc	ra,0xffffe
    80005e1e:	74a080e7          	jalr	1866(ra) # 80004564 <namei>
    80005e22:	84aa                	mv	s1,a0
    80005e24:	c905                	beqz	a0,80005e54 <sys_open+0x13a>
    ilock(ip);
    80005e26:	ffffe097          	auipc	ra,0xffffe
    80005e2a:	f98080e7          	jalr	-104(ra) # 80003dbe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e2e:	04449703          	lh	a4,68(s1)
    80005e32:	4785                	li	a5,1
    80005e34:	f4f712e3          	bne	a4,a5,80005d78 <sys_open+0x5e>
    80005e38:	f4c42783          	lw	a5,-180(s0)
    80005e3c:	dba1                	beqz	a5,80005d8c <sys_open+0x72>
      iunlockput(ip);
    80005e3e:	8526                	mv	a0,s1
    80005e40:	ffffe097          	auipc	ra,0xffffe
    80005e44:	1e0080e7          	jalr	480(ra) # 80004020 <iunlockput>
      end_op();
    80005e48:	fffff097          	auipc	ra,0xfffff
    80005e4c:	996080e7          	jalr	-1642(ra) # 800047de <end_op>
      return -1;
    80005e50:	557d                	li	a0,-1
    80005e52:	b76d                	j	80005dfc <sys_open+0xe2>
      end_op();
    80005e54:	fffff097          	auipc	ra,0xfffff
    80005e58:	98a080e7          	jalr	-1654(ra) # 800047de <end_op>
      return -1;
    80005e5c:	557d                	li	a0,-1
    80005e5e:	bf79                	j	80005dfc <sys_open+0xe2>
    iunlockput(ip);
    80005e60:	8526                	mv	a0,s1
    80005e62:	ffffe097          	auipc	ra,0xffffe
    80005e66:	1be080e7          	jalr	446(ra) # 80004020 <iunlockput>
    end_op();
    80005e6a:	fffff097          	auipc	ra,0xfffff
    80005e6e:	974080e7          	jalr	-1676(ra) # 800047de <end_op>
    return -1;
    80005e72:	557d                	li	a0,-1
    80005e74:	b761                	j	80005dfc <sys_open+0xe2>
      fileclose(f);
    80005e76:	854a                	mv	a0,s2
    80005e78:	fffff097          	auipc	ra,0xfffff
    80005e7c:	db0080e7          	jalr	-592(ra) # 80004c28 <fileclose>
    iunlockput(ip);
    80005e80:	8526                	mv	a0,s1
    80005e82:	ffffe097          	auipc	ra,0xffffe
    80005e86:	19e080e7          	jalr	414(ra) # 80004020 <iunlockput>
    end_op();
    80005e8a:	fffff097          	auipc	ra,0xfffff
    80005e8e:	954080e7          	jalr	-1708(ra) # 800047de <end_op>
    return -1;
    80005e92:	557d                	li	a0,-1
    80005e94:	b7a5                	j	80005dfc <sys_open+0xe2>
    f->type = FD_DEVICE;
    80005e96:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005e9a:	04649783          	lh	a5,70(s1)
    80005e9e:	02f91223          	sh	a5,36(s2)
    80005ea2:	bf21                	j	80005dba <sys_open+0xa0>
    itrunc(ip);
    80005ea4:	8526                	mv	a0,s1
    80005ea6:	ffffe097          	auipc	ra,0xffffe
    80005eaa:	026080e7          	jalr	38(ra) # 80003ecc <itrunc>
    80005eae:	bf2d                	j	80005de8 <sys_open+0xce>

0000000080005eb0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005eb0:	7175                	addi	sp,sp,-144
    80005eb2:	e506                	sd	ra,136(sp)
    80005eb4:	e122                	sd	s0,128(sp)
    80005eb6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005eb8:	fffff097          	auipc	ra,0xfffff
    80005ebc:	8ac080e7          	jalr	-1876(ra) # 80004764 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005ec0:	08000613          	li	a2,128
    80005ec4:	f7040593          	addi	a1,s0,-144
    80005ec8:	4501                	li	a0,0
    80005eca:	ffffd097          	auipc	ra,0xffffd
    80005ece:	268080e7          	jalr	616(ra) # 80003132 <argstr>
    80005ed2:	02054963          	bltz	a0,80005f04 <sys_mkdir+0x54>
    80005ed6:	4681                	li	a3,0
    80005ed8:	4601                	li	a2,0
    80005eda:	4585                	li	a1,1
    80005edc:	f7040513          	addi	a0,s0,-144
    80005ee0:	00000097          	auipc	ra,0x0
    80005ee4:	806080e7          	jalr	-2042(ra) # 800056e6 <create>
    80005ee8:	cd11                	beqz	a0,80005f04 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005eea:	ffffe097          	auipc	ra,0xffffe
    80005eee:	136080e7          	jalr	310(ra) # 80004020 <iunlockput>
  end_op();
    80005ef2:	fffff097          	auipc	ra,0xfffff
    80005ef6:	8ec080e7          	jalr	-1812(ra) # 800047de <end_op>
  return 0;
    80005efa:	4501                	li	a0,0
}
    80005efc:	60aa                	ld	ra,136(sp)
    80005efe:	640a                	ld	s0,128(sp)
    80005f00:	6149                	addi	sp,sp,144
    80005f02:	8082                	ret
    end_op();
    80005f04:	fffff097          	auipc	ra,0xfffff
    80005f08:	8da080e7          	jalr	-1830(ra) # 800047de <end_op>
    return -1;
    80005f0c:	557d                	li	a0,-1
    80005f0e:	b7fd                	j	80005efc <sys_mkdir+0x4c>

0000000080005f10 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f10:	7135                	addi	sp,sp,-160
    80005f12:	ed06                	sd	ra,152(sp)
    80005f14:	e922                	sd	s0,144(sp)
    80005f16:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	84c080e7          	jalr	-1972(ra) # 80004764 <begin_op>
  argint(1, &major);
    80005f20:	f6c40593          	addi	a1,s0,-148
    80005f24:	4505                	li	a0,1
    80005f26:	ffffd097          	auipc	ra,0xffffd
    80005f2a:	1cc080e7          	jalr	460(ra) # 800030f2 <argint>
  argint(2, &minor);
    80005f2e:	f6840593          	addi	a1,s0,-152
    80005f32:	4509                	li	a0,2
    80005f34:	ffffd097          	auipc	ra,0xffffd
    80005f38:	1be080e7          	jalr	446(ra) # 800030f2 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f3c:	08000613          	li	a2,128
    80005f40:	f7040593          	addi	a1,s0,-144
    80005f44:	4501                	li	a0,0
    80005f46:	ffffd097          	auipc	ra,0xffffd
    80005f4a:	1ec080e7          	jalr	492(ra) # 80003132 <argstr>
    80005f4e:	02054b63          	bltz	a0,80005f84 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f52:	f6841683          	lh	a3,-152(s0)
    80005f56:	f6c41603          	lh	a2,-148(s0)
    80005f5a:	458d                	li	a1,3
    80005f5c:	f7040513          	addi	a0,s0,-144
    80005f60:	fffff097          	auipc	ra,0xfffff
    80005f64:	786080e7          	jalr	1926(ra) # 800056e6 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f68:	cd11                	beqz	a0,80005f84 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f6a:	ffffe097          	auipc	ra,0xffffe
    80005f6e:	0b6080e7          	jalr	182(ra) # 80004020 <iunlockput>
  end_op();
    80005f72:	fffff097          	auipc	ra,0xfffff
    80005f76:	86c080e7          	jalr	-1940(ra) # 800047de <end_op>
  return 0;
    80005f7a:	4501                	li	a0,0
}
    80005f7c:	60ea                	ld	ra,152(sp)
    80005f7e:	644a                	ld	s0,144(sp)
    80005f80:	610d                	addi	sp,sp,160
    80005f82:	8082                	ret
    end_op();
    80005f84:	fffff097          	auipc	ra,0xfffff
    80005f88:	85a080e7          	jalr	-1958(ra) # 800047de <end_op>
    return -1;
    80005f8c:	557d                	li	a0,-1
    80005f8e:	b7fd                	j	80005f7c <sys_mknod+0x6c>

0000000080005f90 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005f90:	7135                	addi	sp,sp,-160
    80005f92:	ed06                	sd	ra,152(sp)
    80005f94:	e922                	sd	s0,144(sp)
    80005f96:	e526                	sd	s1,136(sp)
    80005f98:	e14a                	sd	s2,128(sp)
    80005f9a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005f9c:	ffffc097          	auipc	ra,0xffffc
    80005fa0:	dd0080e7          	jalr	-560(ra) # 80001d6c <myproc>
    80005fa4:	892a                	mv	s2,a0
  
  begin_op();
    80005fa6:	ffffe097          	auipc	ra,0xffffe
    80005faa:	7be080e7          	jalr	1982(ra) # 80004764 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fae:	08000613          	li	a2,128
    80005fb2:	f6040593          	addi	a1,s0,-160
    80005fb6:	4501                	li	a0,0
    80005fb8:	ffffd097          	auipc	ra,0xffffd
    80005fbc:	17a080e7          	jalr	378(ra) # 80003132 <argstr>
    80005fc0:	04054b63          	bltz	a0,80006016 <sys_chdir+0x86>
    80005fc4:	f6040513          	addi	a0,s0,-160
    80005fc8:	ffffe097          	auipc	ra,0xffffe
    80005fcc:	59c080e7          	jalr	1436(ra) # 80004564 <namei>
    80005fd0:	84aa                	mv	s1,a0
    80005fd2:	c131                	beqz	a0,80006016 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005fd4:	ffffe097          	auipc	ra,0xffffe
    80005fd8:	dea080e7          	jalr	-534(ra) # 80003dbe <ilock>
  if(ip->type != T_DIR){
    80005fdc:	04449703          	lh	a4,68(s1)
    80005fe0:	4785                	li	a5,1
    80005fe2:	04f71063          	bne	a4,a5,80006022 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005fe6:	8526                	mv	a0,s1
    80005fe8:	ffffe097          	auipc	ra,0xffffe
    80005fec:	e98080e7          	jalr	-360(ra) # 80003e80 <iunlock>
  iput(p->cwd);
    80005ff0:	15093503          	ld	a0,336(s2)
    80005ff4:	ffffe097          	auipc	ra,0xffffe
    80005ff8:	f84080e7          	jalr	-124(ra) # 80003f78 <iput>
  end_op();
    80005ffc:	ffffe097          	auipc	ra,0xffffe
    80006000:	7e2080e7          	jalr	2018(ra) # 800047de <end_op>
  p->cwd = ip;
    80006004:	14993823          	sd	s1,336(s2)
  return 0;
    80006008:	4501                	li	a0,0
}
    8000600a:	60ea                	ld	ra,152(sp)
    8000600c:	644a                	ld	s0,144(sp)
    8000600e:	64aa                	ld	s1,136(sp)
    80006010:	690a                	ld	s2,128(sp)
    80006012:	610d                	addi	sp,sp,160
    80006014:	8082                	ret
    end_op();
    80006016:	ffffe097          	auipc	ra,0xffffe
    8000601a:	7c8080e7          	jalr	1992(ra) # 800047de <end_op>
    return -1;
    8000601e:	557d                	li	a0,-1
    80006020:	b7ed                	j	8000600a <sys_chdir+0x7a>
    iunlockput(ip);
    80006022:	8526                	mv	a0,s1
    80006024:	ffffe097          	auipc	ra,0xffffe
    80006028:	ffc080e7          	jalr	-4(ra) # 80004020 <iunlockput>
    end_op();
    8000602c:	ffffe097          	auipc	ra,0xffffe
    80006030:	7b2080e7          	jalr	1970(ra) # 800047de <end_op>
    return -1;
    80006034:	557d                	li	a0,-1
    80006036:	bfd1                	j	8000600a <sys_chdir+0x7a>

0000000080006038 <sys_exec>:

uint64
sys_exec(void)
{
    80006038:	7121                	addi	sp,sp,-448
    8000603a:	ff06                	sd	ra,440(sp)
    8000603c:	fb22                	sd	s0,432(sp)
    8000603e:	f726                	sd	s1,424(sp)
    80006040:	f34a                	sd	s2,416(sp)
    80006042:	ef4e                	sd	s3,408(sp)
    80006044:	eb52                	sd	s4,400(sp)
    80006046:	0380                	addi	s0,sp,448
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006048:	e4840593          	addi	a1,s0,-440
    8000604c:	4505                	li	a0,1
    8000604e:	ffffd097          	auipc	ra,0xffffd
    80006052:	0c4080e7          	jalr	196(ra) # 80003112 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006056:	08000613          	li	a2,128
    8000605a:	f5040593          	addi	a1,s0,-176
    8000605e:	4501                	li	a0,0
    80006060:	ffffd097          	auipc	ra,0xffffd
    80006064:	0d2080e7          	jalr	210(ra) # 80003132 <argstr>
    80006068:	87aa                	mv	a5,a0
    return -1;
    8000606a:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    8000606c:	0c07c263          	bltz	a5,80006130 <sys_exec+0xf8>
  }
  memset(argv, 0, sizeof(argv));
    80006070:	10000613          	li	a2,256
    80006074:	4581                	li	a1,0
    80006076:	e5040513          	addi	a0,s0,-432
    8000607a:	ffffb097          	auipc	ra,0xffffb
    8000607e:	e5a080e7          	jalr	-422(ra) # 80000ed4 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80006082:	e5040493          	addi	s1,s0,-432
  memset(argv, 0, sizeof(argv));
    80006086:	89a6                	mv	s3,s1
    80006088:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    8000608a:	02000a13          	li	s4,32
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000608e:	00391513          	slli	a0,s2,0x3
    80006092:	e4040593          	addi	a1,s0,-448
    80006096:	e4843783          	ld	a5,-440(s0)
    8000609a:	953e                	add	a0,a0,a5
    8000609c:	ffffd097          	auipc	ra,0xffffd
    800060a0:	fb8080e7          	jalr	-72(ra) # 80003054 <fetchaddr>
    800060a4:	02054a63          	bltz	a0,800060d8 <sys_exec+0xa0>
      goto bad;
    }
    if(uarg == 0){
    800060a8:	e4043783          	ld	a5,-448(s0)
    800060ac:	c3b9                	beqz	a5,800060f2 <sys_exec+0xba>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060ae:	ffffb097          	auipc	ra,0xffffb
    800060b2:	bb0080e7          	jalr	-1104(ra) # 80000c5e <kalloc>
    800060b6:	85aa                	mv	a1,a0
    800060b8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800060bc:	cd11                	beqz	a0,800060d8 <sys_exec+0xa0>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800060be:	6605                	lui	a2,0x1
    800060c0:	e4043503          	ld	a0,-448(s0)
    800060c4:	ffffd097          	auipc	ra,0xffffd
    800060c8:	fe2080e7          	jalr	-30(ra) # 800030a6 <fetchstr>
    800060cc:	00054663          	bltz	a0,800060d8 <sys_exec+0xa0>
    if(i >= NELEM(argv)){
    800060d0:	0905                	addi	s2,s2,1
    800060d2:	09a1                	addi	s3,s3,8
    800060d4:	fb491de3          	bne	s2,s4,8000608e <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060d8:	f5040913          	addi	s2,s0,-176
    800060dc:	6088                	ld	a0,0(s1)
    800060de:	c921                	beqz	a0,8000612e <sys_exec+0xf6>
    kfree(argv[i]);
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	992080e7          	jalr	-1646(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800060e8:	04a1                	addi	s1,s1,8
    800060ea:	ff2499e3          	bne	s1,s2,800060dc <sys_exec+0xa4>
  return -1;
    800060ee:	557d                	li	a0,-1
    800060f0:	a081                	j	80006130 <sys_exec+0xf8>
      argv[i] = 0;
    800060f2:	0009079b          	sext.w	a5,s2
    800060f6:	078e                	slli	a5,a5,0x3
    800060f8:	fd078793          	addi	a5,a5,-48
    800060fc:	97a2                	add	a5,a5,s0
    800060fe:	e807b023          	sd	zero,-384(a5)
  int ret = exec(path, argv);
    80006102:	e5040593          	addi	a1,s0,-432
    80006106:	f5040513          	addi	a0,s0,-176
    8000610a:	fffff097          	auipc	ra,0xfffff
    8000610e:	194080e7          	jalr	404(ra) # 8000529e <exec>
    80006112:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006114:	f5040993          	addi	s3,s0,-176
    80006118:	6088                	ld	a0,0(s1)
    8000611a:	c901                	beqz	a0,8000612a <sys_exec+0xf2>
    kfree(argv[i]);
    8000611c:	ffffb097          	auipc	ra,0xffffb
    80006120:	956080e7          	jalr	-1706(ra) # 80000a72 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006124:	04a1                	addi	s1,s1,8
    80006126:	ff3499e3          	bne	s1,s3,80006118 <sys_exec+0xe0>
  return ret;
    8000612a:	854a                	mv	a0,s2
    8000612c:	a011                	j	80006130 <sys_exec+0xf8>
  return -1;
    8000612e:	557d                	li	a0,-1
}
    80006130:	70fa                	ld	ra,440(sp)
    80006132:	745a                	ld	s0,432(sp)
    80006134:	74ba                	ld	s1,424(sp)
    80006136:	791a                	ld	s2,416(sp)
    80006138:	69fa                	ld	s3,408(sp)
    8000613a:	6a5a                	ld	s4,400(sp)
    8000613c:	6139                	addi	sp,sp,448
    8000613e:	8082                	ret

0000000080006140 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006140:	7139                	addi	sp,sp,-64
    80006142:	fc06                	sd	ra,56(sp)
    80006144:	f822                	sd	s0,48(sp)
    80006146:	f426                	sd	s1,40(sp)
    80006148:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000614a:	ffffc097          	auipc	ra,0xffffc
    8000614e:	c22080e7          	jalr	-990(ra) # 80001d6c <myproc>
    80006152:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006154:	fd840593          	addi	a1,s0,-40
    80006158:	4501                	li	a0,0
    8000615a:	ffffd097          	auipc	ra,0xffffd
    8000615e:	fb8080e7          	jalr	-72(ra) # 80003112 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006162:	fc840593          	addi	a1,s0,-56
    80006166:	fd040513          	addi	a0,s0,-48
    8000616a:	fffff097          	auipc	ra,0xfffff
    8000616e:	dea080e7          	jalr	-534(ra) # 80004f54 <pipealloc>
    return -1;
    80006172:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006174:	0c054463          	bltz	a0,8000623c <sys_pipe+0xfc>
  fd0 = -1;
    80006178:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000617c:	fd043503          	ld	a0,-48(s0)
    80006180:	fffff097          	auipc	ra,0xfffff
    80006184:	524080e7          	jalr	1316(ra) # 800056a4 <fdalloc>
    80006188:	fca42223          	sw	a0,-60(s0)
    8000618c:	08054b63          	bltz	a0,80006222 <sys_pipe+0xe2>
    80006190:	fc843503          	ld	a0,-56(s0)
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	510080e7          	jalr	1296(ra) # 800056a4 <fdalloc>
    8000619c:	fca42023          	sw	a0,-64(s0)
    800061a0:	06054863          	bltz	a0,80006210 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061a4:	4691                	li	a3,4
    800061a6:	fc440613          	addi	a2,s0,-60
    800061aa:	fd843583          	ld	a1,-40(s0)
    800061ae:	68a8                	ld	a0,80(s1)
    800061b0:	ffffb097          	auipc	ra,0xffffb
    800061b4:	774080e7          	jalr	1908(ra) # 80001924 <copyout>
    800061b8:	02054063          	bltz	a0,800061d8 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800061bc:	4691                	li	a3,4
    800061be:	fc040613          	addi	a2,s0,-64
    800061c2:	fd843583          	ld	a1,-40(s0)
    800061c6:	0591                	addi	a1,a1,4
    800061c8:	68a8                	ld	a0,80(s1)
    800061ca:	ffffb097          	auipc	ra,0xffffb
    800061ce:	75a080e7          	jalr	1882(ra) # 80001924 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800061d2:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061d4:	06055463          	bgez	a0,8000623c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    800061d8:	fc442783          	lw	a5,-60(s0)
    800061dc:	07e9                	addi	a5,a5,26
    800061de:	078e                	slli	a5,a5,0x3
    800061e0:	97a6                	add	a5,a5,s1
    800061e2:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800061e6:	fc042783          	lw	a5,-64(s0)
    800061ea:	07e9                	addi	a5,a5,26
    800061ec:	078e                	slli	a5,a5,0x3
    800061ee:	94be                	add	s1,s1,a5
    800061f0:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800061f4:	fd043503          	ld	a0,-48(s0)
    800061f8:	fffff097          	auipc	ra,0xfffff
    800061fc:	a30080e7          	jalr	-1488(ra) # 80004c28 <fileclose>
    fileclose(wf);
    80006200:	fc843503          	ld	a0,-56(s0)
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	a24080e7          	jalr	-1500(ra) # 80004c28 <fileclose>
    return -1;
    8000620c:	57fd                	li	a5,-1
    8000620e:	a03d                	j	8000623c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006210:	fc442783          	lw	a5,-60(s0)
    80006214:	0007c763          	bltz	a5,80006222 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006218:	07e9                	addi	a5,a5,26
    8000621a:	078e                	slli	a5,a5,0x3
    8000621c:	97a6                	add	a5,a5,s1
    8000621e:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006222:	fd043503          	ld	a0,-48(s0)
    80006226:	fffff097          	auipc	ra,0xfffff
    8000622a:	a02080e7          	jalr	-1534(ra) # 80004c28 <fileclose>
    fileclose(wf);
    8000622e:	fc843503          	ld	a0,-56(s0)
    80006232:	fffff097          	auipc	ra,0xfffff
    80006236:	9f6080e7          	jalr	-1546(ra) # 80004c28 <fileclose>
    return -1;
    8000623a:	57fd                	li	a5,-1
}
    8000623c:	853e                	mv	a0,a5
    8000623e:	70e2                	ld	ra,56(sp)
    80006240:	7442                	ld	s0,48(sp)
    80006242:	74a2                	ld	s1,40(sp)
    80006244:	6121                	addi	sp,sp,64
    80006246:	8082                	ret
	...

0000000080006250 <kernelvec>:
    80006250:	7111                	addi	sp,sp,-256
    80006252:	e006                	sd	ra,0(sp)
    80006254:	e40a                	sd	sp,8(sp)
    80006256:	e80e                	sd	gp,16(sp)
    80006258:	ec12                	sd	tp,24(sp)
    8000625a:	f016                	sd	t0,32(sp)
    8000625c:	f41a                	sd	t1,40(sp)
    8000625e:	f81e                	sd	t2,48(sp)
    80006260:	fc22                	sd	s0,56(sp)
    80006262:	e0a6                	sd	s1,64(sp)
    80006264:	e4aa                	sd	a0,72(sp)
    80006266:	e8ae                	sd	a1,80(sp)
    80006268:	ecb2                	sd	a2,88(sp)
    8000626a:	f0b6                	sd	a3,96(sp)
    8000626c:	f4ba                	sd	a4,104(sp)
    8000626e:	f8be                	sd	a5,112(sp)
    80006270:	fcc2                	sd	a6,120(sp)
    80006272:	e146                	sd	a7,128(sp)
    80006274:	e54a                	sd	s2,136(sp)
    80006276:	e94e                	sd	s3,144(sp)
    80006278:	ed52                	sd	s4,152(sp)
    8000627a:	f156                	sd	s5,160(sp)
    8000627c:	f55a                	sd	s6,168(sp)
    8000627e:	f95e                	sd	s7,176(sp)
    80006280:	fd62                	sd	s8,184(sp)
    80006282:	e1e6                	sd	s9,192(sp)
    80006284:	e5ea                	sd	s10,200(sp)
    80006286:	e9ee                	sd	s11,208(sp)
    80006288:	edf2                	sd	t3,216(sp)
    8000628a:	f1f6                	sd	t4,224(sp)
    8000628c:	f5fa                	sd	t5,232(sp)
    8000628e:	f9fe                	sd	t6,240(sp)
    80006290:	ab7fc0ef          	jal	ra,80002d46 <kerneltrap>
    80006294:	6082                	ld	ra,0(sp)
    80006296:	6122                	ld	sp,8(sp)
    80006298:	61c2                	ld	gp,16(sp)
    8000629a:	7282                	ld	t0,32(sp)
    8000629c:	7322                	ld	t1,40(sp)
    8000629e:	73c2                	ld	t2,48(sp)
    800062a0:	7462                	ld	s0,56(sp)
    800062a2:	6486                	ld	s1,64(sp)
    800062a4:	6526                	ld	a0,72(sp)
    800062a6:	65c6                	ld	a1,80(sp)
    800062a8:	6666                	ld	a2,88(sp)
    800062aa:	7686                	ld	a3,96(sp)
    800062ac:	7726                	ld	a4,104(sp)
    800062ae:	77c6                	ld	a5,112(sp)
    800062b0:	7866                	ld	a6,120(sp)
    800062b2:	688a                	ld	a7,128(sp)
    800062b4:	692a                	ld	s2,136(sp)
    800062b6:	69ca                	ld	s3,144(sp)
    800062b8:	6a6a                	ld	s4,152(sp)
    800062ba:	7a8a                	ld	s5,160(sp)
    800062bc:	7b2a                	ld	s6,168(sp)
    800062be:	7bca                	ld	s7,176(sp)
    800062c0:	7c6a                	ld	s8,184(sp)
    800062c2:	6c8e                	ld	s9,192(sp)
    800062c4:	6d2e                	ld	s10,200(sp)
    800062c6:	6dce                	ld	s11,208(sp)
    800062c8:	6e6e                	ld	t3,216(sp)
    800062ca:	7e8e                	ld	t4,224(sp)
    800062cc:	7f2e                	ld	t5,232(sp)
    800062ce:	7fce                	ld	t6,240(sp)
    800062d0:	6111                	addi	sp,sp,256
    800062d2:	10200073          	sret
    800062d6:	00000013          	nop
    800062da:	00000013          	nop
    800062de:	0001                	nop

00000000800062e0 <timervec>:
    800062e0:	34051573          	csrrw	a0,mscratch,a0
    800062e4:	e10c                	sd	a1,0(a0)
    800062e6:	e510                	sd	a2,8(a0)
    800062e8:	e914                	sd	a3,16(a0)
    800062ea:	6d0c                	ld	a1,24(a0)
    800062ec:	7110                	ld	a2,32(a0)
    800062ee:	6194                	ld	a3,0(a1)
    800062f0:	96b2                	add	a3,a3,a2
    800062f2:	e194                	sd	a3,0(a1)
    800062f4:	4589                	li	a1,2
    800062f6:	14459073          	csrw	sip,a1
    800062fa:	6914                	ld	a3,16(a0)
    800062fc:	6510                	ld	a2,8(a0)
    800062fe:	610c                	ld	a1,0(a0)
    80006300:	34051573          	csrrw	a0,mscratch,a0
    80006304:	30200073          	mret
	...

000000008000630a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000630a:	1141                	addi	sp,sp,-16
    8000630c:	e422                	sd	s0,8(sp)
    8000630e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006310:	0c0007b7          	lui	a5,0xc000
    80006314:	4705                	li	a4,1
    80006316:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006318:	c3d8                	sw	a4,4(a5)
}
    8000631a:	6422                	ld	s0,8(sp)
    8000631c:	0141                	addi	sp,sp,16
    8000631e:	8082                	ret

0000000080006320 <plicinithart>:

void
plicinithart(void)
{
    80006320:	1141                	addi	sp,sp,-16
    80006322:	e406                	sd	ra,8(sp)
    80006324:	e022                	sd	s0,0(sp)
    80006326:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006328:	ffffc097          	auipc	ra,0xffffc
    8000632c:	a18080e7          	jalr	-1512(ra) # 80001d40 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006330:	0085171b          	slliw	a4,a0,0x8
    80006334:	0c0027b7          	lui	a5,0xc002
    80006338:	97ba                	add	a5,a5,a4
    8000633a:	40200713          	li	a4,1026
    8000633e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006342:	00d5151b          	slliw	a0,a0,0xd
    80006346:	0c2017b7          	lui	a5,0xc201
    8000634a:	97aa                	add	a5,a5,a0
    8000634c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006350:	60a2                	ld	ra,8(sp)
    80006352:	6402                	ld	s0,0(sp)
    80006354:	0141                	addi	sp,sp,16
    80006356:	8082                	ret

0000000080006358 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006358:	1141                	addi	sp,sp,-16
    8000635a:	e406                	sd	ra,8(sp)
    8000635c:	e022                	sd	s0,0(sp)
    8000635e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006360:	ffffc097          	auipc	ra,0xffffc
    80006364:	9e0080e7          	jalr	-1568(ra) # 80001d40 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006368:	00d5151b          	slliw	a0,a0,0xd
    8000636c:	0c2017b7          	lui	a5,0xc201
    80006370:	97aa                	add	a5,a5,a0
  return irq;
}
    80006372:	43c8                	lw	a0,4(a5)
    80006374:	60a2                	ld	ra,8(sp)
    80006376:	6402                	ld	s0,0(sp)
    80006378:	0141                	addi	sp,sp,16
    8000637a:	8082                	ret

000000008000637c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000637c:	1101                	addi	sp,sp,-32
    8000637e:	ec06                	sd	ra,24(sp)
    80006380:	e822                	sd	s0,16(sp)
    80006382:	e426                	sd	s1,8(sp)
    80006384:	1000                	addi	s0,sp,32
    80006386:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006388:	ffffc097          	auipc	ra,0xffffc
    8000638c:	9b8080e7          	jalr	-1608(ra) # 80001d40 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006390:	00d5151b          	slliw	a0,a0,0xd
    80006394:	0c2017b7          	lui	a5,0xc201
    80006398:	97aa                	add	a5,a5,a0
    8000639a:	c3c4                	sw	s1,4(a5)
}
    8000639c:	60e2                	ld	ra,24(sp)
    8000639e:	6442                	ld	s0,16(sp)
    800063a0:	64a2                	ld	s1,8(sp)
    800063a2:	6105                	addi	sp,sp,32
    800063a4:	8082                	ret

00000000800063a6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063a6:	1141                	addi	sp,sp,-16
    800063a8:	e406                	sd	ra,8(sp)
    800063aa:	e022                	sd	s0,0(sp)
    800063ac:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ae:	479d                	li	a5,7
    800063b0:	04a7cc63          	blt	a5,a0,80006408 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063b4:	0023c797          	auipc	a5,0x23c
    800063b8:	a8c78793          	addi	a5,a5,-1396 # 80241e40 <disk>
    800063bc:	97aa                	add	a5,a5,a0
    800063be:	0187c783          	lbu	a5,24(a5)
    800063c2:	ebb9                	bnez	a5,80006418 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800063c4:	00451693          	slli	a3,a0,0x4
    800063c8:	0023c797          	auipc	a5,0x23c
    800063cc:	a7878793          	addi	a5,a5,-1416 # 80241e40 <disk>
    800063d0:	6398                	ld	a4,0(a5)
    800063d2:	9736                	add	a4,a4,a3
    800063d4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    800063d8:	6398                	ld	a4,0(a5)
    800063da:	9736                	add	a4,a4,a3
    800063dc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    800063e0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    800063e4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    800063e8:	97aa                	add	a5,a5,a0
    800063ea:	4705                	li	a4,1
    800063ec:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800063f0:	0023c517          	auipc	a0,0x23c
    800063f4:	a6850513          	addi	a0,a0,-1432 # 80241e58 <disk+0x18>
    800063f8:	ffffc097          	auipc	ra,0xffffc
    800063fc:	140080e7          	jalr	320(ra) # 80002538 <wakeup>
}
    80006400:	60a2                	ld	ra,8(sp)
    80006402:	6402                	ld	s0,0(sp)
    80006404:	0141                	addi	sp,sp,16
    80006406:	8082                	ret
    panic("free_desc 1");
    80006408:	00002517          	auipc	a0,0x2
    8000640c:	53850513          	addi	a0,a0,1336 # 80008940 <syscalls+0x330>
    80006410:	ffffa097          	auipc	ra,0xffffa
    80006414:	12c080e7          	jalr	300(ra) # 8000053c <panic>
    panic("free_desc 2");
    80006418:	00002517          	auipc	a0,0x2
    8000641c:	53850513          	addi	a0,a0,1336 # 80008950 <syscalls+0x340>
    80006420:	ffffa097          	auipc	ra,0xffffa
    80006424:	11c080e7          	jalr	284(ra) # 8000053c <panic>

0000000080006428 <virtio_disk_init>:
{
    80006428:	1101                	addi	sp,sp,-32
    8000642a:	ec06                	sd	ra,24(sp)
    8000642c:	e822                	sd	s0,16(sp)
    8000642e:	e426                	sd	s1,8(sp)
    80006430:	e04a                	sd	s2,0(sp)
    80006432:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006434:	00002597          	auipc	a1,0x2
    80006438:	52c58593          	addi	a1,a1,1324 # 80008960 <syscalls+0x350>
    8000643c:	0023c517          	auipc	a0,0x23c
    80006440:	b2c50513          	addi	a0,a0,-1236 # 80241f68 <disk+0x128>
    80006444:	ffffb097          	auipc	ra,0xffffb
    80006448:	904080e7          	jalr	-1788(ra) # 80000d48 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000644c:	100017b7          	lui	a5,0x10001
    80006450:	4398                	lw	a4,0(a5)
    80006452:	2701                	sext.w	a4,a4
    80006454:	747277b7          	lui	a5,0x74727
    80006458:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000645c:	14f71b63          	bne	a4,a5,800065b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006460:	100017b7          	lui	a5,0x10001
    80006464:	43dc                	lw	a5,4(a5)
    80006466:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006468:	4709                	li	a4,2
    8000646a:	14e79463          	bne	a5,a4,800065b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000646e:	100017b7          	lui	a5,0x10001
    80006472:	479c                	lw	a5,8(a5)
    80006474:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006476:	12e79e63          	bne	a5,a4,800065b2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000647a:	100017b7          	lui	a5,0x10001
    8000647e:	47d8                	lw	a4,12(a5)
    80006480:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006482:	554d47b7          	lui	a5,0x554d4
    80006486:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000648a:	12f71463          	bne	a4,a5,800065b2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000648e:	100017b7          	lui	a5,0x10001
    80006492:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006496:	4705                	li	a4,1
    80006498:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000649a:	470d                	li	a4,3
    8000649c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000649e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064a0:	c7ffe6b7          	lui	a3,0xc7ffe
    800064a4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47dbc7df>
    800064a8:	8f75                	and	a4,a4,a3
    800064aa:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ac:	472d                	li	a4,11
    800064ae:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064b0:	5bbc                	lw	a5,112(a5)
    800064b2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064b6:	8ba1                	andi	a5,a5,8
    800064b8:	10078563          	beqz	a5,800065c2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064bc:	100017b7          	lui	a5,0x10001
    800064c0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    800064c4:	43fc                	lw	a5,68(a5)
    800064c6:	2781                	sext.w	a5,a5
    800064c8:	10079563          	bnez	a5,800065d2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    800064cc:	100017b7          	lui	a5,0x10001
    800064d0:	5bdc                	lw	a5,52(a5)
    800064d2:	2781                	sext.w	a5,a5
  if(max == 0)
    800064d4:	10078763          	beqz	a5,800065e2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    800064d8:	471d                	li	a4,7
    800064da:	10f77c63          	bgeu	a4,a5,800065f2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    800064de:	ffffa097          	auipc	ra,0xffffa
    800064e2:	780080e7          	jalr	1920(ra) # 80000c5e <kalloc>
    800064e6:	0023c497          	auipc	s1,0x23c
    800064ea:	95a48493          	addi	s1,s1,-1702 # 80241e40 <disk>
    800064ee:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800064f0:	ffffa097          	auipc	ra,0xffffa
    800064f4:	76e080e7          	jalr	1902(ra) # 80000c5e <kalloc>
    800064f8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	764080e7          	jalr	1892(ra) # 80000c5e <kalloc>
    80006502:	87aa                	mv	a5,a0
    80006504:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006506:	6088                	ld	a0,0(s1)
    80006508:	cd6d                	beqz	a0,80006602 <virtio_disk_init+0x1da>
    8000650a:	0023c717          	auipc	a4,0x23c
    8000650e:	93e73703          	ld	a4,-1730(a4) # 80241e48 <disk+0x8>
    80006512:	cb65                	beqz	a4,80006602 <virtio_disk_init+0x1da>
    80006514:	c7fd                	beqz	a5,80006602 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006516:	6605                	lui	a2,0x1
    80006518:	4581                	li	a1,0
    8000651a:	ffffb097          	auipc	ra,0xffffb
    8000651e:	9ba080e7          	jalr	-1606(ra) # 80000ed4 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006522:	0023c497          	auipc	s1,0x23c
    80006526:	91e48493          	addi	s1,s1,-1762 # 80241e40 <disk>
    8000652a:	6605                	lui	a2,0x1
    8000652c:	4581                	li	a1,0
    8000652e:	6488                	ld	a0,8(s1)
    80006530:	ffffb097          	auipc	ra,0xffffb
    80006534:	9a4080e7          	jalr	-1628(ra) # 80000ed4 <memset>
  memset(disk.used, 0, PGSIZE);
    80006538:	6605                	lui	a2,0x1
    8000653a:	4581                	li	a1,0
    8000653c:	6888                	ld	a0,16(s1)
    8000653e:	ffffb097          	auipc	ra,0xffffb
    80006542:	996080e7          	jalr	-1642(ra) # 80000ed4 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006546:	100017b7          	lui	a5,0x10001
    8000654a:	4721                	li	a4,8
    8000654c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000654e:	4098                	lw	a4,0(s1)
    80006550:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006554:	40d8                	lw	a4,4(s1)
    80006556:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000655a:	6498                	ld	a4,8(s1)
    8000655c:	0007069b          	sext.w	a3,a4
    80006560:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006564:	9701                	srai	a4,a4,0x20
    80006566:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000656a:	6898                	ld	a4,16(s1)
    8000656c:	0007069b          	sext.w	a3,a4
    80006570:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006574:	9701                	srai	a4,a4,0x20
    80006576:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000657a:	4705                	li	a4,1
    8000657c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000657e:	00e48c23          	sb	a4,24(s1)
    80006582:	00e48ca3          	sb	a4,25(s1)
    80006586:	00e48d23          	sb	a4,26(s1)
    8000658a:	00e48da3          	sb	a4,27(s1)
    8000658e:	00e48e23          	sb	a4,28(s1)
    80006592:	00e48ea3          	sb	a4,29(s1)
    80006596:	00e48f23          	sb	a4,30(s1)
    8000659a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000659e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065a2:	0727a823          	sw	s2,112(a5)
}
    800065a6:	60e2                	ld	ra,24(sp)
    800065a8:	6442                	ld	s0,16(sp)
    800065aa:	64a2                	ld	s1,8(sp)
    800065ac:	6902                	ld	s2,0(sp)
    800065ae:	6105                	addi	sp,sp,32
    800065b0:	8082                	ret
    panic("could not find virtio disk");
    800065b2:	00002517          	auipc	a0,0x2
    800065b6:	3be50513          	addi	a0,a0,958 # 80008970 <syscalls+0x360>
    800065ba:	ffffa097          	auipc	ra,0xffffa
    800065be:	f82080e7          	jalr	-126(ra) # 8000053c <panic>
    panic("virtio disk FEATURES_OK unset");
    800065c2:	00002517          	auipc	a0,0x2
    800065c6:	3ce50513          	addi	a0,a0,974 # 80008990 <syscalls+0x380>
    800065ca:	ffffa097          	auipc	ra,0xffffa
    800065ce:	f72080e7          	jalr	-142(ra) # 8000053c <panic>
    panic("virtio disk should not be ready");
    800065d2:	00002517          	auipc	a0,0x2
    800065d6:	3de50513          	addi	a0,a0,990 # 800089b0 <syscalls+0x3a0>
    800065da:	ffffa097          	auipc	ra,0xffffa
    800065de:	f62080e7          	jalr	-158(ra) # 8000053c <panic>
    panic("virtio disk has no queue 0");
    800065e2:	00002517          	auipc	a0,0x2
    800065e6:	3ee50513          	addi	a0,a0,1006 # 800089d0 <syscalls+0x3c0>
    800065ea:	ffffa097          	auipc	ra,0xffffa
    800065ee:	f52080e7          	jalr	-174(ra) # 8000053c <panic>
    panic("virtio disk max queue too short");
    800065f2:	00002517          	auipc	a0,0x2
    800065f6:	3fe50513          	addi	a0,a0,1022 # 800089f0 <syscalls+0x3e0>
    800065fa:	ffffa097          	auipc	ra,0xffffa
    800065fe:	f42080e7          	jalr	-190(ra) # 8000053c <panic>
    panic("virtio disk kalloc");
    80006602:	00002517          	auipc	a0,0x2
    80006606:	40e50513          	addi	a0,a0,1038 # 80008a10 <syscalls+0x400>
    8000660a:	ffffa097          	auipc	ra,0xffffa
    8000660e:	f32080e7          	jalr	-206(ra) # 8000053c <panic>

0000000080006612 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006612:	7159                	addi	sp,sp,-112
    80006614:	f486                	sd	ra,104(sp)
    80006616:	f0a2                	sd	s0,96(sp)
    80006618:	eca6                	sd	s1,88(sp)
    8000661a:	e8ca                	sd	s2,80(sp)
    8000661c:	e4ce                	sd	s3,72(sp)
    8000661e:	e0d2                	sd	s4,64(sp)
    80006620:	fc56                	sd	s5,56(sp)
    80006622:	f85a                	sd	s6,48(sp)
    80006624:	f45e                	sd	s7,40(sp)
    80006626:	f062                	sd	s8,32(sp)
    80006628:	ec66                	sd	s9,24(sp)
    8000662a:	e86a                	sd	s10,16(sp)
    8000662c:	1880                	addi	s0,sp,112
    8000662e:	8a2a                	mv	s4,a0
    80006630:	8bae                	mv	s7,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006632:	00c52c83          	lw	s9,12(a0)
    80006636:	001c9c9b          	slliw	s9,s9,0x1
    8000663a:	1c82                	slli	s9,s9,0x20
    8000663c:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006640:	0023c517          	auipc	a0,0x23c
    80006644:	92850513          	addi	a0,a0,-1752 # 80241f68 <disk+0x128>
    80006648:	ffffa097          	auipc	ra,0xffffa
    8000664c:	790080e7          	jalr	1936(ra) # 80000dd8 <acquire>
  for(int i = 0; i < 3; i++){
    80006650:	4901                	li	s2,0
  for(int i = 0; i < NUM; i++){
    80006652:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006654:	0023bb17          	auipc	s6,0x23b
    80006658:	7ecb0b13          	addi	s6,s6,2028 # 80241e40 <disk>
  for(int i = 0; i < 3; i++){
    8000665c:	4a8d                	li	s5,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    8000665e:	0023cc17          	auipc	s8,0x23c
    80006662:	90ac0c13          	addi	s8,s8,-1782 # 80241f68 <disk+0x128>
    80006666:	a095                	j	800066ca <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006668:	00fb0733          	add	a4,s6,a5
    8000666c:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006670:	c11c                	sw	a5,0(a0)
    if(idx[i] < 0){
    80006672:	0207c563          	bltz	a5,8000669c <virtio_disk_rw+0x8a>
  for(int i = 0; i < 3; i++){
    80006676:	2605                	addiw	a2,a2,1 # 1001 <_entry-0x7fffefff>
    80006678:	0591                	addi	a1,a1,4
    8000667a:	05560d63          	beq	a2,s5,800066d4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    8000667e:	852e                	mv	a0,a1
  for(int i = 0; i < NUM; i++){
    80006680:	0023b717          	auipc	a4,0x23b
    80006684:	7c070713          	addi	a4,a4,1984 # 80241e40 <disk>
    80006688:	87ca                	mv	a5,s2
    if(disk.free[i]){
    8000668a:	01874683          	lbu	a3,24(a4)
    8000668e:	fee9                	bnez	a3,80006668 <virtio_disk_rw+0x56>
  for(int i = 0; i < NUM; i++){
    80006690:	2785                	addiw	a5,a5,1
    80006692:	0705                	addi	a4,a4,1
    80006694:	fe979be3          	bne	a5,s1,8000668a <virtio_disk_rw+0x78>
    idx[i] = alloc_desc();
    80006698:	57fd                	li	a5,-1
    8000669a:	c11c                	sw	a5,0(a0)
      for(int j = 0; j < i; j++)
    8000669c:	00c05e63          	blez	a2,800066b8 <virtio_disk_rw+0xa6>
    800066a0:	060a                	slli	a2,a2,0x2
    800066a2:	01360d33          	add	s10,a2,s3
        free_desc(idx[j]);
    800066a6:	0009a503          	lw	a0,0(s3)
    800066aa:	00000097          	auipc	ra,0x0
    800066ae:	cfc080e7          	jalr	-772(ra) # 800063a6 <free_desc>
      for(int j = 0; j < i; j++)
    800066b2:	0991                	addi	s3,s3,4
    800066b4:	ffa999e3          	bne	s3,s10,800066a6 <virtio_disk_rw+0x94>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066b8:	85e2                	mv	a1,s8
    800066ba:	0023b517          	auipc	a0,0x23b
    800066be:	79e50513          	addi	a0,a0,1950 # 80241e58 <disk+0x18>
    800066c2:	ffffc097          	auipc	ra,0xffffc
    800066c6:	e12080e7          	jalr	-494(ra) # 800024d4 <sleep>
  for(int i = 0; i < 3; i++){
    800066ca:	f9040993          	addi	s3,s0,-112
{
    800066ce:	85ce                	mv	a1,s3
  for(int i = 0; i < 3; i++){
    800066d0:	864a                	mv	a2,s2
    800066d2:	b775                	j	8000667e <virtio_disk_rw+0x6c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066d4:	f9042503          	lw	a0,-112(s0)
    800066d8:	00a50713          	addi	a4,a0,10
    800066dc:	0712                	slli	a4,a4,0x4

  if(write)
    800066de:	0023b797          	auipc	a5,0x23b
    800066e2:	76278793          	addi	a5,a5,1890 # 80241e40 <disk>
    800066e6:	00e786b3          	add	a3,a5,a4
    800066ea:	01703633          	snez	a2,s7
    800066ee:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800066f0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800066f4:	0196b823          	sd	s9,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800066f8:	f6070613          	addi	a2,a4,-160
    800066fc:	6394                	ld	a3,0(a5)
    800066fe:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006700:	00870593          	addi	a1,a4,8
    80006704:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006706:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006708:	0007b803          	ld	a6,0(a5)
    8000670c:	9642                	add	a2,a2,a6
    8000670e:	46c1                	li	a3,16
    80006710:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006712:	4585                	li	a1,1
    80006714:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006718:	f9442683          	lw	a3,-108(s0)
    8000671c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006720:	0692                	slli	a3,a3,0x4
    80006722:	9836                	add	a6,a6,a3
    80006724:	058a0613          	addi	a2,s4,88
    80006728:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000672c:	0007b803          	ld	a6,0(a5)
    80006730:	96c2                	add	a3,a3,a6
    80006732:	40000613          	li	a2,1024
    80006736:	c690                	sw	a2,8(a3)
  if(write)
    80006738:	001bb613          	seqz	a2,s7
    8000673c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006740:	00166613          	ori	a2,a2,1
    80006744:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006748:	f9842603          	lw	a2,-104(s0)
    8000674c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006750:	00250693          	addi	a3,a0,2
    80006754:	0692                	slli	a3,a3,0x4
    80006756:	96be                	add	a3,a3,a5
    80006758:	58fd                	li	a7,-1
    8000675a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000675e:	0612                	slli	a2,a2,0x4
    80006760:	9832                	add	a6,a6,a2
    80006762:	f9070713          	addi	a4,a4,-112
    80006766:	973e                	add	a4,a4,a5
    80006768:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000676c:	6398                	ld	a4,0(a5)
    8000676e:	9732                	add	a4,a4,a2
    80006770:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006772:	4609                	li	a2,2
    80006774:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006778:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000677c:	00ba2223          	sw	a1,4(s4)
  disk.info[idx[0]].b = b;
    80006780:	0146b423          	sd	s4,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006784:	6794                	ld	a3,8(a5)
    80006786:	0026d703          	lhu	a4,2(a3)
    8000678a:	8b1d                	andi	a4,a4,7
    8000678c:	0706                	slli	a4,a4,0x1
    8000678e:	96ba                	add	a3,a3,a4
    80006790:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006794:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006798:	6798                	ld	a4,8(a5)
    8000679a:	00275783          	lhu	a5,2(a4)
    8000679e:	2785                	addiw	a5,a5,1
    800067a0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067a4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067a8:	100017b7          	lui	a5,0x10001
    800067ac:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067b0:	004a2783          	lw	a5,4(s4)
    sleep(b, &disk.vdisk_lock);
    800067b4:	0023b917          	auipc	s2,0x23b
    800067b8:	7b490913          	addi	s2,s2,1972 # 80241f68 <disk+0x128>
  while(b->disk == 1) {
    800067bc:	4485                	li	s1,1
    800067be:	00b79c63          	bne	a5,a1,800067d6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067c2:	85ca                	mv	a1,s2
    800067c4:	8552                	mv	a0,s4
    800067c6:	ffffc097          	auipc	ra,0xffffc
    800067ca:	d0e080e7          	jalr	-754(ra) # 800024d4 <sleep>
  while(b->disk == 1) {
    800067ce:	004a2783          	lw	a5,4(s4)
    800067d2:	fe9788e3          	beq	a5,s1,800067c2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800067d6:	f9042903          	lw	s2,-112(s0)
    800067da:	00290713          	addi	a4,s2,2
    800067de:	0712                	slli	a4,a4,0x4
    800067e0:	0023b797          	auipc	a5,0x23b
    800067e4:	66078793          	addi	a5,a5,1632 # 80241e40 <disk>
    800067e8:	97ba                	add	a5,a5,a4
    800067ea:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800067ee:	0023b997          	auipc	s3,0x23b
    800067f2:	65298993          	addi	s3,s3,1618 # 80241e40 <disk>
    800067f6:	00491713          	slli	a4,s2,0x4
    800067fa:	0009b783          	ld	a5,0(s3)
    800067fe:	97ba                	add	a5,a5,a4
    80006800:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006804:	854a                	mv	a0,s2
    80006806:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000680a:	00000097          	auipc	ra,0x0
    8000680e:	b9c080e7          	jalr	-1124(ra) # 800063a6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006812:	8885                	andi	s1,s1,1
    80006814:	f0ed                	bnez	s1,800067f6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006816:	0023b517          	auipc	a0,0x23b
    8000681a:	75250513          	addi	a0,a0,1874 # 80241f68 <disk+0x128>
    8000681e:	ffffa097          	auipc	ra,0xffffa
    80006822:	66e080e7          	jalr	1646(ra) # 80000e8c <release>
}
    80006826:	70a6                	ld	ra,104(sp)
    80006828:	7406                	ld	s0,96(sp)
    8000682a:	64e6                	ld	s1,88(sp)
    8000682c:	6946                	ld	s2,80(sp)
    8000682e:	69a6                	ld	s3,72(sp)
    80006830:	6a06                	ld	s4,64(sp)
    80006832:	7ae2                	ld	s5,56(sp)
    80006834:	7b42                	ld	s6,48(sp)
    80006836:	7ba2                	ld	s7,40(sp)
    80006838:	7c02                	ld	s8,32(sp)
    8000683a:	6ce2                	ld	s9,24(sp)
    8000683c:	6d42                	ld	s10,16(sp)
    8000683e:	6165                	addi	sp,sp,112
    80006840:	8082                	ret

0000000080006842 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006842:	1101                	addi	sp,sp,-32
    80006844:	ec06                	sd	ra,24(sp)
    80006846:	e822                	sd	s0,16(sp)
    80006848:	e426                	sd	s1,8(sp)
    8000684a:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000684c:	0023b497          	auipc	s1,0x23b
    80006850:	5f448493          	addi	s1,s1,1524 # 80241e40 <disk>
    80006854:	0023b517          	auipc	a0,0x23b
    80006858:	71450513          	addi	a0,a0,1812 # 80241f68 <disk+0x128>
    8000685c:	ffffa097          	auipc	ra,0xffffa
    80006860:	57c080e7          	jalr	1404(ra) # 80000dd8 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006864:	10001737          	lui	a4,0x10001
    80006868:	533c                	lw	a5,96(a4)
    8000686a:	8b8d                	andi	a5,a5,3
    8000686c:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    8000686e:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006872:	689c                	ld	a5,16(s1)
    80006874:	0204d703          	lhu	a4,32(s1)
    80006878:	0027d783          	lhu	a5,2(a5)
    8000687c:	04f70863          	beq	a4,a5,800068cc <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006880:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006884:	6898                	ld	a4,16(s1)
    80006886:	0204d783          	lhu	a5,32(s1)
    8000688a:	8b9d                	andi	a5,a5,7
    8000688c:	078e                	slli	a5,a5,0x3
    8000688e:	97ba                	add	a5,a5,a4
    80006890:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006892:	00278713          	addi	a4,a5,2
    80006896:	0712                	slli	a4,a4,0x4
    80006898:	9726                	add	a4,a4,s1
    8000689a:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    8000689e:	e721                	bnez	a4,800068e6 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068a0:	0789                	addi	a5,a5,2
    800068a2:	0792                	slli	a5,a5,0x4
    800068a4:	97a6                	add	a5,a5,s1
    800068a6:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068a8:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068ac:	ffffc097          	auipc	ra,0xffffc
    800068b0:	c8c080e7          	jalr	-884(ra) # 80002538 <wakeup>

    disk.used_idx += 1;
    800068b4:	0204d783          	lhu	a5,32(s1)
    800068b8:	2785                	addiw	a5,a5,1
    800068ba:	17c2                	slli	a5,a5,0x30
    800068bc:	93c1                	srli	a5,a5,0x30
    800068be:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800068c2:	6898                	ld	a4,16(s1)
    800068c4:	00275703          	lhu	a4,2(a4)
    800068c8:	faf71ce3          	bne	a4,a5,80006880 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800068cc:	0023b517          	auipc	a0,0x23b
    800068d0:	69c50513          	addi	a0,a0,1692 # 80241f68 <disk+0x128>
    800068d4:	ffffa097          	auipc	ra,0xffffa
    800068d8:	5b8080e7          	jalr	1464(ra) # 80000e8c <release>
}
    800068dc:	60e2                	ld	ra,24(sp)
    800068de:	6442                	ld	s0,16(sp)
    800068e0:	64a2                	ld	s1,8(sp)
    800068e2:	6105                	addi	sp,sp,32
    800068e4:	8082                	ret
      panic("virtio_disk_intr status");
    800068e6:	00002517          	auipc	a0,0x2
    800068ea:	14250513          	addi	a0,a0,322 # 80008a28 <syscalls+0x418>
    800068ee:	ffffa097          	auipc	ra,0xffffa
    800068f2:	c4e080e7          	jalr	-946(ra) # 8000053c <panic>
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
