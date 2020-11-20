* !!! Text format : ISO8859-1 (Edited by Linux) !!!

정의
1. MBR은 Cylinder=0, Head=0, Sector=1을 지칭합니다.
2. OS1_MBR은 Cylinder=0, Head=0, Sector=60 으로 지칭합니다.
3. OS2_MBR은 Cylinder=0, Head=0, Sector=61 으로 지칭합니다.
4. LOADER_SECTOR은 Cylinder=0, Head=0, Sector=51 으로 지칭합니다.

설치법
1. 먼저 OS1에 해당하는 운영체제를 설치합니다.
2. OS1을 설치완료후 MBR을 OS1_MBR로 복사합니다.
3. MBR을 리셋후에 OS2를 설치합니다.
4. OS2를 설치완료후 MBR을 OS2_MBR로 복사합니다.
5. 부트로더 파일인 SUM.BIN의 앞부분 512바이트(!)만을 MBR에 복사합니다.
6. SUM.BIN의 오프셋 512바이트부터(!) 나머지 부분을 LOADER_SECTOR에 복사합니다.
7. (!) loader.bin 이 복사된 영역에서 OFFSET 2 에 해당 제한용량을 섹터갯수를 단위로 하여 저장합니다. (즉, 51번 섹터의 오프셋 2)

* End of document
