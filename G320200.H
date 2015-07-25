
/*+++ Definitionen und Strukturen +++*/
#ifndef BYTE
 typedef unsigned char byte;
 #define BYTE
#endif

#define RGB(r,g,b) (((long) ((b) << 8 | (g)) << 8) | (r))

/*+++ Funktionen +++*/
extern void _far init320200(void);
extern void _far setpix(int x,int y,byte farbe);
extern byte _far getpix(int x,int y);
extern void _far setpage(byte page);
extern void _far showpage(byte page);
extern void _far blockmove(byte vonpage,int vonx,int vony,unsigned char nachpage,
                           int nachx,int nachy,int breite,int hoehe,byte *bmskp);


/* Polygon zeichnen */
void SetPoly(short x1,short y1,short x2,short y2,short x3,short y3,short x4,short y4,unsigned char page,unsigned char farbe);

/* Horizontale Linie zeichnen */
void MakeHorzLine(short x0,short x1,short y,byte farbe,byte page);

/* Linie ziehen */
void Line(short xa,short ya,short xe,short ye, byte farbe);

/* Linienalgorithmus in Buffer */
struct st_xy *linie( short x1, short y1, short x2, short y2, struct st_xy *p);

struct st_xy {
         short x;
         short y;
        };
struct st_xxy { short x0,x1,y; };


void WaitSync(void);
void SetFarbe(byte farbe,char r,char g,char b);
