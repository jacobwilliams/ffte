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
C     PARALLEL 2-D COMPLEX FFT ROUTINE
C
C     FORTRAN77 + MPI SOURCE PROGRAM
C
C     CALL PZFFT2D(A,B,NX,NY,ICOMM,NPU,IOPT)
C
C     NX IS THE LENGTH OF THE TRANSFORMS IN THE X-DIRECTION (INTEGER*4)
C     NY IS THE LENGTH OF THE TRANSFORMS IN THE Y-DIRECTION (INTEGER*4)
C       ------------------------------------
C         NX = (2**IP) * (3**IQ) * (5**IR)
C         NY = (2**JP) * (3**JQ) * (5**JR)
C       ------------------------------------
C     ICOMM IS THE COMMUNICATOR (INTEGER*4)
C     NPU IS THE NUMBER OF PROCESSORS (INTEGER*4)
C     IOPT = 0 FOR INITIALIZING THE COEFFICIENTS (INTEGER*4)
C     IOPT = -1 FOR FORWARD TRANSFORM WHERE
C              A(NX,NY/NPU) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE A(*,BLOCK)
C              B(NX,NY/NPU) IS COMPLEX OUTPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE B(*,BLOCK)
C     IOPT = +1 FOR INVERSE TRANSFORM WHERE
C              A(NX,NY/NPU) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE A(*,BLOCK)
C              B(NX,NY/NPU) IS COMPLEX OUTPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE B(*,BLOCK)
C     IOPT = -2 FOR FORWARD TRANSFORM WHERE
C              A(NX,NY/NPU) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE A(*,BLOCK)
C              B(NX/NPU,NY) IS COMPLEX OUTPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE B(BLOCK,*)
C     IOPT = +2 FOR INVERSE TRANSFORM WHERE
C              A(NX/NPU,NY) IS COMPLEX INPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE A(BLOCK,*)
C              B(NX,NY/NPU) IS COMPLEX OUTPUT VECTOR (COMPLEX*16)
C!HPF$ DISTRIBUTE B(*,BLOCK)
C
C     WRITTEN BY DAISUKE TAKAHASHI
C
      SUBROUTINE PZFFT2D(A,B,NX,NY,ICOMM,NPU,IOPT)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      COMPLEX*16 A(*),B(*)
      COMPLEX*16 C((NDA2+NP)*(NBLK+1)+NP)
      COMPLEX*16 WX(NDA2/2+NP),WY(NDA2/2+NP)
      SAVE WX,WY
      INTEGER*8 NN
C
      NN=INT8(NX)*INT8(NY)/INT8(NPU)
C
      IF (IOPT .EQ. 0) THEN
        CALL SETTBL(WX,NX)
        CALL SETTBL(WY,NY)
        RETURN
      END IF
C
      IF (IOPT .EQ. 1 .OR. IOPT .EQ. 2) THEN
        DO 10 I=1,NN
          A(I)=DCONJG(A(I))
   10   CONTINUE
      END IF
C
      ND=(MAX0(NX,NY)+NP)*NBLK+NP
      IF (IOPT .EQ. -1 .OR. IOPT .EQ. -2) THEN
!$OMP PARALLEL PRIVATE(C)
        CALL PZFFT2DF(A,A,A,B,B,B,C,C,C(ND+1),WX,WY,NX,NY,ICOMM,NPU,
     1                IOPT)
!$OMP END PARALLEL
      ELSE
!$OMP PARALLEL PRIVATE(C)
        CALL PZFFT2DB(A,A,A,B,B,B,C,C,C(ND+1),WX,WY,NX,NY,ICOMM,NPU,
     1                IOPT)
!$OMP END PARALLEL
      END IF
      IF (IOPT .EQ. 1 .OR. IOPT .EQ. 2) THEN
        DN=1.0D0/(DBLE(NX)*DBLE(NY))
        DO 20 I=1,NN
          B(I)=DCONJG(B(I))*DN
   20   CONTINUE
      END IF
      RETURN
      END
      SUBROUTINE PZFFT2DF(A,AXYP,AYXP,B,BXPY,BY,CX,CY,D,WX,WY,NX,NY,
     1                    ICOMM,NPU,IOPT)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      COMPLEX*16 A(NX,*),AXYP(NX/NPU,NY/NPU,*),AYXP(NY/NPU,NX/NPU,*)
      COMPLEX*16 B(NX/NPU,*),BXPY(NX/NPU,NPU,*),BY(NY/NPU,*)
      COMPLEX*16 CX(NX+NP,*),CY(NY+NP,*),D(*)
      COMPLEX*16 WX(*),WY(*)
      DIMENSION LNX(3),LNY(3)
      INTEGER*8 NN
C
      CALL FACTOR(NX,LNX)
      CALL FACTOR(NY,LNY)
C
      NNX=NX/NPU
      NNY=NY/NPU
      NN=INT8(NX)*INT8(NY)/INT8(NPU)
C
!$OMP DO
      DO 60 JJ=1,NNY,NBLK
        DO 20 J=JJ,MIN0(JJ+NBLK-1,NNY)
          DO 10 I=1,NX
            CX(I,J-JJ+1)=A(I,J)
   10     CONTINUE
   20   CONTINUE
        DO 30 J=JJ,MIN0(JJ+NBLK-1,NNY)
          CALL FFT235(CX(1,J-JJ+1),D,WX,NX,LNX)
   30   CONTINUE
        DO 50 I=1,NX
          DO 40 J=JJ,MIN0(JJ+NBLK-1,NNY)
            BY(J,I)=CX(I,J-JJ+1)
   40     CONTINUE
   50   CONTINUE
   60 CONTINUE
!$OMP SINGLE
      CALL PZTRANS(B,A,NN,ICOMM,NPU)
!$OMP END SINGLE
!$OMP DO
      DO 130 II=1,NNX,NBLK
        DO 90 K=1,NPU
          DO 80 I=II,MIN0(II+NBLK-1,NNX)
            DO 70 J=1,NNY
              CY(J+(K-1)*NNY,I-II+1)=AYXP(J,I,K)
   70       CONTINUE
   80     CONTINUE
   90   CONTINUE
        DO 100 I=II,MIN0(II+NBLK-1,NNX)
          CALL FFT235(CY(1,I-II+1),D,WY,NY,LNY)
  100   CONTINUE
        DO 120 J=1,NY
          DO 110 I=II,MIN0(II+NBLK-1,NNX)
            B(I,J)=CY(J,I-II+1)
  110     CONTINUE
  120   CONTINUE
  130 CONTINUE
      IF (IOPT .EQ. -2) RETURN
!$OMP SINGLE
      CALL PZTRANS(B,A,NN,ICOMM,NPU)
!$OMP END SINGLE
!$OMP DO
      DO 170 JJ=1,NNY,NBLK
        DO 160 K=1,NPU
          DO 150 J=JJ,MIN0(JJ+NBLK-1,NNY)
            DO 140 I=1,NNX
              BXPY(I,K,J)=AXYP(I,J,K)
  140       CONTINUE
  150     CONTINUE
  160   CONTINUE
  170 CONTINUE
      RETURN
      END
      SUBROUTINE PZFFT2DB(A,AXPY,AY,B,BXYP,BYXP,CX,CY,D,WX,WY,NX,NY,
     1                    ICOMM,NPU,IOPT)
      IMPLICIT REAL*8 (A-H,O-Z)
      INCLUDE 'param.h'
      COMPLEX*16 A(NX/NPU,*),AXPY(NX/NPU,NPU,*),AY(NY/NPU,*)
      COMPLEX*16 B(NX,*),BXYP(NX/NPU,NY/NPU,*),BYXP(NY/NPU,NX/NPU,*)
      COMPLEX*16 CX(NX+NP,*),CY(NY+NP,*),D(*)
      COMPLEX*16 WX(*),WY(*)
      DIMENSION LNX(3),LNY(3)
      INTEGER*8 NN
C
      CALL FACTOR(NX,LNX)
      CALL FACTOR(NY,LNY)
C
      NNX=NX/NPU
      NNY=NY/NPU
      NN=INT8(NX)*INT8(NY)/INT8(NPU)
C
      IF (IOPT .EQ. 1) THEN
!$OMP DO
        DO 40 JJ=1,NNY,NBLK
          DO 30 K=1,NPU
            DO 20 J=JJ,MIN0(JJ+NBLK-1,NNY)
              DO 10 I=1,NNX
                BXYP(I,J,K)=AXPY(I,K,J)
   10         CONTINUE
   20       CONTINUE
   30     CONTINUE
   40   CONTINUE
!$OMP SINGLE
        CALL PZTRANS(B,A,NN,ICOMM,NPU)
!$OMP END SINGLE
      END IF
!$OMP DO
      DO 130 II=1,NNX,NBLK
        DO 70 JJ=1,NY,NBLK
          DO 60 I=II,MIN0(II+NBLK-1,NNX)
            DO 50 J=JJ,MIN0(JJ+NBLK-1,NY)
              CY(J,I-II+1)=A(I,J)
   50       CONTINUE
   60     CONTINUE
   70   CONTINUE
        DO 80 I=II,MIN0(II+NBLK-1,NNX)
          CALL FFT235(CY(1,I-II+1),D,WY,NY,LNY)
   80   CONTINUE
        DO 120 JJ=1,NNY,NBLK
          DO 110 K=1,NPU
            DO 100 I=II,MIN0(II+NBLK-1,NNX)
              DO 90 J=JJ,MIN0(JJ+NBLK-1,NNY)
                BYXP(J,I,K)=CY(J+(K-1)*NNY,I-II+1)
   90         CONTINUE
  100       CONTINUE
  110     CONTINUE
  120   CONTINUE
  130 CONTINUE
!$OMP SINGLE
      CALL PZTRANS(B,A,NN,ICOMM,NPU)
!$OMP END SINGLE
!$OMP DO
      DO 200 JJ=1,NNY,NBLK
        DO 160 II=1,NX,NBLK
          DO 150 J=JJ,MIN0(JJ+NBLK-1,NNY)
            DO 140 I=II,MIN0(II+NBLK-1,NX)
              CX(I,J-JJ+1)=AY(J,I)
  140       CONTINUE
  150     CONTINUE
  160   CONTINUE
        DO 170 J=JJ,MIN0(JJ+NBLK-1,NNY)
          CALL FFT235(CX(1,J-JJ+1),D,WX,NX,LNX)
  170   CONTINUE
        DO 190 J=JJ,MIN0(JJ+NBLK-1,NNY)
          DO 180 I=1,NX
            B(I,J)=CX(I,J-JJ+1)
  180     CONTINUE
  190   CONTINUE
  200 CONTINUE
      RETURN
      END
