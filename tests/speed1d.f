C
C     FFTE: A FAST FOURIER TRANSFORM PACKAGE
C
C     (C) COPYRIGHT SOFTWARE, 2000, 2001, 2002, ALL RIGHTS RESERVED
C                BY
C         DAISUKE TAKAHASHI
C         INSTITURE OF INFORMATION SCIENCES AND ELECTRONICS,
C         UNIVERSITY OF TSUKUBA
C         1-1-1 TENNODAI, TSUKUBA-SHI, IBARAKI 305-8573, JAPAN
C         E-MAIL: daisuke@is.tsukuba.ac.jp
C
C
C     ZFFT1D SPEED TEST PROGRAM
C
C     FORTRAN77 SOURCE PROGRAM
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      PARAMETER (NDA=1048576)
      COMPLEX*16 A(NDA+NP),B(NDA+NP)
      REAL*4 TARRAY(2)
      DIMENSION IP(3)
C
      WRITE(6,*) ' N ='
      READ(5,*) N
      CALL FACTOR(N,IP)
C
      CALL INIT(A,N)
      CALL ZFFT1D(A,B,N,1)
      LOOP=1
C
   10 CONTINUE
      TIME1=ETIME(TARRAY)
      DO I=1,LOOP
      CALL ZFFT1D(A,B,N,1)
      END DO
      TIME2=ETIME(TARRAY)
      TIME0=TIME2-TIME1
      IF (TIME0 .LT. 1.0D0) THEN
        LOOP=LOOP*2
        GO TO 10
      END IF
      TIME0=TIME0/DBLE(LOOP)
      FLOPS=(2.5D0*DBLE(IP(1))+4.66666666666666D0*DBLE(IP(2))
     1       +6.8D0*DBLE(IP(3)))*2.0D0*DBLE(N)/TIME0/1.0D6
      WRITE(6,*) ' N =',N,' TIME =',TIME0,FLOPS,' MFLOPS'
C
      STOP
      END
      SUBROUTINE INIT(A,N)
      IMPLICIT REAL*8 (A-H,O-Z)
      COMPLEX*16 A(*)
C
      DO 10 I=1,N
        A(I)=(0.0D0,0.0D0)
   10 CONTINUE
      RETURN
      END
