#include <math.h>
#include "calc_3d.h"

/*
Nat. Carl/Imifos 1993
*/


/*********************************************************************
Berechnet ob ein SCAPEObjekt (Gegenstand im Raum) im Sichtbereich des
Beobachters liegt
*/
flag CalcSCAPEObjPos(SCAPEobj *in_obj,
           short xw_obs,short yw_obs,short zw_obs,/* Blickrichtung    */
           fixed x_obs,fixed y_obs,fixed z_obs)  /* Position Observer */
{
  static SCAPEobj zw;
  static flag fl=FALSE;

  /* Position des Objektes in Bezug auf den Beobachter berechnen */
   Translation_Punkt(in_obj->xpos,in_obj->ypos,in_obj->zpos,
           &zw.xpos,&zw.ypos,&zw.zpos,
           x_obs,y_obs,z_obs);
   Rotation_Punkt(zw.xpos,zw.ypos,zw.zpos,
        &zw.xpos,&zw.ypos,&zw.zpos,
        xw_obs,yw_obs,zw_obs);

   /* Zur spaeteren Verwendung zurckgeben */
   in_obj->ret_zpos=zw.zpos;

   /*
   if (zw.xpos>F(-400) && zw.xpos<F(400) &&
       zw.ypos>F(-300) && zw.ypos<F(300) &&
       zw.zpos>0) fl=TRUE;*/

   if (zw.zpos>1)
    { fl=TRUE; in_obj->sichtbar=TRUE; }
    else { in_obj->sichtbar=FALSE; }

  return fl;
}

/*********************************************************************
Berechnet ob ein komplettes SCAPEObjekt wie es der Beobachter sieht.
*/

void CalcObjekt(SCAPEobj *in_obj,
      short xw_obs,short yw_obs,short zw_obs, /* Blickrichtung  &  */
      fixed x_obs,fixed y_obs,fixed z_obs,   /* Position Observer */
      fixed obs_vgr)
{
  byte   seite,punkt,anzsei;
  fixed v1,v2,w1,w2;
  short mitte[MAX_SEITEN],zwj;
  byte reihe[MAX_SEITEN];
  byte i,j,min,zwi;

  for (seite=0;seite<in_obj->objtyp->anzseiten;seite++)
   {
     /* Transformation vom OBJEKT- ins WORLD- und dann ins VIEW-Space */
     for (punkt=0;punkt<4;punkt++)
       {
          /* Die Eigendrehung des Objektes berechnen */
          Rotation_Punkt(in_obj->objtyp->seite[seite].punkt[punkt].x,
               in_obj->objtyp->seite[seite].punkt[punkt].y,
               in_obj->objtyp->seite[seite].punkt[punkt].z,
               &in_obj->aktuell.seite[seite].punkt[punkt].x,
               &in_obj->aktuell.seite[seite].punkt[punkt].y,
               &in_obj->aktuell.seite[seite].punkt[punkt].z,
               in_obj->xwi,in_obj->ywi,in_obj->zwi);

          /* Objekt vom absoluten Nullpunkt auf die Objektposition
             verschieben OBJEKT- => WORD-SPACE */
          Translation_Punkt(in_obj->aktuell.seite[seite].punkt[punkt].x,
             in_obj->aktuell.seite[seite].punkt[punkt].y,
             in_obj->aktuell.seite[seite].punkt[punkt].z,
             &in_obj->aktuell.seite[seite].punkt[punkt].x,
             &in_obj->aktuell.seite[seite].punkt[punkt].y,
             &in_obj->aktuell.seite[seite].punkt[punkt].z,
             in_obj->xpos,in_obj->ypos,in_obj->zpos);

          /* Objektposition vom absoluten Nullpunkt auf die
        Beobachterposition beziehen WORLD- => VIEW-SPACE */
          Translation_Punkt(in_obj->aktuell.seite[seite].punkt[punkt].x,
             in_obj->aktuell.seite[seite].punkt[punkt].y,
             in_obj->aktuell.seite[seite].punkt[punkt].z,
             &in_obj->aktuell.seite[seite].punkt[punkt].x,
             &in_obj->aktuell.seite[seite].punkt[punkt].y,
             &in_obj->aktuell.seite[seite].punkt[punkt].z,
             x_obs,y_obs,z_obs);

          /* Objekt um den Blickwinkel drehen:
        der Beobachter blickt immer auf 0ø, nur die Objekte
        drehen... */
          Rotation_Punkt(in_obj->aktuell.seite[seite].punkt[punkt].x,
               in_obj->aktuell.seite[seite].punkt[punkt].y,
               in_obj->aktuell.seite[seite].punkt[punkt].z,
               &in_obj->aktuell.seite[seite].punkt[punkt].x,
               &in_obj->aktuell.seite[seite].punkt[punkt].y,
               &in_obj->aktuell.seite[seite].punkt[punkt].z,
               xw_obs,yw_obs,zw_obs);

         /* Fluchtpunkte des Objektes berechnen */
         Fluchtpunkt_Punkt(in_obj->aktuell.seite[seite].punkt[punkt].x,
            in_obj->aktuell.seite[seite].punkt[punkt].y,
            in_obj->aktuell.seite[seite].punkt[punkt].z,
            &in_obj->aktuell.seite[seite].punkt[punkt].x,
            &in_obj->aktuell.seite[seite].punkt[punkt].y,
            &in_obj->aktuell.seite[seite].punkt[punkt].z);


         /* Vergroesserung des Objektes berechnen */
         in_obj->aktuell.seite[seite].punkt[punkt].x=
        FixedMul(in_obj->aktuell.seite[seite].punkt[punkt].x,obs_vgr);
         in_obj->aktuell.seite[seite].punkt[punkt].y=
        FixedMul(in_obj->aktuell.seite[seite].punkt[punkt].y,obs_vgr);
         in_obj->aktuell.seite[seite].punkt[punkt].z=
        FixedMul(in_obj->aktuell.seite[seite].punkt[punkt].z,obs_vgr);

       } /* von for 4-Punktberechnung */

   /* Sichtbarkeit auf Wunsch nach der SCALAR-Methode berechnen */
   in_obj->aktuell.seite[seite].sichtbar=TRUE;
   if (in_obj->objtyp->seite[seite].calc_typ==SCALAR)
    {

      /* Scalarpodukt berechnen */
      v1=I(in_obj->aktuell.seite[seite].punkt[1].x-
      in_obj->aktuell.seite[seite].punkt[0].x);
      w1=I(in_obj->aktuell.seite[seite].punkt[3].x-
      in_obj->aktuell.seite[seite].punkt[0].x);
      v2=I(in_obj->aktuell.seite[seite].punkt[1].y-
      in_obj->aktuell.seite[seite].punkt[0].y);
      w2=I(in_obj->aktuell.seite[seite].punkt[3].y-
      in_obj->aktuell.seite[seite].punkt[0].y);

      /* Wenn Z-Komponente >0 dann sichtbar */
      if ((v1*w2-v2*w1)<0)
      in_obj->aktuell.seite[seite].sichtbar=FALSE;
    }

    /* Mittelpunkt einer Flaeche berechnen: Z-Koord. */
    in_obj->aktuell.seite[seite].mpz=
      FixedDiv(in_obj->aktuell.seite[seite].punkt[0].z+
          in_obj->aktuell.seite[seite].punkt[1].z+
          in_obj->aktuell.seite[seite].punkt[2].z+
          in_obj->aktuell.seite[seite].punkt[3].z,F(4));

    /* Bestimmte Parameter einer Seite zurueckgeben */
    in_obj->aktuell.seite[seite].farbe   =in_obj->objtyp->seite[seite].farbe;
    in_obj->aktuell.seite[seite].calc_typ=in_obj->objtyp->seite[seite].calc_typ;
    in_obj->aktuell.anzseiten=anzsei     =in_obj->objtyp->anzseiten;
     } /* von for Seiteberechnung */

     /* Nachdem alle Seiten berechnet wurden, werden sie sortiert: */
     /* von hintern (0) nach vorne              */
     for (seite=0;seite<anzsei;seite++)
      {
   mitte[seite]=I(in_obj->aktuell.seite[seite].mpz);
   reihe[seite]=seite;
      }

     for (i=0;i<(byte)(anzsei-1);i++)
      {
   min=i;
   for (j=(byte)(i+1);j<anzsei;j++)
     if (mitte[j] < mitte[min])
       min = j;

   zwj=mitte[min];
   mitte[min]=mitte[i];
   mitte[i]=zwj;
   zwi=reihe[min];
   reihe[min]=reihe[i];
   reihe[i]=zwi;
      } /* von for seite */

    for (seite=0;seite<anzsei;seite++)
   in_obj->aktuell.reihenfolge[seite]=reihe[seite];

   }


void Definition_Flaeche(byte seite,objekt *obj,
         short x1,short y1,short z1,
         short x2,short y2,short z2,
         short x3,short y3,short z3,
         short x4,short y4,short z4,
         byte col,byte calc)
{
  byte x;

  obj->seite[seite].punkt[0].x=F(x1);
  obj->seite[seite].punkt[0].y=F(y1);
  obj->seite[seite].punkt[0].z=F(z1);
  obj->seite[seite].punkt[1].x=F(x2);
  obj->seite[seite].punkt[1].y=F(y2);
  obj->seite[seite].punkt[1].z=F(z2);
  obj->seite[seite].punkt[2].x=F(x3);
  obj->seite[seite].punkt[2].y=F(y3);
  obj->seite[seite].punkt[2].z=F(z3);
  obj->seite[seite].punkt[3].x=F(x4);
  obj->seite[seite].punkt[3].y=F(y4);
  obj->seite[seite].punkt[3].z=F(z4);

  obj->seite[seite].sichtbar=TRUE;
  obj->seite[seite].farbe   =col;
  obj->seite[seite].calc_typ=calc;
  for (x=0;x<MAX_SEITEN;x++) obj->reihenfolge[x]=x;
}

void Definition_SCAPEObjekt(SCAPEobj *obj,
             objekt *typ, short xpos,short ypos,short zpos,
             short xwin,short ywin,short zwin,fixed vergr)
{
  obj->vergr=INT_TO_FIXED(vergr);
  obj->objtyp=typ;
  obj->xwi=xwin;
  obj->ywi=ywin;
  obj->zwi=zwin;
  obj->xpos=INT_TO_FIXED(xpos);
  obj->ypos=INT_TO_FIXED(ypos);
  obj->zpos=INT_TO_FIXED(zpos);
}

void Berechne_SinCos_Tab(void)
{
  short za;
  /* Tabelle vorberechnen */
  for (za=0;za<max_winkel;za++)
    {
      sinus[za]  =DOUBLE_TO_FIXED(sin((float)za*rad_deg));
      cosinus[za]=DOUBLE_TO_FIXED(cos((float)za*rad_deg));
    }
}

void Init_3D(void)
{
  /* Tabelle vorberechnen */
  Berechne_SinCos_Tab();

  /* Tabelle dem ASM-Teil anmelden */
  Rotation_Init(sinus,cosinus);

  /* Fluchtpunktroutine */
  Fluchtpunkt_Init(INT_TO_FIXED(14),INT_TO_FIXED(400),
         INT_TO_FIXED(1),INT_TO_FIXED(1),INT_TO_FIXED(1));
}
