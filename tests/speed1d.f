C
C     FFTE: A FAST FOURIER TRANSFORM PACKAGE
C
C     (C) COPYRIGHT SOFTWARE, 2000-2004, 2008-2011, ALL RIGHTS RESERVED
C                BY
C         DAISUKE TAKAHASHI
C         FACULTY OF ENGINEERING, INFORMATION AND SYSTEMS
C         UNIVERSITY OF TSUKUBA
C         1-1-1 TENNODAI, TSUKUBA, IBARAKI 305-8573, JAPAN
C         E-MAIL: daisuke@cs.tsukuba.ac.jp
C
C
C     ZFFT1D SPEED TEST PROGRAM
C
C     FORTRAN77 SOURCE PROGRAM
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (NDA=16777216)
      COMPLEX*16 A(NDA),B(NDA*2)
      DIMENSION IP(3)
      SAVE A,B
C
      WRITE(6,*) ' N ='
      READ(5,*) N
      CALL FACTOR(N,IP)
C
      CALL INIT(A,N)
      CALL ZFFT1D(A,N,0,B)
      CALL ZFFT1D(A,N,-1,B)
      LOOP=1
C
!$ 10 CONTINUE
!$    TIME1=OMP_GET_WTIME()
      DO 20 I=1,LOOP
        CALL ZFFT1D(A,N,-1,B)
   20 CONTINUE
!$    TIME2=OMP_GET_WTIME()
!$    TIME0=TIME2-TIME1
!$    IF (TIME0 .LT. 1.0D0) THEN
!$      LOOP=LOOP*2
!$      GO TO 10
!$    END IF
!$    TIME0=TIME0/DBLE(LOOP)
!$    FLOPS=(2.5D0*DBLE(IP(1))+4.66666666666666D0*DBLE(IP(2))
!$   1       +6.8D0*DBLE(IP(3)))*2.0D0*DBLE(N)/TIME0/1.0D6
!$    WRITE(6,*) ' N =',N
!$    WRITE(6,*) ' TIME =',TIME0
!$    WRITE(6,*) FLOPS,' MFLOPS'
C
      STOP
      END
      SUBROUTINE INIT(A,N)
      IMPLICIT REAL*8 (A-H,O-Z)
      COMPLEX*16 A(*)
C
!DIR$ VECTOR ALIGNED
      DO 10 I=1,N
C        A(I)=DCMPLX(DBLE(I),DBLE(N-I+1))
        A(I)=(0.0D0,0.0D0)
   10 CONTINUE
      RETURN
      END
