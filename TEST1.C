#include <dos.h>
#include <conio.h>
#include <graph.h>
#include <stdio.h>

#include "g320200.h"
#include "calc_3d.h"


/* Sichtfenster */
#define SCR_X0 20
#define SCR_Y0 20
#define SCR_X1 300
#define SCR_Y1 130
                  
// Objektearten
objekt platte;
objekt kubus;

// RaumObjekte
SCAPEobj boden,
         kubus1,
         kubus2,
         kubus3,
         kubus4;
                  
                  

#include "def.c"


void main()
{
  Init_3D();
  init320200();
  
  

}