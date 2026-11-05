/* Educational byte-oriented AES-128, following FIPS 197.
 * Column-major state, rolling round key, no crypto instructions or accelerator.
 * S-box is loaded into data RAM by benchmark startup (Harvard ROM is code-only).
 * This is a compact baseline, not an optimized or constant-time library.
 */
typedef unsigned char u8;
static const volatile u8 *const box = (const volatile u8 *)0x1100;
static u8 xtime(u8 x) { return (u8)((x << 1) ^ ((x >> 7) * 0x1b)); }

__attribute__((noinline))
void aes_software(const volatile u8 *input, const volatile u8 *key,
                  volatile u8 *output) {
    u8 s[16], k[16], shifted[16], rc=1;
    for(unsigned i=0;i<16;i++) { k[i]=key[i]; s[i]=input[i]^k[i]; }
    for(unsigned round=1;round<=10;round++) {
        for(unsigned col=0;col<4;col++)
            for(unsigned row=0;row<4;row++)
                shifted[4*col+row]=box[s[4*((col+row)&3)+row]];
        for(unsigned i=0;i<16;i++) s[i]=shifted[i];
        if(round!=10) for(unsigned col=0;col<4;col++) {
            unsigned i=4*col;
            u8 a=s[i],b=s[i+1],c=s[i+2],d=s[i+3],t=a^b^c^d;
            s[i]=a^t^xtime(a^b); s[i+1]=b^t^xtime(b^c);
            s[i+2]=c^t^xtime(c^d); s[i+3]=d^t^xtime(d^a);
        }
        u8 a=box[k[13]],b=box[k[14]],c=box[k[15]],d=box[k[12]];
        k[0]^=a^rc; k[1]^=b; k[2]^=c; k[3]^=d;
        for(unsigned i=4;i<16;i++) k[i]^=k[i-4];
        rc=xtime(rc);
        for(unsigned i=0;i<16;i++) s[i]^=k[i];
    }
    for(unsigned i=0;i<16;i++) output[i]=s[i];
}
