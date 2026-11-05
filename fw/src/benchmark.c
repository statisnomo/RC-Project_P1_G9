typedef unsigned char u8;
typedef unsigned int u32;
void aes_software(const volatile u8 *,const volatile u8 *,volatile u8 *);
static volatile u32 *const aes=(volatile u32 *)0x40000000;
static volatile u32 *const ticks=(volatile u32 *)0x40000380;
static volatile u32 *const ram=(volatile u32 *)0x1000;

__attribute__((noinline)) static u32 hardware(void) {
    for(unsigned i=0;i<4;i++) aes[4+i]=ram[i];
    for(unsigned i=0;i<4;i++) aes[8+i]=ram[4+i];
    aes[0]=1;
    u32 budget=65536;
    while(!(aes[1]&2)) if(--budget==0) return 0;
    for(unsigned i=0;i<4;i++) ram[12+i]=aes[12+i];
    return 1;
}

int main(void) {
    /* 0x1040 status: 1 waiting, 2 result ready, 3 HW timeout.
     * 0x1044 command: host writes 1; firmware clears it before publishing done.
     * 0x1048 match; 0x104c software cycles; 0x1050 hardware cycles.
     * Inputs/output/command are testbench-loaded RAM in this development ROM.
     */
    ram[17]=0; ram[16]=1;
    for(;;) {
        while(ram[17]!=1) {}
        ram[16]=0;
        u32 begin=*ticks;
        aes_software((volatile u8 *)0x1010,(volatile u8 *)0x1000,(volatile u8 *)0x1020);
        u32 end=*ticks;
        ram[19]=end-begin;
        begin=*ticks;
        u32 ok=hardware();
        end=*ticks;
        ram[20]=end-begin;
        u32 equal=ok;
        for(unsigned i=0;i<4;i++) if(ram[8+i]!=ram[12+i]) equal=0;
        ram[18]=equal;
        ram[17]=0;
        ram[16]=ok?2:3;
    }
}
