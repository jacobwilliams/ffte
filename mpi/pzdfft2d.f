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
C     PARALLEL 2-D COMPLEX-TO-REAL FFT ROUTINE
C
C     FORTRAN77 + MPI SOURCE PROGRAM
C
C     CALL PZDFFT2D(A,B,NX,NY,ICOMM,ME,NPU,IOPT)
C
C     NX IS THE LENGTH OF THE TRANSFORMS IN THE X-DIRECTION (INTEGER*4)
C     NY IS THE LENGTH OF THE TRANSFORMS IN THE Y-DIRECTION (INTEGER*4)
C       ------------------------------------
C         NX = (2**IP) * (3**IQ) * (5**IR)
C         NY = (2**JP) * (3**JQ) * (5**JR)
C       ------------------------------------
C     ICOMM IS THE COMMUNICATOR (INTEGER*4)
C     ME IS THE RANK (INTEGER*4)
C     NPU IS THE NUMBER OF PROCESSORS (INTEGER*4)
C     IOPT = 0 FOR INITIALIZING THE COEFFICIENTS (INTEGER*4)
C     IOPT = +1 FOR INVERSE TRANSFORM WHERE
C              A(NX/2+1,NY/NPU) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE A(*,BLOCK)
C              B(NX,NY/NPU) IS REAL OUTPUT VECTOR (REAL*8)
C!HPF$ DISTRIBUTE B(*,BLOCK)
C     IOPT = +2 FOR INVERSE TRANSFORM WHERE
C     ME = 0   A((NX/2)/NPU+1,NY) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C     ME > 0   A((NX/2)/NPU,NY) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE A(BLOCK,*)
C              B(NX,NY/NPU) IS REAL OUTPUT VECTOR (REAL*8)
C!HPF$ DISTRIBUTE B(*,BLOCK)
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      SUBROUTINE PZDFFT2D(A,B,NX,NY,ICOMM,ME,NPU,IOPT)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      DIMENSION A(*)
      COMPLEX*16 B(*)
      COMPLEX*16 C((NDA2+NP)*NBLK),D(NDA2)
      COMPLEX*16 WX(NDA2),WY(NDA2)
      SAVE WX,WY
C
      IF (IOPT .EQ. 0) THEN
        CALL SETTBL(WX,NX)
        CALL SETTBL(WY,NY)
        RETURN
      END IF
C
!$OMP PARALLEL PRIVATE(C,D)
      CALL PZDFFT2D0(A,A,A,B,B,B,C,C,D,WX,WY,NX,NY,ICOMM,ME,NPU,IOPT)
!$OMP END PARALLEL
      RETURN
      END
      SUBROUTINE PZDFFT2D0(A,AXY,AYX,B,BYX,DB,CX,CY,D,WX,WY,NX,NY,
     1                     ICOMM,ME,NPU,IOPT)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'mpif.h'
      INCLUDE 'param.h'
      COMPLEX*16 A(*),AXY(NX/2+1,*),AYX(NY/NPU,*)
      COMPLEX*16 B(*),BYX(NY/NPU,*)
      COMPLEX*16 CX(*),CY(NY+NP,*),D(*)
      COMPLEX*16 WX(*),WY(*)
      COMPLEX*16 TEMP
      DIMENSION DB(NX,*)
      DIMENSION ISCNT(MAXNPU),ISDSP(MAXNPU),IRCNT(MAXNPU),IRDSP(MAXNPU)
      DIMENSION LNX(3),LNY(3)
C
      DN=1.0D0/(DBLE(NX)*DBLE(NY))
C
      CALL FACTOR(NX,LNX)
      CALL FACTOR(NY,LNY)
C
      NNX=NX/NPU
      NNY=NY/NPU
C
      ISCNT(1)=NNY*(NNX/2+1)
      ISDSP(1)=0
      DO 10 I=2,NPU
        ISCNT(I)=NNY*(NNX/2)
        ISDSP(I)=ISDSP(I-1)+ISCNT(I-1)
   10 CONTINUE
      IF (ME .EQ. 0) THEN
        IRCNT(1)=NNY*(NNX/2+1)
        IRDSP(1)=0
        DO 20 I=2,NPU
          IRCNT(I)=NNY*(NNX/2+1)
          IRDSP(I)=IRDSP(I-1)+IRCNT(I-1)
   20   CONTINUE
      ELSE
        IRCNT(1)=NNY*(NNX/2)
        IRDSP(1)=0
        DO 30 I=2,NPU
          IRCNT(I)=NNY*(NNX/2)
          IRDSP(I)=IRDSP(I-1)+IRCNT(I-1)
   30   CONTINUE
      END IF
C
      IF (IOPT .EQ. 1) THEN
!$OMP DO
        DO 70 J=1,NNY
!DIR$ VECTOR ALIGNED
          DO 40 I=1,NNX/2+1
            B(I+(J-1)*(NNX/2+1))=AXY(I,J)
   40     CONTINUE
          DO 60 K=2,NPU
!DIR$ VECTOR ALIGNED
            DO 50 I=1,NNX/2
              B(I+(J-1)*(NNX/2)+((K-2)*(NNX/2)+(NNX/2+1))*NNY)
     1       =AXY(I+((K-2)*(NNX/2)+(NNX/2+1)),J)
   50       CONTINUE
   60     CONTINUE
   70   CONTINUE
!$OMP BARRIER
!$OMP MASTER
        CALL MPI_ALLTOALLV(B,ISCNT,ISDSP,MPI_DOUBLE_COMPLEX,
     1                     A,IRCNT,IRDSP,MPI_DOUBLE_COMPLEX,
     2                     ICOMM,IERR)
!$OMP END MASTER
!$OMP BARRIER
      END IF
C
      IF (ME .EQ. 0) THEN
!$OMP DO
        DO 140 II=1,NNX/2+1,NBLK
          DO 90 I=II,MIN0(II+NBLK-1,NNX/2+1)
!DIR$ VECTOR ALIGNED
            DO 80 J=1,NY
              CY(J,I-II+1)=DCONJG(A(I+(J-1)*(NNX/2+1)))
   80       CONTINUE
   90     CONTINUE
          DO 100 I=II,MIN0(II+NBLK-1,NNX/2+1)
            CALL FFT235(CY(1,I-II+1),D,WY,NY,LNY)
  100     CONTINUE
          DO 130 K=1,NPU
            DO 120 I=II,MIN0(II+NBLK-1,NNX/2+1)
!DIR$ VECTOR ALIGNED
              DO 110 J=1,NNY
                BYX(J,I+(K-1)*(NNX/2+1))=CY(J+(K-1)*NNY,I-II+1)
  110         CONTINUE
  120       CONTINUE
  130     CONTINUE
  140   CONTINUE
      ELSE
!$OMP DO
        DO 210 II=1,NNX/2,NBLK
          DO 160 I=II,MIN0(II+NBLK-1,NNX/2)
!DIR$ VECTOR ALIGNED
            DO 150 J=1,NY
              CY(J,I-II+1)=DCONJG(A(I+(J-1)*(NNX/2)))
  150       CONTINUE
  160     CONTINUE
          DO 170 I=II,MIN0(II+NBLK-1,NNX/2)
            CALL FFT235(CY(1,I-II+1),D,WY,NY,LNY)
  170     CONTINUE
          DO 200 K=1,NPU
            DO 190 I=II,MIN0(II+NBLK-1,NNX/2)
!DIR$ VECTOR ALIGNED
              DO 180 J=1,NNY
                BYX(J,I+(K-1)*(NNX/2))=CY(J+(K-1)*NNY,I-II+1)
  180         CONTINUE
  190       CONTINUE
  200     CONTINUE
  210   CONTINUE
      END IF
!$OMP BARRIER
!$OMP MASTER
      CALL MPI_ALLTOALLV(B,IRCNT,IRDSP,MPI_DOUBLE_COMPLEX,
     1                   A,ISCNT,ISDSP,MPI_DOUBLE_COMPLEX,
     2                   ICOMM,IERR)
!$OMP END MASTER
!$OMP BARRIER
      IF (MOD(NNY,2) .EQ. 0) THEN
!$OMP DO PRIVATE(TEMP)
        DO 240 J=1,NNY,2
          CX(1)=DCMPLX(DBLE(AYX(J,1)),DBLE(AYX(J+1,1)))
!DIR$ VECTOR ALIGNED
          DO 220 I=2,NX/2+1
            TEMP=(0.0D0,1.0D0)*AYX(J+1,I)
            CX(I)=AYX(J,I)+TEMP
            CX(NX-I+2)=DCONJG(AYX(J,I)-TEMP)
  220     CONTINUE
          CALL FFT235(CX,D,WX,NX,LNX)
          DO 230 I=1,NX
            DB(I,J)=DBLE(CX(I))*DN
            DB(I,J+1)=DIMAG(CX(I))*DN
  230     CONTINUE
  240   CONTINUE
      ELSE
!$OMP DO PRIVATE(TEMP)
        DO 270 J=1,NNY-1,2
          CX(1)=DCMPLX(DBLE(AYX(J,1)),DBLE(AYX(J+1,1)))
!DIR$ VECTOR ALIGNED
          DO 250 I=2,NX/2+1
            TEMP=(0.0D0,1.0D0)*AYX(J+1,I)
            CX(I)=AYX(J,I)+TEMP
            CX(NX-I+2)=DCONJG(AYX(J,I)-TEMP)
  250     CONTINUE
          CALL FFT235(CX,D,WX,NX,LNX)
          DO 260 I=1,NX
            DB(I,J)=DBLE(CX(I))*DN
            DB(I,J+1)=DIMAG(CX(I))*DN
  260     CONTINUE
  270   CONTINUE
        CX(1)=DCMPLX(DBLE(AYX(NNY,1)),0.0D0)
!DIR$ VECTOR ALIGNED
        DO 280 I=2,NX/2+1
          CX(I)=AYX(NNY,I)
          CX(NX-I+2)=DCONJG(AYX(NNY,I))
  280   CONTINUE
        CALL FFT235(CX,D,WX,NX,LNX)
        DO 290 I=1,NX
          DB(I,NNY)=DBLE(CX(I))*DN
  290   CONTINUE
      END IF
      RETURN
      END
