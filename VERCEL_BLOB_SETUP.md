# Vercel Blob 설정 가이드

큰 3D 모델 파일(`nike_2.glb` - 8.2MB)은 Vercel의 5MB 파일 크기 제한을 초과하므로 Vercel Blob Storage에 업로드해야 합니다.

## 📦 Vercel Blob에 파일 업로드하기

### 1단계: Vercel 대시보드에서 Blob Storage 생성

1. [Vercel Dashboard](https://vercel.com/dashboard) 접속
2. 프로젝트 (`iamhere`) 선택
3. **Storage** 탭 클릭
4. **Create Database** 버튼 클릭
5. **Blob** 선택
6. 이름 입력 (예: `iamhere-models`) 후 **Create** 클릭

### 2단계: 파일 업로드

#### 옵션 A: Vercel Dashboard UI 사용 (권장)

1. 생성된 Blob Storage 클릭
2. **Upload** 버튼 클릭
3. `assets/nike_2.glb` 파일 선택
4. 업로드 완료 후 파일 URL 복사 (예: `https://xxxxx.public.blob.vercel-storage.com/nike_2.glb`)

#### 옵션 B: Vercel CLI 사용

```bash
# Vercel 프로젝트 연결 (처음 한 번만)
vercel link

# Blob에 파일 업로드
vercel blob upload assets/nike_2.glb --token <YOUR_VERCEL_TOKEN>
```

### 3단계: 환경 변수 설정

1. Vercel Dashboard → 프로젝트 → **Settings** → **Environment Variables**
2. 새 환경 변수 추가:
   - **Name**: `NIKE_2_GLB_URL`
   - **Value**: 업로드된 파일의 전체 URL (예: `https://xxxxx.public.blob.vercel-storage.com/nike_2.glb`)
   - **Environments**: Production, Preview, Development 모두 체크
3. **Save** 클릭

### 4단계: 재배포

환경 변수를 설정한 후 자동으로 재배포되거나, 수동으로 재배포를 트리거하세요:

```bash
git push
```

## 🔍 작동 방식

- **웹 (Vercel)**: Vercel Blob URL에서 `nike_2.glb` (8.2MB) 로드
- **모바일**: 로컬 assets에서 `nike_2.glb` 로드
- **Fallback**: 환경 변수가 없으면 작은 `nike.glb` (2.7MB) 사용

## 💰 비용

Vercel Blob Storage:
- **무료 티어**: 500MB 스토리지, 5GB 대역폭/월
- **Pro**: 100GB 스토리지, 1TB 대역폭/월

8.2MB 파일 하나는 무료 티어로 충분합니다.

## ✅ 확인

배포 후 브라우저 콘솔에서 확인:
```
📦 Web platform detected - using Vercel Blob URL
📦 Nike model path set for web: https://your-blob-url.vercel-storage.com/nike_2.glb
```

## 🔧 트러블슈팅

### CORS 에러 발생 시

Vercel Blob Storage는 기본적으로 Public Access가 활성화되어 있습니다. CORS 에러가 발생하면:

1. Blob Storage 설정에서 **Public Access** 확인
2. 파일 업로드 시 `--public` 플래그 사용

### 파일이 로드되지 않는 경우

1. 환경 변수 `NIKE_2_GLB_URL`이 올바르게 설정되었는지 확인
2. URL이 공개 접근 가능한지 확인 (브라우저에서 직접 접속 테스트)
3. 브라우저 콘솔에서 로딩 로그 확인
