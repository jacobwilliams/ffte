C
C     FFTE: A FAST FOURIER TRANSFORM PACKAGE
C
C     (C) COPYRIGHT SOFTWARE, 2000-2004, ALL RIGHTS RESERVED
C                BY
C         DAISUKE TAKAHASHI
C         INSTITURE OF INFORMATION SCIENCES AND ELECTRONICS
C         UNIVERSITY OF TSUKUBA
C         1-1-1 TENNODAI, TSUKUBA, IBARAKI 305-8573, JAPAN
C         E-MAIL: daisuke@is.tsukuba.ac.jp
C
C
C     2-DIMENSIONAL COMPLEX FFT ROUTINE
C
C     FORTRAN77 SOURCE PROGRAM
C
C     CALL ZFFT2D(A,NX,NY,IOPT)
C
C     A(NX,NY) IS COMPLEX INPUT/OUTPUT VECTOR (COMPLEX*16)
C     NX IS THE LENGTH OF THE TRANSFORMS IN THE X-DIRECTION (INTEGER*4)
C     NY IS THE LENGTH OF THE TRANSFORMS IN THE Y-DIRECTION (INTEGER*4)
C       ------------------------------------
C         NX = (2**IP) * (3**IQ) * (5**IR)
C         NY = (2**JP) * (3**JQ) * (5**JR)
C       ------------------------------------
C     IOPT = 1 FOR FORWARD TRANSFORM (INTEGER*4)
C          = 2 FOR INVERSE TRANSFORM
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      SUBROUTINE ZFFT2D(A,NX,NY,IOPT)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      COMPLEX*16 A(*)
      COMPLEX*16 B((NDA2+NP)*NBLK+NP),C(NDA2+NP)
      COMPLEX*16 WX(NDA2/2+NP),WY(NDA2/2+NP)
      DATA NX0,NY0/0,0/
      SAVE NX0,NY0,WX,WY
C
      IF (IOPT .EQ. 2) THEN
        DO 10 I=1,NX*NY
          A(I)=DCONJG(A(I))
   10   CONTINUE
      END IF
C
      IF (NX .NE. NX0) THEN
        CALL SETTBL(WX,NX)
        NX0=NX
      END IF
      IF (NY .NE. NY0) THEN
        CALL SETTBL(WY,NY)
        NY0=NY
      END IF
!$OMP PARALLEL PRIVATE(B,C)
      CALL ZFFT2D0(A,B,C,WX,WY,NX,NY)
!$OMP END PARALLEL
C
      IF (IOPT .EQ. 2) THEN
        DN=1.0D0/DBLE(NX*NY)
        DO 20 I=1,NX*NY
          A(I)=DCONJG(A(I))*DN
   20   CONTINUE
      END IF
      RETURN
      END
      SUBROUTINE ZFFT2D0(A,B,C,WX,WY,NX,NY)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      COMPLEX*16 A(NX,*),B(NY+NP,*),C(*)
      COMPLEX*16 WX(*),WY(*)
      DIMENSION LNX(3),LNY(3)
C
      CALL FACTOR(NX,LNX)
      CALL FACTOR(NY,LNY)
C
!$OMP DO
      DO 70 II=1,NX,NBLK
        DO 30 JJ=1,NY,NBLK
          DO 20 I=II,MIN0(II+NBLK-1,NX)
            DO 10 J=JJ,MIN0(JJ+NBLK-1,NY)
              B(J,I-II+1)=A(I,J)
   10       CONTINUE
   20     CONTINUE
   30   CONTINUE
        DO 40 I=II,MIN0(II+NBLK-1,NX)
          CALL FFT23458(B(1,I-II+1),C,WY,NY,LNY)
   40   CONTINUE
        DO 60 J=1,NY
          DO 50 I=II,MIN0(II+NBLK-1,NX)
            A(I,J)=B(J,I-II+1)
   50     CONTINUE
   60   CONTINUE
   70 CONTINUE
!$OMP DO
      DO 80 J=1,NY
        CALL FFT23458(A(1,J),B,WX,NX,LNX)
   80 CONTINUE
      RETURN
      END
