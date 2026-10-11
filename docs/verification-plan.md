# RTL 검증 자료 복구 및 테스트 계획

[README](../README.md)

2026-10-10 당시 공개 main `823394d36a5af4e87571101de8e8b47cc9352a5c`의 RTL 11개를 확인했습니다. 당시 GitHub에는 테스트벤치·명령어 파일·파형이 없었습니다. **이후 사용자 제공 최종 발표자료에서 원본 파형·Tcl Console의 Halt 및 1,646사이클 검증 결과를 확인했으며, [별도 검증 기록](simulation-evidence.md)에 정리했습니다.** 원본 테스트벤치·.mem 파일은 여전히 저장소에 없고, 이번 문서 변경 과정에서 새로운 시뮬레이션을 실행하지 않았습니다.

## 원본으로 확인할 수 있는 것

- `TOP.v`: clk/reset, ExpSrc0~2 입력, Halt/Hex_Out 및 카운터 출력.
- `Instruction_Memory.v`: `inst_main.mem`, `inst_exc.mem`을 실행 디렉터리에서 읽음. 32비트 hex, 각각 1024워드 배열. 예외 선택 범위는 0x800 이상 0x1000 미만.
- `Program_Counter.v`: 리셋 PC=0, 예외 PC=0x800.
- 분기 지연 슬롯 없이 jal 복귀 주소는 PC+4. 기존 README의 제한 사항 유지.

원본 명령어와 파형의 바이트를 RTL만으로 복원할 수는 없습니다. 새 테스트를 만들 경우 ‘원본 복구’가 아닌 신규 검증 자료로 명시합니다.

## 제작할 테스트벤치

`tests/tb_top.v`, `tests/fixtures/inst_main.mem`, `tests/fixtures/inst_exc.mem`, `tests/expected/`를 별도 코드 PR에서 작성합니다. 정상 종료(Halt)와 최대 사이클 timeout을 모두 두고, 클럭 에지 후 안정된 출력과 레지스터/메모리 기록을 scoreboard로 비교합니다. 파형만 보고 통과 판정하지 않습니다.

| 순서 | 시나리오 | 기대 결과와 관측 지점 |
| --- | --- | --- |
| P0 | 클럭·reset·명령어 로딩 | PC=0, X/Z 없는 초기 명령어, 누락 mem 파일은 실패 처리 |
| P0 | addi/ori/lui 및 $zero 쓰기 | 즉시값 확장, 목적 레지스터 값, $zero=0 |
| P0 | add/sub/논리/시프트 | 독립 산술 기대값과 write_reg_data 비교 |
| P0 | sw→lw | 정렬 주소에 기록한 32비트 값 회수 |
| P1 | beq/bne taken·not taken | PC+4+(signed offset<<2), 지연 슬롯 미실행 |
| P1 | j/jal/jr | 목표 PC, $ra=PC+4, 복귀 경로 |
| P1 | mult/div, mfhi/mflo | 양수·음수 및 signed/unsigned 경계의 HI/LO |
| P1 | syscall | $v0=10에서 Halt, Hex_Out 출력 경로; 벤치가 종료 수행 |
| P1 | 외부 예외·eret | 0x800 진입, Cause/EPC 및 복귀; 우선순위는 CP0 정책과 대조 |
| P2 | 분류 카운터·미지원 입력 | R/I/J 집계 누락, 0 나눗셈·비정렬·mthi/mtlo를 별도 한계로 기록 |

레지스터·메모리·CP0에는 공통 reset이 없으므로 벤치의 초기화 가정과 실제 하드웨어 초기화 요구를 분리해야 합니다.

## 실행 기록 형식

향후 시뮬레이터 도구/버전, 정확한 컴파일·실행 명령, RTL 커밋 SHA, 테스트 입력 SHA-256, assert 통과/실패 수, stdout, VCD를 보관합니다. 모든 `.v` 파일을 포함하고 `Imme Extend.v` 파일명 공백을 인용합니다. 이번 **문서 갱신 환경에서는** 신규 시뮬레이션을 실행하지 않았습니다. 다만 당시 프로젝트의 실제 시뮬레이션 결과는 [원본 검증 기록](simulation-evidence.md)에서 확인됩니다.

## 사용자가 제공할 자료

우선순위: 원본 프로젝트 ZIP 및 testbench → 두 .mem 파일과 어셈블리 원문 → 시뮬레이터 설정/로그/VCD 또는 원본 파형 화면 → 과제 요구사항과 본인 담당 모듈. FPGA 보드 결과가 있다면 제약 파일·합성/타이밍 보고서·실물 사진도 별도로 확인합니다.
