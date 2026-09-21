# Verilog 기반 Single-Cycle MIPS CPU

논리회로설계 과목에서 구현한 **32비트 단일 사이클 MIPS CPU** 프로젝트입니다. 명령어 인출·해독·연산·메모리 접근·레지스터 기록 경로를 연결하고, HI/LO 연산, 외부 예외 처리, syscall 출력, 명령어 분류 카운터를 구성했습니다.

## 주요 구성

- 32비트 데이터 경로와 32개 범용 레지스터
- 산술·논리·비교·시프트 연산
- load/store, 조건 분기, 점프와 함수 호출
- signed/unsigned 곱셈·나눗셈 및 HI/LO 결과 저장
- CP0 기반 외부 예외 입력 3개, 예외 원인·복귀 주소 관리
- syscall에 따른 출력 값과 Halt 신호
- 전체 클럭 수 및 R/I/J 분류 카운터

교육용으로 구현한 명령어 부분집합이며, 전체 MIPS ISA 호환성을 검증한 구현은 아닙니다.

## 모듈 구성

| 파일 | 역할 |
| --- | --- |
| [TOP.v](TOP.v) | 데이터 경로 통합, HI/LO, 다음 PC 선택, 통계 카운터 |
| [Program_Counter.v](Program_Counter.v) | PC 저장, 리셋, 예외 주소 선택 |
| [Instruction_Memory.v](Instruction_Memory.v) | 일반·예외 명령어 ROM |
| [Control_Unit.v](Control_Unit.v) | opcode·funct 해독과 제어 신호 생성 |
| [Register_File.v](Register_File.v) | 32개 레지스터, 비동기 읽기·동기 쓰기, $zero 쓰기 보호 |
| [Imme Extend.v](Imme%20Extend.v) | 16비트 즉시값의 부호·제로 확장 |
| [ALU.v](ALU.v) | 산술·논리·시프트·곱셈·나눗셈 |
| [Data_Memory.v](Data_Memory.v) | 4096 × 32비트 데이터 메모리 |
| [CP0.v](CP0.v) | Status, Cause, EPC, Block 및 예외 제어 |
| [Syscall_Decoder.v](Syscall_Decoder.v) | Halt 및 Hex 출력 |
| [Statistics.v](Statistics.v) | R/I/J 명령어 분류 |

## 구현된 명령어 경로

| 분류 | 명령어 |
| --- | --- |
| 산술 | add, addu, sub, subu, addi, addiu |
| 논리 | and, or, xor, nor, andi, ori, xori, lui |
| 비교 | slt, sltu, slti, sltiu |
| 시프트 | sll, srl, sra, sllv, srlv, srav |
| 곱셈·나눗셈 | mult, multu, div, divu, mfhi, mflo |
| 메모리 | lw, sw |
| 분기·점프 | beq, bne, j, jal, jr |
| 시스템 | syscall, CP0 읽기·쓰기 및 eret 경로 |

`mthi`·`mtlo`는 TOP에 HI/LO 쓰기 경로가 있으나 Control_Unit의 전용 제어 처리가 없어 추가 확인이 필요합니다. ALU의 overflow·carry 출력은 현재 예외 입력으로 연결되어 있지 않습니다.

## 최상위 인터페이스

| 신호 | 방향 / 폭 | 의미 |
| --- | --- | --- |
| clk | 입력 / 1비트 | 시스템 클럭 |
| reset | 입력 / 1비트 | PC·HI/LO·통계 카운터 초기화 |
| ExpSrc0~2 | 입력 / 각 1비트 | 외부 예외 입력 |
| Halt | 출력 / 1비트 | syscall에서 $v0 = 10일 때 활성화 |
| Hex_Out | 출력 / 32비트 | syscall 시 $a0 값 저장 |
| Total_Cycles | 출력 / 32비트 | 리셋 이후 클럭 카운터 |
| R, I, J | 출력 / 각 32비트 | opcode 분류별 카운터 |

Halt는 종료를 알리는 출력이며 CPU 내부 클럭이나 PC를 자동 정지시키지 않습니다. 테스트벤치에서 이를 감지해 시뮬레이션을 종료해야 합니다. `reset`은 전체 메모리·레지스터·CP0를 초기화하는 공통 리셋이 아닙니다.

## 메모리와 예외 처리

- PC 초기값: `0x00000000`
- 예외 진입 주소: `0x00000800`
- 일반 명령어: `inst_main.mem`
- 예외 처리 명령어: `inst_exc.mem`
- 예외 ROM 선택 구간: `0x00000800 ≤ PC < 0x00001000`
- 데이터 메모리 주소 인덱스: `Address[13:2]`

CP0는 Status(12), Cause(13), EPC(14), Block(15) 레지스터를 읽는 경로를 제공합니다. 외부 예외와 차단 비트를 처리하며 eret 경로에서 EPC를 다음 PC로 선택합니다. 표준 CP0 전체 동작을 구현한 것은 아닙니다.

## 시뮬레이션 준비

현재 저장소에는 RTL 소스만 있으며, **테스트벤치와 두 .mem 파일은 포함되어 있지 않습니다.**

1. Verilog 시뮬레이터 프로젝트에 모든 `.v` 파일을 추가합니다.
2. `TOP`을 인스턴스화하는 테스트벤치를 작성합니다.
3. 클럭·리셋을 생성하고 기본적으로 `ExpSrc0~2`를 0으로 설정합니다.
4. 32비트 명령어를 16진수로 기록한 `inst_main.mem`과 `inst_exc.mem`을 실행 작업 디렉터리에 준비합니다.
5. PC, 레지스터 기록, 메모리 쓰기, Hex_Out, Halt를 관찰합니다.
6. 예외 입력을 인가하고 `0x800` 진입과 EPC 복귀 경로를 확인합니다.

파일명 `Imme Extend.v`에는 공백이 있으므로 명시적으로 명령에 넣을 때 따옴표로 감싸야 합니다.

## 구현 범위와 확인할 부분

- `jal`의 링크 값은 PC + 4이며, 분기 지연 슬롯을 구현하는 구조는 아닙니다.
- I형 통계는 `Statistics.v`에 나열된 opcode만 집계합니다. sltiu·xori·lui 등은 현재 I 카운터에 포함되지 않습니다.
- 나눗셈의 0 제수와 메모리 비정렬 접근에 대한 별도 예외 처리 경로는 없습니다.
- 곱셈·나눗셈은 조합 연산으로 기술되어 있습니다. FPGA 적용 시 타이밍·자원 사용량을 별도로 검토해야 합니다.
- 테스트벤치, 검증 로그, FPGA 제약 파일 및 합성 결과는 현재 저장소에 포함되어 있지 않습니다.
