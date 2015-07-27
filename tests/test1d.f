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
C     ZFFT1D TEST PROGRAM
C
C     FORTRAN77 SOURCE PROGRAM
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      IMPLICIT REAL*8 (A-H,O-Z)
      PARAMETER (NDA=1048576)
      COMPLEX*16 A(NDA),B(NDA)
      SAVE A,B
C
      WRITE(6,*) ' N ='
      READ(5,*) N
C
      CALL INIT(A,N)
C
      CALL ZFFT1D(A,B,N,1)
      CALL DUMP(B,N)
C
      CALL ZFFT1D(B,A,N,2)
      CALL DUMP(A,N)
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
