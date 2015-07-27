C
C     FFTE: A FAST FOURIER TRANSFORM PACKAGE
C
C     (C) COPYRIGHT SOFTWARE, 2000-2004, ALL RIGHTS RESERVED
C                BY
C         DAISUKE TAKAHASHI
C         GRADUATE SCHOOL OF SYSTEMS AND INFORMATION ENGINEERING
C         UNIVERSITY OF TSUKUBA
C         1-1-1 TENNODAI, TSUKUBA, IBARAKI 305-8573, JAPAN
C         E-MAIL: daisuke@cs.tsukuba.ac.jp
C
C
C     ZFFT2D TEST PROGRAM
C
C     FORTRAN77 SOURCE PROGRAM
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (NDA=1048576)
      COMPLEX*16 A(NDA)
      SAVE A
C
      WRITE(6,*) ' NX,NY ='
      READ(5,*) NX,NY
C
      CALL INIT(A,NX*NY)
      CALL ZFFT2D(A,NX,NY,0)
C
      CALL ZFFT2D(A,NX,NY,-1)
      CALL DUMP(A,NX*NY)
C
      CALL ZFFT2D(A,NX,NY,1)
      CALL DUMP(A,NX*NY)
C
      STOP
      END
      SUBROUTINE INIT(A,N)
      IMPLICIT REAL*8 (A-H,O-Z)
      COMPLEX*16 A(*)
C
      DO 10 I=1,N
        A(I)=DCMPLX(DBLE(I),DBLE(N-I+1))
   10 CONTINUE
      RETURN
      END
      SUBROUTINE DUMP(A,N)
      IMPLICIT REAL*8 (A-H,O-Z)
      COMPLEX*16 A(*)
C
      DO 10 I=1,N
        WRITE(6,*) I,A(I)
   10 CONTINUE
      RETURN
      END
