/* Variabel- & Programmconstantendefinitionen */
#define flag char
#define TRUE 1
#define FALSE 0
#ifndef BYTE
   #define BYTE
   typedef unsigned char byte;
#endif   
typedef long fixed;

/* Berechnungsconstanten */
#define rad_deg    0.0174533
#define max_winkel 400        /* Uebertrag ueber 360 wird im ASM-Prg */
                              /* nicht getestet           */

/* FixedPoint-Makros */
#define INT_TO_FIXED(x)     (((long)(int) (x) )<<16)
#define F(x)                INT_TO_FIXED(x)
#define DOUBLE_TO_FIXED(x)  ((long)( (x)*65536.0+0.01))
#define FIXED_TO_INT(x)     (int)((x)>>16)
#define I(x)                FIXED_TO_INT(x)
#define FIXED_TO_DOUBLE(x)  (double)( (x)/65536.0)

/* Definiert die verschiedenen Berechnungs- & Darstellungsmoeglichkeiten */
#define SCALAR     1     /* Scalarberechung ausfuehren      */
#define TRANSPARENT 2    /* Seite transparent darstellen    */
#define VECTOR     4     /* Rahmenvektoren zeichnen         */
#define VECTFILL    8    /* Seite ausfuellen          */

#define max_winkel 400        /* Uebertrag Åber 360 wird im ASM-Prg */
fixed sinus[max_winkel];      /* nicht getestet           */
fixed cosinus[max_winkel];


/*===== Definitionen eines Objektes =====*/
/*Maximale Anzahl Seiten in einem Objekt */
#define MAX_SEITEN 30

/* Definiert einen Punkt im Raum */
struct punktstr { fixed x,y,z; };

/* Definiert eine Seite im Raum */
struct seitestr {
        byte calc_typ;      /* Art der Berechnung  */
        byte farbe;         /* Farbe         */
        fixed mpz;          /* Mittelpunkt der Flaeche   */
                            /* dient zur Festlegung der */
                            /* Darstellungsreihenfolge   */
        struct punktstr punkt[4]; /* Die 4 Punkte einer Seite */
        flag sichtbar;            /* Ist die Seite sichtbar ? */
                                  /* Wird nach der Berechnung */
                                  /* gesetzt.      */
      };

/* Definiert ein komplettes Objekt */
struct objstr 
    {
      byte anzseiten;                     /* Anzahl der Seiten     */
      byte reihenfolge[MAX_SEITEN];       /* Bestimmt die Reihen-  */
                                          /* folge der Darstellung */
      struct seitestr seite[MAX_SEITEN];  /* die Seiten            */
    };

/* Definition des Types OBJEKT */
typedef struct objstr objekt;

/*==== Definitionen der SCAPEObjekte =====*/
#define MAX_SCAPEOBJEKTE 20

struct SCAPEobjstr {
           fixed xpos,ypos,zpos; /* Position des Gegenstandes im  */
                  /* Raum.           */
           short xwi,ywi,zwi;    /* Initiale Eigendrehung des     */
                  /* Gegenstandes.         */
           fixed vergr;    /* die eigene Vergroesserung     */
           objekt *objtyp;    /* Zeiger auf Objekt , welches   */
                  /* der Gegenstand darstellt       */
           objekt aktuell;    /* Komplettes OBJEKT, beinhaltet */
                  /* das komplette Objekt nach der */
                  /* Berechnung         */
           fixed ret_zpos;    /* beinhaltet die Z-Koordinate   */
                  /* nach der Umrechnung (zur Fest-*/
                  /* legung der Zeichenreihenfolge */
           flag sichtbar;     /* TRUE wenn das Objekt vom       */
                  /* Beobachter gesehen wird.       */
         };

/* Definition des Types SCAPEOBJ (Gegenstand im Raum) */
typedef struct SCAPEobjstr SCAPEobj;

/*===== PROTOTYPEN ======*/

/* ===== EXTERNE ASSEMBLERROUTINEN =====================*/
/*======================================================*/
extern long _far FixedMulR(fixed,fixed);
extern long _far FixedMul (fixed,fixed);
extern long _far FixedDivR(fixed,fixed);
extern long _far FixedDiv (fixed,fixed);

extern void _far Rotation_Init (fixed*,fixed*);       /* Zeiger auf die Winkeltabelle */

extern void _far Rotation_Punkt(fixed,fixed,fixed,    /* X,Y,Z In    */
            fixed*,fixed*,fixed*,      /* &X,&Y,&Z Out */
            short,short,short);     /* X,Y,Z-Winkel */

extern void _far Fluchtpunkt_Init  (fixed,         /* Faktor zwischen fluchtx,fluchty und fluchtz (n14)*/
                fixed,        /* fluchtpunkt Z-Achse               */
                fixed,fixed,fixed);    /* max_x,max_y,max_z                 */
extern void _far Fluchtpunkt_Punkt (fixed,fixed,fixed,      /* X,Y,Z In                    */
                fixed*,fixed*,fixed*); /* &X,&Y,&Z Out                   */

extern void _far Translation_Punkt (fixed,fixed,fixed,      /* X,Y,Z In                    */
                fixed*,fixed*,fixed*,  /* &X,&Y,&Z Out                   */
                fixed,fixed,fixed);    /* Distanzen X , Y , Z               */

/* ===== C-ROUTINEN =====================*/
/*=======================================*/
void Berechne_SinCos_Tab(void);
void Init_3D(void);

/* Berechnet ob und wie das Objekt gesehen wird */
void CalcObjekt(SCAPEobj *in_obj,         /* Gegenstand       */
      short xw_obs,short yw_obs,short zw_obs, /* Blickrichtung &   */
      fixed x_obs,fixed y_obs,fixed z_obs,   /* Position Observer */
      fixed obs_vgr);

/* Berechnet ob das Objekt im Sichtbereich liegt */
flag CalcSCAPEObjPos(SCAPEobj *in_obj,
           short xw_obs,short yw_obs,short zw_obs,/* Blickrichtung    */
           fixed x_obs,fixed y_obs,fixed z_obs);  /* Position Observer */

/* Definiert eine Flaeche in eimen Objekt */
void Definition_Flaeche(   byte seite,objekt *obj,
                           short x1,short y1,short z1,
                           short x2,short y2,short z2,
                           short x3,short y3,short z3,
                           short x4,short y4,short z4,
                           byte col,byte calc);

/* Definiert ein SCAPEObjekt */
void Definition_SCAPEObjekt(SCAPEobj *obj,
             objekt *typ, short xpos,short ypos,short zpos,
             short xwin,short ywin,short zwin,fixed vergr);
