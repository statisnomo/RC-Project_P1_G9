# Official peripheral manuals and remaining identification

Reviewed online on 26 October 2026. The board references already supplied
by the user remain in `../zedboard/`.

- [Digilent PmodKYPD reference manual](https://digilent.com/reference/_media/pmod:pmod:pmodkypd_rm.pdf):
  revision B, manual revised April 8, 2016.
- [Digilent PmodOLED reference manual](https://digilent.com/reference/_media/pmod:pmod:pmodOLED_rm.pdf):
  revision A, manual revised May 24, 2016.

These links identify the manufacturer's documents. Automated downloads
were blocked by the website on October 26; no local PDF copy is claimed
in this folder. Save the originals here later if the lab/browser permits.

Before peripheral wiring, obtain a readable photo of each actual module's
front/back, model/revision, and pin-1 marking. Confirm whether the OLED is
the external PmodOLED in the approved plan or a different product. The
board's built-in OLED has a separate connection.

Record the keypad's actual key legends. The previous `*`/`#` UI proposal
assumed those symbols; it must be adjusted if the supplied keypad has
literal E/F buttons. The selected 32-hex-digit block format is unchanged.

For later display implementation, also obtain the matching panel/controller
datasheet (the linked PmodOLED manual names UG-2832HSWEG04 and SSD1306),
module schematic, and any lab-specific adapter/cable pinout. These are
not needed for the current clock-and-LED board tests.
