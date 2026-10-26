// Simulation-only reference: polynomial arithmetic, not the RTL lookup table
// or optimized MixColumns identity. Bytes are still packed per the contract.
function automatic [7:0] ref_multiply;
    input [7:0] a, b;
    reg [15:0] product;
    integer i;
    begin
        product = 0;
        for (i = 0; i < 8; i = i + 1)
            if (b[i]) product = product ^ ({8'b0, a} << i);
        for (i = 14; i >= 8; i = i - 1)
            if (product[i]) product = product ^ (16'h011b << (i-8));
        ref_multiply = product[7:0];
    end
endfunction

function automatic [7:0] ref_sbox;
    input [7:0] value;
    reg [7:0] inverse, power;
    integer exponent, i;
    begin
        // Nonzero a^-1 = a^254 in GF(2^8); zero maps to inverse zero.
        inverse = 1;
        power = value;
        exponent = 254;
        for (i = 0; i < 8; i = i + 1) begin
            if (exponent & 1) inverse = ref_multiply(inverse, power);
            power = ref_multiply(power, power);
            exponent = exponent >> 1;
        end
        ref_sbox = inverse ^ {inverse[6:0],inverse[7]} ^
                   {inverse[5:0],inverse[7:6]} ^
                   {inverse[4:0],inverse[7:5]} ^
                   {inverse[3:0],inverse[7:4]} ^ 8'h63;
    end
endfunction

function automatic [127:0] ref_shift;
    input [127:0] value;
    reg [7:0] matrix [0:3][0:3];
    integer r, c;
    begin
        for (r = 0; r < 4; r = r + 1)
            for (c = 0; c < 4; c = c + 1)
                matrix[r][c] = value[127-8*(c*4+r) -: 8];
        for (r = 0; r < 4; r = r + 1)
            for (c = 0; c < 4; c = c + 1)
                ref_shift[127-8*(c*4+r) -: 8] = matrix[r][(c+r)%4];
    end
endfunction

function automatic [127:0] ref_mix;
    input [127:0] value;
    reg [7:0] a [0:3];
    integer c, r;
    begin
        for (c = 0; c < 4; c = c + 1) begin
            for (r = 0; r < 4; r = r + 1) a[r] = value[127-8*(c*4+r) -: 8];
            for (r = 0; r < 4; r = r + 1)
                ref_mix[127-8*(c*4+r) -: 8] = ref_multiply(a[r],2) ^
                    ref_multiply(a[(r+1)%4],3) ^ a[(r+2)%4] ^ a[(r+3)%4];
        end
    end
endfunction

function automatic [127:0] ref_round;
    input [127:0] value, round_key;
    input last_round;
    reg [127:0] temp;
    integer i;
    begin
        for (i = 0; i < 16; i = i + 1)
            temp[127-8*i -: 8] = ref_sbox(value[127-8*i -: 8]);
        temp = ref_shift(temp);
        if (!last_round) temp = ref_mix(temp);
        ref_round = temp ^ round_key;
    end
endfunction

function automatic [127:0] ref_key;
    input [127:0] value;
    input integer round_number;
    reg [31:0] words [0:7];
    reg [31:0] temp;
    reg [7:0] rc;
    integer i, b;
    begin
        for (i = 0; i < 4; i = i + 1) words[i] = value[127-32*i -: 32];
        rc = 1;
        for (i = 1; i < round_number; i = i + 1) rc = ref_multiply(rc,2);
        for (i = 4; i < 8; i = i + 1) begin
            temp = words[i-1];
            if (i == 4) begin
                temp = {temp[23:0],temp[31:24]};
                for (b = 0; b < 4; b = b + 1)
                    temp[31-8*b -: 8] = ref_sbox(temp[31-8*b -: 8]);
                temp = temp ^ {rc,24'b0};
            end
            words[i] = words[i-4] ^ temp;
        end
        ref_key = {words[4],words[5],words[6],words[7]};
    end
endfunction

function automatic [127:0] ref_encrypt;
    input [127:0] key_value, plain_value;
    reg [127:0] rk, temp;
    integer round_number;
    begin
        rk = key_value;
        temp = plain_value ^ rk;
        for (round_number = 1; round_number <= 10; round_number = round_number + 1) begin
            rk = ref_key(rk,round_number);
            temp = ref_round(temp,rk,round_number==10);
        end
        ref_encrypt = temp;
    end
endfunction

function automatic [31:0] next_random;
    input [31:0] value;
    reg [31:0] temp;
    begin
        temp = value ^ (value << 13);
        temp = temp ^ (temp >> 17);
        next_random = temp ^ (temp << 5);
    end
endfunction
