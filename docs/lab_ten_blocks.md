# Ten consecutive physical AES blocks

Use the fixed key `000102030405060708090A0B0C0D0E0F`. Enter each 32-digit input with separate press/release actions. Do not reset between trials. The two expected lines below match the OLED layout; UART joins them into one line. Record PASS/FAIL and the actual output on any mismatch. These references were calculated independently using .NET AES, ECB, no padding, and are also exercised by simulation test 26.

## Trial 1

Input: `00112233445566778899AABBCCDDEEFF`

Expected OLED:

```text
69C4E0D86A7B0430
D8CDB78070B4C55A
```

- [ ] PASS / FAIL: __________

## Trial 2

Input: `00000000000000000000000000000000`

Expected OLED:

```text
C6A13B37878F5B82
6F4F8162A1C8D879
```

- [ ] PASS / FAIL: __________

## Trial 3

Input: `FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF`

Expected OLED:

```text
3C441F32CE078223
64D7A2990E50BB13
```

- [ ] PASS / FAIL: __________

## Trial 4

Input: `0123456789ABCDEF0123456789ABCDEF`

Expected OLED:

```text
3071708FFD241222
9B2677BA5F1C52D2
```

- [ ] PASS / FAIL: __________

## Trial 5

Input: `000102030405060708090A0B0C0D0E0F`

Expected OLED:

```text
0A940BB5416EF045
F1C39458C653EA5A
```

- [ ] PASS / FAIL: __________

## Trial 6

Input: `FEDCBA9876543210FEDCBA9876543210`

Expected OLED:

```text
7727A9F92C7F254C
F18E29B4572B0C83
```

- [ ] PASS / FAIL: __________

## Trial 7

Input: `11111111111111111111111111111111`

Expected OLED:

```text
35D14E6D3E3A279C
F01E343E34E7DED3
```

- [ ] PASS / FAIL: __________

## Trial 8

Input: `AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA`

Expected OLED:

```text
FBD49B091A38F87A
D5C3EE2580BA414C
```

- [ ] PASS / FAIL: __________

## Trial 9

Input: `55555555555555555555555555555555`

Expected OLED:

```text
A5548F9415018420
2F8200AAA9D02D56
```

- [ ] PASS / FAIL: __________

## Trial 10

Input: `80000000000000000000000000000000`

Expected OLED:

```text
4399572CD6EA5341
B8D35876A7098AF7
```

- [ ] PASS / FAIL: __________
