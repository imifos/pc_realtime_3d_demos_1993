#include <stdio.h>
#include <stdlib.h>
#include <conio.h>
#include <dos.h>
#include <graph.h>

#include "g320200.h"

/*
Natasha Carl 1993 (Imifos)
*/

/*******/
void Line(short xa,short ya,short xe,short ye, byte farbe)
{
   static struct st_xy lin[1024];
   static struct st_xy *p1,*p;

   p1=linie(xa,ya,xe,ye,lin);

   for (p=lin;p<p1;p++)
    setpix(p->x,p->y,farbe);
}


void SetPoly(short x1,short y1,short x2,short y2,short x3,short y3,short x4,short y4,byte page,byte farbe)
{
 static struct st_xy lin1[1024];
 static struct st_xy lin2[1024];
 static struct st_xy *p1, *p2;
 static struct st_xy *z1, *z2;
 static short  yc1,yc2,yc3,yc4,
	       xc1,xc2,xc3,xc4;
 short y;

 #define SC_MAP_MASK 2
 #define SC_INDEX 0x3C4

 /* Startpunkt == Tiefster Punkt */
 yc1=y1; yc2=y2; yc3=y3; yc4=y4;
 xc1=x1; xc2=x2; xc3=x3; xc4=x4;

 if ((y2>=y1) && (y2>=y3) && (y2>=y4))
    { yc1=y2; yc2=y3; yc3=y4; yc4=y1;
      xc1=x2; xc2=x3; xc3=x4; xc4=x1; };

 if ((y3>=y1) && (y3>=y2) && (y3>=y4))
    { yc1=y3; yc2=y4; yc3=y1; yc4=y2;
      xc1=x3; xc2=x4; xc3=x1; xc4=x2; };

 if ((y4>=y1) && (y4>=y3) && (y4>=y2))
    { yc1=y4; yc2=y1; yc3=y2; yc4=y3;
      xc1=x4; xc2=x1; xc3=x2; xc4=x3; };

  /* Entweder 1-2 & 4-3 oder 1 & 2-3-4 */
  p1 = lin1;
  p2 = lin2;
  if ( abs(yc2-yc1)>abs(yc3-yc1) && abs(yc2-yc1)>abs(yc4-yc1) )
      {
	p1=linie ( xc1,yc1,xc2,yc2,p1); /* 1 */
	p2=linie ( xc1,yc1,xc4,yc4,p2); /* 2 */
	p2=linie( xc4,yc4,xc3,yc3,p2);
	p2=linie ( xc3,yc3,xc2,yc2,p2);
      } else if ( abs(yc4-yc1)>abs(yc3-yc1) && abs(yc4-yc1)>abs(yc2-yc1) )
	       {
		 p1=linie ( xc1,yc1,xc4,yc4,p1); /* 1 */
		 p2=linie ( xc1,yc1,xc2,yc2,p2); /* 2 */
		 p2=linie ( xc2,yc2,xc3,yc3,p2);
		 p2=linie ( xc3,yc3,xc4,yc4,p2);
	       } else {
			p1=linie ( xc1,yc1,xc2,yc2,p1); /* 1 */
			p1=linie ( xc2,yc2,xc3,yc3,p1);
			p2=linie ( xc1,yc1,xc4,yc4,p2); /* 2 */
			p2=linie ( xc4,yc4,xc3,yc3,p2);
		      }


    z1 = lin1;
    z2 = lin2;


    y=z1->y;

    schleife:

    if (y<0 || y>199) goto no_line;

    if (z1->x<0)   z1->x=0;
    if (z1->x>319) z1->x=319;
    if (z2->x<0)   z2->x=0;
    if (z2->x>319) z2->x=319;
    if (z2->x==0 && z1->x==0) goto no_line;
    if (z2->x==319 && z1->x==319) goto no_line;

    MakeHorzLine(z1->x,z2->x,y,farbe,page);
    no_line:

    y--;
    do { z1++;}
       while (z1->y!=y && z1<p1);
    if (z1>=p1) goto raus;

    do { z2++; }
       while (z2->y!=y && z2<p2);
    if (z2>=p2) goto raus;

    goto schleife;

raus:

return;
}


/******** LINIENBERECHNUNG *********/

void MakeHorzLine(short x0,short x1,short y,unsigned char farbe,unsigned char page)
{
  #define SC_MAP_MASK 2
  #define SC_INDEX 0x3C4

    _asm{
	   ;--------------------------------------------------------
	   ;Waagerechte Linie zeichnen (x1,x2,farbe,bildschirmseite)
	   ;--------------------------------------------------------
	   push di
	   push si

	   ;** ES auf Basisadr setzten,je nach Bildschirmseite **
	   mov al,page
	   cmp al,0
	   jne page1
	   mov ax,0xa000    ;Seite 0: A000:0000h
	   jmp adr_es
	   page1:
	   mov ax,0xa400    ;Seite 1: A400:0000h
	   adr_es:
	   mov es,ax

	   ;** Y-Koord. vorberechnen **
	   mov ax,80
	   mul y
	   mov si,ax

	   ;** x0 & x1 laden & eventuell vertauschen **
	   mov cx,x0
	   mov dx,x1
	   cmp cx,dx
	   jl no_tausch
	   xchg dx,cx
	   no_tausch:

	   ;** Schleife **
	   horline_schl:
	   cmp cx,dx
	   jg ende_horline_schl

	      push cx
	      push dx

	      ;SetPixel-Routine: CS,DX,farbe
	      mov bx,cx
	      shr bx,1
              shr bx,1
	      mov di,si
	      add di,bx

	      and cl,3		   ;Bit-Maske fr die zu adressierende
	      mov ah,1		   ;Map in AH berechnen
	      shl ah,cl
	      mov al,SC_MAP_MASK   ;nach AL die Registernummer
	      mov dx,SC_INDEX	   ;Indexadresse des Sequencers laden
	      out dx,ax		   ;Bit-Mask-Register laden

	      mov al,farbe	   ;Farbe des Punktes laden
	      stosb		   ;und in die gew„hlte Bit-Map schreiben

	      pop dx
	      pop cx
	   inc cx		   ;naechster Punkt & weiter
	   jmp horline_schl

	   ende_horline_schl:
	   pop si
	   pop di
	}

}



struct st_xy *linie( short x1, short y1, short x2, short y2, struct st_xy *p)
{
 /* zwischenspeicher */
 static struct st_xy *basis;
 static short aincr, xincr, yincr;
 static char flg;
 static short abs_difx,abs_dify;

 basis=p;
 flg=0;
 _asm {
        push ds
	push di
	push si

	;** abs(x2-x1) **
	mov bx,x2
	sub bx,x1
	cmp bx,0
	jge w1
	neg bx
	w1:
	mov abs_difx,bx     ;zwischenspeichern fuer spaeter

	;** abs(y2-y1) **
	mov cx,y2
	sub cx,y1
	cmp cx,0
	jge w2
	neg cx
	w2:
	mov abs_dify,cx

	;** in richtung der groessten dif. laufen **
	cmp bx,cx
	jge x_wandert
	jmp label_y_wandert
	x_wandert:
	jmp label_x_wandert

	/***** Y-ACHSE - laeuft *****/
	label_y_wandert:

	  /* Spalteninkrement festlegen */
	  mov cx,x1
	  mov dx,x2
	  cmp dx,cx
	  jg xinc_p1
	  mov ax,-1
	  jmp w4
	  xinc_p1:
	  mov ax,1
	  w4:			;  xincr = ( x2 > x1 ) ?	1 : -1
	  mov xincr,ax

	  /* Schrittwerte ermitteln */
	  mov dx,abs_dify
	  mov bx,abs_difx   ;dx

	  mov ax,bx	    ;dx<-bx
	  shl ax,1	    ;dx*2
	  mov si,ax	    ;bincr=2*dx=si
	  sub ax,dx	    ;d=2*dx-dy=ax

	  sub bx,dx
	  shl bx,1
	  mov aincr,bx	    ;aincr=2*(dx-dy)

	  /* Line auf Y-Achse durchlaufen */
          push ax
          mov ax,word ptr [p+2]
          mov ds,ax
	  mov di,word ptr [p]   ;DI zeiger auf Feld
          pop ax

	  mov cx,x1
	  mov dx,y1
	  mov bx,xincr

	  ;************
	  ;Test ob Punkte im Bereich des Bildschirms sind
	  ;cmp cx,0
	  ;jge okx1
	  ;mov cx,0
	  ;jmp savex1
	  ;okx1:
	  ;cmp cx,320
	  ;jl savex1
	  ;mov cx,319
	  ;savex1:

	  ;cmp dx,0
	  ;jge oky1
	  ;mov dx,0
	  ;jmp savey1
	  ;oky1:
	  ;cmp dx,200
	  ;jl savey1
	  ;mov dx,199

	  ;savey1:
	  ;************

	  ;erste Pos abspeichern
	  mov [di],cx
	  add di,2
	  mov [di],dx

	  add di,2

	  cmp dx,y2
	  jg y_zurueck

	  /* Y ++ */
	  inc dx	 ;y (zaehler) = y1+1 =Startwert
	  loop2:
	    ; condition
	    cmp dx,y2
	    jg ende_y	    ; alles zu ende

	    ; Welches increment?
	    cmp ax,0
	    jl l2w1
	    add cx,bx
	    add ax,aincr
	    jmp l2w2
	    l2w1:
	    add ax,si
	    l2w2:
	    ; Werte abspeichern & zaehler+1
	    mov [di],cx
	    add di,2
	    mov [di],dx
	    add di,2
	    inc dx
	  jmp loop2

	  /* Y -- */
	  y_zurueck:
	  dec dx
	  loop2r:
	    ; condition
	    cmp dx,y2
	    jl ende_y	    ; alles zu ende

	    ; Welches increment?
	    cmp ax,0
	    jl l2w1r
	    add cx,bx
	    add ax,aincr
	    jmp l2w2r
	    l2w1r:
	    add ax,si
	    l2w2r:
	    ; Werte abspeichern & zaehler+1
	    mov [di],cx
	    add di,2
	    mov [di],dx
	    add di,2
	    dec dx
	  jmp loop2r

	 ende_y: jmp ende_poly

	 /***** X-ACHSE - laeuft *****/
	label_x_wandert:
	  ; Zeileninkrement festlegen
	  mov cx,y1
	  mov dx,y2
	  cmp dx,cx
	  jg yinc_p01
	  mov ax,-1
	  jmp w04
	  yinc_p01:
	  mov ax,1
	  w04:
	  mov yincr,ax

	  ;Schrittwerte ermitteln
	  mov dx,abs_difx
	  mov bx,abs_dify   ;dy

	  mov ax,bx	    ;ax<-bx
	  shl ax,1	    ;dx*2
	  mov si,ax	    ;bincr=2*dx=si
	  sub ax,dx	    ;d=2*dx-dy=ax

	  sub bx,dx
	  shl bx,1
	  mov aincr,bx	    ;aincr=2*(dx-dy)

	 /* Line auf X-Achse durchlaufen */
          push ax
          mov ax,word ptr [p+2]
          mov ds,ax
	  mov di,word ptr [p]   ;DI zeiger auf Feld
          pop ax

	  mov cx,y1  ;y = y1
	  mov dx,x1
	  mov bx,yincr

	  mov [di],dx  ;erste Pos abspeichern
	  add di,2
	  mov [di],cx
	  add di,2

	  cmp dx,x2
	  jg x_zurueck

	  /* X ++ */
	  inc dx     ; x (zaehler) = x1+1
	  loop02:
	    ; condition
	    cmp dx,x2
	    jg ende_poly

	    ; Welches increment?
	    cmp ax,0
	    jl l02w1
	    add cx,bx
	    add ax,aincr
	    jmp l02w2
	    l02w1:
	    add ax,si
	    l02w2:
	    ; Werte abspeichern & zaehler+1
	    mov [di],dx
	    add di,2
	    mov [di],cx
	    add di,2
	    inc dx
	  jmp loop02

	  /* X -- */
	  x_zurueck:
	  dec dx	   ; x (zaehler) = x1+1
	  loop02r:
	    ; condition
	    cmp dx,x2
	    jl ende_poly

	    ; Welches increment?
	    cmp ax,0
	    jl l02w1r
	    add cx,bx
	    add ax,aincr
	    jmp l02w2r
	    l02w1r:
	    add ax,si
	    l02w2r:
	    ; Werte abspeichern & zaehler+1
	    mov [di],dx
	    add di,2
	    mov [di],cx
	    add di,2
	    dec dx
	  jmp loop02r

      ende_poly:

      mov word ptr [p],di	    ;sichern, um spaeter returnwert
      pop si
      pop di
      pop ds
    }

  return p;
}

/* Auf Beginn des neuen Bildes warten */
void WaitSync(void)
{
  while ( inp(0x3da) & 8);
  while ( !(inp(0x3da) & 8));
}

void SetFarbe(byte farbe,char r,char g,char b)
{
  _disable();
  outp(0x3c8,farbe);
  outp(0x3c9,r);
  outp(0x3c9,g);
  _asm {
	  mov dx,3dah
	  wait2: in al,dx
		 test al,1
	  jz wait2
       }
  outp(0x3c9,b);
  _enable();
 }
