.model large
.386
.code

;Natasha Carl (aka imifos), 1993 

; Daten 
;------
; Basisadr. der Tabellen
sinbasis        dd ?                    
cosbasis        dd ?

; Zwischenspeicher fuer die Koordinaten
x_zw            dd ?     
y_zw            dd ?
z_zw            dd ?

; FLuchtpunkt InitDaten
fluchtxy        dd ?
fluchtz         dd ?
distx_inv       dd ?                    ; Invers von distx,..
disty_inv       dd ?
distz_inv       dd ?

; Funktionen
;-----------

;-- Public-Deklarationen -----------------------------------------------

public       _FixedMulR
public       _FixedMul
public       _FixedDivR
public	     _FixedDiv

public       _Rotation_Init    
public	     _Rotation_Punkt

public       _Fluchtpunkt_Init
public       _Fluchtpunkt_Punkt

public 	     _Translation_Punkt

;************************************************************************
; fixed FixedMulR (fixed,fixed);
;
;************************************************************************

_FixedMulR      proc far

sframe1 struc                           ;Struktur zum Zugriff auf den Stack
        bp1             dw ?            ;nimmt BP auf
        ret_adr1        dd ?            ;RÅcksprungadresse zum Aufrufer (32-bit)
        faktorA1        dd ?                   
        faktorB1        dd ?
sframe1 ends                            ;Ende der Struktur

        push    bp                      ;Adressierung der Parameter Åber
        mov     bp,sp                   ;das BP-Register vorbereiten

	mov	eax,[bp+faktorA1]
	imul	[bp+faktorB1]
        add     eax,8000h
        adc     edx,0
        shr     eax,16

        pop     bp
        ret
_FixedMulR      endp                    ;Ende der Prozedur

;************************************************************************
; fixed FixedMul (fixed,fixed);
;
;************************************************************************

_FixedMul       proc far

sframe2 struc                           ;Struktur zum Zugriff auf den Stack
        bp2             dw ?            ;nimmt BP auf
        ret_adr2        dd ?            ;RÅcksprungadresse zum Aufrufer (32-bit)
        faktorA2        dd ?                   
        faktorB2        dd ?
sframe2 ends                            ;Ende der Struktur

        push    bp                      ;Adressierung der Parameter Åber
        mov     bp,sp                   ;das BP-Register vorbereiten

        mov     eax,[bp+faktorA2]
        imul    [bp+faktorB2]
        shr     eax,16

        pop     bp
        ret
_FixedMul       endp                    ;Ende der Prozedur

;************************************************************************
; fixed FixedDivR (fixed,fixed);
;
;************************************************************************

_FixedDivR      proc far

sframe3 struc                           ;Struktur zum Zugriff auf den Stack
        bp3             dw ?            ;nimmt BP auf
        ret_adr3        dd ?            ;RÅcksprungadresse zum Aufrufer (32-bit)
        teiler1         dd ?                   
        nenner1         dd ?
sframe3 ends                            ;Ende der Struktur

        push    bp
        mov     bp,sp
        sub     cx,cx
        mov     eax,[bp+teiler1]
        and     eax,eax
        jns     FDP1
        inc     cx
        neg     eax
FDP1:   sub     edx,edx
        rol     eax,16
        mov     dx,ax
        sub     ax,ax
        mov     ebx,[bp+nenner1]
        and     ebx,ebx
        jns     FDP2
        dec     cx
        neg     ebx
FDP2:   div     ebx
        shr     ebx,1
        adc     ebx,0
        dec     ebx
        cmp     ebx,edx
        adc     eax,0
        and     cx,cx
        jz      FDP3
        neg     eax
FDP3:   mov     edx,eax
        shr     edx,16
        pop     bp
        ret

_FixedDivR      endp                    ;Ende der Prozedur

;************************************************************************
; fixed FixedDiv (fixed,fixed);
;
;************************************************************************
_FixedDiv      proc far

sframe4 struc                           ;Struktur zum Zugriff auf den Stack
        bp4             dw ?            ;nimmt BP auf
        ret_adr4        dd ?            ;RÅcksprungadresse zum Aufrufer (32-bit)
        teiler2         dd ?                   
        nenner2         dd ?
sframe4 ends                            ;Ende der Struktur

        push    bp
        mov     bp,sp

        mov     edx,[bp+teiler2]
        sub     eax,eax
        shrd    eax,edx,16
        sar     edx,16
        idiv    dword ptr [bp+nenner2]
        shld    edx,eax,16

        pop     bp
        ret

        
_FixedDiv      endp                    ;Ende der Prozedur

;************************************************************************
; void Rotation_Init(fixed *sintable,fixed *costable);
;
;************************************************************************
_Rotation_Init proc far

sframe5 struc
        bp5             dw ?
        ret_adr5        dd ?
        sin             dd ?
        cos             dd ?
sframe5 ends

        push    bp
        mov     bp,sp                

        mov     eax,[bp+sin]
        mov     [sinbasis],eax
        mov     eax,[bp+cos]
        mov     [cosbasis],eax

        pop     bp
        ret

_Rotation_Init  endp

;************************************************************************
; void Rotation_Punkt(fixed xin  ,fixed yin  ,fixed zin,
;		      fixed *xout,fixed *yout,fixed *zout,
;                     short xwinkel,short ywinkel,short zwinkel); 
;                                           /* Rot. um X,Y,Z-Achse */
;
;************************************************************************
_Rotation_Punkt proc far

sframe6 struc
        bp6             dw ?
        ret_adr6        dd ?

        xin             dd ?
        yin             dd ?
        zin             dd ?
        adr_xout        dd ?
        adr_yout        dd ?
        adr_zout        dd ?    
        xwinkel         dw ?
        ywinkel         dw ?
        zwinkel         dw ?
sframe6 ends

        push    bp
	mov	bp,sp			; SP retten bevor nochmals benutzt!!!
        push    ds

        ;----------------------------
        ;- Add. Rotation um X-Achse -
        ;----------------------------

        ; Offsets der sin/cos-Tabelle berechnen:
        ;   SI : offset sin(winkel)
        ;   DI : offset cos(winkel)
        ;   DS : segment der Tabellen (! DSsin muss gleich DScos sein)

        mov     cx,word ptr [bp+xwinkel]; Winkel in CX und mal 4
        shl     cx,2            
        lds     si,sinbasis
        add     si,cx                   ; SI = Offset
        lds     di,cosbasis             ; DS = Segment
        add     di,cx                   ; DI = Offset

        ; Neue Y - Koordinate ausrechnen
        ; newy=cos(w)*y-sin(w)*z

	mov	ebx,dword ptr [bp+yin]	; Zeit sparen und Moeglichk. nutzen

	mov	eax,ebx			; yin in EAX
        imul    dword ptr [di]          ; EAX=EAX*cos()
        shrd    eax,edx,16              
        mov     ecx,eax                 ; Ergebnis zwischenspeichern
        mov     eax,dword ptr [bp+zin]  ; zin in EAX
        imul    dword ptr [si]          ; EAX=EAX*sin()
        shrd    eax,edx,16
        sub     ecx,eax                 ; newy=ECX-EAX

        mov     dword ptr [y_zw],ecx    ; newy zwischenspeichern

        ; Neue Z - Koordinate ausrechnen
        ; newy=sin(w)*y+cos(w)*z
 
	mov	eax,ebx
        imul    dword ptr [si]          
        shrd    eax,edx,16              
        mov     ecx,eax                 ; Ergebnis zwischenspeichern
        mov     eax,dword ptr [bp+zin]  
        imul    dword ptr [di]
        shrd    eax,edx,16
        add     ecx,eax                 ; newz=ECX+EAX

        mov     dword ptr [z_zw],ecx    ; newz zwischenspeichern

        ;----------------------------
        ;- Add. Rotation um Y-Achse -
        ;----------------------------

        ; Offsets der sin/cos-Tabelle berechnen:

        mov     cx,word ptr [bp+ywinkel]
        shl     cx,2            
        lds     si,sinbasis
        add     si,cx                   ; SI = Offset
        lds     di,cosbasis             ; DS = Segment
        add     di,cx                   ; DI = Offset

        ; Neue X - Koordinate ausrechnen
        ; newx=cos(w)*x+sin(w)*z

	mov	ebx,dword ptr [bp+xin]	; xin wurde noch nicht veraendert

	mov	eax,ebx
        imul    dword ptr [di]          
        shrd    eax,edx,16              
        mov     ecx,eax                 ; Ergebnis zwischenspeichern
        mov     eax,dword ptr [z_zw]    ; zin aus Zwischenspeicher in EAX
        imul    dword ptr [si]          ; EAX=EAX*sin()
        shrd    eax,edx,16
        add     ecx,eax                 ; newx=ECX+EAX

        mov     dword ptr [x_zw],ecx    ; newx zwischenspeichern

        ; Neue Z - Koordinate ausrechnen
        ; newz=cos(w)*z-sin(w)*x
 
        mov     eax,dword ptr [z_zw]  
        imul    dword ptr [di]          
        shrd    eax,edx,16              
        mov     ecx,eax                 ; Ergebnis zwischenspeichern
	mov	eax,ebx 		; EAX <- EBX = Xin
        imul    dword ptr [si]
        shrd    eax,edx,16
        sub     ecx,eax                 ; newz=ECX-EAX

        mov     dword ptr [z_zw],ecx    ; newz zwischenspeichern

        ;----------------------------
        ;- Add. Rotation um Z-Achse -
        ;----------------------------

        ; Offsets der sin/cos-Tabelle berechnen:

        mov     cx,word ptr [bp+zwinkel]
        shl     cx,2            
        lds     si,sinbasis
        add     si,cx                   ; SI = Offset
        lds     di,cosbasis             ; DS = Segment
        add     di,cx                   ; DI = Offset

        ; Neue X - Koordinate ausrechnen
        ; newx=cos(w)*x-sin(w)*y

	mov	ebx,dword ptr [x_zw]	; xin aus Zwischenspeicher

	mov	eax,ebx
        imul    dword ptr [di]          
        shrd    eax,edx,16              
        mov     ecx,eax                 ; Ergebnis zwischenspeichern
        mov     eax,dword ptr [y_zw]   
        imul    dword ptr [si]          ; EAX=EAX*sin()
        shrd    eax,edx,16
        sub     ecx,eax                 ; newx=ECX-EAX

        mov     dword ptr [x_zw],ecx    ; newx zwischenspeichern

        ; Neue Y - Koordinate ausrechnen
        ; newy=sin(w)*x+cos(w)*y
 
	mov	eax,ebx
        imul    dword ptr [si]          
        shrd    eax,edx,16              
        mov     ecx,eax                 ; Ergebnis zwischenspeichern
        mov     eax,dword ptr [y_zw]  
        imul    dword ptr [di]
        shrd    eax,edx,16
        add     ecx,eax                

        ;-------------------------------
        ;- Zwischenspeicher uebergeben -
        ;-------------------------------
        mov     ds,word ptr [bp+adr_xout+2] ;Aussgehend: DSxout=DSyout=DSzout

        mov     bx,word ptr [bp+adr_xout]   ; Off Zeiger xout
        mov     eax,dword ptr [x_zw]        ; Wert von NEWX
        mov     dword ptr [bx],eax          ; nach xout    

        mov     bx,word ptr [bp+adr_yout]   
	mov	dword ptr [bx],ecx	    ; Noch im Register

        mov     bx,word ptr [bp+adr_zout]   
        mov     eax,dword ptr [z_zw] 
        mov     dword ptr [bx],eax       

        pop     ds                      ;Das war's
        pop     bp
        ret

_Rotation_Punkt endp

;************************************************************************
; void Fluchtpunkt_Init	(fixed fakt,fixed fluchtz,
;			 fixed max_x,fixed max_y,fixed max_z);
;    * fakt    : Faktor zwischen fluchtx/fluchty und fluchtz (normal 14)
;    * fluchtz : Entfernung Fluchtpunkt Z-Achse (800-1200)
;************************************************************************
_Fluchtpunkt_Init proc far

sframe7 struc
        bp7             dw ?
        ret_adr7        dd ?

        fakt            dd ?
        flucht_z        dd ?
        max_x           dd ?
        max_y           dd ?
        max_z           dd ?
sframe7 ends

        push    bp
	mov	bp,sp

        ; fluchtx,fluchty,fluchtz ausrechnen
        
        mov     ebx,[bp+flucht_z]       ; EBX = fluchtZ
        mov     eax,ebx
        imul    dword ptr [bp+fakt]     ; fluchtxy=fakt*fluchtz
        shrd    eax,edx,16              ; EAX = fluchtX,fluchtY
        
        mov     dword ptr [fluchtxy],eax; Abspeichern                        
        mov     dword ptr [fluchtz],ebx

        ; 1/dist-x-z-y ausrechnen 
        ; (wenn dist zu klein wird, wird das Erg. zu gross -> Folge INT 0)
        
	;- 1/distz -
        mov     ecx,[bp+max_z]
        sub     ecx,ebx                 ; distz=maxz-fluchtz

        cmp     ecx,2000                ; wenn zu klein -> vergroessern
	ja	noadd_z 		; Wird als UNSIGNED behandelt,
					; da 0 das Zentrum ist: 2000<X<2000
        add     ecx,1300        

noadd_z:mov	edx,1		       ; FixPnt 1 auf EAX & EDX verteilen
	sub	eax,eax
        idiv    ecx
	mov	dword ptr [distz_inv],eax ; Abspeichern

	;- 1/distx -
	mov	ebx,dword ptr [fluchtxy]

	mov	ecx,dword ptr [bp+max_x]
	sub	ecx,ebx 		; distx=maxx-fluchtx

        cmp     ecx,2000                ; wenn zu klein -> vergroessern
	ja	noadd_x
        add     ecx,1300        

noadd_x:mov	edx,1		       ; FixPnt 1 auf EAX & EDX verteilen
	sub	eax,eax
        idiv    ecx
	mov	dword ptr [distx_inv],eax

	;- 1/disty -
	mov	ebx,dword ptr [fluchtxy]

	mov	ecx,dword ptr [bp+max_y]
	sub	ecx,ebx 		; disty=maxy-fluchty

        cmp     ecx,2000                ; wenn zu klein -> vergroessern
	ja	noadd_y
        add     ecx,1300        

noadd_y:mov	edx,1			; FixPnt 1 auf EAX & EDX verteilen
	sub	eax,eax
        idiv    ecx
	mov	dword ptr [disty_inv],eax

	; eventuell noch INTR 0 umbiegen um ein Abbruch durch DIV 0 zu vermeiden

	pop bp			       ; Vorbereitung beendet
        ret

_Fluchtpunkt_Init endp

;************************************************************************
; void Fluchtpunkt_Punkt(fixed Xin  ,fixed Yin	,fixed Zin,						       */
;			 fixed *Xout,fixed *Yout,fixed *Zout);
;************************************************************************
_Fluchtpunkt_Punkt proc far

sframe8 struc
	bp8		dw ?
	ret_adr8	dd ?

	Xkoo		dd ?
	Ykoo		dd ?
	Zkoo		dd ?
	ptr_Xout	dd ?	   ; Ausgehend von DS fuer alle gleich
	ptr_Yout	dd ?
	ptr_Zout	dd ?
sframe8 ends

        push    bp
	mov	bp,sp
        push    ds

	mov	edi,dword ptr [bp+Xkoo]
	mov	esi,dword ptr [bp+Ykoo]

	; Multiplikationsfaktor fuer Z-Achse berechnen, um die Fluchtpunkte
	; mit einzubringen

	mov	eax,dword ptr [bp+Zkoo]
	neg	eax			   ; EAX=-Zin
	sub	eax,dword ptr [fluchtz]

	imul	dword ptr [distz_inv]
	shrd	eax,edx,16
	mov	ecx,eax

	mov	edx,1		       ; FixPnt 1 auf EAX & EDX verteilen
	sub	eax,eax
	idiv	ecx
	mov	ecx,eax 	       ; faktor_z jetzt in ECX

	imul	edi		       ; x_new=x_in*faktor_z
	shrd	eax,edx,16
	mov	edi,eax

	mov	eax,ecx
	imul	esi		       ; y_new=y_in*faktor_z
	shrd	eax,edx,16
	mov	esi,eax

	; Multiplikationsfaktor fuer X-Achse berechnen

	mov	eax,dword ptr [bp+Xkoo]
	neg	eax			   ; EAX=-Xin
	sub	eax,dword ptr [fluchtxy]

	imul	dword ptr [distx_inv]
	shrd	eax,edx,16
	mov	ecx,eax

	mov	edx,1
	sub	eax,eax
	idiv	ecx		       ; faktor_x jetzt in EAX

	imul	esi		       ; y_new=y*faktor_x
	shrd	eax,edx,16

	; Wert abspeichern und DS erhalten
	mov	ds,word ptr [bp+ptr_Yout+2]
	mov	bx,word ptr [bp+ptr_Yout]
	mov	dword ptr [bx],eax

	; Multiplikationsfaktor fuer Y-Achse berechnen

	mov	eax,dword ptr [bp+Ykoo]
	neg	eax			   ; EAX=-Yin
	sub	eax,dword ptr [fluchtxy]

	imul	dword ptr [distx_inv]
	shrd	eax,edx,16
	mov	ecx,eax

	mov	edx,1
	sub	eax,eax
	idiv	ecx		       ; faktor_x jetzt in EAX

	imul	edi		       ; x_new=x*faktor_y=EAX
	shrd	eax,edx,16

	; Wert abspeichern und DS erhalten
	mov	ds,word ptr [bp+ptr_Xout+2]
	mov	bx,word ptr [bp+ptr_Xout]
	mov	dword ptr [bx],eax

	pop	ds
	pop	bp
	ret
_Fluchtpunkt_Punkt endp


;************************************************************************
; void Translation_Punkt(fixed Xin  ,fixed Yin  ,fixed Zin,                                                    */
;			 fixed *Xout,fixed *Yout,fixed *Zout);
;************************************************************************
_Translation_Punkt proc far

sframe9 struc
        bp9             dw ?
        ret_adr9        dd ?

        Xkoo9           dd ?
        Ykoo9           dd ?
        Zkoo9           dd ?
        ptr_Xout9       dd ?       ; Ausgehend von DS fuer alle gleich
        ptr_Yout9       dd ?
	ptr_Zout9	dd ?
	dist_x		dd ?
	dist_y		dd ?
	dist_z		dd ?
sframe9 ends

        push    bp
	mov	bp,sp
        push    ds

	mov	ds,word ptr [bp+ptr_Xout+2]

	mov	eax,dword ptr [bp+Xkoo]
	mov	ecx,dword ptr [bp+dist_x]
	add	eax,ecx
	mov	bx,word ptr [bp+ptr_Xout]
	mov	dword ptr [bx],eax

	mov	eax,dword ptr [bp+Ykoo]
	mov	ecx,dword ptr [bp+dist_y]
	add	eax,ecx
	mov	bx,word ptr [bp+ptr_Yout]
	mov	dword ptr [bx],eax

	mov	eax,dword ptr [bp+Zkoo]
	mov	ecx,dword ptr [bp+dist_z]
	add	eax,ecx
	mov	bx,word ptr [bp+ptr_Zout]
	mov	dword ptr [bx],eax

	pop	ds
	pop	bp
	ret
_Translation_Punkt endp

end
