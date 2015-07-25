;ROUTINEN ZUM 320x200x256-Grafikmodus
;
;Basisroutinen	    : PC INTERN V3.0 (Michael Tischer)
;Erweiterte Routinen: Nat Carl (aka imifos), 1993 
;
;Speichermodel LARGE
;

IGROUP group _text                ;Zusammenfassung der Programm-Segmente
DGROUP group _bss,  _data         ;Zusammenfassung der Daten-Segmente
       assume CS:IGROUP, DS:DGROUP, ES:DGROUP, SS:DGROUP

_BSS   segment word public 'BSS'  ;dieses Segment nimmt alle nicht ini-
_BSS   ends                       ;tialisierten statischen Variablen auf

_DATA  segment word public 'DATA' ;alle initialisierten globalen und
                                  ;statischen Variablen werden in diesem
                                  ;Segment untergebracht

_DATA  ends

;== Konstanten =========================================================

SC_INDEX       = 3c4h             ;Indexregister des Sequencer-Ctrl.
SC_MAP_MASK    = 2                ;Nummer des Map-Mask-Registers
SC_MEM_MODE    = 4                ;Nummer des Memory-Mode-Registers

GC_INDEX       = 3ceh             ;Indexregister des Graphics-Ctrl.
GC_READ_MAP    = 4                ;Nummer des Read-Map-Registers
GC_GRAPH_MODE  = 5                ;Nummer des Graphics-Mode-Registers
GC_MISCELL     = 6                ;Nummer des Miscellaneous-Registers

CRTC_INDEX     = 3d4h             ;Indexregistes des CRT-Controllers
CC_MAX_SCAN    = 9                ;Nummer des Maximum-Scan-Line-Reg.
CC_START_HI    = 0Ch              ;Nummer des Hi-Start-Registers
CC_UNDERLINE   = 14h              ;Nummer des Underline-Registers
CC_MODE_CTRL   = 17h              ;Nummer des Mode-Control-Registers

DAC_WRITE_ADR  = 3C8h             ;DAC-Write-Adresse
DAC_READ_ADR   = 3C7h             ;DAC-Read-Adresse
DAC_DATA       = 3C9h             ;DAC-Datenregister

VERT_RETRACE   = 3DAh             ;Input Status-Register #1

PIXX           = 320              ;horizontale Aufl”sung


;== Daten ==============================================================

_DATA  segment word public 'DATA'

vio_seg    dw 0a000h              ;Video-Segment mit akt. Seite

_DATA  ends

_TEXT  segment byte public 'CODE' ;das Programmsegment

;-- Public-Deklarationen -----------------------------------------------

public    _init320200             ;320*400-Punkte-Modus initialisieren
public    _setpix                 ;Punkt setzen
public    _getpix                 ;Farbe eines Punktes ermitteln
public    _showpage               ;Seite 0 oder 1 anzeigen
public    _setpage                ;Seite fr setpix und getpix festlegen
public	  _blockmove

;== BASIS-Routinen=====================================================
;======================================================================

;-- INIT320200: initialisiert den 320*200 Punkte-Modus -----------------
;-- Deklaration : void init320200( void );

_init320200 proc far

	   ;-- zun„chst ganz normal den Modus 13h einstellen, damit das
	   ;-- BIOS die meiste Arbeit der Initialisierung bernimmt.
	   ;-- Danach die Register ver„ndern, die sich noch nicht in
	   ;-- der gewnschten Stellung befinden.

	   mov   ax,0013h         ;normalen Modus 13h einstellen
	   int   10h

	   mov   dx,GC_INDEX      ;Auftrennung der Speicheradressen
	   mov   al,GC_GRAPH_MODE ;im Graphics-Mode-Register des
	   out   dx,al            ;Gaphics-Controllers ber das
	   inc   dx               ;Bit #4 abschalten
	   in    al,dx
	   and   al,11101111b
	   out   dx,al
	   dec   dx

	   mov   al,GC_MISCELL    ;und das Ganze noch einmal im
	   out   dx,al            ;Miscellanous-Register ber das
	   inc   dx               ;Bit #1
	   in    al,dx
	   and   al,11111101b
	   out   dx,al

	   mov   dx,SC_INDEX      ;das Memory-Mode-Register im
	   mov   al,SC_MEM_MODE   ;Sequencer-Controlller dahingehend
	   out   dx,al            ;modifizieren, daá keine Auftrennung
	   inc   dx               ;der Adressen in verschiedene Bit-
	   in    al,dx            ;Planes mehr erfolgt und die aktuelle
	   and   al,11110111b     ;Plane ber das Bit-Mask-Register
	   or    al,4             ;festgelegt wird
	   out   dx,al

	   mov   ax,vio_seg       ;alle vier Bit-Planes komplett mit
	   mov   es,ax            ;dem Farbcode 00h fllen und damit
	   xor   di,di            ;den Bildschirm zun„chst l”schen
	   mov   ax,di
	   mov   cx,8000h
	   rep   stosw

	   mov   dx,CRTC_INDEX    ;Doppelwort-Modus ber das Bit 6
	   mov   al,CC_UNDERLINE  ;im Underline-Register des CRT-
	   out   dx,al            ;Controllers abstellen
	   inc   dx
	   in    al,dx
	   and   al,10111111b
	   out   dx,al
	   dec   dx

	   mov   al,CC_MODE_CTRL  ;ber das Bit 6 im Mode-Control-
	   out   dx,al            ;Register des CRT-Controllers jetzt
	   inc   dx               ;vom Word- in den Byte-Modus wechseln
	   in    al,dx
	   or    al,01000000b
	   out   dx,al

	   ret                    ;zurck zum Aufrufer

_init320200 endp                  ;Ende der Prozedur

;-- SETPIX: verleiht einem Punkt eine bestimmte Farbe ------------------
;-- Deklaration : void setpix( int x, int y, unsigned char farbe );

_setpix    proc far

sframe0	   struc		   ;Struktur zum Zugriff auf den Stack
bp0        dw ?                   ;nimmt BP auf
ret_adr0   dd ?			  ;Rcksprungadresse zum Aufrufer (far)
x0         dw ?                   ;X-Ordinate
y0         dw ?                   ;Y-Ordinate
farbe      dw ?                   ;Farbe
sframe0    ends		   ;Ende der Struktur

frame	 equ [ bp - bp0 ]	   ;adressiert die Elemente der Struktur

	   push  bp               ;Adressierung der Parameter ber
	   mov   bp,sp            ;das BP-Register vorbereiten

	   push  di               ;DI auf dem Stack sichern


	   mov   ax,PIXX / 4      ;Offset in den Video-RAM berechnen
	   mul	 frame.y0	  ;und nach DI laden

	   mov	 cx,frame.x0
	   mov   bx,cx
	   shr   bx,1
	   shr   bx,1
	   add   ax,bx
	   mov   di,ax

	   and   cl,3             ;Bit-Maske fr die zu adressierende
	   mov   ah,1             ;Map in AH berechnen
	   shl   ah,cl
	   mov   al,SC_MAP_MASK   ;nach AL die Registernummer
	   mov   dx,SC_INDEX      ;Indexadresse des Sequencers laden
	   out   dx,ax            ;Bit-Mask-Register laden

	   mov   ax,vio_seg       ;ES auf den Video-RAM setzen
	   mov   es,ax
	   mov	 al,byte ptr frame.farbe  ;Farbe des Punktes laden
	   stosb                  ;und in die gew„hlte Bit-Map schreiben

nicht_zeichnen:

	   pop   di               ;Register wieder vom Stack holen
	   pop   bp

	   ret                    ;zurck zum Aufrufer

_setpix    endp                   ;Ende der Prozedur

;-- GETPIX: liefert die Farbe eines Punktes ----------------------------
;-- Deklaration : unsigned char getpix( int x, int y );

_getpix    proc far

sframe1    struc                  ;Struktur zum Zugriff auf den Stack
bp1        dw ?                   ;nimmt BP auf
ret_adr1   dd ?			 ;Rcksprungadresse zum Aufrufer
x1         dw ?                   ;X-Ordinate
y1         dw ?                   ;Y-Ordinate
sframe1    ends                   ;Ende der Struktur

frame      equ [ bp - bp1 ]       ;adressiert die Elemente der Struktur

	   push  bp               ;Adressierung der Parameter ber
	   mov   bp,sp            ;das BP-Register vorbereiten

	   push  si               ;SI auf dem Stack sichern

	   mov   ax,PIXX / 4      ;Offset in den Video-RAM berechnen
	   mul   frame.y1         ;und nach SI laden
	   mov   si,frame.x1
	   mov   cx,si
	   shr   si,1
	   shr   si,1
	   add   si,ax

	   and   cl,3             ;Bit-Maske fr die zu adressierende
	   mov   ah,cl            ;Map in AH berechnen
	   mov   al,GC_READ_MAP   ;nach AL die Registernummer
	   mov   dx,GC_INDEX      ;Indexadresse des Graphic-Ctrl laden
	   out   dx,ax            ;Read-Map-Register laden

	   mov   ax,vio_seg       ;ES auf den Video-RAM setzen
	   mov   es,ax
	   mov   al,es:[si]       ;Farbe des Punktes laden

	   pop   si               ;Register wieder vom Stack holen
	   pop   bp

	   ret                    ;zurck zum Aufrufer

_getpix    endp                   ;Ende der Prozedur

;-- SETPAGE: W„hlt die Seite aus, auf die bei Funktionsaufrufen von ----
;--          setpix und getpix zugegriffen werden soll
;-- Deklaration : void setpage( unsigend char page );

_setpage   proc far

sframe2	  struc		  ;Struktur zum Zugriff auf den Stack
bp2	  dw ?			 ;nimmt BP auf
ret_adr2   dd ?			 ;Rcksprungadresse zum Aufrufer
seite0	  db ?			 ;
sframe2	  ends			 ;Ende der Struktur

frame	   equ [ bp - bp2 ]	 ;adressiert die Elemente der Struktur

	   push  bp               ;Adressierung der Parameter ber
	   mov   bp,sp            ;das BP-Register vorbereiten

	   mov cl,frame.seite0

	   mov   al,4             ;Hi-Byte der Segadr = Seite * 4 + A0h
	   mul   cl
	   or    al,0A0h

	   mov   byte ptr vio_seg + 1,al ;neue Segmentadresse merken

	   pop bp
	   ret                    ;zurck zum Aufrufer

_setpage   endp                   ;Ende der Prozedur

;-- SHOWPAGE: Bringt eine der beiden Bildschirmseiten zur Anzeige ------
;-- Deklaration : void showpage( unsigend char page );

_showpage  proc far

sframe3	  struc		  ;Struktur zum Zugriff auf den Stack
bp3	  dw ?			 ;nimmt BP auf
ret_adr3   dd ?
seite1	  db ?
sframe3	  ends			 ;Ende der Struktur

frame	   equ [ bp - bp3 ]	 ;adressiert die Elemente der Struktur

	   push  bp               ;Adressierung der Parameter ber
	   mov   bp,sp            ;das BP-Register vorbereiten

	   mov cl,frame.seite1
	   mov   al,64            ;Hi-Byte des Offsets = Seite * 64
	   mul   cl
	   mov   ah,al            ;Hi-Byte des Offsets nach AH

	   ;-- jetzt die neue Startadresse laden -----------------------

	   mov   dx,CRTC_INDEX    ;CRT-Controller adressieren
	   mov   al,CC_START_HI   ;Registernummer nach AL
	   out   dx,ax            ;und ab gehts

	   ;-- wieder auf den Start eines Bildschirmaufbaus warten -----

	   mov   dx,VERT_RETRACE  ;zun„chst auf Ende des vertikalen
sp3:       in    al,dx            ;Rcklaufs warten
	   test  al,8
	   jne   sp3

sp4:       in    al,dx            ;dann auf den Start des Rcklaufs
	   test  al,8
	   je    sp4

	   pop bp
	   ret                    ;zurck zum Aufrufer

_showpage  endp                   ;Ende der Prozedur

;-- BLOCKMOVE: verschiebt eine Gruppe von Pixeln im Video-RAM ----------
;-- Deklaration : void blockmove( unsigned char vonpage, int vonx,
;--                               int vony, unsigned char nachpage,
;--				  int nachx, int nachy, int breite,
;--				  int hoehe, byte *bmskp );

_blockmove proc far

sframe4    struc                  ;Struktur zum Zugriff auf den Stack
bp4        dw ?                   ;nimmt BP auf
additiv    dw ?                   ;lokale variable
restz      dw ?
movec      dw ?
dataseg    dw ?
ret_adr4   dd ?			 ;Rcksprungadresse zum Aufrufer
vonpage    dw ?                   ;von Seite
vonx       dw ?                   ;von X-Ordinate
vony       dw ?                   ;von Y-Ordinate
nachpage   dw ?                   ;nach Seite
nachx      dw ?                   ;nach X-Ordinate
nachy      dw ?                   ;nach Y-Ordinate
breite     dw ?                   ;Breite
hoehe      dw ?                   ;H”he
bmskp      dw ?                   ;Zeiger auf Puffer mit der Bit-Mask
sframe4    ends                   ;Ende der Struktur

frame      equ [ bp - bp4 ]       ;adressiert die Elemente der Struktur

	   sub   sp,8             ;8 Bytes fr lokale Variablen

	   push  bp               ;Adressierung der Parameter ber
	   mov   bp,sp            ;das BP-Register vorbereiten

	   push  ds
	   push  si
	   push  di

	   mov   frame.dataseg,ds

	   mov   dx,GC_INDEX      ;aktuellen Write-Mode holen und
	   mov   al,GC_GRAPH_MODE ;Write-Mode 1 einstellen
	   out   dx,al
	   inc   dx
	   in    al,dx
	   push  ax               ;aktuellen Modus auf Stack merken
	   and   al,not 3
	   or    al,1
	   out   dx,al

	   mov   al,4             ;DS auf Anfang der VON-Seite
	   mov   cl,byte ptr frame.vonpage
	   mul   cl
	   or    al,0A0h
	   xchg  ah,al
	   mov   ds,ax

	   mov   al,4             ;ES auf Anfang der NACH-Seite
	   mov   cl,byte ptr frame.nachpage
	   mul   cl
	   or    al,0A0h
	   xchg  ah,al
	   mov   es,ax

	   mov   ax,PIXX / 4      ;SI auf Startposition VON
	   mul   frame.vony
	   mov   si,frame.vonx
	   shr   si,1
	   shr   si,1
	   add   si,ax

	   mov   ax,PIXX / 4      ;DI auf Zielposition NACH
	   mul   frame.nachy
	   mov   di,frame.nachx
	   shr   di,1
	   shr   di,1
	   add   di,ax

	   mov   dh,byte ptr frame.hoehe   ;DH = Zeilen
	   mov   dl,byte ptr frame.breite  ;DL = Bytes
	   shr   dl,1
	   shr   dl,1

	   mov   bx,PIXX / 4      ;BX als Offset zur n„chsten Zeile
	   sub   bl,dl
	   xor   ch,ch            ;Hi-Byte des Counters ist immer 0
	   cmp   frame.bmskp,0    ;kein Hintergrund beachten?
	   jne   mt2              ;Doch, andere Kopierroutine

	   push  dx               ;DX auf dem Stack sichern
	   mov   dx,SC_INDEX      ;Zugriff auf alle Bit-Planes sichern
	   mov   ah,0Fh
	   mov   al,SC_MAP_MASK
	   out   dx,ax
	   pop   dx               ;DX zurckholen

	   ;-- Kopierroutine fr alle vier Bit-Planes, also ohne Berck-
	   ;-- sichtigung des Hintergrundes

mt1:       mov   cl,dl            ;Anzahl Bytes nach CL

	   rep movsb              ;Zeile kopieren
	   add   di,bx            ;DI in n„chste Zeile
	   add   si,bx            ;und auch SI
	   dec   dh               ;noch eine Zeile?
	   jne   mt1              ;Ja ---> weiter
	   jmp short mtend        ;Nein, Ausstieg aus der Routine vorb.

	   ;-- Kopierroutine fr individuelle Bit-Planes unter Zuhilfe-
	   ;-- nahme des bergebenen Bit-Mask-Arrays

mt2:       mov   byte ptr frame.restz,dh ;zun„chst Variablen merken, die
	   mov   byte ptr frame.movec,dl ;hier auf dem Stack in lokalen
	   mov   frame.additiv,bx        ;Variablen festgeh. werden

	   mov   al,SC_MAP_MASK   ;jetzt permanent MAP-MASK-Register
	   mov   dx,SC_INDEX      ;adressieren
	   out   dx,al
	   inc   dx               ;DX jetzt auf Datenregister

	   mov   bx,frame.bmskp   ;BX als Zeiger auf Bit-Mask-Array
	   push  ds
	   mov   ds,frame.dataseg
	   mov   al,[bx]          ;erstes Byte laden
	   xor   ah,ah            ;Anfang mit einem geraden Byte
	   pop   ds

mt3:       mov   cl,byte ptr frame.movec ;Anzahl Bytes nach CL

mt4:       out   dx,al            ;Bit-Mask setzen
	   movsb                  ;4-Bytes kopieren

	   inc   ah               ;Odd/Even-Z„hler inkrementieren
	   test  ah,1             ;jetzt wieder ungerade?
	   jne   mt5              ;Ja, Nibble verschieben

	   ;-- wieder auf geradem Byte, n„chstes Byte aus Puffer -------

	   inc   bx               ;BX auf das n„chste Bit-Masken-Byte
	   push  ds
	   mov   ds,frame.dataseg
	   mov   al,[bx]          ;n„chste Byte laden
	   pop   ds
	   loop  mt4              ;n„chsten vier Latches
	   jmp   short mt6

mt5:       shr   al,1             ;Bit-Maske des ungeraden Bytes in das
	   shr   al,1             ;Lo-Nibble holen
	   shr   al,1
	   shr   al,1
	   loop  mt4              ;n„chsten vier Latches

mt6:       add   di,frame.additiv ;DI in n„chste Zeile
	   add   si,frame.additiv ;und auch SI
	   dec   byte ptr frame.restz ;noch eine Zeile?
	   jne   mt3                  ;Ja ---> weiter

mtend:     mov   dx,GC_INDEX      ;wieder den alten Write-Mode ein-
	   pop   ax               ;stellen
	   mov   ah,al
	   mov   al,GC_GRAPH_MODE
	   out   dx,ax

	   pop   di
	   pop   si
	   pop   ds
	   pop   bp

	   add   sp,8             ;lokale Variablen wieder l”schen
	   ret

_blockmove endp



;== Ende BASISROUTINEN ===================================================
;=========================================================================

_text    ends                     ;Ende des Programm-Segments
         end                      ;Ende des Assembler-Source
