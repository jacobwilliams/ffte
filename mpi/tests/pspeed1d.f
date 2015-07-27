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
C     PZFFT1D SPEED TEST PROGRAM
C
C     FORTRAN77 + MPI SOURCE PROGRAM
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'mpif.h'
      INCLUDE 'param.h'
      PARAMETER (NDA=1048576,LOOP=10)
      COMPLEX*16 A(NDA),B(NDA),W(NDA*3/2)
      DIMENSION IP(3)
      INTEGER*8 N,NN
      SAVE A,B,W
C
      CALL MPI_INIT(IERR)
      CALL MPI_COMM_RANK(MPI_COMM_WORLD,ME,IERR)
      CALL MPI_COMM_SIZE(MPI_COMM_WORLD,NPU,IERR)
C
      IF (ME .EQ. 0) THEN
        WRITE(6,*) ' N ='
        READ(5,*) N
      END IF
      CALL MPI_BCAST(N,1,MPI_DOUBLE_PRECISION,0,MPI_COMM_WORLD,IERR)
      CALL FACTOR8(N,IP)
C
      NN=N/INT8(NPU)
      CALL INIT(A,NN,ME,NPU)
      CALL PZFFT1D(A,B,W,N,MPI_COMM_WORLD,ME,NPU,0)
      CALL PZFFT1D(A,B,W,N,MPI_COMM_WORLD,ME,NPU,-1)
C
      TIME0=2.0D0**52
      DO I=1,LOOP
      CALL MPI_BARRIER(MPI_COMM_WORLD,IERR)
      IF (ME .EQ. 0) THEN
        TIME1=MPI_WTIME()
      END IF
C
      CALL PZFFT1D(A,B,W,N,MPI_COMM_WORLD,ME,NPU,-1)
C
      CALL MPI_BARRIER(MPI_COMM_WORLD,IERR)
      IF (ME .EQ. 0) THEN
        TIME2=MPI_WTIME()
        TIME0=DMIN1(TIME0,TIME2-TIME1)
      END IF
      END DO
      IF (ME .EQ. 0) THEN
        FLOPS=(2.5D0*DBLE(IP(1))+4.66666666666666D0*DBLE(IP(2))
     1         +6.8D0*DBLE(IP(3)))*2.0D0*DBLE(N)/TIME0/1.0D6
        WRITE(6,*) ' NPU =',NPU
        WRITE(6,*) ' N =',N,' TIME =',TIME0,FLOPS,' MFLOPS'
      END IF
C
      CALL MPI_FINALIZE(IERR)
      STOP
      END
      SUBROUTINE INIT(A,NN,ME,NPU)
      IMPLICIT REAL*8 (A-H,O-Z)
      COMPLEX*16 A(*)
      INTEGER*8 N,NN
C
      N=NN*INT8(NPU)
      DO 10 I=1,NN
C        A(I)=DCMPLX(DBLE(I)+DBLE(NN)*DBLE(ME),
C     1              DBLE(N)-(DBLE(I)+DBLE(NN)*DBLE(ME))+1.0D0)
        A(I)=(0.0D0,0.0D0)
   10 CONTINUE
      RETURN
      END
