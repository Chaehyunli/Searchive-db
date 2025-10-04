# 📜 Searchive-db

Searchive 프로젝트의 중앙 데이터 인프라 허브

## 🎯 프로젝트 개요

**Searchive-db**는 Searchive 프로젝트의 모든 데이터베이스, 검색 엔진, 파일 저장소, AI 모델 서버를 Docker Compose로 통합 관리하는 레포지토리입니다.

단 한 번의 명령어로 프로젝트에 필요한 모든 백그라운드 서비스를 실행하여 로컬 개발 환경을 쉽고 일관되게 구축할 수 있습니다.

---

## 🏗️ 시스템 아키텍처

Searchive는 역할에 따라 명확하게 분리된 3개의 레포지토리로 구성됩니다:

```
┌─────────────┐
│  Frontend   │ ← 사용자 인터페이스
└──────┬──────┘
       │
       ↓
┌─────────────┐
│   Backend   │ ← API 서버 / 비즈니스 로직
└──────┬──────┘
       │
       ↓
┌─────────────────────────────────────────┐
│          Searchive-db (본 레포)          │
│  ┌──────────┬──────────┬──────────────┐ │
│  │PostgreSQL│  MinIO   │Elasticsearch │ │
│  ├──────────┼──────────┼──────────────┤ │
│  │  Redis   │  Ollama  │              │ │
│  └──────────┴──────────┴──────────────┘ │
└─────────────────────────────────────────┘
```

### 데이터 흐름

1. **사용자 요청** → Frontend
2. Frontend → **Backend API 서버**
3. Backend → **Searchive-db** (PostgreSQL, MinIO, Elasticsearch, Redis, Ollama)
4. 데이터 처리 및 응답
5. Backend → Frontend → **사용자**

---

## 📁 폴더 구조

```
Searchive-db/
├── docker-compose.yml          # 전체 인프라 정의
├── .env.example                # 환경 변수 템플릿
├── README.md                   # 본 문서
└── minio-init/
    └── init-bucket.sh          # MinIO 버킷 자동 생성 스크립트
```

---

## 🛠️ 구성 요소

### 1. PostgreSQL (관계의 수호자)

**역할:** 사용자 계정, 문서 메타데이터, 파일 경로 등 구조화된 데이터를 관리합니다.

**설정 방식:**
- 컨테이너 시작 시 빈 데이터베이스만 생성됩니다.
- 테이블 스키마는 백엔드의 마이그레이션 도구(예: Prisma, TypeORM)를 통해 자동으로 생성 및 관리됩니다.
- 사용자, 암호, DB 이름은 `.env` 파일을 통해 주입됩니다.

> **💡 마이그레이션 기반 접근:**
> 이 프로젝트는 데이터베이스 스키마를 코드로 버전 관리하여 팀 협업과 스키마 변경을 안전하게 관리합니다.

---

### 2. MinIO (원본의 보관자)

**역할:** 사용자가 업로드한 모든 원본 파일(PDF, DOCX 등)을 보관하는 S3 호환 오브젝트 스토리지입니다.

**설정 방식:**
- `minio` 서비스가 건강(healthy) 상태가 되면, `minio-init` 서비스가 자동으로 실행됩니다.
- `./minio-init/init-bucket.sh` 스크립트를 통해 `user-documents` 버킷을 자동 생성합니다.

---

### 3. Redis (세션 저장소)

**역할:** 사용자 로그인 세션 정보를 저장하여 로그인 상태를 유지합니다.

**설정 방식:**
- 별도의 설정 파일 없이 공식 이미지를 실행하는 것만으로 즉시 사용 가능합니다.
- 데이터 영속성은 Docker 볼륨을 통해 보장됩니다.

---

### 4. Elasticsearch (지식의 색인자)

**역할:** 문서에서 추출된 텍스트와 벡터 데이터를 색인하여 빠른 검색을 제공합니다.

**설정 방식:**
- 단일 노드 모드로 실행되며, 보안 설정은 개발 환경을 위해 비활성화되어 있습니다.
- 벡터 검색을 위한 dense_vector 필드를 지원합니다.

---

### 5. Ollama (AI 모델 서버)

**역할:** 로컬에서 LLM(대규모 언어 모델)을 실행하여 문서 요약, 질문 답변 등의 AI 기능을 제공합니다.

**설정 방식:**
- 컨테이너 실행 후 별도로 모델을 다운로드해야 합니다.
- 기본적으로 `llama3:8b` 모델 사용을 권장합니다.

---

## 🚀 빠른 시작

### 1. 사전 요구사항

- Docker 및 Docker Compose 설치
- 최소 16GB RAM 권장 (Elasticsearch + Ollama 구동 시)

### 2. 환경 설정

`.env` 파일을 생성하고 필요한 값을 채워 넣습니다:

```bash
cp .env.example .env
# .env 파일을 편집하여 필요한 값을 설정하세요
```

### 3. 전체 인프라 실행

```bash
docker-compose up -d
```

### 4. AI 모델 다운로드 (최초 1회)

```bash
docker exec -it searchive-ollama ollama pull llama3:8b
```

### 5. 서비스 확인

각 서비스가 정상적으로 실행되었는지 확인:

```bash
docker-compose ps
```

**접속 가능한 서비스:**
- PostgreSQL: `localhost:5432`
- MinIO Console: `http://localhost:9001`
- Elasticsearch: `http://localhost:9200`
- Redis: `localhost:6379`
- Ollama: `http://localhost:11434`

### 6. 인프라 종료

```bash
docker-compose down
```

**데이터 포함 완전 삭제:**
```bash
docker-compose down -v
```

---

## 🔧 환경 변수 (.env)

주요 환경 변수는 `.env.example` 파일을 참고하세요:

```env
# PostgreSQL
POSTGRES_USER=searchive_user
POSTGRES_PASSWORD=your_secure_password
POSTGRES_DB=searchive_db

# MinIO
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin

# Elasticsearch
ELASTIC_PASSWORD=your_elastic_password
```

---

## 📊 데이터 영속성

모든 데이터는 Docker Named Volume을 통해 영속성이 보장됩니다:

- `postgres-data`: PostgreSQL 데이터
- `minio-data`: MinIO 오브젝트 스토리지
- `elasticsearch-data`: Elasticsearch 인덱스
- `redis-data`: Redis 세션 데이터
- `ollama-data`: Ollama 모델 파일

---

## 🐛 트러블슈팅

### Elasticsearch가 시작되지 않는 경우

메모리 부족일 수 있습니다. `docker-compose.yml`에서 메모리 설정 조정:

```yaml
environment:
  - "ES_JAVA_OPTS=-Xms512m -Xmx512m"  # 기본값을 줄임
```

### MinIO 버킷이 생성되지 않는 경우

수동으로 버킷 생성:

```bash
docker exec -it searchive-minio-init sh /init-bucket.sh
```

### Ollama 모델 다운로드가 느린 경우

모델 크기가 크므로 네트워크 속도에 따라 시간이 걸릴 수 있습니다. 인내심을 가지고 기다려주세요.

---

## 🏗️ 통신 아키텍처 구조도
아래 그림은 Searchive 시스템의 전체 통신 흐름을 보여줍니다.

```text
+-------------------+      (HTTPS: 3000)      +-------------------+      (HTTP API: 8000)      +-----------------------------------------+
|                   | ----------------------> |                   | -------------------------> |                                         |
| 사용자 (Web Browser)|                         | Frontend (React)  |                            |           Backend (FastAPI)             |
|                   | <---------------------- |                   | <------------------------- |                                         |
+-------------------+                         +-------------------+                            +-------------------+---------------------+
                                                                                                                   |
                                                                                                                   | (TCP/HTTP)
                                                                                                                   |
                                                                       +-------------------------------------------v-------------------------------------------+
                                                                       |               Searchive-db (Docker Network)                                         |
                                                                       |                                                                                       |
                                                                       | +------------------+  +-----------------+  +------------------+  +-----------------+   |
                                                                       | | PostgreSQL     |  | Redis           |  | MinIO            |  | Elasticsearch   |   |
                                                                       | | (Port: 5432)   |  | (Port: 6379)    |  | (API Port: 9000) |  | (Port: 9200)    |   |
                                                                       | +------------------+  +-----------------+  +------------------+  +-----------------+   |
                                                                       |                                                                                       |
                                                                       |                           +------------------+                                      |
                                                                       |                           | Ollama (LLM)     |                                      |
                                                                       |                           | (Port: 11434)    |                                      |
                                                                       |                           +------------------+                                      |
                                                                       |                                                                                       |
                                                                       +---------------------------------------------------------------------------------------+
```
| 출발지 (Source) | 목적지 (Destination) | 포트 (Port) | 통신 방식 (Protocol) | 주된 목적 |
| :--- | :--- | :--- | :--- | :--- |
| **사용자** (웹 브라우저) | **Frontend** (React) | `3000` | HTTP | `Searchive` 웹사이트 접속 및 UI 상호작용 |
| **Frontend** (React) | **Backend** (FastAPI) | `8000` | HTTP (API Call) | 로그인, 파일 업로드, 검색, AI 채팅 등 모든 기능 요청 |
| **Backend** (FastAPI) | **PostgreSQL** | `5432` | TCP (SQL) | 사용자 정보, 문서 메타데이터 조회 및 저장 |
| **Backend** (FastAPI) | **Redis** | `6379` | TCP | 사용자 로그인 세션 정보 저장 및 조회 |
| **Backend** (FastAPI) | **MinIO** | `9000` | HTTP (S3 API) | 원본 문서 파일 업로드, 다운로드, 관리 |
| **Backend** (FastAPI) | **Elasticsearch** | `9200` | HTTP (REST API) | 텍스트/벡터 데이터 색인 및 검색 쿼리 실행 |
| **Backend** (FastAPI) | **Ollama (Llama 3)** | `11434` | HTTP (API Call) | RAG 답변 생성, 요약 등 AI 추론 요청 |
| **개발자** (웹 브라우저) | **MinIO Console** | `9001` | HTTP | (개발용) 업로드된 파일 시각적 확인 |

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

## 👥 기여

버그 제보 및 기능 제안은 이슈 탭을 통해 남겨주세요.
